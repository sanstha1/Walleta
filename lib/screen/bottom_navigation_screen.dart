import 'package:flutter/material.dart';
import 'package:walleta/screen/home/view/homeview.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const Scaffold(body: Center(child: Text('Chart'))),
    const Scaffold(body: Center(child: Text('Report'))),
    const Scaffold(body: Center(child: Text('Account'))),
  ];

  void _onVoiceTap() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: _VoiceButton(onTap: _onVoiceTap),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _VoiceButton extends StatelessWidget {
  final VoidCallback onTap;
  const _VoiceButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF4DD9C0), Color(0xFF2BB5A0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x664DD9C0),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.mic, color: Colors.white, size: 28),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.show_chart_rounded, label: 'Chart'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'Report'),
    _NavItem(icon: Icons.person_outline_rounded, label: 'Account'),
  ];

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: const Color(0xFF1A1A2E),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            ..._buildItems(0, 2),
            const SizedBox(width: 72),
            ..._buildItems(2, 4),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildItems(int start, int end) {
    return List.generate(end - start, (i) {
      final index = start + i;
      final item = _items[index];
      final isSelected = currentIndex == index;

      return Expanded(
        child: GestureDetector(
          onTap: () => onTap(index),
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                color: isSelected ? Colors.white : Colors.white38,
                size: 24,
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white38,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
