import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_animations.dart';
import '../models/auth_models.dart';
import '../services/api_service.dart';
import '../services/predict_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/stat_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/shimmer_loading.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'role_select_screen.dart';
import 'scan_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key, required this.api, required this.user});
  final ApiService api;
  final UserModel user;

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int current = 0;

  bool get isAdmin => widget.user.role.toLowerCase() == 'admin';

  @override
  Widget build(BuildContext context) {
    return isAdmin ? _buildAdminShell() : _buildStaffShell();
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => RoleSelectScreen(api: widget.api)),
      (route) => false,
    );
  }

  // ── Staff Shell ──
  Widget _buildStaffShell() {
    final predict = PredictService(baseUrl: widget.api.baseUrl);
    final pages = [
      HomeScreen(api: widget.api, onStartAudit: () => setState(() => current = 1)),
      ScanScreen(api: widget.api, predictService: predict),
      HistoryScreen(api: widget.api),
    ];
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Column(
          children: [
            _buildAppBar('INVENTORY AUDIT', widget.user),
            Expanded(child: pages[current]),
          ],
        ),
      ),
      drawer: _buildDrawer(
        title: 'INVENTORY AUDIT',
        subtitle: 'Menu Staff',
        items: [
          _DrawerItem(icon: Icons.home_rounded, label: 'HOME', index: 0),
          _DrawerItem(icon: Icons.camera_alt_rounded, label: 'AUDIT', index: 1),
          _DrawerItem(icon: Icons.bar_chart_rounded, label: 'REPORTS', index: 2),
        ],
      ),
      bottomNavigationBar: _buildBottomNav([
        _NavItem(icon: Icons.home_rounded, label: 'HOME'),
        _NavItem(icon: Icons.camera_alt_rounded, label: 'AUDIT'),
        _NavItem(icon: Icons.bar_chart_rounded, label: 'REPORTS'),
      ]),
    );
  }

  // ── Admin Shell ──
  Widget _buildAdminShell() {
    final pages = [
      AdminDashboardPage(api: widget.api),
      _AdminProductPage(api: widget.api),
      _AdminUserPage(api: widget.api),
      _AdminReportPage(api: widget.api),
    ];
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Column(
          children: [
            _buildAppBar('INVENTORY AUDIT', widget.user),
            Expanded(child: pages[current]),
          ],
        ),
      ),
      drawer: _buildDrawer(
        title: 'INVENTORY AUDIT',
        subtitle: 'Menu Admin',
        items: [
          _DrawerItem(icon: Icons.dashboard_rounded, label: 'DASHBOARD', index: 0),
          _DrawerItem(icon: Icons.inventory_2_rounded, label: 'PRODUK', index: 1),
          _DrawerItem(icon: Icons.group_rounded, label: 'USER', index: 2),
          _DrawerItem(icon: Icons.description_rounded, label: 'LAPORAN', index: 3),
        ],
      ),
      bottomNavigationBar: _buildBottomNav([
        _NavItem(icon: Icons.dashboard_rounded, label: 'DASHBOARD'),
        _NavItem(icon: Icons.inventory_2_rounded, label: 'PRODUK'),
        _NavItem(icon: Icons.group_rounded, label: 'USER'),
        _NavItem(icon: Icons.description_rounded, label: 'LAPORAN'),
      ]),
    );
  }

  // ── Custom AppBar ──
  Widget _buildAppBar(String title, UserModel user) {
    return SafeArea(
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
            // Hamburger
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            const Spacer(),
            // Title + Role badge
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: user.role.toLowerCase() == 'admin'
                        ? AppColors.warning.withOpacity(0.15)
                        : AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: user.role.toLowerCase() == 'admin'
                          ? AppColors.warning.withOpacity(0.4)
                          : AppColors.success.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: user.role.toLowerCase() == 'admin'
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            // User badge
            PopupMenuButton<String>(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_outline, size: 18, color: AppColors.textOnPrimary),
              ),
              onSelected: (value) {
                if (value == 'logout') _logout();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.username, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryMuted,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'logout', child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                    SizedBox(width: 10),
                    Text('Logout', style: TextStyle(color: AppColors.error)),
                  ],
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Premium Drawer ──
  Widget _buildDrawer({
    required String title,
    required String subtitle,
    required List<_DrawerItem> items,
  }) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.inventory_2_rounded, size: 24, color: AppColors.textOnPrimary),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 8),

            // Nav items
            ...items.map((item) => _buildDrawerTile(item)),

            const Spacer(),
            const Divider(color: AppColors.divider, height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text('LOGOUT', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(_DrawerItem item) {
    final selected = current == item.index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: selected ? AppColors.primary : AppColors.textMuted,
          size: 22,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        selected: selected,
        selectedTileColor: AppColors.primaryMuted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          setState(() => current = item.index);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ── Premium Bottom Nav ──
  Widget _buildBottomNav(List<_NavItem> items) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final selected = current == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => current = i),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 24,
                          color: selected ? AppColors.primary : AppColors.navInactive,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? AppColors.primary : AppColors.navInactive,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _DrawerItem {
  final IconData icon;
  final String label;
  final int index;
  const _DrawerItem({required this.icon, required this.label, required this.index});
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ═══════════════════════════════════════════════
// ADMIN DASHBOARD PAGE
// ═══════════════════════════════════════════════

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key, required this.api});
  final ApiService api;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late Future<Map<String, dynamic>> _future;
  late Future<List<Map<String, dynamic>>> _trendFuture;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getDashboard();
    _trendFuture = widget.api.getDashboardTrend();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      setState(() {
        _future = widget.api.getDashboard();
        _trendFuture = widget.api.getDashboardTrend();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _future = widget.api.getDashboard();
      _trendFuture = widget.api.getDashboardTrend();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: ShimmerLoading(count: 4, height: 100),
          );
        }
        final d = snap.data ?? const {};
        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              FadeSlideIn(
                child: StatCard(
                  title: 'TOTAL PRODUK',
                  value: '${d['total_products'] ?? 0}',
                  icon: Icons.inventory_2_rounded,
                  accentColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'TOTAL USER',
                        value: '${d['total_users'] ?? 0}',
                        icon: Icons.group_rounded,
                        accentColor: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'TOTAL AUDIT',
                        value: '${d['total_audits'] ?? 0}',
                        icon: Icons.fact_check_rounded,
                        accentColor: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 160),
                child: _trendSection(_trendFuture),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 240),
                child: _activityCard(d),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════
// ADMIN PRODUCT PAGE
// ═══════════════════════════════════════════════

class _AdminProductPage extends StatefulWidget {
  const _AdminProductPage({required this.api});
  final ApiService api;

  @override
  State<_AdminProductPage> createState() => _AdminProductPageState();
}

class _AdminProductPageState extends State<_AdminProductPage> {
  late Future<List<Map<String, dynamic>>> _future;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = widget.api.getAdminProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _future = widget.api.getAdminProducts();
    });
  }

  Future<void> _deleteProduct(Map<String, dynamic> item) async {
    final id = (item['id'] as num).toInt();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _buildConfirmDialog(
        title: 'Hapus Produk',
        content: 'Hapus produk "${item['name'] ?? '-'}"?',
      ),
    );
    if (confirm != true) return;
    try {
      await widget.api.deleteAdminProduct(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_successSnackBar('Produk berhasil dihapus'));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_errorSnackBar('Gagal hapus: $e'));
    }
  }

  Future<void> _editProduct(Map<String, dynamic> item) async {
    final formKey = GlobalKey<FormState>();
    final skuCtrl = TextEditingController(text: (item['sku'] ?? '').toString());
    final nameCtrl = TextEditingController(text: (item['name'] ?? '').toString());
    final catCtrl = TextEditingController(text: (item['category'] ?? '').toString());
    final descCtrl = TextEditingController(text: (item['description'] ?? '').toString());
    final imgCtrl = TextEditingController(text: (item['image_url'] ?? '').toString());
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => _buildFormDialog(
        title: 'Edit Produk',
        formKey: formKey,
        fields: [
          _DialogField(controller: skuCtrl, label: 'SKU', icon: Icons.qr_code),
          _DialogField(controller: nameCtrl, label: 'Nama', icon: Icons.label_outline),
          _DialogField(controller: catCtrl, label: 'Kategori', icon: Icons.category_outlined),
          _DialogField(controller: descCtrl, label: 'Deskripsi', icon: Icons.description_outlined),
          _DialogField(controller: imgCtrl, label: 'Image URL', icon: Icons.image_outlined),
        ],
      ),
    );
    if (updated != true) return;
    try {
      await widget.api.updateAdminProduct(
        productId: (item['id'] as num).toInt(),
        payload: {
          'sku': skuCtrl.text.trim(),
          'name': nameCtrl.text.trim(),
          'category': catCtrl.text.trim(),
          'description': descCtrl.text.trim(),
          'image_url': imgCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_successSnackBar('Produk berhasil diperbarui'));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_errorSnackBar('Gagal update: $e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: ShimmerLoading(count: 4),
          );
        }
        final items = snap.data ?? const [];
        final query = _searchCtrl.text.trim().toLowerCase();
        final filtered = query.isEmpty
            ? items
            : items.where((p) {
                final name = (p['name'] ?? '').toString().toLowerCase();
                final sku = (p['sku'] ?? '').toString().toLowerCase();
                final category = (p['category'] ?? '').toString().toLowerCase();
                return name.contains(query) || sku.contains(query) || category.contains(query);
              }).toList();
        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _sectionTitle('Manajemen Produk'),
              const SizedBox(height: 14),
              _buildSearchField(_searchCtrl, 'Cari produk berdasarkan nama atau SKU...', () => setState(() {})),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                const EmptyStateWidget(
                  icon: Icons.inventory_2_outlined,
                  title: 'Belum ada produk',
                  subtitle: 'Produk yang ditambahkan akan muncul di sini.',
                )
              else
                ...filtered.map((p) => _productRow(
                      context,
                      p,
                      onEdit: () => _editProduct(p),
                      onDelete: () => _deleteProduct(p),
                    )),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════
// ADMIN USER PAGE
// ═══════════════════════════════════════════════

class _AdminUserPage extends StatefulWidget {
  const _AdminUserPage({required this.api});
  final ApiService api;

  @override
  State<_AdminUserPage> createState() => _AdminUserPageState();
}

class _AdminUserPageState extends State<_AdminUserPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getAdminUsers();
  }

  void _refresh() {
    setState(() {
      _future = widget.api.getAdminUsers();
    });
  }

  Future<void> _deleteUser(Map<String, dynamic> item) async {
    final id = (item['id'] as num).toInt();
    final username = (item['username'] ?? '').toString();
    if (username == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(_errorSnackBar('Super admin tidak dapat dihapus'));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _buildConfirmDialog(
        title: 'Hapus User',
        content: 'Hapus user "$username"?',
      ),
    );
    if (confirm != true) return;
    try {
      await widget.api.deleteAdminUser(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_successSnackBar('User berhasil dihapus'));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_errorSnackBar('Gagal hapus user: $e'));
    }
  }

  Future<void> _editUser(Map<String, dynamic> item) async {
    final formKey = GlobalKey<FormState>();
    final usernameCtrl = TextEditingController(text: (item['username'] ?? '').toString());
    final emailCtrl = TextEditingController(text: (item['email'] ?? '').toString());
    final roleCtrl = TextEditingController(text: (item['role'] ?? '').toString());
    final storeCtrl = TextEditingController(text: (item['store_id'] ?? '').toString());
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => _buildFormDialog(
        title: 'Edit User',
        formKey: formKey,
        fields: [
          _DialogField(controller: usernameCtrl, label: 'Username', icon: Icons.person_outline),
          _DialogField(controller: emailCtrl, label: 'Gmail / Email', icon: Icons.alternate_email_outlined),
          _DialogField(controller: roleCtrl, label: 'Role', icon: Icons.shield_outlined),
          _DialogField(controller: storeCtrl, label: 'Store ID', icon: Icons.store_outlined),
        ],
      ),
    );
    if (updated != true) return;
    try {
      await widget.api.updateAdminUser(
        userId: (item['id'] as num).toInt(),
        payload: {
          'id': (item['id'] as num).toInt(),
          'username': usernameCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'role': roleCtrl.text.trim(),
          'store_id': int.tryParse(storeCtrl.text.trim()) ?? (item['store_id'] as num).toInt(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_successSnackBar('User berhasil diperbarui'));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_errorSnackBar('Gagal update user: $e'));
    }
  }

  Future<void> _addUser() async {
    final formKey = GlobalKey<FormState>();
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: 'staff');
    final storeCtrl = TextEditingController(text: '1');

    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _buildFormDialog(
        title: 'Tambah User Baru',
        formKey: formKey,
        fields: [
          _DialogField(controller: usernameCtrl, label: 'Username', icon: Icons.person_outline),
          _DialogField(controller: emailCtrl, label: 'Gmail / Email', icon: Icons.alternate_email_outlined),
          _DialogField(controller: passwordCtrl, label: 'Password', icon: Icons.lock_outline),
          _DialogField(controller: roleCtrl, label: 'Role (admin/staff)', icon: Icons.shield_outlined),
          _DialogField(controller: storeCtrl, label: 'Store ID', icon: Icons.store_outlined),
        ],
      ),
    );
    if (created != true) return;
    try {
      await widget.api.createAdminUser(
        payload: {
          'username': usernameCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'password': passwordCtrl.text,
          'role': roleCtrl.text.trim().toLowerCase(),
          'store_id': int.tryParse(storeCtrl.text.trim()) ?? 1,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_successSnackBar('User baru berhasil ditambahkan'));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_errorSnackBar('Gagal tambah user: $e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Padding(
              padding: EdgeInsets.all(20),
               child: ShimmerLoading(count: 4),
            );
          }
          final items = snap.data ?? const [];
          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _sectionTitle('Manajemen User'),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  const EmptyStateWidget(
                    icon: Icons.group_outlined,
                    title: 'Belum ada user',
                    subtitle: 'User yang terdaftar akan muncul di sini.',
                  )
                else
                  ...items.map((u) => _userCard(
                        u,
                        onEdit: () => _editUser(u),
                        onDelete: () => _deleteUser(u),
                      )),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addUser,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// ADMIN STORE PAGE (kept for compatibility)
// ═══════════════════════════════════════════════

class _AdminStorePage extends StatefulWidget {
  const _AdminStorePage({required this.api});
  final ApiService api;

  @override
  State<_AdminStorePage> createState() => _AdminStorePageState();
}

class _AdminStorePageState extends State<_AdminStorePage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getAdminStores();
  }

  void _refresh() {
    setState(() {
      _future = widget.api.getAdminStores();
    });
  }

  Future<void> _upsertStore({Map<String, dynamic>? item}) async {
    final nameCtrl = TextEditingController(text: (item?['name'] ?? '').toString());
    final addressCtrl = TextEditingController(text: (item?['address'] ?? '').toString());
    final phoneCtrl = TextEditingController(text: (item?['phone'] ?? '').toString());
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _buildFormDialog(
        title: item == null ? 'Tambah Toko' : 'Edit Toko',
        fields: [
          _DialogField(controller: nameCtrl, label: 'Nama Toko', icon: Icons.store_outlined),
          _DialogField(controller: addressCtrl, label: 'Alamat', icon: Icons.location_on_outlined),
          _DialogField(controller: phoneCtrl, label: 'Telepon', icon: Icons.phone_outlined),
        ],
      ),
    );
    if (saved != true) return;
    final payload = {
      'name': nameCtrl.text.trim(),
      'address': addressCtrl.text.trim(),
      'phone': phoneCtrl.text.trim(),
    };
    try {
      if (item == null) {
        await widget.api.createAdminStore(payload);
      } else {
        await widget.api.updateAdminStore(storeId: (item['id'] as num).toInt(), payload: payload);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        _successSnackBar(item == null ? 'Toko berhasil ditambah' : 'Toko berhasil diperbarui'),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_errorSnackBar('Gagal simpan toko: $e'));
    }
  }

  Future<void> _deleteStore(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _buildConfirmDialog(
        title: 'Hapus Toko',
        content: 'Hapus toko "${item['name'] ?? '-'}"?',
      ),
    );
    if (confirm != true) return;
    try {
      await widget.api.deleteAdminStore((item['id'] as num).toInt());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_successSnackBar('Toko berhasil dihapus'));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_errorSnackBar('Gagal hapus toko: $e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (_, snap) {
        final items = snap.data ?? const [];
        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionTitle('Kelola Toko'),
                  GradientButton(
                    label: 'TAMBAH',
                    icon: Icons.add_rounded,
                    fullWidth: false,
                    height: 40,
                    fontSize: 12,
                    onPressed: () => _upsertStore(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (items.isEmpty)
                const EmptyStateWidget(
                  icon: Icons.store_outlined,
                  title: 'Belum ada data toko',
                )
              else
                ...items.map((s) => _storeCard(s,
                    onEdit: () => _upsertStore(item: s),
                    onDelete: () => _deleteStore(s),
                  )),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════
// ADMIN REPORT PAGE
// ═══════════════════════════════════════════════

class _AdminReportPage extends StatelessWidget {
  const _AdminReportPage({required this.api});
  final ApiService api;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: api.getAdminReportSummary(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: ShimmerLoading(count: 4, height: 70),
          );
        }
        final data = snap.data ?? const {};
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _sectionTitle('Laporan Global'),
            const SizedBox(height: 14),
            _reportSummary('Total Stok Aman', '${data['total_aman'] ?? 0}', AppColors.success, Icons.check_circle_rounded),
            _reportSummary('Total Stok Tidak Aman', '${data['total_tidak_aman'] ?? 0}', AppColors.error, Icons.warning_rounded),
            _reportSummary('Total Audit', '${data['total_sessions'] ?? 0}', AppColors.info, Icons.fact_check_rounded),
            const SizedBox(height: 16),
            GradientButton(
              label: 'EXPORT LAPORAN',
              icon: Icons.file_download_rounded,
              onPressed: () async {
                try {
                  final csv = await api.exportAdminReport();
                  if (!context.mounted) return;
                  showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Export Laporan'),
                      content: SingleChildScrollView(
                        child: Text(csv, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('TUTUP')),
                      ],
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(_errorSnackBar('Gagal export: $e'));
                }
              },
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════
// SHARED HELPER WIDGETS (redesigned)
// ═══════════════════════════════════════════════

Widget _sectionTitle(String title) => Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: 0.3,
      ),
    );

Widget _buildSearchField(TextEditingController ctrl, String hint, VoidCallback onChanged) {
  return Container(
    decoration: BoxDecoration(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.glassBorder),
    ),
    child: TextField(
      controller: ctrl,
      onChanged: (_) => onChanged(),
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
  );
}

Widget _trendSection(Future<List<Map<String, dynamic>>> future) => GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.trending_up_rounded, size: 18, color: AppColors.secondary),
              ),
              const SizedBox(width: 10),
              const Text('Audit Trends', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (_, snap) {
              final trend = snap.data ?? const [];
              if (trend.isEmpty) {
                return const SizedBox(
                  height: 180,
                  child: Center(
                    child: Text('Belum ada data tren.', style: TextStyle(color: AppColors.textMuted)),
                  ),
                );
              }
              final max = trend
                  .map((e) => (e['count'] as num?)?.toDouble() ?? 0)
                  .fold<double>(1, (a, b) => b > a ? b : a);
              return SizedBox(
                height: 220,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: trend.map((e) {
                    final count = (e['count'] as num?)?.toDouble() ?? 0;
                    final height = 30 + ((count / max) * 140);
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${count.toInt()}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 28,
                          height: height,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: AppColors.primaryGradientVertical,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (e['date'] ?? '').toString(),
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );

Widget _activityCard(Map<String, dynamic> d) => GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const Text('Recent Activity', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          _activityTile(
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppColors.success,
            title: 'Audit terbaru',
            subtitle: '${d['latest_session_date'] ?? '-'} oleh ${d['latest_user'] ?? '-'}',
            trailing: '${d['audits_today'] ?? 0} hari ini',
          ),
          Divider(color: AppColors.divider, height: 1),
          _activityTile(
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.warning,
            title: 'Stok menipis',
            subtitle: '${d['low_stock'] ?? 0} item perlu perhatian',
            trailing: '${d['total_products'] ?? 0} produk',
          ),
        ],
      ),
    );

Widget _activityTile({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String subtitle,
  required String trailing,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
        Text(trailing, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      ],
    ),
  );
}

Widget _productRow(
  BuildContext context,
  Map<String, dynamic> item, {
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) =>
    Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.surfaceBright,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_outlined, size: 22, color: AppColors.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((item['name'] ?? '-').toString(), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (item['category'] ?? '-').toString(),
                        style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (item['sku'] ?? '-').toString(),
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _iconActionButton(Icons.edit_outlined, AppColors.secondary, onEdit),
          const SizedBox(width: 4),
          _iconActionButton(Icons.delete_outline, AppColors.error, onDelete),
        ],
      ),
    );

Widget _userCard(
  Map<String, dynamic> item, {
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) =>
    Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                (item['username'] ?? '-').toString().substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textOnPrimary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((item['username'] ?? '-').toString(), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                if (item['email'] != null && (item['email'] as String).isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    (item['email'] as String),
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (item['role'] ?? '-').toString().toUpperCase(),
                        style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Store ${(item['store_id'] ?? '-')}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          _iconActionButton(Icons.edit_outlined, AppColors.secondary, onEdit),
          const SizedBox(width: 4),
          (item['username'] ?? '').toString() == 'admin'
              ? _iconActionButton(Icons.lock_outline, AppColors.textMuted, () {})
              : _iconActionButton(Icons.delete_outline, AppColors.error, onDelete),
        ],
      ),
    );

Widget _storeCard(
  Map<String, dynamic> s, {
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) =>
    Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((s['name'] ?? '-').toString(), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text((s['address'] ?? '-').toString(), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                Text((s['phone'] ?? '-').toString(), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          _iconActionButton(Icons.edit_outlined, AppColors.secondary, onEdit),
          _iconActionButton(Icons.delete_outline, AppColors.error, onDelete),
        ],
      ),
    );

Widget _reportSummary(String title, String value, Color accent, IconData icon) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: accent)),
        ],
      ),
    );

Widget _iconActionButton(IconData icon, Color color, VoidCallback onPressed) {
  return SizedBox(
    width: 38,
    height: 38,
    child: IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: color),
      style: IconButton.styleFrom(
        backgroundColor: color.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}

// ── Dialogs ──

class _DialogField {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  const _DialogField({required this.controller, required this.label, required this.icon});
}

Widget _buildConfirmDialog({required String title, required String content}) {
  return Builder(
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content, style: const TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('BATAL'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('HAPUS'),
        ),
      ],
    ),
  );
}

Widget _buildFormDialog({
  required String title,
  GlobalKey<FormState>? formKey,
  required List<_DialogField> fields,
}) {
  return Builder(
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: fields
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: f.controller,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: f.label,
                            prefixIcon: Icon(f.icon, size: 20),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('BATAL'),
        ),
        GradientButton(
          label: 'SIMPAN',
          fullWidth: false,
          height: 42,
          fontSize: 13,
          onPressed: () {
            if (formKey?.currentState?.validate() ?? true) {
              Navigator.pop(context, true);
            }
          },
        ),
      ],
    ),
  );
}

SnackBar _successSnackBar(String msg) => SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ],
      ),
    );

SnackBar _errorSnackBar(String msg) => SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ],
      ),
    );
