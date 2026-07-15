import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_animations.dart';
import '../services/api_service.dart';
import '../widgets/gradient_button.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key, required this.api});
  final ApiService api;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Logo & Branding ──
                    FadeSlideIn(
                      child: _buildLogo(),
                    ),
                    const SizedBox(height: 32),

                    // ── Title ──
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 100),
                      child: const Text(
                        'AUDIT PRO',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    FadeSlideIn(
                      delay: const Duration(milliseconds: 180),
                      child: const Text(
                        'Inventory Audit Management System',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ── Subtitle ──
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 250),
                      child: const Text(
                        'Pilih Mode',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 300),
                      child: const Text(
                        'Masuk sebagai admin atau staff untuk lanjut ke fitur yang sesuai.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Role Cards ──
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 380),
                      child: Row(
                        children: [
                          Expanded(
                            child: _RoleCard(
                              title: 'ADMIN',
                              subtitle: 'Kelola user, produk,\ndan laporan',
                              icon: Icons.admin_panel_settings_rounded,
                              accentColor: AppColors.primary,
                              onLogin: () => Navigator.push(
                                context,
                                _smoothRoute(LoginScreen(api: api, role: 'admin')),
                              ),
                              onRegister: () => Navigator.push(
                                context,
                                _smoothRoute(RegisterScreen(api: api, role: 'admin')),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _RoleCard(
                              title: 'STAFF',
                              subtitle: 'Scan produk dan\nsimpan hasil audit',
                              icon: Icons.qr_code_scanner_rounded,
                              accentColor: AppColors.secondary,
                              onLogin: () => Navigator.push(
                                context,
                                _smoothRoute(LoginScreen(api: api, role: 'staff')),
                              ),
                              onRegister: () => Navigator.push(
                                context,
                                _smoothRoute(RegisterScreen(api: api, role: 'staff')),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: AppColors.primaryGradient,
        boxShadow: AppColors.primaryGlowShadow,
      ),
      child: const Icon(
        Icons.inventory_2_rounded,
        size: 40,
        color: AppColors.textOnPrimary,
      ),
    );
  }

  static PageRouteBuilder _smoothRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}

class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onLogin,
    required this.onRegister,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _hovered = true),
      onTapUp: (_) => setState(() => _hovered = false),
      onTapCancel: () => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.card,
            border: Border.all(
              color: _hovered
                  ? widget.accentColor.withOpacity(0.4)
                  : AppColors.glassBorder,
              width: 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.accentColor.withOpacity(0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : AppColors.cardShadow,
          ),
          child: Column(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.icon, size: 28, color: widget.accentColor),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: widget.accentColor,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Text(
                widget.subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Login button
              GradientButton(
                label: 'LOGIN',
                onPressed: widget.onLogin,
                height: 42,
                fontSize: 12,
                gradient: LinearGradient(
                  colors: [
                    widget.accentColor,
                    widget.accentColor.withOpacity(0.8),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Register button
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton(
                  onPressed: widget.onRegister,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.accentColor,
                    side: BorderSide(
                      color: widget.accentColor.withOpacity(0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'REGISTER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
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
