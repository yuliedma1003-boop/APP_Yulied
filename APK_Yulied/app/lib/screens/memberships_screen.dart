import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../format.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/titan_ui.dart';

class MembershipsScreen extends StatelessWidget {
  const MembershipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const Text('MÓDULO EXTRA', style: TextStyle(color: TitanColors.orange, fontWeight: FontWeight.w800, letterSpacing: 1.4, fontSize: 12)),
        const DisplayTitle('PLANES'),
        const Text('Activa o cambia tu membresía. También funciona offline y se replica en la API.', style: TextStyle(color: TitanColors.muted)),
        const SizedBox(height: 16),
        if (app.activeMembership != null)
          TitanCard(
            accent: TitanColors.mint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusPill('Activa', color: TitanColors.mint),
                const SizedBox(height: 8),
                Text(app.activeMembership!.planName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                Text('Desde ${app.activeMembership!.startDate} hasta ${app.activeMembership!.endDate}', style: const TextStyle(color: TitanColors.muted)),
              ],
            ),
          ),
        const SizedBox(height: 12),
        if (app.plans.isEmpty)
          const EmptyState(icon: Icons.workspace_premium_outlined, title: 'Sin planes locales', subtitle: 'Conéctate para descargar los planes de la API.')
        else
          ...app.plans.map((plan) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TitanCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(moneyFmt.format(plan.price), style: const TextStyle(fontFamily: 'Anton', fontSize: 28, color: TitanColors.orange)),
                      Text('${plan.durationDays} días · ${plan.description}', style: const TextStyle(color: TitanColors.muted)),
                      const SizedBox(height: 8),
                      ...plan.benefits.map((b) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(children: [const Icon(Icons.check_circle, size: 16, color: TitanColors.mint), const SizedBox(width: 6), Expanded(child: Text(b))]),
                          )),
                      const SizedBox(height: 10),
                      TitanButton(
                        label: 'Activar este plan',
                        onPressed: () async {
                          final ok = await confirmAction(
                            context,
                            title: 'Activar plan',
                            message: '¿Activar ${plan.name}?',
                            confirmLabel: 'Activar',
                          );
                          if (!ok || !context.mounted) return;
                          try {
                            await app.subscribe(plan);
                            if (context.mounted) flash(context, 'Plan ${plan.name} activado');
                          } catch (e) {
                            if (context.mounted) {
                              flash(context, e is ApiException ? e.message : 'No se pudo activar', error: true);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}
