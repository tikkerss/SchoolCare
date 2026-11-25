import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/shared/widgets/dashed.dart';
import 'package:schoolcare/shared/widgets/permukaan.dart';

/// Kartu tiket untuk jadwal/pelajaran: kolom jam di kiri (±60) dipisah garis
/// putus-putus softPink, isi di kanan. [sorot] = sedang berlangsung (bayangan pink).
class TicketCard extends StatelessWidget {
  const TicketCard({
    super.key,
    required this.jamMulai,
    required this.child,
    this.jamSelesai,
    this.labelAtas,
    this.sorot = false,
    this.onTap,
    this.warna = AppColors.white,
  });

  final String jamMulai;
  final String? jamSelesai;

  /// Teks kecil di atas jam, mis. "Jam 1".
  final String? labelAtas;
  final Widget child;
  final bool sorot;
  final VoidCallback? onTap;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Container(
      decoration: BoxDecoration(
        color: warna,
        borderRadius: radius,
        boxShadow: sorot ? AppColors.activeShadow : AppColors.cardShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Permukaan.putih(
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 64,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (labelAtas != null)
                            Text(labelAtas!, style: const TextStyle(fontSize: 10, color: AppColors.inkFaint)),
                          Text(
                            jamMulai,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: sorot ? AppColors.pink : AppColors.ink,
                            ),
                          ),
                          if (jamSelesai != null)
                            Text(jamSelesai!, style: const TextStyle(fontSize: 11, color: AppColors.inkMuted)),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: DashedVerticalLine(color: AppColors.softPink),
                  ),
                  Expanded(
                    child: Padding(padding: const EdgeInsets.fromLTRB(14, 14, 14, 14), child: child),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu polos bergaya SchoolCare: radius 20, tanpa garis, bayangan tipis.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.warna = AppColors.white,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final Color warna;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Container(
      decoration: BoxDecoration(color: warna, borderRadius: radius, boxShadow: AppColors.cardShadow),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Permukaan.putih(
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
