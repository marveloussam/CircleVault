import 'package:circlevault/views/circle/circle_list_screen.dart';
import 'package:circlevault/views/main/widgets/bottom_nav.dart';
import 'package:circlevault/views/payment/wallet_screen.dart';
import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Page-space index (0–3), not nav-space (0,1,3,4)
  int _pageIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),       // page 0 ↔ nav 0
    WalletScreen(),     // page 1 ↔ nav 1
    CircleListScreen(), // page 2 ↔ nav 3
    ProfileScreen(),    // page 3 ↔ nav 4
  ];

  // Nav emits 0,1,3,4 → map to page indices 0,1,2,3
  void _onNavTap(int navIndex) {
    setState(() {
      _pageIndex = navIndex > 2 ? navIndex - 1 : navIndex;
    });
  }

  // Page index back to nav index for the active highlight
  int get _navIndex => _pageIndex >= 2 ? _pageIndex + 1 : _pageIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: IndexedStack(
        index: _pageIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _navIndex,
        onTap: _onNavTap,
      ),
    );
  }
}