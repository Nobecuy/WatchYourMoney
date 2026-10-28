import 'package:flutter/material.dart';

import 'dynamic_island_alert.dart';

class DynamicIslandSimulator extends StatelessWidget {
  const DynamicIslandSimulator({super.key});

  static const Color _surface = Color(0xFF17191D);
  static const Color _text = Color(0xFFF4F4F5);
  static const Color _muted = Color(0xFF9699A2);
  static const Color _green = Color(0xFF10B981);
  static const Color _red = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.smartphone_rounded, color: _muted, size: 19),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Dynamic Island Lab',
                  style: TextStyle(
                    color: _text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _LiveIndicator(),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Uji animasi alert dan transisi kapsul.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('FULL ALERT'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SimulatorButton(
                  label: 'Alert Sukses',
                  icon: Icons.check_circle_outline_rounded,
                  color: _green,
                  onTap: () {
                    DynamicIslandAlert.success(
                      context: context,
                      message: 'Proses berhasil',
                      detail: 'berhasil disimpan',
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SimulatorButton(
                  label: 'Alert Gagal',
                  icon: Icons.cancel_outlined,
                  color: _red,
                  onTap: () {
                    DynamicIslandAlert.error(
                      context: context,
                      message: 'Proses Gagal',
                      detail: 'Cek apakah ada yang terlewat',
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionLabel('MINI PILL'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SimulatorButton(
                  label: 'Mini Sukses',
                  icon: Icons.check_rounded,
                  color: _green,
                  onTap: () {
                    DynamicIslandAlert.miniSuccess(
                      context: context,
                      message: 'tersimpan',
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SimulatorButton(
                  label: 'Mini Gagal',
                  icon: Icons.close_rounded,
                  color: _red,
                  onTap: () {
                    DynamicIslandAlert.miniError(
                      context: context,
                      message: 'Gagal menyimpan',
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionLabel('ISLAND STATE'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SimulatorButton(
                  label: 'Reset Idle',
                  icon: Icons.radio_button_checked_rounded,
                  color: const Color(0xFFB8BBC4),
                  onTap: () {
                    DynamicIslandAlert.showIdle(context);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SimulatorButton(
                  label: 'Tutup Island',
                  icon: Icons.close_rounded,
                  color: const Color(0xFFB8BBC4),
                  onTap: DynamicIslandAlert.dismiss,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: DynamicIslandSimulator._muted,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _LiveIndicator extends StatelessWidget {
  const _LiveIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: DynamicIslandSimulator._green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: DynamicIslandSimulator._green, size: 6),
          SizedBox(width: 5),
          Text(
            'READY',
            style: TextStyle(
              color: DynamicIslandSimulator._green,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimulatorButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SimulatorButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
