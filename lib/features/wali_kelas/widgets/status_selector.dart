import 'package:material_ui/material_ui.dart';

import '../data/models.dart';

Color warnaStatus(StatusAbsen s) => switch (s) {
  StatusAbsen.hadir => const Color(0xFF2E9E5B),
  StatusAbsen.terlambat => const Color(0xFFE0A100),
  StatusAbsen.izin => const Color(0xFF1E6FD9),
  StatusAbsen.sakit => const Color(0xFF8E5CD9),
  StatusAbsen.alpa => const Color(0xFFD64545),
};

/// Lima tombol bulat H / T / I / S / A.
class StatusSelector extends StatelessWidget {
  const StatusSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final StatusAbsen value;
  final ValueChanged<StatusAbsen> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: StatusAbsen.values.map((s) {
        final dipilih = s == value;
        final warna = warnaStatus(s);
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Tooltip(
            message: s.label,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enabled ? () => onChanged(s) : null,
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dipilih ? warna : Colors.transparent,
                  border: Border.all(
                    color: enabled || dipilih ? warna : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  s.kode,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: dipilih
                        ? Colors.white
                        : (enabled ? warna : Colors.grey.shade400),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
