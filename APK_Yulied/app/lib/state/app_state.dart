import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models.dart';
import '../data/api_client.dart';
import '../data/local_db.dart';

const defaultApiUrl = 'http://10.15.10.21:3000';

String localPasswordHash(String email, String password) {
  return sha256.convert(utf8.encode('${email.toLowerCase()}|$password|titanfit-sena')).toString();
}

class AppState extends ChangeNotifier {
  AppState();

  final LocalDb db = LocalDb.instance;
  final ApiClient api = ApiClient(baseUrl: defaultApiUrl);
  final _uuid = const Uuid();

  AppUser? user;
  bool online = false;
  bool syncing = false;
  bool ready = false;
  String? lastError;
  String lastSyncLabel = 'Sin sincronizar';
  int pendingCount = 0;
  String apiUrl = defaultApiUrl;

  List<GymClass> classes = [];
  List<Booking> bookings = [];
  List<MembershipPlan> plans = [];
  List<Membership> memberships = [];
  List<Routine> routines = [];
  List<InventoryItem> inventory = [];

  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool get isLoggedIn => user != null;
  bool get isAdmin => user?.isAdmin ?? false;
  Membership? get activeMembership =>
      memberships.where((m) => m.userId == user?.id && m.status == 'activa').firstOrNull;

  List<Booking> get myBookings => bookings.where((b) => b.userId == user?.id).toList();
  List<GymClass> get upcomingClasses =>
      classes.where((c) => c.date.isAfter(DateTime.now().subtract(const Duration(hours: 1)))).toList();

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    apiUrl = prefs.getString('apiUrl') ?? defaultApiUrl;
    api.baseUrl = apiUrl;
    final savedId = prefs.getString('userId');
    if (savedId != null) {
      user = await db.userById(savedId);
      api.token = user?.token;
    }
    await reloadLocal();
    await refreshConnectivity();
    _sub = Connectivity().onConnectivityChanged.listen((_) => refreshConnectivity());
    ready = true;
    notifyListeners();
    if (online && user != null) {
      unawaited(syncNow());
    }
  }

  Future<void> setApiUrl(String value) async {
    apiUrl = value.trim().replaceAll(RegExp(r'/$'), '');
    api.baseUrl = apiUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apiUrl', apiUrl);
    notifyListeners();
    await refreshConnectivity();
    if (online && user != null) await syncNow();
  }

  Future<void> refreshConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    final hasNet = !result.contains(ConnectivityResult.none);
    var reachable = false;
    if (hasNet) reachable = await api.health();
    final changed = online != reachable;
    online = reachable;
    if (changed) notifyListeners();
    if (online && user != null && pendingCount > 0) {
      unawaited(syncNow());
    }
  }

  Future<void> reloadLocal() async {
    classes = await db.classes();
    bookings = await db.bookings();
    plans = await db.plans();
    memberships = await db.memberships();
    routines = await db.routines();
    inventory = await db.inventory();
    pendingCount = await db.queueCount();
    notifyListeners();
  }

  Future<void> _saveSession(AppUser next) async {
    user = next;
    api.token = next.token;
    await db.upsertUser(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', next.id);
    await prefs.remove('lastSync');
  }

  Future<void> login(String email, String password) async {
    lastError = null;
    notifyListeners();
    await refreshConnectivity();
    if (online) {
      final data = await api.login(email, password);
      final mapped = AppUser.fromMap({
        ...Map<String, dynamic>.from(data['user'] as Map),
        'password_hash': localPasswordHash(email, password),
        'token': data['token'],
      });
      await _saveSession(mapped);
      await syncNow();
      return;
    }
    final local = await db.userByEmail(email.trim().toLowerCase());
    if (local == null || local.passwordHash != localPasswordHash(email, password)) {
      throw ApiException('Sin conexión y no hay sesión previa en este dispositivo');
    }
    await _saveSession(local);
    await reloadLocal();
  }

  Future<void> register({required String name, required String email, required String password, String phone = ''}) async {
    lastError = null;
    final id = _uuid.v4();
    await refreshConnectivity();
    if (online) {
      final data = await api.register(id: id, name: name, email: email, password: password, phone: phone);
      final mapped = AppUser.fromMap({
        ...Map<String, dynamic>.from(data['user'] as Map),
        'password_hash': localPasswordHash(email, password),
        'token': data['token'],
      });
      await _saveSession(mapped);
      await syncNow();
      return;
    }
    final exists = await db.userByEmail(email.trim().toLowerCase());
    if (exists != null) throw ApiException('Ese correo ya está registrado en este dispositivo');
    final local = AppUser(
      id: id,
      name: name,
      email: email.trim().toLowerCase(),
      role: 'cliente',
      phone: phone,
      passwordHash: localPasswordHash(email, password),
    );
    await db.enqueue('users', 'create', {
      'id': id,
      'name': name,
      'email': email.trim().toLowerCase(),
      'password': password,
      'phone': phone,
    });
    await _saveSession(local);
    await reloadLocal();
  }

  Future<void> logout() async {
    user = null;
    api.token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    notifyListeners();
  }

  bool hasActiveBooking(String classId) {
    return bookings.any((b) => b.userId == user?.id && b.classId == classId && b.status != 'cancelada');
  }

  Future<void> bookClass(GymClass gymClass) async {
    if (user == null) return;
    if (isAdmin) throw ApiException('El administrador gestiona reservas; no agenda como cliente');
    final existing = bookings.where((b) => b.userId == user!.id && b.classId == gymClass.id && b.status != 'cancelada');
    if (existing.isNotEmpty) throw ApiException('Ya tienes una reserva en esta clase');
    if (gymClass.available <= 0) throw ApiException('No hay cupos disponibles');
    final booking = Booking(
      id: _uuid.v4(),
      userId: user!.id,
      classId: gymClass.id,
      status: 'pendiente',
      userName: user!.name,
      userEmail: user!.email,
      className: gymClass.name,
      trainer: gymClass.trainer,
      startsAt: gymClass.startsAt,
      room: gymClass.room,
      syncStatus: 'pending',
    );
    await db.upsertBooking(booking);
    await db.upsertClass(gymClass.copyWith(available: gymClass.available <= 0 ? 0 : gymClass.available - 1));
    await db.enqueue('bookings', 'create', {
      'id': booking.id,
      'classId': booking.classId,
      'notes': '',
    });
    await reloadLocal();
    await syncNow();
  }

  Future<void> updateBookingStatus(Booking booking, String status) async {
    if (user == null) return;
    if (status == 'confirmada' && !isAdmin) throw ApiException('Solo el administrador confirma reservas');
    if (status == 'cancelada' && booking.userId != user!.id && !isAdmin) {
      throw ApiException('No puedes cancelar esta reserva');
    }
    final updated = Booking(
      id: booking.id,
      userId: booking.userId,
      classId: booking.classId,
      status: status,
      notes: booking.notes,
      userName: booking.userName,
      userEmail: booking.userEmail,
      className: booking.className,
      trainer: booking.trainer,
      startsAt: booking.startsAt,
      room: booking.room,
      syncStatus: 'pending',
    );
    await db.upsertBooking(updated);
    if (status == 'cancelada' && booking.status != 'cancelada') {
      final gymClass = classes.where((c) => c.id == booking.classId).firstOrNull;
      if (gymClass != null) {
        await db.upsertClass(gymClass.copyWith(
          available: gymClass.available >= gymClass.capacity ? gymClass.capacity : gymClass.available + 1,
        ));
      }
    }
    await db.enqueue('bookings', 'update', {'id': booking.id, 'status': status, 'notes': booking.notes});
    await reloadLocal();
    await syncNow();
  }

  Future<void> subscribe(MembershipPlan plan) async {
    if (user == null) return;
    if (isAdmin) throw ApiException('El administrador no activa membresías de cliente');
    final start = DateTime.now();
    final end = start.add(Duration(days: plan.durationDays));
    final membership = Membership(
      id: _uuid.v4(),
      userId: user!.id,
      planId: plan.id,
      startDate: start.toIso8601String().substring(0, 10),
      endDate: end.toIso8601String().substring(0, 10),
      status: 'activa',
      planName: plan.name,
      syncStatus: 'pending',
    );
    await db.upsertMembership(membership);
    await db.enqueue('memberships', 'create', {'id': membership.id, 'planId': plan.id});
    await reloadLocal();
    await syncNow();
  }

  Future<void> saveClass(GymClass gymClass, {required bool isNew}) async {
    if (!isAdmin) throw ApiException('Solo el administrador crea o edita clases');
    await db.upsertClass(gymClass.copyWith(syncStatus: 'pending'));
    await db.enqueue('classes', isNew ? 'create' : 'update', gymClass.toApi());
    await reloadLocal();
    await syncNow();
  }

  Future<void> deleteClass(GymClass gymClass) async {
    if (!isAdmin) throw ApiException('Solo el administrador elimina clases');
    await db.deleteClass(gymClass.id);
    await db.enqueue('classes', 'delete', {'id': gymClass.id});
    await reloadLocal();
    await syncNow();
  }

  Future<void> saveInventory(InventoryItem item, {required bool isNew}) async {
    if (!isAdmin) throw ApiException('Solo el administrador gestiona inventario');
    await db.upsertInventory(item.copyWith(syncStatus: 'pending'));
    await db.enqueue('inventory', isNew ? 'create' : 'update', item.toApi());
    await reloadLocal();
    await syncNow();
  }

  Future<void> removeInventory(InventoryItem item) async {
    if (!isAdmin) throw ApiException('Solo el administrador gestiona inventario');
    await db.deleteInventory(item.id);
    await db.enqueue('inventory', 'delete', {'id': item.id});
    await reloadLocal();
    await syncNow();
  }

  Future<void> syncNow() async {
    if (user == null) return;
    await refreshConnectivity();
    if (!online) {
      lastSyncLabel = 'Offline · $pendingCount cambio(s) pendiente(s)';
      notifyListeners();
      return;
    }
    syncing = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = await db.queue();
      final changes = queue.map((q) => {'entity': q.entity, 'operation': q.operation, 'record': q.record}).toList();
      final data = await api.sync(since: null, changes: changes);
      await _applySnapshot(data['snapshot'] as Map<String, dynamic>? ?? {});
      await db.clearQueue();
      final serverTime = data['serverTime']?.toString() ?? DateTime.now().toIso8601String();
      await prefs.setString('lastSync', serverTime);
      lastSyncLabel = 'Sincronizado ${_clock()}';
      lastError = null;
    } on ApiException catch (e) {
      lastError = e.message;
      lastSyncLabel = 'Error de sync: ${e.message}';
    } catch (e) {
      lastError = 'No se pudo sincronizar';
      lastSyncLabel = 'Sin conexión con la API';
      online = false;
    } finally {
      syncing = false;
      await reloadLocal();
    }
  }

  Future<void> _applySnapshot(Map<String, dynamic> snap) async {
    List<Map<String, dynamic>> listOf(String key) {
      final raw = snap[key];
      if (raw is! List) return [];
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    await db.replaceClasses(listOf('classes').map(GymClass.fromApi).toList());
    for (final local in classes.where((c) => c.syncStatus == 'pending')) {
      final exists = listOf('classes').any((row) => row['id']?.toString() == local.id);
      if (!exists) await db.upsertClass(local);
    }
    var nextBookings = listOf('bookings').map(Booking.fromApi).toList();
    if (!isAdmin && user != null) {
      nextBookings = nextBookings.where((b) => b.userId == user!.id).toList();
    }
    final pendingBookings = bookings.where((b) => b.syncStatus == 'pending').toList();
    await db.replaceBookings(nextBookings);
    for (final local in pendingBookings) {
      if (nextBookings.every((b) => b.id != local.id)) await db.upsertBooking(local);
    }
    await db.replacePlans(listOf('plans').map(MembershipPlan.fromApi).toList());
    var nextMem = listOf('memberships').map(Membership.fromApi).toList();
    if (!isAdmin && user != null) {
      nextMem = nextMem.where((m) => m.userId == user!.id).toList();
    }
    await db.replaceMemberships(nextMem);
    await db.replaceRoutines(listOf('routines').map(Routine.fromApi).toList());
    if (isAdmin) {
      final remoteInv = listOf('inventory').map(InventoryItem.fromApi).toList();
      final pendingInv = inventory.where((i) => i.syncStatus == 'pending').toList();
      await db.replaceInventory(remoteInv);
      for (final local in pendingInv) {
        if (remoteInv.every((i) => i.id != local.id)) await db.upsertInventory(local);
      }
    }
  }

  String _clock() {
    final n = DateTime.now();
    final h = n.hour.toString().padLeft(2, '0');
    final m = n.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
