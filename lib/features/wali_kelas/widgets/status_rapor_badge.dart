import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/shared/widgets/status_badge.dart';

import '../data/rapor_models.dart';

GayaChip gayaStatusRapor(StatusRapor s) => switch (s) {
  StatusRapor.belumDisusun => GayaChip.putih,
  StatusRapor.draft => GayaChip.softYellow,
  StatusRapor.terbit => GayaChip.orange,
  StatusRapor.diambil => GayaChip.pink,
};

Color warnaStatusRapor(StatusRapor s) => gayaStatusRapor(s).aksen;

class StatusRaporBadge extends StatelessWidget {
  const StatusRaporBadge(this.status, {super.key});

  final StatusRapor status;

  @override
  Widget build(BuildContext context) => StatusPill(label: status.label, gaya: gayaStatusRapor(status));
}
