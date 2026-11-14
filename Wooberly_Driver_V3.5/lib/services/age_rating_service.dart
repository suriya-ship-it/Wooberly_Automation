import 'dart:io';
import 'package:age_range_signals/age_range_signals.dart';

import '../utils/globals.dart';

enum AgeRestrictionStatus { approved, declined, supervised, declared }

class AgeRatingController {
  static final AgeRatingController _instance =
  AgeRatingController._internal();

  factory AgeRatingController() => _instance;

  AgeRatingController._internal();

  Future<void> checkUserAge() async {
    if (Platform.isAndroid) {
      await AgeRangeSignals.instance.initialize(ageGates: [16, 18]);
      ageStatus = await ageRatingStatus();
    } else {
      ageStatus = AgeRestrictionStatus.approved;
    }
  }
  Future<AgeRestrictionStatus> ageRatingStatus() async {
    try {
      final result = await AgeRangeSignals.instance.checkAgeSignals();

      switch (result.status) {
        case AgeSignalsStatus.verified:
          return AgeRestrictionStatus.approved;

        case AgeSignalsStatus.supervised:
          return AgeRestrictionStatus.supervised;

        case AgeSignalsStatus.supervisedApprovalDenied:
          return AgeRestrictionStatus.declined;

        case AgeSignalsStatus.supervisedApprovalPending:
          return AgeRestrictionStatus.declined;

        case AgeSignalsStatus.declared:
          return AgeRestrictionStatus.declared;

        case AgeSignalsStatus.declined:
          return AgeRestrictionStatus.declined;

        case AgeSignalsStatus.unknown:
          return AgeRestrictionStatus.declined;
      }
    } catch (_) {
      return AgeRestrictionStatus.declined;
    }
  }
}