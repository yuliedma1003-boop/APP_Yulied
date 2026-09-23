import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models.dart';

String _hash(String email, String password) {
  return sha256.convert(utf8.encode('${email.toLowerCase()}|$password|titanfit-sena')).toString();
}

class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();
  Database? _db;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'titanfit.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            name TEXT,
            email TEXT UNIQUE,
            role TEXT,
            phone TEXT,
            password_hash TEXT,
            token TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE classes (
            id TEXT PRIMARY KEY,
            name TEXT,
            description TEXT,
            trainer TEXT,
            starts_at TEXT,
            duration_min INTEGER,
            capacity INTEGER,
            available INTEGER,
            room TEXT,
            difficulty TEXT,
            sync_status TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE bookings (
            id TEXT PRIMARY KEY,
            user_id TEXT,
            class_id TEXT,
            status TEXT,
            notes TEXT,
            user_name TEXT,
            user_email TEXT,
            class_name TEXT,
            trainer TEXT,
            starts_at TEXT,
            room TEXT,
            sync_status TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE plans (
            id TEXT PRIMARY KEY,
            name TEXT,
            description TEXT,
            duration_days INTEGER,
            price INTEGER,
            benefits TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE memberships (
            id TEXT PRIMARY KEY,
            user_id TEXT,
            plan_id TEXT,
            start_date TEXT,
            end_date TEXT,
            status TEXT,
            plan_name TEXT,
            sync_status TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE routines (
            id TEXT PRIMARY KEY,
            name TEXT,
            goal TEXT,
            level TEXT,
            duration_weeks INTEGER,
            exercises TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE inventory (
            id TEXT PRIMARY KEY,
            name TEXT,
            category TEXT,
            quantity INTEGER,
            status TEXT,
            location TEXT,
            sync_status TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entity TEXT,
            operation TEXT,
            record_json TEXT,
            created_at TEXT
          )
        ''');
      },
    );
    await seedDemoIfEmpty();
  }

  Future<void> seedDemoIfEmpty() async {
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM classes')) ?? 0;
    if (count > 0) return;
    final now = DateTime.now();
    await upsertUser(AppUser(
      id: 'admin-titanfit-001',
      name: 'Administrador TitanFit',
      email: 'admin@titanfit.co',
      role: 'administrador',
      phone: '3000000000',
      passwordHash: _hash('admin@titanfit.co', 'Admin123*'),
    ));
    await upsertUser(AppUser(
      id: 'user-yulied-001',
      name: 'Yulied Marcela Lopez',
      email: 'yulied@titanfit.co',
      role: 'cliente',
      phone: '3105550188',
      passwordHash: _hash('yulied@titanfit.co', 'Yulied123*'),
    ));

    Future<void> addClass(String id, String name, String trainer, int hours, String room, String difficulty, String description) async {
      final starts = now.add(Duration(hours: hours)).toIso8601String();
      await upsertClass(GymClass(
        id: id,
        name: name,
        description: description,
        trainer: trainer,
        startsAt: starts,
        durationMin: 45,
        capacity: 16,
        available: 15,
        room: room,
        difficulty: difficulty,
      ));
    }

    await addClass('class-local-001', 'Spinning Power', 'Camila Restrepo', 6, 'Sala Cardio', 'intermedio', 'Intervalos sobre bicicleta.');
    await addClass('class-local-002', 'HIIT Titan', 'Andres Molina', 20, 'Zona Funcional', 'avanzado', 'Circuito explosivo de fuerza y cardio.');
    await addClass('class-local-003', 'Yoga Restaurativo', 'Laura Mendez', 30, 'Sala Yoga', 'principiante', 'Movilidad y respiración.');
    await addClass('class-local-004', 'Boxeo Fitness', 'Valentina Cruz', 44, 'Ring', 'intermedio', 'Técnica de golpes y saco.');

    await replacePlans([
      MembershipPlan(id: 'plan-basico', name: 'Plan Básico', description: 'Pesas y 4 clases al mes', durationDays: 30, price: 89900, benefits: ['Zona de pesas', '4 clases grupales']),
      MembershipPlan(id: 'plan-plus', name: 'Plan Plus', description: 'Clases ilimitadas 90 días', durationDays: 90, price: 239900, benefits: ['Clases ilimitadas', 'Valoración mensual', 'Sauna']),
      MembershipPlan(id: 'plan-elite', name: 'Plan Elite', description: 'Anual con entrenador', durationDays: 365, price: 799900, benefits: ['Todo Plus', '4 sesiones 1 a 1', 'Nutrición']),
    ]);

    await upsertMembership(Membership(
      id: 'mem-yulied-001',
      userId: 'user-yulied-001',
      planId: 'plan-plus',
      startDate: now.toIso8601String().substring(0, 10),
      endDate: now.add(const Duration(days: 30)).toIso8601String().substring(0, 10),
      status: 'activa',
      planName: 'Plan Plus',
    ));

    await replaceRoutines([
      Routine(id: 'rutina-fullbody', name: 'Full Body Principiante', goal: 'Adaptación', level: 'principiante', durationWeeks: 4, exercises: [
        {'name': 'Sentadilla goblet', 'sets': '3', 'reps': '12', 'rest': '60s'},
        {'name': 'Press con mancuernas', 'sets': '3', 'reps': '10', 'rest': '75s'},
        {'name': 'Plancha', 'sets': '3', 'reps': '30s', 'rest': '45s'},
      ]),
      Routine(id: 'rutina-hipertrofia', name: 'Hipertrofia Upper/Lower', goal: 'Masa muscular', level: 'intermedio', durationWeeks: 8, exercises: [
        {'name': 'Press banca', 'sets': '4', 'reps': '8-10', 'rest': '90s'},
        {'name': 'Dominadas', 'sets': '4', 'reps': '8', 'rest': '90s'},
      ]),
    ]);

    await replaceInventory([
      InventoryItem(id: 'inv-01', name: 'Mancuernas 10kg (par)', category: 'pesas', quantity: 12, status: 'operativo', location: 'Sala de pesas'),
      InventoryItem(id: 'inv-04', name: 'Bicicleta spinning', category: 'cardio', quantity: 18, status: 'operativo', location: 'Sala Cardio'),
      InventoryItem(id: 'inv-07', name: 'Saco de boxeo', category: 'combate', quantity: 4, status: 'mantenimiento', location: 'Ring'),
    ]);

    await upsertBooking(Booking(
      id: 'book-001',
      userId: 'user-yulied-001',
      classId: 'class-local-001',
      status: 'confirmada',
      userName: 'Yulied Marcela Lopez',
      userEmail: 'yulied@titanfit.co',
      className: 'Spinning Power',
      trainer: 'Camila Restrepo',
      startsAt: now.add(const Duration(hours: 6)).toIso8601String(),
      room: 'Sala Cardio',
    ));
    await upsertBooking(Booking(
      id: 'book-002',
      userId: 'user-yulied-001',
      classId: 'class-local-002',
      status: 'pendiente',
      userName: 'Yulied Marcela Lopez',
      userEmail: 'yulied@titanfit.co',
      className: 'HIIT Titan',
      trainer: 'Andres Molina',
      startsAt: now.add(const Duration(hours: 20)).toIso8601String(),
      room: 'Zona Funcional',
    ));
  }

  Database get db => _db!;

  Future<void> upsertUser(AppUser user) async {
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<AppUser?> userByEmail(String email) async {
    final rows = await db.query('users', where: 'email = ?', whereArgs: [email.toLowerCase()]);
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<AppUser?> userById(String id) async {
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<void> replaceClasses(List<GymClass> items) async {
    final batch = db.batch();
    batch.delete('classes');
    for (final item in items) {
      batch.insert('classes', item.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertClass(GymClass item) async {
    await db.insert('classes', item.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<GymClass>> classes() async {
    final rows = await db.query('classes', orderBy: 'starts_at ASC');
    return rows.map(GymClass.fromDb).toList();
  }

  Future<void> deleteClass(String id) async {
    await db.delete('bookings', where: 'class_id = ?', whereArgs: [id]);
    await db.delete('classes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> upsertBooking(Booking item) async {
    await db.insert('bookings', item.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> replaceBookings(List<Booking> items) async {
    final batch = db.batch();
    batch.delete('bookings');
    for (final item in items) {
      batch.insert('bookings', item.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Booking>> bookings() async {
    final rows = await db.query('bookings', orderBy: 'starts_at ASC');
    return rows.map(Booking.fromDb).toList();
  }

  Future<void> replacePlans(List<MembershipPlan> items) async {
    final batch = db.batch();
    batch.delete('plans');
    for (final item in items) {
      batch.insert('plans', item.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<MembershipPlan>> plans() async {
    final rows = await db.query('plans', orderBy: 'price ASC');
    return rows.map(MembershipPlan.fromDb).toList();
  }

  Future<void> replaceMemberships(List<Membership> items) async {
    final batch = db.batch();
    batch.delete('memberships');
    for (final item in items) {
      batch.insert('memberships', item.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertMembership(Membership item) async {
    await db.insert('memberships', item.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Membership>> memberships() async {
    final rows = await db.query('memberships', orderBy: 'start_date DESC');
    return rows.map(Membership.fromDb).toList();
  }

  Future<void> replaceRoutines(List<Routine> items) async {
    final batch = db.batch();
    batch.delete('routines');
    for (final item in items) {
      batch.insert('routines', item.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Routine>> routines() async {
    final rows = await db.query('routines', orderBy: 'name ASC');
    return rows.map(Routine.fromDb).toList();
  }

  Future<void> replaceInventory(List<InventoryItem> items) async {
    final batch = db.batch();
    batch.delete('inventory');
    for (final item in items) {
      batch.insert('inventory', item.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertInventory(InventoryItem item) async {
    await db.insert('inventory', item.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteInventory(String id) async {
    await db.delete('inventory', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<InventoryItem>> inventory() async {
    final rows = await db.query('inventory', orderBy: 'name ASC');
    return rows.map(InventoryItem.fromDb).toList();
  }

  Future<void> enqueue(String entity, String operation, Map<String, dynamic> record) async {
    await db.insert('sync_queue', {
      'entity': entity,
      'operation': operation,
      'record_json': jsonEncode(record),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<QueueItem>> queue() async {
    final rows = await db.query('sync_queue', orderBy: 'id ASC');
    return rows
        .map(
          (row) => QueueItem(
            id: row['id'] as int,
            entity: row['entity'] as String,
            operation: row['operation'] as String,
            record: jsonDecode(row['record_json'] as String) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> clearQueue() async {
    await db.delete('sync_queue');
  }

  Future<int> queueCount() async {
    final result = await db.rawQuery('SELECT COUNT(*) AS n FROM sync_queue');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
