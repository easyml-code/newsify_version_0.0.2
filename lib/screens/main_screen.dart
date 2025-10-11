import 'package:flutter/material.dart';
import '../tabs/home_tab.dart';
import '../tabs/insights_tab.dart';
import '../tabs/account_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1;
  bool isLocalSelected = false;

  void toggleLocalSelection() {
    setState(() {
      isLocalSelected = !isLocalSelected;
    });
    debugPrint('Local button clicked - Selected: $isLocalSelected');
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      const InsightsTab(),
      HomeTab(
        isLocalSelected: isLocalSelected,
        onLocalToggle: toggleLocalSelection,
      ),
      const AccountTab(),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: tabs[_currentIndex],
      bottomNavigationBar: Container(
        color: Colors.black,
        child: SafeArea(
          top: false,
          child: Padding(
            padding:
                const EdgeInsets.only(left: 40, right: 40, top: 4, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(Icons.search, 0),
                _buildNavItem(Icons.home_rounded, 1),
                _buildNavItem(Icons.person_outline, 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFF2196F3) : Colors.grey[600],
          size: 28,
        ),
      ),
    );
  }
}
