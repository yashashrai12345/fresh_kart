import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

class LocationService {
  /// Requests device GPS permission and fetches current street/locality address
  static Future<String?> getCurrentAddress() async {
    try {
      final location = Location();

      // Check if location service is enabled
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          throw Exception('Location services are disabled on your device.');
        }
      }

      // Check/request permission
      PermissionStatus permission = await location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await location.requestPermission();
        if (permission == PermissionStatus.denied) {
          throw Exception('Location permissions were denied.');
        }
      }

      if (permission == PermissionStatus.deniedForever) {
        throw Exception(
            'Location permissions are permanently denied. Please enable them in app settings.');
      }

      // Get current position
      final locationData = await location.getLocation();
      final lat = locationData.latitude;
      final lon = locationData.longitude;

      if (lat == null || lon == null) {
        throw Exception('Could not determine current position.');
      }

      // Reverse geocode via OpenStreetMap Nominatim
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1',
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'FreshKartProduceDelivery/1.0 (contact@freshkart.in)',
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('display_name')) {
          return data['display_name'] as String;
        }
      }

      // Fallback to coordinates if reverse geocode is slow
      return 'Location: ${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
    } catch (e) {
      debugPrint('LocationService Error: $e');
      rethrow;
    }
  }
}
