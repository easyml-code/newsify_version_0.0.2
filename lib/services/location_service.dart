import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  LocationData? _cachedLocation;
  DateTime? _lastFetchTime;

  LocationData? get cachedLocation => _cachedLocation;

  /// Check if location permission is granted
  Future<bool> hasPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Request location permission and get location
  Future<LocationData?> requestAndGetLocation() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services are disabled');
        return null;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permission permanently denied');
        return null;
      }

      // Get current position
      debugPrint('📍 Getting current position...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode to get address
      debugPrint('🔍 Reverse geocoding...');
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        debugPrint('❌ No address found');
        return null;
      }

      final place = placemarks.first;
      final locationData = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        district: place.subAdministrativeArea ?? place.locality ?? 'Unknown',
        state: place.administrativeArea ?? 'Unknown',
        pincode: place.postalCode ?? 'Unknown',
        locality: place.locality ?? 'Unknown',
        country: place.country ?? 'Unknown',
      );

      // Cache the location
      _cachedLocation = locationData;
      _lastFetchTime = DateTime.now();
      await saveToPrefs(locationData);

      debugPrint('✅ Location obtained: ${locationData.district}, ${locationData.state}');
      return locationData;
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
      return null;
    }
  }

  /// Load cached location from SharedPreferences
  Future<LocationData?> loadCachedLocation() async {
    if (_cachedLocation != null) return _cachedLocation;

    try {
      final prefs = await SharedPreferences.getInstance();
      final district = prefs.getString('location_district');
      final state = prefs.getString('location_state');
      final pincode = prefs.getString('location_pincode');
      final locality = prefs.getString('location_locality');
      final country = prefs.getString('location_country');
      final lat = prefs.getDouble('location_lat');
      final lng = prefs.getDouble('location_lng');

      if (district != null && state != null && lat != null && lng != null) {
        _cachedLocation = LocationData(
          latitude: lat,
          longitude: lng,
          district: district,
          state: state,
          pincode: pincode ?? 'Unknown',
          locality: locality ?? 'Unknown',
          country: country ?? 'Unknown',
        );
        debugPrint('✅ Loaded cached location: ${_cachedLocation!.district}');
        return _cachedLocation;
      }
    } catch (e) {
      debugPrint('❌ Error loading cached location: $e');
    }
    return null;
  }

  /// Save location to SharedPreferences (made public)
  Future<void> saveToPrefs(LocationData location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('location_district', location.district);
      await prefs.setString('location_state', location.state);
      await prefs.setString('location_pincode', location.pincode);
      await prefs.setString('location_locality', location.locality);
      await prefs.setString('location_country', location.country);
      await prefs.setDouble('location_lat', location.latitude);
      await prefs.setDouble('location_lng', location.longitude);
      debugPrint('💾 Location saved to preferences');
    } catch (e) {
      debugPrint('❌ Error saving location: $e');
    }
  }

  /// Clear cached location
  Future<void> clearLocation() async {
    _cachedLocation = null;
    _lastFetchTime = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('location_district');
      await prefs.remove('location_state');
      await prefs.remove('location_pincode');
      await prefs.remove('location_locality');
      await prefs.remove('location_country');
      await prefs.remove('location_lat');
      await prefs.remove('location_lng');
      debugPrint('🗑️ Location cleared');
    } catch (e) {
      debugPrint('❌ Error clearing location: $e');
    }
  }

  /// Check if location is stale (older than 5 minutes)
  bool isLocationStale() {
    if (_lastFetchTime == null) return true;
    return DateTime.now().difference(_lastFetchTime!) > const Duration(minutes: 5);
  }

  /// Update cached location (for manual edits)
  void updateCachedLocation(LocationData location) {
    _cachedLocation = location;
    _lastFetchTime = DateTime.now();
  }
}

class LocationData {
  final double latitude;
  final double longitude;
  final String district;
  final String state;
  final String pincode;
  final String locality;
  final String country;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.district,
    required this.state,
    required this.pincode,
    required this.locality,
    required this.country,
  });

  String get fullAddress => '$locality, $district, $state - $pincode';
}