library contact_picker;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:app_name/models/edit_profile_model.dart';
import 'package:app_name/utils/globals.dart' as globals;
import 'package:app_name/views/multi_contact_picker_page.dart';


const MethodChannel _channel = MethodChannel('contact_picker');
const int _androidNativeMultiPickSdk = 37;

Future<List<EmergencyContacts>> pickContacts({int maxCount = 5}) async {
  final int safeMaxCount = maxCount.clamp(1, 100);

  if (Platform.isAndroid) {
    final int sdkVersion = await getAndroidSdkVersion();
    debugPrint("sdkVersion: ${sdkVersion}");
    if (sdkVersion >= _androidNativeMultiPickSdk) {
      return _pickNativeContacts(maxCount: safeMaxCount);
    }


    final List<EmergencyContacts>? selected = await Get.to<List<EmergencyContacts>>(
      () => MultiContactPickerPage(maxCount: safeMaxCount),
      transition: Transition.rightToLeft,
      fullscreenDialog: true,
    );
    return selected ?? <EmergencyContacts>[];
  }

  return _pickNativeContacts(maxCount: safeMaxCount);
}

Future<EmergencyContacts?> pickContact({int maxCount = 1}) async {
  final int safeMaxCount = maxCount.clamp(1, 100);

  if (Platform.isAndroid) {
    final int sdkVersion = await getAndroidSdkVersion();
    if (sdkVersion < _androidNativeMultiPickSdk) {
      return _pickSingleNativeContact();
    }
  }

  final List<EmergencyContacts> list =
      await _pickNativeContacts(maxCount: safeMaxCount);
  return list.isEmpty ? null : list.first;
}

Future<int> getAndroidSdkVersion() async {
  if (!Platform.isAndroid) {
    return -1;
  }

  final int? sdkVersion = await _channel.invokeMethod<int>('getSdkVersion');
  return sdkVersion ?? -1;
}

Future<EmergencyContacts?> pickSingleNativeContact() async {
  return _pickSingleNativeContact();
}

Future<EmergencyContacts?> _pickSingleNativeContact() async {
  final dynamic raw = await _channel.invokeMethod<dynamic>('pickSingleContact');

  return _mapSingleResult(raw);
}

Future<List<EmergencyContacts>> _pickNativeContacts({required int maxCount}) async {
  final dynamic raw = await _channel.invokeMethod<dynamic>(
    'pickContacts',
    <String, dynamic>{'maxCount': maxCount},
  );

  if (raw == null) {
    return <EmergencyContacts>[];
  }

  final List<dynamic> list = raw as List<dynamic>;
  final List<EmergencyContacts> results =
      list.map(_mapSingleResult).whereType<EmergencyContacts>().toList();

  return results.length > maxCount ? results.sublist(0, maxCount) : results;
}

EmergencyContacts? _mapSingleResult(dynamic raw) {
  if (raw == null) {
    return null;
  }

  final Map<Object?, Object?> map = raw as Map<Object?, Object?>;
  final String name = (map['name'] as String?)?.trim() ?? '';
  final String phone = (map['phone'] as String?)?.trim() ?? '';

  if (phone.isEmpty) {
    debugPrint('Skipping contact without phone number: $map');
    return null;
  }


  return EmergencyContacts(id: 0,userId: '0',contactName: name, phoneNumber: phone);
}