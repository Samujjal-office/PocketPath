import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/screens/sign_in_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/transactions/screens/transactions_screen.dart';
import 'features/add_expense/screens/add_expense_screen.dart';
import 'features/budgets/screens/budgets_screen.dart';
import 'features/goals/screens/goals_screen.dart';
import 'features/insights/screens/insights_screen.dart';
import 'features/settings/screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode for mobile-first design
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const PocketPathApp());
}

class PocketPathApp extends StatelessWidget {
  const PocketPathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PocketPath',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/auth',
      routes: {
        '/auth': (_) => const SignInScreen(),
        '/dashboard': (_) => const MainScaffold(),
        '/transactions': (_) => const TransactionsScreen(),
        '/add-expense': (_) => const AddExpenseScreen(),
        '/budgets': (_) => const BudgetsScreen(),
        '/goals': (_) => const GoalsScreen(),
        '/insights': (_) => const InsightsScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}

/// Bottom navigation shell that wraps the main tab screens.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    TransactionsScreen(),
    AddExpenseScreen(),
    BudgetsScreen(),
    InsightsScreen(),
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Transactions',
    ),
    _NavItem(
      icon: Icons.add_circle_outline_rounded,
      activeIcon: Icons.add_circle_rounded,
      label: 'Add',
    ),
    _NavItem(
      icon: Icons.donut_small_outlined,
      activeIcon: Icons.donut_small_rounded,
      label: 'Budgets',
    ),
    _NavItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Insights',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF3F4F6), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isSelected = _currentIndex == index;
              final isAddButton = index == 2;

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = index),
                  behavior: HitTestBehavior.opaque,
                  child: Semantics(
                    label: item.label,
                    selected: isSelected,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isAddButton)
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFB45309)
                                  : const Color(0xFFD97706),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isSelected
                                  ? item.activeIcon
                                  : item.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          )
                        else ...[
                          Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected
                                ? const Color(0xFFD97706)
                                : const Color(0xFF9CA3AF),
                            size: 24,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
