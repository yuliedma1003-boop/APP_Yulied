import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../format.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/titan_ui.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final items = app.myBookings;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const Text('PERFIL USUARIO', style: TextStyle(color: TitanColors.orange, fontWeight: FontWeight.w800, letterSpacing: 1.4, fontSize: 12)),
        const DisplayTitle('CANCELAR'),
        const Text('Cancela tu propia reserva (pendiente o confirmada). El cambio queda en SQLite y se sincroniza con la API.', style: TextStyle(color: TitanColors.muted)),
        const SizedBox(height: 16),
        if (items.isEmpty)
          const EmptyState(icon: Icons.event_busy, title: 'Sin reservas', subtitle: 'Agenda una clase para poder cancelarla aquí.')
        else
          ...items.map((item) => _BookingTile(
                item: item,
                actions: item.status == 'cancelada'
                    ? const []
                    : [
                        ('Cancelar mi reserva', 'cancelada', TitanColors.danger),
                      ],
              )),
      ],
    );
  }
}

class AdminBookingsScreen extends StatelessWidget {
  const AdminBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pending = app.bookings.where((b) => b.status == 'pendiente').toList();
    final confirmed = app.bookings.where((b) => b.status == 'confirmada').toList();
    final cancelled = app.bookings.where((b) => b.status == 'cancelada').toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const Text('PERFIL ADMINISTRADOR', style: TextStyle(color: TitanColors.orange, fontWeight: FontWeight.w800, letterSpacing: 1.4, fontSize: 12)),
        const DisplayTitle('GESTIÓN'),
        const Text('Confirma o cancela reservas de cualquier cliente. Puedes cancelar también las ya confirmadas.', style: TextStyle(color: TitanColors.muted)),
        const SizedBox(height: 16),
        Text('Pendientes (${pending.length})', style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (pending.isEmpty)
          const Text('No hay reservas por confirmar.', style: TextStyle(color: TitanColors.muted))
        else
          ...pending.map((item) => _BookingTile(
                item: item,
                showUser: true,
                actions: const [
                  ('Confirmar', 'confirmada', TitanColors.mint),
                  ('Cancelar', 'cancelada', TitanColors.danger),
                ],
              )),
        const SizedBox(height: 18),
        Text('Confirmadas (${confirmed.length})', style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (confirmed.isEmpty)
          const Text('No hay reservas confirmadas.', style: TextStyle(color: TitanColors.muted))
        else
          ...confirmed.map((item) => _BookingTile(
                item: item,
                showUser: true,
                actions: const [
                  ('Cancelar', 'cancelada', TitanColors.danger),
                ],
              )),
        const SizedBox(height: 18),
        Text('Canceladas (${cancelled.length})', style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (cancelled.isEmpty)
          const Text('Nadie ha cancelado aún.', style: TextStyle(color: TitanColors.muted))
        else
          ...cancelled.map((item) => _BookingTile(item: item, showUser: true, actions: const [])),
      ],
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.item, this.actions = const [], this.showUser = false});
  final Booking item;
  final List<(String, String, Color)> actions;
  final bool showUser;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TitanCard(
        accent: statusColor(item.status),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(item.className, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                StatusPill(prettyStatus(item.status), color: statusColor(item.status)),
              ],
            ),
            const SizedBox(height: 4),
            Text(prettyDate(item.startsAt), style: const TextStyle(color: TitanColors.muted)),
            Text('${item.trainer} · ${item.room}', style: const TextStyle(color: TitanColors.muted, fontSize: 12)),
            if (showUser) Text(item.userName.isEmpty ? item.userEmail : item.userName, style: const TextStyle(color: TitanColors.cream, fontSize: 13)),
            if (item.syncStatus == 'pending')
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Pendiente de sincronizar', style: TextStyle(color: TitanColors.amber, fontSize: 11)),
              ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  for (final action in actions)
                    OutlinedButton(
                      onPressed: () async {
                        final goingToCancel = action.$2 == 'cancelada';
                        final ok = await confirmAction(
                          context,
                          title: goingToCancel ? 'Cancelar reserva' : 'Confirmar reserva',
                          message: goingToCancel
                              ? 'Se liberará el cupo de ${item.className}.'
                              : 'La reserva de ${item.userName.isEmpty ? 'este cliente' : item.userName} quedará confirmada.',
                          confirmLabel: action.$1,
                        );
                        if (!ok || !context.mounted) return;
                        try {
                          await app.updateBookingStatus(item, action.$2);
                          if (context.mounted) {
                            flash(context, goingToCancel ? 'Reserva cancelada' : 'Reserva confirmada');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            flash(context, e is ApiException ? e.message : 'No se pudo actualizar', error: true);
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: action.$3, side: BorderSide(color: action.$3)),
                      child: Text(action.$1),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
