import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_animations.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/stat_card.dart';
import '../widgets/shimmer_loading.dart';
import 'audit_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.api, this.onStartAudit});
  final ApiService api;
  final VoidCallback? onStartAudit;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: api.getDashboard(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: ShimmerLoading(count: 4, height: 100),
          );
        }
        final data = snap.data ?? const {};
        final totalProducts = (data['total_products'] ?? 0).toString();
        final lowStock = (data['low_stock'] ?? 0).toString();
        final latestDate = (data['latest_session_date'] ?? '-').toString();
        final latestUser = (data['latest_user'] ?? '-').toString();

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: api.getHistory(),
          builder: (context, historySnap) {
            final history = historySnap.data ?? const [];
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                // ── Hero Card ──
                FadeSlideIn(
                  child: _heroCard(totalProducts),
                ),
                const SizedBox(height: 14),

                // ── Small Cards ──
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'STOK MENIPIS',
                          value: lowStock,
                          subtitle: 'Item < 5 unit',
                          icon: Icons.warning_amber_rounded,
                          accentColor: AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'AUDIT TERAKHIR',
                          value: latestDate,
                          subtitle: 'Oleh: $latestUser',
                          icon: Icons.schedule_rounded,
                          accentColor: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ── Start Audit Button ──
                FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: GradientButton(
                    label: 'MULAI AUDIT',
                    icon: Icons.camera_alt_rounded,
                    onPressed: onStartAudit,
                    height: 56,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Activity Log ──
                FadeSlideIn(
                  delay: const Duration(milliseconds: 240),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.history_rounded, size: 18, color: AppColors.warning),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'LOG AKTIVITAS TERBARU',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                if (history.isEmpty)
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: const Text(
                        'Belum ada aktivitas audit.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ...history.take(3).toList().asMap().entries.map(
                    (entry) => FadeSlideIn(
                      delay: Duration(milliseconds: 300 + (entry.key * 80)),
                      child: _activityItem(context, entry.value),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _heroCard(String totalProducts) {
    return GlassCard(
      glowColor: AppColors.primary,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL PRODUK',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_rounded, size: 22, color: AppColors.textOnPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedCounter(
            value: int.tryParse(totalProducts) ?? 0,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.success.withOpacity(0.5), blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Tersinkronisasi dengan gudang pusat',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activityItem(BuildContext context, Map<String, dynamic> item) {
    final status = (item['status'] ?? 'AMAN').toString();
    final sessionId = int.tryParse((item['session_id'] ?? '0').toString()) ?? 0;
    final isAman = status.toUpperCase() == 'AMAN';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isAman ? AppColors.success : AppColors.warning).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isAman ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
              size: 20,
              color: isAman ? AppColors.success : AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (item['item_name'] ?? '-').toString(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['date'] ?? '-'}  •  ${item['total'] ?? 0} produk',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          // Status chip
          GestureDetector(
            onTap: sessionId > 0
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AuditDetailScreen(api: api, sessionId: sessionId),
                      ),
                    )
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (isAman ? AppColors.success : AppColors.warning).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (isAman ? AppColors.success : AppColors.warning).withOpacity(0.3),
                ),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isAman ? AppColors.success : AppColors.warning,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
