import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/features/auth/providers/auth_provider.dart';
import 'package:schoolcare/shared/widgets/emotikon_kehadiran.dart';

/// Halaman login. Setelah berhasil, TIDAK perlu context.go(...):
/// router otomatis pindah ke beranda sesuai peran.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    await context.read<AuthProvider>().signIn(_email.text, _password.text);
    if (mounted) setState(() => _loading = false);
  }

  static const _labelStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink);

  @override
  Widget build(BuildContext context) {
    final error = context.watch<AuthProvider>().errorMessage;

    return Scaffold(
      backgroundColor: AppColors.pink,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // ---- judul + kartu form; maskot duduk menumpuk di atas kartu
              Stack(clipBehavior: Clip.none, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const SizedBox(
                    height: 140,
                    child: Padding(
                      padding: EdgeInsets.only(right: 140),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Selamat datang di', style: TextStyle(fontSize: 15, color: AppColors.white)),
                          // Mengecil sendiri di layar sempit (kolom judul ±170 px di samping maskot)
                          // supaya kata "SchoolCare" tidak terpotong ke baris baru.
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'SchoolCare',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                                height: 1.15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ---- kartu form
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        const Text('Masuk', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        const Text(
                          'Masuk dengan akun dari sekolah',
                          style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
                        ),
                        const SizedBox(height: 20),
                        const Text('Email', style: _labelStyle),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText: 'nama@email.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) => (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
                        ),
                        const SizedBox(height: 14),
                        const Text('Kata sandi', style: _labelStyle),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            hintText: 'Minimal 6 karakter',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 12),
                          Text(error, style: const TextStyle(color: AppColors.pink, fontSize: 12)),
                        ],
                        const SizedBox(height: 22),
                        FilledButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                                )
                              : const Text('Masuk'),
                        ),
                      ]),
                    ),
                  ),
                ]),
                const Positioned(top: 22, right: 4, child: IgnorePointer(child: MaskotTasi(size: 150))),
              ]),
              const SizedBox(height: 16),

              // ---- info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.softYellow, borderRadius: BorderRadius.circular(16)),
                child: const Row(children: [
                  Icon(Icons.info_outline, color: AppColors.black, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Belum punya akun atau lupa sandi? Hubungi Manajemen Sekolah.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.black, height: 1.4),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
