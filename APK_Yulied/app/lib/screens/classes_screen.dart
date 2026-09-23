import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../data/api_client.dart';
import '../format.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/titan_ui.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  Future<void> _openForm(BuildContext context, {GymClass? existing}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ClassFormScreen(existing: existing)),
    );
    if (!context.mounted || saved != true) return;
    flash(context, existing == null ? 'Clase creada correctamente' : 'Clase actualizada');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final classes = app.isAdmin ? app.classes : app.upcomingClasses;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Text(app.isAdmin ? 'PERFIL ADMINISTRADOR' : 'PERFIL USUARIO', style: const TextStyle(color: TitanColors.orange, fontWeight: FontWeight.w800, letterSpacing: 1.4, fontSize: 12)),
        DisplayTitle(app.isAdmin ? 'CLASES' : 'AGENDAR'),
        Text(
          app.isAdmin
              ? 'Crea, edita o elimina la programación. El cliente agenda desde su propio perfil.'
              : 'Reserva tu cupo. Si no hay internet, queda en SQLite y se sincroniza después.',
          style: const TextStyle(color: TitanColors.muted),
        ),
        if (app.isAdmin) ...[
          const SizedBox(height: 12),
          TitanButton(
            label: 'Nueva clase',
            icon: Icons.add,
            filled: false,
            onPressed: () => _openForm(context),
          ),
        ],
        const SizedBox(height: 16),
        if (classes.isEmpty)
          const EmptyState(icon: Icons.event_busy, title: 'No hay clases cargadas', subtitle: 'Sincroniza con la API o crea una clase desde el perfil administrador.')
        else
          ...classes.map((item) {
            final already = app.hasActiveBooking(item.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TitanCard(
                accent: TitanColors.orange,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
                        StatusPill(item.difficulty, color: TitanColors.info),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(prettyDate(item.startsAt), style: const TextStyle(color: TitanColors.cream)),
                    Text('${item.trainer} · ${item.room} · ${item.durationMin} min', style: const TextStyle(color: TitanColors.muted, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(item.description, style: const TextStyle(color: TitanColors.muted, fontSize: 13, height: 1.35)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        StatusPill('${item.available}/${item.capacity} cupos', color: item.available > 0 ? TitanColors.mint : TitanColors.danger),
                        const Spacer(),
                        if (!app.isAdmin)
                          FilledButton(
                            onPressed: (item.available <= 0 || already)
                                ? null
                                : () async {
                                    final ok = await confirmAction(
                                      context,
                                      title: 'Agendar clase',
                                      message: '¿Reservar cupo en ${item.name}?',
                                      confirmLabel: 'Agendar',
                                    );
                                    if (!ok || !context.mounted) return;
                                    try {
                                      await app.bookClass(item);
                                      if (context.mounted) {
                                        flash(context, 'Reserva creada. Estado: pendiente. El admin debe confirmarla.');
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        flash(context, e is ApiException ? e.message : 'No se pudo reservar', error: true);
                                      }
                                    }
                                  },
                            style: FilledButton.styleFrom(backgroundColor: TitanColors.orange, foregroundColor: Colors.white),
                            child: Text(already ? 'Ya agendada' : 'Agendar'),
                          )
                        else
                          Wrap(
                            spacing: 4,
                            children: [
                              TextButton(
                                onPressed: () => _openForm(context, existing: item),
                                child: const Text('Editar'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final ok = await confirmAction(
                                    context,
                                    title: 'Eliminar clase',
                                    message: 'Se quitará ${item.name} y sus reservas.',
                                    confirmLabel: 'Eliminar',
                                  );
                                  if (!ok || !context.mounted) return;
                                  try {
                                    await app.deleteClass(item);
                                    if (context.mounted) flash(context, 'Clase eliminada');
                                  } catch (e) {
                                    if (context.mounted) flash(context, e is ApiException ? e.message : 'No se pudo eliminar', error: true);
                                  }
                                },
                                child: const Text('Eliminar', style: TextStyle(color: TitanColors.danger)),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class ClassFormScreen extends StatefulWidget {
  const ClassFormScreen({super.key, this.existing});
  final GymClass? existing;
  @override
  State<ClassFormScreen> createState() => _ClassFormScreenState();
}

class _ClassFormScreenState extends State<ClassFormScreen> {
  late final name = TextEditingController(text: widget.existing?.name ?? '');
  late final trainer = TextEditingController(text: widget.existing?.trainer ?? '');
  late final room = TextEditingController(text: widget.existing?.room ?? '');
  late final description = TextEditingController(text: widget.existing?.description ?? '');
  late final capacity = TextEditingController(text: '${widget.existing?.capacity ?? 12}');
  late DateTime starts = widget.existing?.date ?? DateTime.now().add(const Duration(hours: 2));
  late String difficulty = widget.existing?.difficulty ?? 'intermedio';
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    trainer.dispose();
    room.dispose();
    description.dispose();
    capacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Nueva clase' : 'Editar clase')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
          const SizedBox(height: 12),
          TextField(controller: trainer, decoration: const InputDecoration(labelText: 'Entrenador')),
          const SizedBox(height: 12),
          TextField(controller: room, decoration: const InputDecoration(labelText: 'Sala')),
          const SizedBox(height: 12),
          TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Descripción')),
          const SizedBox(height: 12),
          TextField(controller: capacity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cupo')),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            initialValue: difficulty,
            items: const [
              DropdownMenuItem(value: 'principiante', child: Text('Principiante')),
              DropdownMenuItem(value: 'intermedio', child: Text('Intermedio')),
              DropdownMenuItem(value: 'avanzado', child: Text('Avanzado')),
            ],
            onChanged: (value) => setState(() => difficulty = value ?? 'intermedio'),
            decoration: const InputDecoration(labelText: 'Nivel'),
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: TitanColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(prettyDate(starts.toIso8601String())),
            subtitle: const Text('Fecha y hora'),
            trailing: const Icon(Icons.schedule),
            onTap: () async {
              final date = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 60)), initialDate: starts);
              if (date == null || !context.mounted) return;
              final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(starts));
              if (time == null) return;
              setState(() => starts = DateTime(date.year, date.month, date.day, time.hour, time.minute));
            },
          ),
          const SizedBox(height: 20),
          TitanButton(
            label: 'Guardar clase',
            busy: saving,
            onPressed: () async {
              if (name.text.trim().isEmpty || trainer.text.trim().isEmpty) {
                flash(context, 'Nombre y entrenador son obligatorios', error: true);
                return;
              }
              setState(() => saving = true);
              final app = context.read<AppState>();
              try {
                final item = GymClass(
                  id: widget.existing?.id ?? const Uuid().v4(),
                  name: name.text.trim(),
                  description: description.text.trim(),
                  trainer: trainer.text.trim(),
                  startsAt: starts.toIso8601String(),
                  durationMin: 45,
                  capacity: int.tryParse(capacity.text) ?? 12,
                  available: widget.existing?.available ?? int.tryParse(capacity.text) ?? 12,
                  room: room.text.trim(),
                  difficulty: difficulty,
                  syncStatus: 'pending',
                );
                await app.saveClass(item, isNew: widget.existing == null);
                if (!context.mounted) return;
                Navigator.pop(context, true);
              } catch (e) {
                if (!context.mounted) return;
                setState(() => saving = false);
                flash(context, e is ApiException ? e.message : 'No se pudo guardar la clase', error: true);
              }
            },
          ),
        ],
      ),
    );
  }
}
