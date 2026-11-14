import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/utils/google_map.dart';
import 'package:app_name/utils/secure_storage/storage_impl.dart';


import 'dart:io';
import 'package:flutter/services.dart';

class AppPreferences {
  final _storage = GetSecureStorage(password: globals.SecurityKey);

  static const String PREF_API_ICONS = "API_ICONS";
  static const MethodChannel _credentialsChannel = MethodChannel("credentials_restore");

  String get preferredLaunguage => _storage.read("preferredLaunguage") ?? globals.preferredLanguage ;
  set preferredLaunguage(String preferredLaunguage) {
    _storage.write("preferredLaunguage", preferredLaunguage);
  }

  String get authToken => _storage.read("authToken") ?? '';
  set authToken(String authToken) {
    _storage.write("authToken", authToken);
    if (Platform.isAndroid && authToken.isNotEmpty) {
      _credentialsChannel.invokeMethod("setRestoreCredential", {"token": authToken}).catchError((_) {});
    }
  }

  Future<String?> checkRestoredCredential() async {
    if (Platform.isAndroid) {
      try {
        final String? restoredToken = await _credentialsChannel.invokeMethod<String>("getRestoreCredential");
        return restoredToken;
      } catch (e) {
        debugPrint("Restore credential error: $e");
      }
    }
    return null;
  }

  String get downloadedLanguages => _storage.read("downloadedLanguages");
  set downloadedLanguages(String downloadedLanguages) {
    _storage.write("downloadedLanguages", downloadedLanguages);
  }


  Future<void> saveUint8ListMap({required Map<String, Uint8List> dataMap}) async {
    Map<String, String> base64Map = dataMap.map((url, uint8list) {
      return MapEntry(url, base64Encode(uint8list));
    });
    String jsonString = jsonEncode(base64Map);
    await _storage.write( AppPreferences.PREF_API_ICONS, jsonString);
  }

  Future<Map<String, Uint8List>> getUint8ListMap() async {
    String? jsonString = await _storage.read( AppPreferences.PREF_API_ICONS);
    if (jsonString != null) {
      try {
        Map<String, dynamic> base64Map = jsonDecode(jsonString);
        Map<String, Uint8List> dataMap = base64Map.map((url, base64String) {
          return MapEntry(url, base64Decode(base64String as String));
        });
        return dataMap;
      } catch (e) {
        print('AppPreferences: Error decoding icon map: $e');
      }
    }
    return {};
  }

  /// Generates a cache key based on a list of locations
  String getRouteCacheKey(List<LatLng> locations) {
    if (locations.isEmpty) return "";
    String coordsStr = locations
        .map((loc) => "${loc.latitude.toStringAsFixed(4)},${loc.longitude.toStringAsFixed(4)}")
        .join("_");
    return "route_cache_$coordsStr";
  }

  /// Save route polyline points (all legs) to preference
  Future<void> saveCachedRoute(List<LatLng> locations, dynamic routeData) async {
    if (locations.isEmpty || routeData == null) return;
    try {
      String key = getRouteCacheKey(locations);
      Map<String, dynamic> payload = {};

      if (locations.isNotEmpty) {
        payload["destination"] = {
          "lat": locations.last.latitude,
          "lng": locations.last.longitude,
        };
        payload["origin"] = {
          "lat": locations.first.latitude,
          "lng": locations.first.longitude,
        };
      }

      Map<String, List<Map<String, double>>> jsonMap = {};

      if (routeData is Map<int, List<LatLng>>) {
        routeData.forEach((legIndex, points) {
          jsonMap[legIndex.toString()] = points
              .map((p) => {"lat": p.latitude, "lng": p.longitude})
              .toList();
        });
      } else if (routeData is List<LatLng>) {
        jsonMap["0"] = routeData
            .map((p) => {"lat": p.latitude, "lng": p.longitude})
            .toList();
      }

      if (jsonMap.isNotEmpty) {
        payload["routes"] = jsonMap;
        String encoded = jsonEncode(payload);
        await _storage.write(key, encoded);
        await _storage.write("last_cached_route", encoded);
        print("AppPreferences: Successfully cached route for key: $key (${jsonMap.length} legs)");
      }
    } catch (e) {
      print("AppPreferences: Error saving route to preference: $e");
    }
  }

  /// Get cached route destination from preference if available
  LatLng? getCachedRouteDestination(List<LatLng> locations) {
    try {
      String key = locations.isNotEmpty ? getRouteCacheKey(locations) : "";
      dynamic data;
      if (key.isNotEmpty) {
        data = _storage.read(key);
      }
      if (data == null) {
        data = _storage.read("last_cached_route");
      }
      if (data != null) {
        dynamic decoded = data is String ? jsonDecode(data) : data;
        if (decoded is Map && decoded.containsKey("destination")) {
          var dest = decoded["destination"];
          return LatLng(
            (dest["lat"] as num).toDouble(),
            (dest["lng"] as num).toDouble(),
          );
        }
      }
    } catch (e) {
      print("AppPreferences: Error reading cached destination from preference: $e");
    }
    return null;
  }

  /// Get cached route polyline points (all legs) from preference if exists
  Map<int, List<LatLng>>? getCachedRoute(List<LatLng> locations) {
    try {
      String key = locations.isNotEmpty ? getRouteCacheKey(locations) : "";
      debugPrint("getCachedRoutekey: ${key}");
      dynamic data;
      if (key.isNotEmpty) {
        data = _storage.read(key);
      }
      if (data == null) {
        data = _storage.read("last_cached_route");
      }
      if (data != null) {
        dynamic decoded = data is String ? jsonDecode(data) : data;
        Map<int, List<LatLng>> polylinePoints = {};

        dynamic routesMap = decoded;
        if (decoded is Map && decoded.containsKey("routes")) {
          routesMap = decoded["routes"];
        }

        if (routesMap is Map) {
          routesMap.forEach((legStr, jsonList) {
            int legIndex = int.tryParse(legStr.toString()) ?? 0;
            if (jsonList is List) {
              List<LatLng> points = jsonList.map((item) {
                return LatLng(
                  (item["lat"] as num).toDouble(),
                  (item["lng"] as num).toDouble(),
                );
              }).toList();
              polylinePoints[legIndex] = points;
            }
          });
        } else if (routesMap is List) {
          List<LatLng> points = routesMap.map((item) {
            return LatLng(
              (item["lat"] as num).toDouble(),
              (item["lng"] as num).toDouble(),
            );
          }).toList();
          polylinePoints[0] = points;
        }

        if (polylinePoints.isNotEmpty) {
          print("AppPreferences: Retrieved route from preference for key: $key (${polylinePoints.length} legs)");
          return polylinePoints;
        }
      }
    } catch (e) {
      print("AppPreferences: Error reading cached route from preference: $e");
    }
    return null;
  }

  /// Generates a cache key for search places based on the search query value
  String getSearchPlacesCacheKey(String value) {
    return "search_places_${value.trim().toLowerCase()}";
  }

  /// Save search places response JSON to preference
  Future<void> saveCachedSearchPlaces(String value, dynamic jsonResponse) async {
    if (value.isEmpty) return;
    try {
      String key = getSearchPlacesCacheKey(value);
      String jsonString = jsonResponse is String ? jsonResponse : jsonEncode(jsonResponse);
      await _storage.write(key, jsonString);
      print("AppPreferences: Successfully cached search places for key: $key");
    } catch (e) {
      print("AppPreferences: Error saving search places to preference: $e");
    }
  }

  /// Get cached search places response JSON from preference if exists
  dynamic getCachedSearchPlaces(String value) {
    if (value.isEmpty) return null;
    try {
      String key = getSearchPlacesCacheKey(value);
      dynamic data = _storage.read(key);
      if (data != null) {
        dynamic decoded = data is String ? jsonDecode(data) : data;
        print("AppPreferences: Retrieved search places from preference for key: $key");
        return decoded;
      }
    } catch (e) {
      print("AppPreferences: Error reading search places from preference: $e");
    }
    return null;
  }

  Future<void> clearPreference() async {
    if (Platform.isAndroid) {
      _credentialsChannel.invokeMethod("clearRestoreCredential").catchError((_) {});
    }
    await clearPreferencesExcept(PREF_API_ICONS);
  }

  Future<void> clearPreferencesExcept(String keyToKeep) async {
    String? temp = await _storage.read( keyToKeep);
    await _storage.erase();

    if (temp != null) {
      await _storage.write( keyToKeep,  temp);
    }
  }
}