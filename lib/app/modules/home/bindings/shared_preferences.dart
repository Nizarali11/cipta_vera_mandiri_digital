

import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const _kCheckInAt = 'absen_checkInAt';
  static const _kCheckOutAt = 'absen_checkOutAt';

  static SharedPreferences? _prefs;

  /// Panggil sekali waktu app start (misal di main.dart)
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static DateTime? get checkInAt {
    final inMillis = _prefs?.getInt(_kCheckInAt);
    return inMillis != null ? DateTime.fromMillisecondsSinceEpoch(inMillis) : null;
  }

  static DateTime? get checkOutAt {
    final outMillis = _prefs?.getInt(_kCheckOutAt);
    return outMillis != null ? DateTime.fromMillisecondsSinceEpoch(outMillis) : null;
  }

  static Future<void> setCheckIn(DateTime? dt) async {
    if (dt != null) {
      await _prefs?.setInt(_kCheckInAt, dt.millisecondsSinceEpoch);
    } else {
      await _prefs?.remove(_kCheckInAt);
    }
  }

  static Future<void> setCheckOut(DateTime? dt) async {
    if (dt != null) {
      await _prefs?.setInt(_kCheckOutAt, dt.millisecondsSinceEpoch);
    } else {
      await _prefs?.remove(_kCheckOutAt);
    }
  }
}