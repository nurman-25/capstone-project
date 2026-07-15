import 'package:flutter/material.dart';

import 'audit_detail_screen.dart';
import '../core/app_colors.dart';
import '../core/app_animations.dart';
import '../services/api_service.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/shimmer_loading.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.api});
  final ApiService api;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  final TextEditingController _searchCtrl = TextEditingController();
  bool _sortNewest = true;

  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  @override
  void initState() {
    super.initState();
    _future = widget.api.getHistory();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _future = widget.api.getHistory();
    });
  }

  void _showSortDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Urutkan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sortOption('Terbaru', true),
            _sortOption('Terlama', false),
          ],
        ),
      ),
    );
  }

  String _formatToday() {
    final now = DateTime.now();
    final month = _monthNames[now.month - 1];
    return '${now.day} $month ${now.year}';
  }

  String _resolveDateLabel(Map<String, dynamic> item) {
    final raw = (item['date'] ?? '').toString().trim();
    return raw.isEmpty ? _formatToday() : raw;
  }

  DateTime _parseHistoryDate(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);

    final parts = raw.split(RegExp(r'\s+'));
    if (parts.length >= 3) {
      final day = int.tryParse(parts[0]) ?? 1;
      final monthMap = <String, int>{
        'jan': 1,
        'feb': 2,
        'mar': 3,
        'apr': 4,
        'may': 5,
        'mei': 5,
        'jun': 6,
        'jul': 7,
        'aug': 8,
        'agu': 8,
        'sep': 9,
        'oct': 10,
        'okt': 10,
        'nov': 11,
        'dec': 12,
        'des': 12,
      };
      final month = monthMap[parts[1].toLowerCase()] ?? 1;
      final year = int.tryParse(parts[2]) ?? 1970;
      return DateTime(year, month, day);
    }

    return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  Widget _sortOption(String label, bool value) {
    final selected = _sortNewest == value;
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? AppColors.primary : AppColors.textMuted,
      ),
      title: Text(label, style: TextStyle(color: selected ? AppColors.primary : AppColors.textSecondary)),
      onTap: () {
        setState(() => _sortNewest = value);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: ShimmerLoading(count: 4),
          );
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.error_outline, size: 32, color: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal memuat riwayat:\n${snap.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _refresh,
                    child: const Text('COBA LAGI'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snap.data ?? [];
        final query = _searchCtrl.text.trim().toLowerCase();
        final filtered = query.isEmpty
            ? data
            : data.where((item) {
                final status = (item['status'] ?? '').toString().toLowerCase();
                final date = (item['date'] ?? '').toString().toLowerCase();
                final total = (item['total'] ?? '').toString().toLowerCase();
                final name = (item['item_name'] ?? '').toString().toLowerCase();
                return status.contains(query) ||
                    date.contains(query) ||
                    total.contains(query) ||
                    name.contains(query);
              }).toList();
        // Apply sort
        filtered.sort((a, b) {
          final dateA = _parseHistoryDate((a['date'] ?? '').toString());
          final dateB = _parseHistoryDate((b['date'] ?? '').toString());
          return _sortNewest ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
        });
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            FadeSlideIn(
              child: const Text(
                'Reports History',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 6),
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: Text(
                'View past inventory validations. Hari ini: ${_formatToday()}',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 20),

            // ── Search & Sort ──
            FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Search by date, status, or session',
                          hintStyle: TextStyle(color: AppColors.textMuted),
                          prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showSortDialog,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: const Icon(Icons.filter_list_rounded, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            if (filtered.isEmpty)
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: const EmptyStateWidget(
                  icon: Icons.history_rounded,
                  title: 'Belum ada riwayat audit',
                  subtitle: 'Hasil scan yang disimpan akan muncul di sini.',
                ),
              )
            else
              ...filtered.asMap().entries.map((entry) {
                final item = entry.value;
                final status = (item['status'] ?? 'AMAN').toString();
                final isAman = status.toUpperCase() == 'AMAN';
                final dateLabel = _resolveDateLabel(item);

                return FadeSlideIn(
                  delay: Duration(milliseconds: 200 + (entry.key * 60)),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TANGGAL',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dateLabel,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'JUMLAH PRODUK',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item['total'] ?? 0} scanned',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                final sessionId = int.tryParse((item['session_id'] ?? '0').toString()) ?? 0;
                                if (sessionId <= 0) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AuditDetailScreen(api: widget.api, sessionId: sessionId),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                              label: const Text(
                                'VIEW DETAILS',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 400),
              child: OutlinedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('MUAT ULANG'),
              ),
            ),
          ],
        );
      },
    );
  }
}
