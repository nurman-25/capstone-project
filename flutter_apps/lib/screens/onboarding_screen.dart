import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_animations.dart';
import '../services/api_service.dart';
import '../widgets/gradient_button.dart';
import 'role_select_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.api});
  final ApiService api;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _slides = [
    OnboardingData(
      title: 'MAS Nurman',
      subtitle: '',
      description: '',
      icon: Icons.person_rounded,
      accentColor: AppColors.primary,
    ),
    OnboardingData(
      title: 'AUDIT PRO',
      subtitle: '',
      description: 'Gunakan deteksi objek pintar untuk memindai stok barang di rak secara otomatis menggunakan kamera HP Anda.',
      icon: Icons.shopping_basket_rounded,
      accentColor: AppColors.secondary,
    ),
    OnboardingData(
      title: 'Rekomendasi Penggunaan',
      subtitle: 'Langkah Tepat Audit Efisien',
      description: 'Gunakan aplikasi ini untuk stock opname berkala toko Anda, mendeteksi produk yang menipis secara instan, serta ekspor laporan otomatis.',
      icon: Icons.recommend_rounded,
      accentColor: AppColors.success,
    ),
  ];

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _finishOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RoleSelectScreen(api: widget.api),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header (Skip Button) ──
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0, right: 16.0),
                  child: TextButton(
                    onPressed: _finishOnboarding,
                    child: Text(
                      'LEWATI',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Page View Slider ──
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Glow Icon Container
                          FadeSlideIn(
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: slide.accentColor.withOpacity(0.08),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: slide.accentColor.withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        slide.accentColor,
                                        slide.accentColor.withOpacity(0.8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: slide.accentColor.withOpacity(0.3),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    slide.icon,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),

                          // Slide Title
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 100),
                            child: Text(
                              slide.title,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: slide.accentColor,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Slide Subtitle
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 150),
                            child: Text(
                              slide.subtitle,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Slide Description
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 200),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: Text(
                                slide.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Dots Indicator & Navigation Button ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          width: _currentPage == index ? 24.0 : 8.0,
                          height: 8.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4.0),
                            color: _currentPage == index
                                ? _slides[_currentPage].accentColor
                                : AppColors.textMuted.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Button
                    AnimatedCrossFade(
                      firstChild: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _slides[_currentPage].accentColor.withOpacity(0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'SELANJUTNYA',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _slides[_currentPage].accentColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      secondChild: GradientButton(
                        label: 'LANJUT',
                        onPressed: _finishOnboarding,
                        gradient: LinearGradient(
                          colors: [
                            _slides[2].accentColor,
                            _slides[2].accentColor.withOpacity(0.8),
                          ],
                        ),
                      ),
                      crossFadeState: _currentPage == _slides.length - 1
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 200),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingData {
  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color accentColor;
}
