import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_animations.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/premium_text_field.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.api, this.role});
  final ApiService api;
  final String? role;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final usernameC = TextEditingController();
  final emailC = TextEditingController();
  final storeIdC = TextEditingController(text: '1');
  final passC = TextEditingController();
  final confirmC = TextEditingController();
  String role = 'staff';
  bool loading = false;
  String? error;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    role = widget.role ?? 'staff';
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (passC.text != confirmC.text) {
      setState(() => error = 'Password dan konfirmasi tidak sama');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await widget.api.register(
        username: usernameC.text.trim(),
        email: emailC.text.trim(),
        storeId: int.tryParse(storeIdC.text.trim()) ?? 1,
        role: role,
        password: passC.text,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi Berhasil! Silakan Login.'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(api: widget.api, role: role),
        ),
      );
    } catch (e) {
      setState(() => error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockedRole = widget.role != null;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Back Button ──
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: Row(
                          children: [
                            _buildBackButton(context),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Header / Logo ──
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 150),
                        child: Column(
                          children: [
                            const Text(
                              'REGISTER',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Daftarkan akun baru sebagai ${role.toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Form Card ──
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 200),
                        child: GlassCard(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Role Selector if not locked
                                if (!lockedRole) ...[
                                  const Text(
                                    'PILIH HAK AKSES',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textMuted,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildRoleToggle(lockedRole),
                                  const SizedBox(height: 24),
                                ],

                                // Username Input
                                PremiumTextField(
                                  controller: usernameC,
                                  label: 'Username',
                                  hint: 'Masukkan username baru Anda',
                                  prefixIcon: Icons.person_outline_rounded,
                                  validator: (v) => (v == null || v.isEmpty) ? 'Username wajib diisi' : null,
                                ),
                                const SizedBox(height: 16),

                                // Email Input
                                PremiumTextField(
                                  controller: emailC,
                                  label: 'Gmail / Email',
                                  hint: 'Masukkan email Gmail Anda',
                                  prefixIcon: Icons.alternate_email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Email wajib diisi';
                                    if (!v.contains('@') || !v.contains('.')) return 'Format email tidak valid';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Store ID Input
                                PremiumTextField(
                                  controller: storeIdC,
                                  label: 'ID Toko',
                                  hint: 'Masukkan ID toko Anda',
                                  prefixIcon: Icons.storefront_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (v) => (v == null || v.isEmpty) ? 'ID Toko wajib diisi' : null,
                                ),
                                const SizedBox(height: 16),

                                // Password Input
                                PremiumTextField(
                                  controller: passC,
                                  label: 'Password',
                                  hint: 'Masukkan password baru',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  obscureText: _obscurePass,
                                  validator: (v) => (v == null || v.length < 8) ? 'Password minimal 8 karakter' : null,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      size: 20,
                                      color: AppColors.textMuted,
                                    ),
                                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Confirm Password Input
                                PremiumTextField(
                                  controller: confirmC,
                                  label: 'Konfirmasi Password',
                                  hint: 'Masukkan ulang password baru',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  obscureText: _obscureConfirm,
                                  validator: (v) => (v == null || v.isEmpty) ? 'Konfirmasi password wajib diisi' : null,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      size: 20,
                                      color: AppColors.textMuted,
                                    ),
                                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                  ),
                                ),

                                // Error Message
                                if (error != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.errorBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.error.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline, size: 18, color: AppColors.error),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 26),

                                // Register Button
                                GradientButton(
                                  label: 'REGISTER',
                                  loading: loading,
                                  onPressed: loading ? null : submit,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Login Link ──
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 300),
                        child: TextButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LoginScreen(api: widget.api, role: widget.role),
                            ),
                          ),
                          child: RichText(
                            text: const TextSpan(
                              text: 'Sudah punya akun? ',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                              children: [
                                TextSpan(
                                  text: 'Login',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: IconButton(
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
      ),
    );
  }

  Widget _buildRoleToggle(bool locked) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _roleChip('ADMIN', 'admin', locked, AppColors.primary),
          ),
          Expanded(
            child: _roleChip('STAFF', 'staff', locked, AppColors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _roleChip(String label, String value, bool locked, Color activeColor) {
    final isSelected = role == value;
    return GestureDetector(
      onTap: locked ? null : () => setState(() => role = value),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          gradient: isSelected
              ? LinearGradient(
                  colors: [activeColor, activeColor.withOpacity(0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: isSelected ? AppColors.textOnPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
