import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/kitchen_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/supplier_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/confirm_dialog.dart';

import 'dashboard/dashboard_screen.dart';
import 'inventory/category_grid_screen.dart';
import 'suppliers/supplier_list_screen.dart';
import 'purchases/purchase_list_screen.dart';
import 'menu/menu_screen.dart';
import 'sales/sales_screen.dart';
import 'stock_movements/stock_movement_screen.dart';
import 'auth/login_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  bool _loadedInitialData = false;

  static const List<_NavigationItem> _allItems = [
    _NavigationItem(
      module: 'Dashboard',
      title: 'Dashboard',
      label: 'Dashboard',
      compactLabel: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      screen: DashboardScreen(),
    ),
    _NavigationItem(
      module: 'Inventory',
      title: 'Inventory Management',
      label: 'Inventory',
      compactLabel: 'Inventory',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2_rounded,
      screen: CategoryGridScreen(),
    ),
    _NavigationItem(
      module: 'Menu',
      title: 'Smart Kitchen Menu',
      label: 'Menu',
      compactLabel: 'Menu',
      icon: Icons.restaurant_menu_outlined,
      selectedIcon: Icons.restaurant_menu_rounded,
      screen: MenuScreen(),
    ),
    _NavigationItem(
      module: 'Sales',
      title: 'Sales',
      label: 'Sales',
      compactLabel: 'Sales',
      icon: Icons.point_of_sale_outlined,
      selectedIcon: Icons.point_of_sale_rounded,
      screen: SalesScreen(),
    ),
    _NavigationItem(
      module: 'Stock Movements',
      title: 'Stock Movements',
      label: 'Movements',
      compactLabel: 'Moves',
      icon: Icons.swap_vert_outlined,
      selectedIcon: Icons.swap_vert_rounded,
      screen: StockMovementScreen(),
    ),
    _NavigationItem(
      module: 'Suppliers',
      title: 'Supplier Directory',
      label: 'Suppliers',
      compactLabel: 'Suppliers',
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
      screen: SupplierListScreen(),
    ),
    _NavigationItem(
      module: 'Purchases',
      title: 'Purchase History',
      label: 'Purchases',
      compactLabel: 'Purchases',
      icon: Icons.shopping_cart_outlined,
      selectedIcon: Icons.shopping_cart_rounded,
      screen: PurchaseListScreen(),
    ),
  ];

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Confirm Logout',
      content: 'Are you sure you want to log out of NSRIT Canteen System?',
      confirmText: 'Logout',
      cancelText: 'Cancel',
      isDanger: true,
    );

    if (confirmed == true && mounted) {
      await authProvider.signOut();
      if (!mounted) return;
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final visibleItems = _allItems
        .where(
          (item) => adminProvider.hasAccess(authProvider.user, item.module),
        )
        .toList();
    final selectedIndex = _currentIndex >= visibleItems.length
        ? 0
        : _currentIndex;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(
              Icons.restaurant_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              visibleItems[selectedIndex].title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              authProvider.user?.displayName ??
                  authProvider.user?.email ??
                  'NSRIT Canteen',
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: themeProvider.isDarkMode
                ? 'Switch to Light Mode'
                : 'Switch to Dark Mode',
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.wb_sunny_rounded
                  : Icons.nightlight_round,
            ),
            onPressed: () {
              themeProvider.toggleTheme(!themeProvider.isDarkMode);
            },
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _handleLogout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (isTablet)
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              destinations: visibleItems
                  .map(
                    (item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: Text(item.label),
                    ),
                  )
                  .toList(),
            ),
          if (isTablet) const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              children: visibleItems.map((item) => item.screen).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isTablet
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              destinations: visibleItems
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: item.compactLabel,
                    ),
                  )
                  .toList(),
            ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedInitialData) return;
    _loadedInitialData = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAuthorizedData();
      }
    });
  }

  Future<void> _loadAuthorizedData() async {
    final authProvider = context.read<AuthProvider>();
    final adminProvider = context.read<AdminProvider>();
    final inventoryProvider = context.read<InventoryProvider>();
    final supplierProvider = context.read<SupplierProvider>();
    final purchaseProvider = context.read<PurchaseProvider>();
    final kitchenProvider = context.read<KitchenProvider>();
    final user = authProvider.user;

    if (adminProvider.hasAccess(user, 'Inventory') ||
        adminProvider.hasAccess(user, 'Menu')) {
      inventoryProvider.startRealtimeSync();
    }
    if (adminProvider.hasAccess(user, 'Suppliers')) {
      await supplierProvider.loadSuppliers();
    }
    if (adminProvider.hasAccess(user, 'Purchases')) {
      await purchaseProvider.loadPurchases();
    }
    if (adminProvider.hasAccess(user, 'Menu') ||
        adminProvider.hasAccess(user, 'Sales') ||
        adminProvider.hasAccess(user, 'Stock Movements')) {
      await kitchenProvider.loadKitchenData();
    }
    if (user?.role == 'Administrator') {
      adminProvider.startUserSync();
      await adminProvider.loadAdminData();
    }
  }
}

class _NavigationItem {
  final String module;
  final String title;
  final String label;
  final String compactLabel;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;

  const _NavigationItem({
    required this.module,
    required this.title,
    required this.label,
    required this.compactLabel,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });
}
