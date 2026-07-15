import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_animations.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/premium_text_field.dart';
import 'register_screen.dart';
import 'shell_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.api, this.role});
  final ApiService api;
  final String? role;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameC = TextEditingController();
  final passC = TextEditingController();
  bool loading = false;
  String? error;
  bool _obscure = true;

  Future<void> login() async {
    if (usernameC.text.isEmpty || passC.text.isEmpty) {
      setState(() => error = 'Username dan password wajib diisi');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final auth = await widget.api.login(
        username: usernameC.text.trim(),
        password: passC.text,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ShellScreen(api: widget.api, user: auth.user)),
      );
    } catch (e) {
      setState(() => error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      const SizedBox(height: 30),

                      // ── Header / Logo ──
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 150),
                        child: Column(
                          children: [
                            Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withOpacity(0.1),
                                border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                size: 40,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'INVENTORY AUDIT',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Silakan masuk untuk melanjutkan audit barang',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Form Card ──
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 200),
                        child: GlassCard(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'LOGIN',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Username Input
                              PremiumTextField(
                                controller: usernameC,
                                label: 'Username',
                                hint: 'Masukkan username Anda',
                                prefixIcon: Icons.person_outline_rounded,
                              ),
                              const SizedBox(height: 20),

                              // Password Input
                              PremiumTextField(
                                controller: passC,
                                label: 'Password',
                                hint: 'Masukkan password Anda',
                                prefixIcon: Icons.lock_outline_rounded,
                                obscureText: _obscure,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 20,
                                    color: AppColors.textMuted,
                                  ),
                                  onPressed: () => setState(() => _obscure = !_obscure),
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
                                        child: Text(
                                          error!,
                                          style: const TextStyle(
                                            color: AppColors.error,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 28),

                              // Login Button
                              GradientButton(
                                label: 'LOGIN',
                                loading: loading,
                                onPressed: loading ? null : login,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Register Link ──
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 400),
                        child: TextButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RegisterScreen(api: widget.api, role: widget.role),
                            ),
                          ),
                          child: RichText(
                            text: const TextSpan(
                              text: 'Belum punya akun? ',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                              children: [
                                TextSpan(
                                  text: 'Register',
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
}
