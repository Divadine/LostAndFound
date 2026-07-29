import 'dart:convert';
import 'package:http/http.dart' as http;

class PlaceSuggestion {
  final String placeId;
  final String description;

  PlaceSuggestion({required this.placeId, required this.description});

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) =>
      PlaceSuggestion(
        placeId: json['place_id'] as String,
        description: json['description'] as String,
      );
}

class NearbyPlace {
  final String placeId;
  final String name;
  final String vicinity;
  final double latitude;
  final double longitude;
  final String icon;

  NearbyPlace({
    required this.placeId,
    required this.name,
    required this.vicinity,
    required this.latitude,
    required this.longitude,
    required this.icon,
  });

  factory NearbyPlace.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    return NearbyPlace(
      placeId: json['place_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      vicinity: (json['vicinity'] ?? json['formatted_address'] ?? '') as String,
      latitude: (location?['lat'] as num?)?.toDouble() ?? 0,
      longitude: (location?['lng'] as num?)?.toDouble() ?? 0,
      icon: json['icon'] as String? ?? '',
    );
  }
}

class PlaceDetails {
  final double lat;
  final double lng;
  final String formattedAddress;

  PlaceDetails({
    required this.lat,
    required this.lng,
    required this.formattedAddress,
  });
}

class PlacesService {
  static const String _apiKey = 'AIzaSyC5S9f4bqHOjf0DP3yeL1C32t0S609fUQM';

  static Future<List<PlaceSuggestion>> autocomplete(
    String input, {
    double? biasLat,
    double? biasLng,
  }) async {
    if (input.trim().isEmpty) return [];

    final params = <String, String>{
      'input': input,
      'key': _apiKey,
      if (biasLat != null && biasLng != null) 'location': '$biasLat,$biasLng',
      if (biasLat != null && biasLng != null) 'radius': '50000',
    };

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      params,
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final predictions = (data['predictions'] as List<dynamic>? ?? []);
      return predictions
          .map((e) => PlaceSuggestion.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'place_id': placeId,
        'fields': 'geometry,formatted_address',
        'key': _apiKey,
      },
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final result = data['result'] as Map<String, dynamic>?;
      if (result == null) return null;
      final geometry = result['geometry']['location'];
      return PlaceDetails(
        lat: (geometry['lat'] as num).toDouble(),
        lng: (geometry['lng'] as num).toDouble(),
        formattedAddress: result['formatted_address'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  /// Reverse geocode a lat/lng — used when the user taps/drags the pin
  /// directly on the map instead of picking from search suggestions.
  static Future<String?> reverseGeocode(double lat, double lng) async {
    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'latlng': '$lat,$lng',
      'key': _apiKey,
    });

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];
      if (results.isEmpty) return null;
      return results.first['formatted_address'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<List<NearbyPlace>> nearbySearch({
    required double lat,
    required double lng,
    String type = 'police',
    int radius = 5000,
  }) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/nearbysearch/json',
      {
        'location': '$lat,$lng',
        'radius': '$radius',
        'type': type,
        'key': _apiKey,
      },
    );
    print("URL: $uri");
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];
      print("RESPONSE: $results");

      return results
          .map((e) => NearbyPlace.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
