import 'package:flutter/material.dart';
import '../tabs/home_tab.dart';
import '../tabs/insights_tab.dart';
import '../tabs/account_tab.dart';
import '../services/location_service.dart';
import '../widgets/location_bottom_sheet.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1;
  bool isLocalSelected = false;
  String? userDistrict;
  bool _isLoadingLocation = false;

  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _loadCachedLocation();
  }

  Future<void> _loadCachedLocation() async {
    final location = await _locationService.loadCachedLocation();
    if (location != null) {
      setState(() {
        userDistrict = location.district;
      });
    }
  }

  Future<void> toggleLocalSelection() async {
    if (!isLocalSelected) {
      // Enabling local - get location
      setState(() => _isLoadingLocation = true);

      final location = await _locationService.requestAndGetLocation();

      setState(() => _isLoadingLocation = false);

      if (location != null && mounted) {
        // Show bottom sheet with location details
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => LocationBottomSheet(
            location: location,
            onConfirm: (updatedLocation) {
              setState(() {
                isLocalSelected = true;
                userDistrict = updatedLocation.district;
              });

              debugPrint('✅ Local enabled for: ${updatedLocation.district}');
            },

          ),
        );
      } else if (mounted) {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to get location. Please enable location services.'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Disabling local
      setState(() {
        isLocalSelected = false;
      });
      debugPrint('❌ Local disabled');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      const InsightsTab(),
      HomeTab(
        isLocalSelected: isLocalSelected,
        onLocalToggle: toggleLocalSelection,
        userDistrict: userDistrict,
        isLoadingLocation: _isLoadingLocation,
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
            padding: const EdgeInsets.only(left: 40, right: 40, top: 0, bottom: 0),
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