import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/titan_ui.dart';

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const Text('MÓDULO EXTRA', style: TextStyle(color: TitanColors.orange, fontWeight: FontWeight.w800, letterSpacing: 1.4, fontSize: 12)),
        const DisplayTitle('RUTINAS'),
        const Text('Programas de entrenamiento listos para usar, incluso sin conexión.', style: TextStyle(color: TitanColors.muted)),
        const SizedBox(height: 16),
        if (app.routines.isEmpty)
          const EmptyState(icon: Icons.list_alt, title: 'Aún no hay rutinas', subtitle: 'Sincroniza con la API para descargar los programas.')
        else
          ...app.routines.map((routine) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TitanCard(
                  accent: TitanColors.amber,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(routine.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
                          StatusPill(routine.level, color: TitanColors.amber),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${routine.goal} · ${routine.durationWeeks} semanas', style: const TextStyle(color: TitanColors.muted)),
                      const SizedBox(height: 10),
                      ...routine.exercises.map((ex) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.bolt, color: TitanColors.orange, size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(ex['name']?.toString() ?? '')),
                                Text('${ex['sets']} x ${ex['reps']}', style: const TextStyle(color: TitanColors.muted, fontSize: 12)),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}
