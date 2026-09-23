import 'package:flutter/material.dart';

import '../theme.dart';

class DumbbellMark extends StatelessWidget {
  const DumbbellMark({super.key, this.size = 72});
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DumbbellPainter(),
    );
  }
}

class _DumbbellPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = TitanColors.orange
      ..style = PaintingStyle.fill;
    final cy = size.height / 2;
    final bar = RRect.fromLTRBR(size.width * 0.22, cy - size.height * 0.08, size.width * 0.78, cy + size.height * 0.08, const Radius.circular(8));
    canvas.drawRRect(bar, paint);
    canvas.drawCircle(Offset(size.width * 0.22, cy), size.width * 0.18, paint);
    canvas.drawCircle(Offset(size.width * 0.78, cy), size.width * 0.18, paint);
    final hole = Paint()..color = TitanColors.bg;
    canvas.drawCircle(Offset(size.width * 0.22, cy), size.width * 0.07, hole);
    canvas.drawCircle(Offset(size.width * 0.78, cy), size.width * 0.07, hole);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TitanButton extends StatelessWidget {
  const TitanButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = true,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.3)),
            ],
          );
    if (!filled) {
      return OutlinedButton(
        onPressed: busy ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: TitanColors.cream,
          side: const BorderSide(color: TitanColors.line),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: child,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [TitanColors.orange, Color(0xFFFF7A3D)]),
        boxShadow: [
          BoxShadow(color: TitanColors.orange.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: child,
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.color = TitanColors.muted});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8),
      ),
    );
  }
}

Color statusColor(String status) {
  switch (status) {
    case 'confirmada':
    case 'activa':
    case 'operativo':
      return TitanColors.mint;
    case 'pendiente':
    case 'mantenimiento':
      return TitanColors.amber;
    case 'cancelada':
    case 'vencida':
    case 'fuera_de_servicio':
      return TitanColors.danger;
    default:
      return TitanColors.muted;
  }
}

class OfflineBar extends StatelessWidget {
  const OfflineBar({super.key, required this.online, required this.pending, required this.label, this.onSync});
  final bool online;
  final int pending;
  final String label;
  final VoidCallback? onSync;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: online ? const Color(0xFF10261C) : const Color(0xFF2A1A12),
      child: InkWell(
        onTap: onSync,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(online ? Icons.cloud_done_rounded : Icons.cloud_off_rounded, size: 18, color: online ? TitanColors.mint : TitanColors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  online
                      ? (pending > 0 ? 'En línea · $pending pendiente(s) · $label' : 'En línea · $label')
                      : 'Modo offline (SQLite) · $pending cambio(s) en cola',
                  style: TextStyle(color: online ? TitanColors.mint : TitanColors.amber, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.sync, size: 16, color: TitanColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class TitanCard extends StatelessWidget {
  const TitanCard({super.key, required this.child, this.padding, this.onTap, this.accent});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TitanColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TitanColors.line),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 8))],
      ),
      foregroundDecoration: accent == null
          ? null
          : BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border(left: BorderSide(color: accent!, width: 4)),
            ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: card);
  }
}

class DisplayTitle extends StatelessWidget {
  const DisplayTitle(this.text, {super.key, this.size = 34});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontFamily: 'Anton', fontSize: size, height: 1.05, color: TitanColors.cream, letterSpacing: 0.6),
    );
  }
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: TitanColors.card,
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Volver')),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: TitanColors.orange),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result == true;
}

void flash(BuildContext context, String message, {bool error = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? TitanColors.danger : const Color(0xFF1B6B45),
        behavior: SnackBarBehavior.floating,
      ),
    );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 46, color: TitanColors.muted),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: TitanColors.muted)),
        ],
      ),
    );
  }
}
