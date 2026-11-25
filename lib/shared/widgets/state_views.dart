import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/shared/widgets/permukaan.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: CircularProgressIndicator(color: Permukaan.diPutih(context) ? AppColors.pink : AppColors.white),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.icon = Icons.inbox_outlined});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final putih = Permukaan.diPutih(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 56, color: putih ? AppColors.softPink : AppColors.white),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Permukaan.teksRedup(context))),
        ]),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, this.message = 'Gagal memuat data.', this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final warna = Permukaan.diPutih(context) ? null : AppColors.white;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off, size: 48, color: warna ?? AppColors.danger),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: warna ?? AppColors.ink)),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: warna == null ? null : TextButton.styleFrom(foregroundColor: warna),
              child: const Text('Coba lagi'),
            ),
        ]),
      ),
    );
  }
}

/// Pembungkus FutureBuilder: otomatis menampilkan loading, error, dan data kosong.
///
/// PENTING: simpan Future di State (sebagai field / di initState), JANGAN dibuat
/// langsung di dalam build(), supaya query tidak diulang setiap kali layar digambar ulang.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.future,
    required this.builder,
    this.onRetry,
    this.isEmpty,
    this.emptyMessage = 'Belum ada data.',
    this.emptyIcon = Icons.inbox_outlined,
  });

  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;
  final bool Function(T data)? isEmpty;
  final String emptyMessage;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) {
            debugPrint('AsyncView error: ${snap.error}');
            return ErrorView(onRetry: onRetry);
          }
          final data = snap.data as T;
          if (isEmpty?.call(data) ?? false) {
            return EmptyState(message: emptyMessage, icon: emptyIcon);
          }
          return builder(context, data);
        },
      );
}
