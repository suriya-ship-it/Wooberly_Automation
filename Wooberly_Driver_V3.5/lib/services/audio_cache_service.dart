import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;

/// Audio caching service for preloading and storing voice messages.
/// Uses LRU cache pattern to manage storage efficiently.
class AudioCacheService {
  static final AudioCacheService _instance = AudioCacheService._internal();
  factory AudioCacheService() => _instance;
  AudioCacheService._internal();

  /// Maximum number of cached audio files
  static const int _maxCacheSize = 20;
  
  /// LRU cache tracking: key = audioName, value = local file path
  final LinkedHashMap<String, String> _cache = LinkedHashMap();
  
  /// Set of audio names currently being downloaded
  final Set<String> _downloading = {};
  
  /// Cache directory path (lazily initialized)
  String? _cacheDir;

  /// Initialize cache directory
  Future<String> _getCacheDir() async {
    if (_cacheDir != null) return _cacheDir!;
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/audio_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    _cacheDir = cacheDir.path;
    return _cacheDir!;
  }

  /// Check if audio is cached
  bool isCached(String audioName) {
    return _cache.containsKey(audioName);
  }

  /// Get cached file path synchronously (returns null if not cached)
  String? getCachedPathSync(String audioName) {
    if (_cache.containsKey(audioName)) {
      // Move to end of LRU cache (mark as recently used)
      final path = _cache.remove(audioName);
      if (path != null) {
        _cache[audioName] = path;
        return path;
      }
    }
    return null;
  }

  /// Get cached path, downloading if necessary
  Future<String?> getCachedAudioPath(String audioName) async {
    // Check if already cached
    final cachedPath = getCachedPathSync(audioName);
    if (cachedPath != null && await File(cachedPath).exists()) {
      return cachedPath;
    }
    
    // Not cached, download it
    return await _downloadAndCache(audioName);
  }

  /// Preload audio in background (doesn't block)
  void preloadAudio(String audioName) {
    if (audioName.isEmpty) return;
    if (isCached(audioName)) return;
    if (_downloading.contains(audioName)) return;
    
    // Run download in background
    compute(_preloadInIsolate, _PreloadParams(
      audioName: audioName,
      baseUrl: globals.voicePlayerUrl,
      cacheDir: _cacheDir,
    )).then((result) {
      if (result != null) {
        _addToCache(audioName, result);
      }
    }).catchError((e) {
    });
  }

  /// Download and cache audio file
  Future<String?> _downloadAndCache(String audioName) async {
    if (_downloading.contains(audioName)) {
      // Wait for ongoing download
      while (_downloading.contains(audioName)) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return getCachedPathSync(audioName);
    }
    
    _downloading.add(audioName);
    
    try {
      final url = '${globals.voicePlayerUrl}$audioName';
      final cacheDir = await _getCacheDir();
      final filePath = '$cacheDir/$audioName';
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        _addToCache(audioName, filePath);
        return filePath;
      }
    } catch (e) {
    } finally {
      _downloading.remove(audioName);
    }
    
    return null;
  }

  void _addToCache(String audioName, String filePath) {
    // Evict oldest if at capacity
    while (_cache.length >= _maxCacheSize) {
      final oldestKey = _cache.keys.first;
      final oldestPath = _cache.remove(oldestKey);
      if (oldestPath != null) {
        File(oldestPath).delete().catchError((_) {});
      }
    }
    
    _cache[audioName] = filePath;
  }

  /// Preload multiple audio files (for visible messages)
  void preloadMultiple(List<String> audioNames) {
    for (final name in audioNames) {
      if (name.isNotEmpty) {
        preloadAudio(name);
      }
    }
  }

  /// Clear all cached files
  Future<void> clearCache() async {
    for (final path in _cache.values) {
      try {
        await File(path).delete();
      } catch (_) {}
    }
    _cache.clear();
  }
}

/// Parameters for isolate preload
class _PreloadParams {
  final String audioName;
  final String baseUrl;
  final String? cacheDir;
  
  _PreloadParams({
    required this.audioName,
    required this.baseUrl,
    this.cacheDir,
  });
}

/// Preload function to run in isolate
Future<String?> _preloadInIsolate(_PreloadParams params) async {
  try {
    final url = '${params.baseUrl}${params.audioName}';
    
    // Get cache directory
    String cacheDir;
    if (params.cacheDir != null) {
      cacheDir = params.cacheDir!;
    } else {
      final tempDir = await getTemporaryDirectory();
      cacheDir = '${tempDir.path}/audio_cache';
      final dir = Directory(cacheDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
    
    final filePath = '$cacheDir/${params.audioName}';
    
    // Check if already exists
    if (await File(filePath).exists()) {
      return filePath;
    }
    
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    }
  } catch (e) {
  }
  
  return null;
}