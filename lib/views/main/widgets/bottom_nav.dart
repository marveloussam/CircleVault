import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: 110 + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 82 + bottomInset,
              decoration: const BoxDecoration(
                color: Color(0xFFF8F8F8),
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFEAEAEA),
                    width: 1,
                  ),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Row(
                  children: [
                    Expanded(
                      child: _NavItem(
                        icon: Icons.home_filled,
                        label: 'Home',
                        isActive: currentIndex == 0,
                        onTap: () => onTap(0),
                      ),
                    ),

                    Expanded(
                      child: _NavItem(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Wallet',
                        isActive: currentIndex == 1,
                        onTap: () => onTap(1),
                      ),
                    ),

                    const SizedBox(width: 88),

                    Expanded(
                      child: _NavItem(
                        icon: Icons.groups_rounded,
                        label: 'Groups',
                        isActive: currentIndex == 3,
                        onTap: () => onTap(3),
                      ),
                    ),

                    Expanded(
                      child: _NavItem(
                        icon: Icons.person_rounded,
                        label: 'Profile',
                        isActive: currentIndex == 4,
                        onTap: () => onTap(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context)
                    .pushNamed('/createCircle');
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF22C7F7),
                      Color(0xFF00B4C7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x3322C7F7),
                      blurRadius: 24,
                      spreadRadius: 4,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  size: 42,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF68C5A2);
    const inactiveColor = Color(0xFF999999);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 30,
              color: isActive ? activeColor : inactiveColor,
            ),

            const SizedBox(height: 6),

            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 12,
                fontWeight:
                isActive ? FontWeight.w600 : FontWeight.w500,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}