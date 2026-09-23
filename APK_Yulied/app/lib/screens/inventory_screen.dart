import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../data/api_client.dart';
import '../format.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/titan_ui.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  Future<void> _openForm(BuildContext context, {InventoryItem? existing}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => InventoryFormScreen(existing: existing)),
    );
    if (!context.mounted || saved != true) return;
    flash(context, existing == null ? 'Equipo guardado en el inventario' : 'Equipo actualizado');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const Text('MÓDULO ADMIN', style: TextStyle(color: TitanColors.orange, fontWeight: FontWeight.w800, letterSpacing: 1.4, fontSize: 12)),
        const DisplayTitle('INVENTARIO'),
        const Text('Equipos del gimnasio. Altas y cambios quedan en cola SQLite si no hay red.', style: TextStyle(color: TitanColors.muted)),
        const SizedBox(height: 12),
        TitanButton(
          label: 'Registrar equipo',
          icon: Icons.add,
          filled: false,
          onPressed: () => _openForm(context),
        ),
        const SizedBox(height: 16),
        if (app.inventory.isEmpty)
          const EmptyState(icon: Icons.inventory_2_outlined, title: 'Inventario vacío', subtitle: 'Sincroniza o registra el primer equipo.')
        else
          ...app.inventory.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TitanCard(
                  accent: statusColor(item.status),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                          StatusPill(prettyStatus(item.status), color: statusColor(item.status)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${item.category} · ${item.location}', style: const TextStyle(color: TitanColors.muted)),
                      Text('Cantidad: ${item.quantity}', style: const TextStyle(color: TitanColors.cream)),
                      Row(
                        children: [
                          TextButton(onPressed: () => _openForm(context, existing: item), child: const Text('Editar')),
                          TextButton(
                            onPressed: () async {
                              final ok = await confirmAction(
                                context,
                                title: 'Eliminar equipo',
                                message: '¿Quitar ${item.name} del inventario?',
                                confirmLabel: 'Eliminar',
                              );
                              if (!ok || !context.mounted) return;
                              try {
                                await app.removeInventory(item);
                                if (context.mounted) flash(context, 'Equipo eliminado');
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
                ),
              )),
      ],
    );
  }
}

class InventoryFormScreen extends StatefulWidget {
  const InventoryFormScreen({super.key, this.existing});
  final InventoryItem? existing;
  @override
  State<InventoryFormScreen> createState() => _InventoryFormScreenState();
}

class _InventoryFormScreenState extends State<InventoryFormScreen> {
  late final name = TextEditingController(text: widget.existing?.name ?? '');
  late final category = TextEditingController(text: widget.existing?.category ?? 'pesas');
  late final quantity = TextEditingController(text: '${widget.existing?.quantity ?? 1}');
  late final location = TextEditingController(text: widget.existing?.location ?? '');
  late String status = widget.existing?.status ?? 'operativo';
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    category.dispose();
    quantity.dispose();
    location.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (name.text.trim().isEmpty) {
      flash(context, 'El nombre del equipo es obligatorio', error: true);
      return;
    }
    setState(() => saving = true);
    final app = context.read<AppState>();
    try {
      final item = InventoryItem(
        id: widget.existing?.id ?? const Uuid().v4(),
        name: name.text.trim(),
        category: category.text.trim().isEmpty ? 'general' : category.text.trim(),
        quantity: int.tryParse(quantity.text) ?? 0,
        status: status,
        location: location.text.trim(),
        syncStatus: 'pending',
      );
      await app.saveInventory(item, isNew: widget.existing == null);
      if (!context.mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!context.mounted) return;
      setState(() => saving = false);
      flash(context, e is ApiException ? e.message : 'No se pudo guardar el equipo', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Nuevo equipo' : 'Editar equipo')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
          const SizedBox(height: 12),
          TextField(controller: category, decoration: const InputDecoration(labelText: 'Categoría')),
          const SizedBox(height: 12),
          TextField(controller: quantity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cantidad')),
          const SizedBox(height: 12),
          TextField(controller: location, decoration: const InputDecoration(labelText: 'Ubicación')),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            initialValue: status,
            items: const [
              DropdownMenuItem(value: 'operativo', child: Text('Operativo')),
              DropdownMenuItem(value: 'mantenimiento', child: Text('Mantenimiento')),
              DropdownMenuItem(value: 'fuera_de_servicio', child: Text('Fuera de servicio')),
            ],
            onChanged: (value) => setState(() => status = value ?? 'operativo'),
            decoration: const InputDecoration(labelText: 'Estado'),
          ),
          const SizedBox(height: 20),
          TitanButton(label: 'Guardar', onPressed: _save, busy: saving),
        ],
      ),
    );
  }
}
