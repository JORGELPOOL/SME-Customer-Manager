import 'package:flutter/material.dart';
import '../theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    late Color bg, fg;
    late String label;
    switch (status) {
      case 'paid':
        bg = const Color(0xFFE7F1EB);
        fg = AppColors.sage;
        label = 'Paid';
        break;
      case 'partial':
        bg = const Color(0xFFFBF0DC);
        fg = const Color(0xFF8A6115);
        label = 'Partial';
        break;
      default:
        bg = const Color(0xFFF6E3DF);
        fg = AppColors.brick;
        label = 'Unpaid';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w600)),
    );
  }
}

class KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  const KpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.accent = AppColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: accent.withOpacity(0.12), borderRadius: BorderRadius.circular(7)),
              child: Icon(icon, size: 13, color: accent),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.text)),
          ),
        ],
      ),
    );
  }
}
