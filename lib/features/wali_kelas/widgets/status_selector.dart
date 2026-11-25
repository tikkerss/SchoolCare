import 'package:material_ui/material_ui.dart';

import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/shared/widgets/status_badge.dart';

import '../data/models.dart';

/// Gaya chip per status (sama dengan StatusBadge bersama).
GayaChip gayaStatus(StatusAbsen s) => StatusBadge.gayaOf(s.dbValue);

/// Satu warna yang mewakili status (untuk garis tepi/titik).
Color warnaStatus(StatusAbsen s) => gayaStatus(s).aksen;

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
        final gaya = gayaStatus(s);
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
                  color: dipilih ? gaya.latar : AppColors.white,
                  border: Border.all(
                    color: dipilih ? AppColors.pink : AppColors.softPink,
                    width: dipilih ? 2 : 1.5,
                  ),
                ),
                child: Text(
                  s.kode,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: dipilih
                        ? gaya.teks
                        : (enabled ? AppColors.ink : AppColors.inkFaint),
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
