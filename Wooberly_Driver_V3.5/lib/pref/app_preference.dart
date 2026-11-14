import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:wooberly_driver/utils/google_map.dart';
import 'package:wooberly_driver/utils/secure_storage/storage_impl.dart';

import '../utils/globals.dart' as globals;


class AppPreference {
  final pref = GetSecureStorage(password: globals.SECURE_API_KEY);

  clearPreference() async {
    String downloadedLang = pref.read("downloadedLanguages") ?? "";
    await pref.erase();
    await pref.write("downloadedLanguages", downloadedLang);
  }

  /// Clears only cached route polyline data (last_cached_route + any route_cache_* keys).
  Future<void> clearCachedRoutes() async {
    try {
      pref.writeInMemory("last_cached_route", null);
      final Iterable<String> allKeys = pref.getKeys<Iterable<String>>();
      for (final key in allKeys.toList()) {
        if (key.startsWith("route_cache_")) {
          pref.writeInMemory(key, null);
        }
      }
      await pref.save();
      debugPrint("AppPreferences: Cleared all cached routes");
    } catch (e) {
      debugPrint("AppPreferences: Error clearing cached routes: $e");
    }
  }


  bool get isFirstTimeLocationPermission => pref.read("isFirstTimeLocationPermission") ?? false;
  set isFirstTimeLocationPermission(bool? isFirstTimeLocationPermission) {
    pref.write("isFirstTimeLocationPermission", isFirstTimeLocationPermission);
  }

  String get LoginNo => pref.read("LoginNo") ?? "";
  set LoginNo(String? LoginNo) {
    pref.write("LoginNo", LoginNo);
  }

  String get downloadedLanguages => pref.read("downloadedLanguages") ?? "";
  set downloadedLanguages(String? downloadedLanguages) {
    pref.write("downloadedLanguages", downloadedLanguages);
  }

  String get downloadedLangWithTime => pref.read("downloadedLangWithTime") ?? "";
  set downloadedLangWithTime(String? downloadedLangWithTime) {
    pref.write("downloadedLangWithTime", downloadedLangWithTime);
  }

  String get CountryCode => pref.read("CountryCode") ?? "";
  set CountryCode(String? CountryCode) {
    pref.write("CountryCode", CountryCode);
  }

  String get authToken => pref.read("authToken") ?? "";
  set authToken(String? authToken) {
    pref.write("authToken", authToken);
  }

  String get userId => pref.read("userId") ?? "";
  set userId(String? userId) {
    pref.write("userId", userId);
  }

  String get preferredLanguage => pref.read("preferredLanguage") ?? globals.preferredLanguage.value;
  set preferredLanguage(String? preferredLanguage) {
    pref.write("preferredLanguage", preferredLanguage);
  }

  bool get preferredTheme => pref.read("preferredTheme") ?? false;
  set preferredTheme(bool? preferredTheme) {
    pref.write("preferredTheme", preferredTheme);
  }

  String get isDoc => pref.read("isDoc") ?? "";
  set isDoc(String? isDoc) {
    pref.write("isDoc", isDoc);
  }

  String get backPath => pref.read("backPath") ?? "";
  set backPath(String? backPath) {
    pref.write("backPath", backPath);
  }

  String get rcPath => pref.read("rcPath") ?? "";
  set rcPath(String? rcPath) {
    pref.write("rcPath", rcPath);
  }

  String get insuPath => pref.read("insuPath") ?? "";
  set insuPath(String? insuPath) {
    pref.write("insuPath", insuPath);
  }


  String get LicenceFront => pref.read("LicenceFront") ?? "";
  set LicenceFront(String? LicenceFront) {
    pref.write("LicenceFront", LicenceFront);
  }

  String get LicenceBack => pref.read("LicenceBack") ?? "";
  set LicenceBack(String? LicenceBack) {
    pref.write("LicenceBack", LicenceBack);
  }

  String get vehicleRC => pref.read("vehicleRC") ?? "";
  set vehicleRC(String? vehicleRC) {
    pref.write("vehicleRC", vehicleRC);
  }

  String get vehicleInsurance => pref.read("vehicleInsurance") ?? "";
  set vehicleInsurance(String? vehicleInsurance) {
    pref.write("vehicleInsurance", vehicleInsurance);
  }


  bool get onlineStatus => pref.read("onlineStatus") ?? false;
  set onlineStatus(bool? onlineStatus) {
    pref.write("onlineStatus", onlineStatus);
  }

  bool get privateMode => pref.read("privateMode") ?? false;
  set privateMode(bool? privateMode) {
    pref.write("privateMode", privateMode);
  }


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
        await pref.write(key, encoded);
        await pref.write("last_cached_route", encoded);
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
        data = pref.read(key);
      }
      if (data == null) {
        data = pref.read("last_cached_route");
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
        data = pref.read(key);
      }
      if (data == null) {
        data = pref.read("last_cached_route");
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
}