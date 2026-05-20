import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'localization.dart';
import 'state/app_state.dart';
import 'ui/theme.dart';
import 'ui/screens/input_screen.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/budget_screen.dart';
import 'ui/screens/tracking_screen.dart';
import 'ui/screens/invest_screen.dart';
import 'ui/widgets/custom_charts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock orientation to vertical for premium polished experience
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  // Set system navigation overlay styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppState _appState = AppState();

  @override
  Widget build(BuildContext context) {
    return AppStateProvider(
      notifier: _appState,
      child: ListenableBuilder(
        listenable: _appState,
        builder: (context, child) {
          return MaterialApp(
            title: 'Vibrant Finance',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: _appState.themeName == 'gold' ? AppTheme.goldTheme : AppTheme.darkTheme,
            themeMode: _appState.themeName == 'light' ? ThemeMode.light : ThemeMode.dark,
            home: const MainShell(),
          );
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final locale = state.locale;
    final isDark = state.themeMode == ThemeMode.dark;

    final List<Widget> screens = [
      const InputScreen(),
      DashboardScreen(
        onNavigateToLedger: () {
          setState(() {
            _currentIndex = 3; // Ledger screen index (tab index 3)
          });
        },
      ),
      const BudgetScreen(),
      const TrackingScreen(),
      const InvestScreen(),
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: (isDark ? AppColors.border : AppColors.borderLight).withOpacity(0.5),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: isDark ? AppColors.cardBg : AppColors.cardBgLight,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.violet,
          unselectedItemColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.edit_note_outlined),
              activeIcon: const Icon(Icons.edit_note_rounded, color: AppColors.violet),
              label: locale == 'en' ? 'Quick Log' : 'Ghi chép',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined),
              activeIcon: const Icon(Icons.dashboard_rounded, color: AppColors.violet),
              label: AppLocalizations.translate('nav_dashboard', locale),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.pie_chart_outline_rounded),
              activeIcon: const Icon(Icons.pie_chart_rounded, color: AppColors.violet),
              label: AppLocalizations.translate('nav_budget', locale),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_outlined),
              activeIcon: const Icon(Icons.receipt_long_rounded, color: AppColors.violet),
              label: AppLocalizations.translate('nav_ledger', locale),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.auto_graph_outlined),
              activeIcon: const Icon(Icons.auto_graph_rounded, color: AppColors.violet),
              label: AppLocalizations.translate('nav_invest', locale),
            ),
          ],
        ),
      ),
    );
  }
}
