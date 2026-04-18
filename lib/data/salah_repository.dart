import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String? city;
  final String? country;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      city: json['city'] as String?,
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'country': country,
    };
  }
}

class SalahRepository {
  static const String _locKey = 'deen360_user_location';

  Future<void> saveUserLocation(LocationData locationData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_locKey, jsonEncode(locationData.toJson()));
    } catch (e) {
      print('Error saving location: $e');
    }
  }

  Future<LocationData?> getUserLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_locKey);
      if (data != null) {
        return LocationData.fromJson(jsonDecode(data));
      }
      return null;
    } catch (e) {
      print('Error reading location: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSalahTimingsByCoordinates(double lat, double lng) async {
    try {
      final d = DateTime.now();
      final dateStr = '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
      
      final url = Uri.parse('https://api.aladhan.com/v1/timings/$dateStr?latitude=$lat&longitude=$lng&method=2');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data']?['timings'];
      } else {
        print('Aladhan API status: ${response.statusCode}');
        return null;
      }
    } catch (err) {
      print("Salah By Coordinates error: $err");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSalahTimingsByCity(String city, {String country = ''}) async {
    try {
      final cityEncoded = Uri.encodeComponent(city);
      final countryEncoded = Uri.encodeComponent(country);
      final url = Uri.parse('https://api.aladhan.com/v1/timingsByCity?city=$cityEncoded&country=$countryEncoded&method=2');
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data']?['timings'];
      } else {
        print('Aladhan City API status: ${response.statusCode}');
        return null;
      }
    } catch (err) {
      print("Salah By City error: $err");
      return null;
    }
  }
}
