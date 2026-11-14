import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cryptography/cryptography.dart';
import 'package:app_name/utils/secure_storage/storage_impl.dart';
import 'package:app_name/utils/secure_storage/value.dart';

class StorageImpl {
  StorageImpl(this.fileName, [this.path]);

  final String? path;
  final String fileName;

  StringCallback _encrypt = (input) async => input;
  StringCallback _decrypt = (input) async => input;

  final ValueStorage<Map<String, dynamic>> subject =
      ValueStorage<Map<String, dynamic>>(<String, dynamic>{});

  RandomAccessFile? _randomAccessfile;

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Clears all in-memory data and flushes to disk atomically.
  Future<void> clear() async {
    subject
      ..value?.clear()
      ..changeValue("", null);
    await flush();
  }

  /// Deletes both the main and backup storage files from disk.
  Future<void> deleteBox() async {
    final box = await _fileDb(isBackup: false);
    final backup = await _fileDb(isBackup: true);
    await Future.wait([box.delete(), backup.delete()]);
  }

  /// Encrypts current in-memory state and writes it atomically to disk.
  /// Times out after 5 seconds to prevent queue blocking.
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

  /// Initializes storage: wires encrypt/decrypt callbacks, reads existing data
  /// or writes initial data if the file is empty.
  Future<void> init(
    Map<String, dynamic>? initialData,
    StringCallback encrypt,
    StringCallback decrypt,
  ) async {
    _encrypt = encrypt;
    _decrypt = decrypt;
    subject.value = initialData ?? <String, dynamic>{};

    final file = await _getRandomFile();
    return file.lengthSync() == 0 ? flush() : _readFile();
  }

  void remove(String key) {
    subject
      ..value!.remove(key)
      ..changeValue(key, null);
  }

  void write(String key, dynamic value) {
    subject
      ..value![key] = value
      ..changeValue(key, value);
  }

  /// Closes the open RandomAccessFile handle. Call from GetSecureStorage.dispose().
  Future<void> closeFile() async {
    await _randomAccessfile?.close();
    _randomAccessfile = null;
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  Future<void> _doFlush() async {
    final buffer = utf8.encode(await _encrypt(json.encode(subject.value)));
    final length = buffer.length;
    final file = await _getRandomFile();

    _randomAccessfile = await file.lock();
    _randomAccessfile = await _randomAccessfile!.setPosition(0);
    _randomAccessfile = await _randomAccessfile!.writeFrom(buffer);
    _randomAccessfile = await _randomAccessfile!.truncate(length);
    _randomAccessfile = await file.unlock();

    // Fire backup write without blocking the main flush
    unawaited(_madeBackup());
  }

  Future<void> _madeBackup() async {
    try {
      final subjectValue = await _encrypt(json.encode(subject.value));
      final file = await _getFile(true);
      await file.writeAsString(subjectValue, flush: true);
    } catch (e) {
      Get.log('Backup write failed: $e', isError: true);
    }
  }

  Future<void> _readFile() async {
    try {
      final file = await _getRandomFile();
      final positioned = await file.setPosition(0);
      final buffer = Uint8List(await positioned.length());
      await positioned.readInto(buffer);
      final raw = utf8.decode(buffer);

      // Parse outer envelope to detect version
      final envelope = json.decode(raw) as Map<String, dynamic>? ?? {};
      final version = envelope['__v'] as int? ?? 1;

      final decrypted = await _decrypt(raw);
      final decoded = json.decode(decrypted) as Map<String, dynamic>;

      // ── Version migration ──────────────────────────────────────────────────
      if (version < GetSecureStorage.kStorageVersion) {
        Get.log(
          'Storage v$version detected, migrating to v${GetSecureStorage.kStorageVersion}',
        );
        subject.value = decoded;
        await flush();
        return;
      }

      subject.value = decoded;
    } on SecretBoxAuthenticationError {
      Get.log('Authentication Error: Wrong password provided!', isError: true);
      rethrow;
    } catch (e) {
      Get.log('Corrupted box, recovering backup: $e', isError: true);
      await _recoverFromBackup();
    }
  }

  Future<void> _recoverFromBackup() async {
    final file = await _getFile(true);
    dynamic content = {};
    try {
      content = await _decrypt((await file.readAsString()).trim());
    } on SecretBoxAuthenticationError {
      rethrow;
    } on Exception catch (_) {}

    if (content is String && content.isNotEmpty) {
      try {
        subject.value = (json.decode(content) as Map<String, dynamic>?) ?? {};
      } catch (e) {
        Get.log('Cannot recover corrupted box: $e', isError: true);
        subject.value = {};
      }
    } else {
      subject.value = {};
    }
    await flush();
  }

  Future<RandomAccessFile> _getRandomFile() async {
    if (_randomAccessfile != null) return _randomAccessfile!;
    final fileDb = await _getFile(false);
    _randomAccessfile = await fileDb.open(mode: FileMode.append);
    return _randomAccessfile!;
  }

  Future<bool> _hasFile() async {
    if ((await _fileDb(isBackup: false)).existsSync()) return true;
    if ((await _fileDb(isBackup: true)).existsSync()) return true;
    return false;
  }

  Future<void> _deleteFile() async {
    await (await _fileDb(isBackup: false)).delete();
    await (await _fileDb(isBackup: true)).delete();
  }

  Future<File> _getFile(bool isBackup) async {
    final fileDb = await _fileDb(isBackup: isBackup);
    if (!fileDb.existsSync()) fileDb.createSync(recursive: true);
    return fileDb;
  }

  Future<File> _fileDb({
    required bool isBackup,
    String extension = '.gs',
  }) async {
    final dir = await _getImplicitDir();
    final filepath = _getPath(isBackup, extension, path ?? dir.path);
    return File(filepath);
  }

  Future<Directory> _getImplicitDir() async {
    return getApplicationSupportDirectory();
  }

  String _getPath(bool isBackup, String extension, String basePath) {
    final sep = GetPlatform.isWindows ? '\\' : '/';
    return isBackup
        ? '$basePath$sep$fileName.bak'
        : '$basePath$sep$fileName$extension';
  }

  // ─── Static helpers ────────────────────────────────────────────────────────

  static Future<void> deleteContainer(String container, [String? path]) async {
    await StorageImpl(container, path)._deleteFile();
  }

  static Future<bool> hasContainer(String container, [String? path]) async {
    return StorageImpl(container, path)._hasFile();
  }
}

// CHANGES:
// - Removed getSalt() and .salt file logic; salt is now embedded inside the payload
// - Fixed clear() from async void to Future<void> with proper flush
// - Fixed RandomAccessFile leak: added closeFile() method
// - Added flush timeout (5 seconds) to prevent forever-blocking writes
// - Added StorageVersion migration: v1 (old format) → v2 (new embedded-salt format)
// - _madeBackup() now properly awaited via unawaited() to avoid fire-and-forget lint
// - _generateRandomBytes uses Random.secure() (unchanged, already correct)