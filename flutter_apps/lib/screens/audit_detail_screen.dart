import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_animations.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/shimmer_loading.dart';

class AuditDetailScreen extends StatefulWidget {
  const AuditDetailScreen({super.key, required this.api, required this.sessionId});

  final ApiService api;
  final int sessionId;

  @override
  State<AuditDetailScreen> createState() => _AuditDetailScreenState();
}

class _AuditDetailScreenState extends State<AuditDetailScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getSessionDetail(widget.sessionId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Column(
          children: [
            // ── Custom AppBar ──
            SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    bottom: BorderSide(color: AppColors.divider, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Audit Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),

            // ── Body ──
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: ShimmerLoading(count: 4, height: 100),
                    );
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.errorBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.error_outline, size: 28, color: AppColors.error),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Gagal memuat detail: ${snap.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }
                  final data = snap.data ?? {};
                  final items = (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      FadeSlideIn(child: _topMeta(data)),
                      const SizedBox(height: 18),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.compare_arrows_rounded, size: 18, color: AppColors.secondary),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Product Comparison',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 140),
                        child: Text(
                          '${items.length} items scanned',
                          style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...items.asMap().entries.map(
                        (entry) => FadeSlideIn(
                          delay: Duration(milliseconds: 180 + (entry.key * 60)),
                          child: _comparisonCard(entry.value),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topMeta(Map<String, dynamic> data) {
    final statusText = (data['status'] ?? '-').toString();
    final isAman = statusText.toUpperCase() == 'AMAN';

    return GlassCard(
      glowColor: AppColors.primary,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Audit Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#AD-${widget.sessionId}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textOnPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _metaRow(Icons.location_on_outlined, 'Location', 'Warehouse C, Zone 4'),
          const SizedBox(height: 8),
          _metaRow(Icons.person_outline, 'Assigned to', data['user_name']?.toString() ?? '-'),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isAman ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
                size: 16,
                color: isAman ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 8),
              const Text('Overall Status: ', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: (isAman ? AppColors.success : AppColors.warning).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isAman ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ),
      ],
    );
  }

  Widget _comparisonCard(Map<String, dynamic> item) {
    final statusText = (item['status'] ?? '-').toString();
    final isAman = statusText.toUpperCase() == 'AMAN';
    final expected = int.tryParse('${item['expected'] ?? 0}') ?? 0;
    final detected = int.tryParse('${item['detected'] ?? 0}') ?? 0;
    final isMatch = expected == detected;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${item['sku']} - ${item['name']}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isAman ? AppColors.success : AppColors.warning).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (isAman ? AppColors.success : AppColors.warning).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isAman ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _numberBox('EXPECTED', '$expected', AppColors.info)),
              const SizedBox(width: 10),
              Expanded(child: _numberBox('DETECTED', '$detected', isMatch ? AppColors.success : AppColors.error)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numberBox(String title, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: accent),
          ),
        ],
      ),
    );
  }
}
