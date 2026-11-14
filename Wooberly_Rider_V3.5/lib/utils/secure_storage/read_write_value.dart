import 'package:app_name/utils/secure_storage/storage_impl.dart';

typedef StorageFactory = GetSecureStorage Function();

/// A typed property wrapper that reads/writes a single key from a [GetSecureStorage]
/// container. Useful for declaring storage-backed fields cleanly:
///
/// ```dart
/// final username = ''.val('username');
/// username.val = 'Alice';
/// print(username.val); // 'Alice'
/// ```
class ReadWriteValue<T> {
  final String key;
  final T defaultValue;
  final StorageFactory? getBox;

  ReadWriteValue(this.key, this.defaultValue, [this.getBox]);

  GetSecureStorage _getRealBox() => getBox?.call() ?? GetSecureStorage();

  T get val => _getRealBox().read(key) ?? defaultValue;
  set val(T newVal) => _getRealBox().write(key, newVal);
}

extension Data<T> on T {
  ReadWriteValue<T> val(
    String valueKey, {
    StorageFactory? getBox,
    T? defVal,
  }) {
    return ReadWriteValue(valueKey, defVal ?? this, getBox);
  }
}