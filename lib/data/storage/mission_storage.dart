import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MissionStorage {
  static const _key = 'parallax.mission_state.v1';

  final SharedPreferences _preferences;

  const MissionStorage(this._preferences);

  static Future<MissionStorage> create() async {
    final preferences = await SharedPreferences.getInstance();
    return MissionStorage(preferences);
  }

  Map<String, dynamic>? load() {
    final raw = _preferences.getString(_key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(Map<String, dynamic> value) async {
    await _preferences.setString(_key, jsonEncode(value));
  }
}
