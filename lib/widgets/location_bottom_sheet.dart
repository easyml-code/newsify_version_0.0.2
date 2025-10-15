import 'package:flutter/material.dart';
import '../services/location_service.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class LocationBottomSheet extends StatefulWidget {
  final LocationData location;
  final Function(LocationData) onConfirm;


  const LocationBottomSheet({
    super.key,
    required this.location,
    required this.onConfirm,
  });

  @override
  State<LocationBottomSheet> createState() => _LocationBottomSheetState();
}

class _LocationBottomSheetState extends State<LocationBottomSheet> {
  bool _isEditing = false;
  late TextEditingController _districtController;
  late TextEditingController _stateController;
  late TextEditingController _localityController;
  late TextEditingController _pincodeController;

  @override
  void initState() {
    super.initState();
    _districtController = TextEditingController(text: widget.location.district);
    _stateController = TextEditingController(text: widget.location.state);
    _localityController = TextEditingController(text: widget.location.locality);
    _pincodeController = TextEditingController(text: widget.location.pincode);
  }

  @override
  void dispose() {
    _districtController.dispose();
    _stateController.dispose();
    _localityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _handleConfirm() async {
  final updatedLocation = LocationData(
    latitude: widget.location.latitude,
    longitude: widget.location.longitude,
    district: _districtController.text.trim(),
    state: _stateController.text.trim(),
    locality: _localityController.text.trim(),
    pincode: _pincodeController.text.trim(),
    country: widget.location.country,
  );

  // Update and save using public methods
  final locationService = LocationService();
  locationService.updateCachedLocation(updatedLocation);
  await locationService.saveToPrefs(updatedLocation);

  widget.onConfirm(updatedLocation);
  Navigator.pop(context);
}

@override
Widget build(BuildContext context) {
  final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
  
  return Container(
    decoration: BoxDecoration(
      color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    ),
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Handle bar
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Title with Edit button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFF2196F3),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Your Location',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: _toggleEdit,
              icon: Icon(
                _isEditing ? Icons.check : Icons.edit,
                color: const Color(0xFF2196F3),
                size: 18,
              ),
              label: Text(
                _isEditing ? 'Done' : 'Edit',
                style: const TextStyle(
                  color: Color(0xFF2196F3),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Location details (editable or readonly)
        _buildField('District', _districtController, isDarkMode),
        _buildField('State', _stateController, isDarkMode),
        _buildField('Locality', _localityController, isDarkMode),
        _buildField('Pincode', _pincodeController, isDarkMode),
        
        const SizedBox(height: 24),
        
        // Confirm button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Confirm Location',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Cancel button
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildField(String label, TextEditingController controller, bool isDarkMode) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _isEditing
              ? TextField(
                  controller: controller,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF2196F3),
                        width: 2,
                      ),
                    ),
                  ),
                )
              : Text(
                  controller.text,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ],
    ),
  );
}
}