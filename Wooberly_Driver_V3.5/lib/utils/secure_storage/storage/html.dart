import 'dart:async';
import 'dart:convert';

import 'package:web/web.dart' as web;
import 'package:wooberly_driver/utils/secure_storage/storage_impl.dart';
import 'package:wooberly_driver/utils/secure_storage/value.dart';


class StorageImpl {
  StorageImpl(this.fileName, [this.path]);

  final String? path;
  final String fileName;

  StringCallback _encrypt = (input) async => input;
  StringCallback _decrypt = (input) async => input;

  ValueStorage<Map<String, dynamic>> subject =
      ValueStorage<Map<String, dynamic>>(<String, dynamic>{});

  web.Storage get _localStorage => web.window.localStorage;

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Clears all in-memory data and flushes to localStorage atomically.
  Future<void> clear() async {
    subject
      ..value?.clear()
      ..changeValue("", null);
    await flush();
  }

  static Future<bool> hasContainer(String container, [String? path]) async {
    return web.window.localStorage.getItem(container) != null;
  }

  static void deleteContainer(String container, [String? path]) {
    web.window.localStorage.removeItem(container);
    // Also remove legacy salt key if it exists from v1
    web.window.localStorage.removeItem('${container}_salt');
  }

  /// Encrypts current in-memory state and writes to localStorage.
  /// Times out after 5 seconds.
  Future<void> flush() async {
    await _doFlush().timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw TimeoutException(
        'StorageImpl flush timed out for "$fileName"',
      ),
    );
  }

  T? read<T>(String key) => subject.value![key] as T?;

  T getKeys<T>() => subject.value!.keys as T;

  T getValues<T>() => subject.value!.values as T;

  /// Initializes storage from localStorage or writes initial data if absent.
  Future<void> init(
    Map<String, dynamic>? initialData,
    StringCallback encrypt,
    StringCallback decrypt,
  ) async {
    _encrypt = encrypt;
    _decrypt = decrypt;
    subject.value = initialData ?? <String, dynamic>{};

    if (_exists()) {
      await _readFromStorage();
    } else {
      await _doFlush();
    }
  }

  void remove(String key) {
    subject
      ..value?.remove(key)
      ..changeValue(key, null);
  }

  void write(String key, dynamic value) {
    subject
      ..value![key] = value
      ..changeValue(key, value);
  }

  /// No-op on web (no file handles to close), kept for API parity with io.dart.
  Future<void> closeFile() async {}

  // ─── Private helpers ───────────────────────────────────────────────────────

  bool _exists() => _localStorage.getItem(fileName) != null;

  Future<void> _doFlush() async {
    final encrypted = await _encrypt(json.encode(subject.value));
    _localStorage.setItem(fileName, encrypted);
  }

  Future<void> _readFromStorage() async {
    final raw = _localStorage.getItem(fileName);
    if (raw == null) {
      await _doFlush();
      return;
    }

    try {
      final envelope = json.decode(raw) as Map<String, dynamic>? ?? {};
      final version = envelope['__v'] as int? ?? 1;

      final decrypted = await _decrypt(raw);
      final decoded = json.decode(decrypted) as Map<String, dynamic>;

      // ── Version migration ──────────────────────────────────────────────────
      if (version < GetSecureStorage.kStorageVersion) {
        subject.value = decoded;
        await _doFlush(); // re-flush as v2 format
        return;
      }

      subject.value = decoded;
    } catch (e) {
      // Corrupted data: reset
      subject.value = {};
      await _doFlush();
    }
  }
}

extension FirstWhereExt<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

// CHANGES:
// - Removed getSalt() and localStorage _salt key logic; salt embedded in payload
// - clear() now Future<void> and properly awaits flush
// - Added flush timeout (5 seconds)
// - Added StorageVersion migration v1 → v2
// - Identical payload format to io.dart: { __v, __salt, nonce, mac, cipherText }
// - deleteContainer / hasContainer made static consistent with io.dart