import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../format.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/titan_ui.dart';
import 'auth_screens.dart';
import 'bookings_screens.dart';
import 'classes_screen.dart';
import 'inventory_screen.dart';
import 'memberships_screen.dart';
import 'routines_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final items = app.isAdmin
        ? const [
            _Nav(Icons.grid_view_rounded, 'Inicio'),
            _Nav(Icons.fact_check_outlined, 'Gestión'),
            _Nav(Icons.event_available_outlined, 'Clases'),
            _Nav(Icons.inventory_2_outlined, 'Inventario'),
            _Nav(Icons.person_outline, 'Perfil'),
          ]
        : const [
            _Nav(Icons.grid_view_rounded, 'Inicio'),
            _Nav(Icons.fitness_center_rounded, 'Agendar'),
            _Nav(Icons.cancel_outlined, 'Cancelar'),
            _Nav(Icons.workspace_premium_outlined, 'Planes'),
            _Nav(Icons.person_outline, 'Perfil'),
          ];
    final pages = app.isAdmin
        ? const [
            DashboardScreen(),
            AdminBookingsScreen(),
            ClassesScreen(),
            InventoryScreen(),
            ProfileScreen(),
          ]
        : const [
            DashboardScreen(),
            ClassesScreen(),
            MyBookingsScreen(),
            MembershipsScreen(),
            ProfileScreen(),
          ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OfflineBar(
              online: app.online,
              pending: app.pendingCount,
              label: app.lastSyncLabel,
              onSync: app.syncing ? null : () => app.syncNow(),
            ),
            Expanded(child: IndexedStack(index: index, children: pages)),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        backgroundColor: TitanColors.surface,
        indicatorColor: TitanColors.orange.withValues(alpha: 0.2),
        destinations: [
          for (final item in items) NavigationDestination(icon: Icon(item.icon), label: item.label),
        ],
      ),
    );
  }
}

class _Nav {
  const _Nav(this.icon, this.label);
  final IconData icon;
  final String label;
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final name = app.user?.name.split(' ').first ?? 'Atleta';
    final next = app.myBookings.where((b) => b.status != 'cancelada').toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final upcoming = next.where((b) => b.date.isAfter(DateTime.now())).firstOrNull;
    final active = app.myBookings.where((b) => b.status != 'cancelada').length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Text(app.isAdmin ? 'PANEL ADMIN' : 'SEDE PRINCIPAL', style: const TextStyle(color: TitanColors.orange, fontWeight: FontWeight.w800, letterSpacing: 1.4, fontSize: 12)),
        DisplayTitle('HOLA, ${name.toUpperCase()}'),
        Text(app.isAdmin ? 'Confirma, cancela y administra el gimnasio.' : 'Agenda tu clase y cancela tu cupo cuando lo necesites.', style: const TextStyle(color: TitanColors.muted)),
        const SizedBox(height: 18),
        TitanCard(
          accent: TitanColors.orange,
          child: Row(
            children: [
              const DumbbellMark(size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.activeMembership?.planName ?? 'Sin membresía activa', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(
                      app.activeMembership == null ? 'Elige un plan para entrenar con beneficios' : 'Vigente hasta ${app.activeMembership!.endDate}',
                      style: const TextStyle(color: TitanColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _stat('Reservas', '$active', Icons.event_available)),
            const SizedBox(width: 10),
            Expanded(child: _stat('Clases', '${app.upcomingClasses.length}', Icons.fitness_center)),
            const SizedBox(width: 10),
            Expanded(child: _stat(app.online ? 'Online' : 'SQLite', '${app.pendingCount}', Icons.sync)),
          ],
        ),
        const SizedBox(height: 18),
        const Text('Próxima sesión', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (upcoming == null)
          TitanCard(child: Text(app.isAdmin ? 'Cuando un cliente agende, verás la reserva en Gestión.' : 'Aún no tienes clases agendadas. Reserva en Agendar.', style: const TextStyle(color: TitanColors.muted)))
        else
          TitanCard(
            accent: statusColor(upcoming.status),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Expanded(child: Text(upcoming.className, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))), StatusPill(upcoming.status, color: statusColor(upcoming.status))]),
                const SizedBox(height: 6),
                Text(prettyDate(upcoming.startsAt), style: const TextStyle(color: TitanColors.muted)),
                Text('${upcoming.trainer} · ${upcoming.room}', style: const TextStyle(color: TitanColors.muted, fontSize: 12)),
              ],
            ),
          ),
        if (!app.isAdmin) ...[
          const SizedBox(height: 18),
          const Text('Módulos', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chip(context, Icons.fitness_center, 'Agendar clase', const ClassesScreen()),
              _chip(context, Icons.cancel_outlined, 'Cancelar reserva', const MyBookingsScreen()),
              _chip(context, Icons.workspace_premium_outlined, 'Planes', const MembershipsScreen()),
              _chip(context, Icons.list_alt_rounded, 'Rutinas', const RoutinesScreen()),
            ],
          ),
        ] else ...[
          const SizedBox(height: 18),
          const Text('Acciones de administrador', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('${app.bookings.where((b) => b.status == 'pendiente').length} reservas pendientes de confirmar o cancelar', style: const TextStyle(color: TitanColors.muted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chip(context, Icons.fact_check_outlined, 'Confirmar o cancelar', const AdminBookingsScreen()),
              _chip(context, Icons.event_available_outlined, 'Crear / editar clases', const ClassesScreen()),
              _chip(context, Icons.inventory_2_outlined, 'Inventario', const InventoryScreen()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return TitanCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: TitanColors.orange, size: 18),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontFamily: 'Anton', fontSize: 22)),
          Text(label, style: const TextStyle(color: TitanColors.muted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label, Widget page) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: TitanColors.orange),
      label: Text(label),
      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(
            appBar: AppBar(title: Text(label)),
            body: Column(
              children: [
                OfflineBar(
                  online: context.read<AppState>().online,
                  pending: context.read<AppState>().pendingCount,
                  label: context.read<AppState>().lastSyncLabel,
                  onSync: () => context.read<AppState>().syncNow(),
                ),
                Expanded(child: page),
              ],
            ),
          ))),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController api;

  @override
  void initState() {
    super.initState();
    api = TextEditingController(text: context.read<AppState>().apiUrl);
  }

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const Text('CUENTA', style: TextStyle(color: TitanColors.orange, fontWeight: FontWeight.w800, letterSpacing: 1.4, fontSize: 12)),
        const DisplayTitle('PERFIL'),
        const SizedBox(height: 12),
        TitanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(app.user?.name ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              Text(app.user?.email ?? '', style: const TextStyle(color: TitanColors.muted)),
              const SizedBox(height: 8),
              StatusPill(app.user?.role ?? '', color: app.isAdmin ? TitanColors.amber : TitanColors.info),
              const SizedBox(height: 10),
              Text(
                app.isAdmin
                    ? 'Puedes: confirmar reservas, cancelar cualquier cupo, crear/editar/eliminar clases y gestionar inventario.'
                    : 'Puedes: registrarte, iniciar sesión, agendar clases, cancelar tus reservas y activar un plan.',
                style: const TextStyle(color: TitanColors.muted, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('API del backend', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TextField(controller: api, decoration: const InputDecoration(labelText: 'URL', hintText: 'http://192.168.1.21:3000')),
        const SizedBox(height: 10),
        TitanButton(
          label: 'Guardar URL y probar',
          filled: false,
          icon: Icons.save_outlined,
          onPressed: () async {
            await app.setApiUrl(api.text);
            if (!context.mounted) return;
            flash(context, app.online ? 'API en línea' : 'No se alcanzó la API. Seguimos en SQLite.', error: !app.online);
          },
        ),
        const SizedBox(height: 10),
        TitanButton(
          label: app.syncing ? 'Sincronizando...' : 'Sincronizar ahora',
          icon: Icons.sync,
          busy: app.syncing,
          onPressed: app.syncing
              ? null
              : () async {
                  await app.syncNow();
                  if (!context.mounted) return;
                  if (!app.online) {
                    flash(context, 'Sin conexión. Los cambios siguen guardados en SQLite', error: true);
                  } else if (app.lastError != null) {
                    flash(context, app.lastError!, error: true);
                  } else {
                    flash(context, 'Sincronización correcta');
                  }
                },
        ),
        if (!app.isAdmin) ...[
          const SizedBox(height: 16),
          TitanButton(
            label: 'Ver rutinas de entrenamiento',
            filled: false,
            icon: Icons.list_alt,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => Scaffold(appBar: AppBar(title: const Text('Rutinas')), body: const RoutinesScreen()),
            )),
          ),
        ],
        const SizedBox(height: 24),
        const TitanCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Proyecto final de clase', style: TextStyle(fontWeight: FontWeight.w800)),
              SizedBox(height: 6),
              Text('Estudiante: Yulied Marcela Lopez\nPrograma: ADSO · SENA\nFicha: 3311983\nTemática: Gimnasio\nMódulos: Login, Registro, Agendar clase, Gestión admin, Cancelación, Planes, Rutinas e Inventario.\nOffline: SQLite · Online: API REST + sync.', style: TextStyle(color: TitanColors.muted, height: 1.45)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TitanButton(
          label: 'Cerrar sesión',
          filled: false,
          icon: Icons.logout,
          onPressed: () async {
            await app.logout();
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
          },
        ),
      ],
    );
  }
}
