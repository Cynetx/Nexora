import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'defaults.dart';

// افکت‌های سنگین (آرورا، بلور شیشه‌ای، هاور و درخشش‌ها) روی همه‌ی پلتفرم‌ها پیش‌فرض خاموش است؛
// ویندوز، مک و لینوکس دقیقاً مثل اندروید در «حالت سبک» اجرا می‌شوند (کرش و کندی نداشته باشند).
final bool kFancy = false;

class P {
  final Color bg, card, border, text, sub, accent, accent2;
  const P(this.bg, this.card, this.border, this.text, this.sub, this.accent, this.accent2);

  static const dark = P(
    Color(0xFF040A1C),
    Color(0xFF0A1530),
    Color(0xFF1C4C99),
    Colors.white,
    Color(0xFF8FA6CC),
    Color(0xFF2F8CFF),
    Color(0xFF33B5FF),
  );

  static const light = P(
    Color(0xFFF2F6FF),
    Colors.white,
    Color(0xFFC9D9F2),
    Color(0xFF0F1B33),
    Color(0xFF5B6B85),
    Color(0xFF1F6FE0),
    Color(0xFF0098D8),
  );

  static P of(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? dark : light;
}

class Store {
  static late SharedPreferences _p;
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.dark);
  static final ValueNotifier<Map<String, dynamic>?> config = ValueNotifier(null);
  static final ValueNotifier<bool> fetched = ValueNotifier(false);
  // «بهینه‌سازی برنامه» پیش‌فرض روشن است (اندروید، ویندوز، مک و لینوکس)
  static final ValueNotifier<bool> lite = ValueNotifier(true);
  static final ValueNotifier<List<Map<String, dynamic>>> configs = ValueNotifier([]);

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    // کلید جدید lite3: مقدار قدیمی (lite2) نادیده گرفته می‌شود تا همه‌ی دستگاه‌ها یک‌بار با «روشن» شروع کنند
    lite.value = _p.getBool('lite3') ?? true;
    final t = _p.getString('theme') ?? 'dark';
    themeMode.value = t == 'light'
        ? ThemeMode.light
        : t == 'system'
            ? ThemeMode.system
            : ThemeMode.dark;
    final rawList = _p.getString('configs');
    if (rawList != null) {
      try {
        configs.value = (jsonDecode(rawList) as List).map((e) => (e as Map).cast<String, dynamic>()).toList();
      } catch (_) {}
    }
    if (rawList == null && configs.value.isEmpty) configs.value = _defaults();
    final raw = _p.getString('config');
    if (raw != null) {
      try {
        config.value = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    applySelection();
    fetched.value = config.value != null;
    if (_p.getString('deviceId') == null) {
      final r = Random.secure();
      final id = List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      await _p.setString('deviceId', id);
    }
  }

  static List<Map<String, dynamic>> _defaults() => kDefaultConfigs.map((e) => Map<String, dynamic>.from(e)).toList();

  static String get deviceId => _p.getString('deviceId')!;

  static Map<String, dynamic> get geoCache {
    try {
      return (jsonDecode(_p.getString('geoCache') ?? '{}') as Map).cast<String, dynamic>();
    } catch (_) {
      return {};
    }
  }

  static Future<void> setGeoCache(Map<String, dynamic> m) => _p.setString('geoCache', jsonEncode(m));

  static String get sbKey => (_p.getString('sbKey') ?? '').trim();
  static Future<void> setSbKey(String v) => _p.setString('sbKey', v.trim());
  static String get sbUrl => (_p.getString('sbUrl') ?? '').trim();
  static Future<void> setSbUrl(String v) => _p.setString('sbUrl', v.trim());

  static Map<String, dynamic>? _byId(String id) {
    for (final c in configs.value) {
      if ('${c['id']}' == id) return c;
    }
    return null;
  }

  static String locKey(Map<String, dynamic> c) {
    final code = '${c['code'] ?? ''}'.toUpperCase();
    if (code.length == 2) return code;
    final n = '${c['country'] ?? ''}';
    return n.isEmpty ? '' : n;
  }

  static List<Map<String, dynamic>> inLocation(String key) =>
      configs.value.where((c) => locKey(c) == key).toList();

  static List<Map<String, dynamic>> locations() {
    final m = <String, Map<String, dynamic>>{};
    for (final c in configs.value) {
      final k = locKey(c);
      if (k.isEmpty) continue;
      final e = m.putIfAbsent(k, () => {'key': k, 'country': '${c['country'] ?? k}', 'code': '${c['code'] ?? ''}', 'count': 0});
      e['count'] = (e['count'] as int) + 1;
    }
    return m.values.toList();
  }

  static void applySelection() {
    final sid = serverId;
    Map<String, dynamic>? sel;
    if (sid.startsWith('loc:')) {
      final l = inLocation(sid.substring(4));
      if (l.isNotEmpty) sel = l.first;
    } else if (sid.isNotEmpty) {
      sel = _byId(sid);
    }
    if (sel == null) {
      final cur = config.value;
      if (cur != null && _byId('${cur['id']}') != null) {
        sel = _byId('${cur['id']}');
      } else if (configs.value.isNotEmpty) {
        sel = configs.value.first;
      }
    }
    config.value = sel;
    fetched.value = sel != null;
  }

  static List<Map<String, dynamic>> candidates() {
    final sid = serverId;
    if (sid.startsWith('loc:')) {
      final l = inLocation(sid.substring(4));
      if (l.isNotEmpty) return l;
    } else if (sid.isNotEmpty) {
      final c = _byId(sid);
      if (c != null) return [c];
    }
    final all = List<Map<String, dynamic>>.from(configs.value);
    final cur = config.value;
    if (cur != null) {
      final i = all.indexWhere((e) => '${e['id']}' == '${cur['id']}');
      if (i > 0) {
        final x = all.removeAt(i);
        all.insert(0, x);
      }
    }
    return all;
  }

  static Future<void> setConfigs(List<Map<String, dynamic>> list) async {
    configs.value = list;
    await _p.setString('configs', jsonEncode(list));
    applySelection();
  }

  static Future<void> setLite(bool v) async {
    lite.value = v;
    await _p.setBool('lite3', v);
  }

  static String getStr(String k) => _p.getString(k) ?? '';
  static Future<void> setStr(String k, String v) => _p.setString(k, v);

  static bool getBool(String k, bool d) => _p.getBool(k) ?? d;
  static Future<void> setBool(String k, bool v) => _p.setBool(k, v);

  static String get serverId => _p.getString('serverId') ?? '';
  static Future<void> setServerId(String v) => _p.setString('serverId', v);

  static Future<void> setTheme(ThemeMode m) async {
    themeMode.value = m;
    await _p.setString('theme', m == ThemeMode.light ? 'light' : m == ThemeMode.system ? 'system' : 'dark');
  }

  static Future<void> setConfig(Map<String, dynamic>? c) async {
    config.value = c;
    if (c == null) {
      await _p.remove('config');
    } else {
      await _p.setString('config', jsonEncode(c));
    }
  }

  static Future<void> clearCache() async {
    await _p.remove('config');
    await _p.remove('configs');
    configs.value = _defaults();
    config.value = null;
    applySelection();
  }

  static bool get stealth => _p.getBool('stealth_fragment') ?? true;
  static Future<void> setStealth(bool v) => _p.setBool('stealth_fragment', v);

  static String get upstreamProxy => (_p.getString('upstream_proxy') ?? '').trim();
  static Future<void> setUpstreamProxy(String v) => _p.setString('upstream_proxy', v.trim());

  static bool get upstreamProxyEnabled => _p.getBool('upstream_proxy_on') ?? false;
  static Future<void> setUpstreamProxyEnabled(bool v) => _p.setBool('upstream_proxy_on', v);

  static Future<void> resetSettings() async {
    for (final k in ['autoConnect', 'notif', 'battery', 'system', 'advNotif', 'serverId', 'theme', 'lite2', 'lite3', 'stealth_fragment', 'upstream_proxy', 'upstream_proxy_on']) {
      await _p.remove(k);
    }
    themeMode.value = ThemeMode.dark;
    lite.value = true;
    applySelection();
  }
}

String fmtBytes(num b) {
  if (b < 1024) return '${b.toInt()} B';
  if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
  if (b < 1024 * 1024 * 1024) return '${(b / 1024 / 1024).toStringAsFixed(1)} MB';
  return '${(b / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
}

String fmtDuration(int s) {
  final h = (s ~/ 3600).toString().padLeft(2, '0');
  final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
  final x = (s % 60).toString().padLeft(2, '0');
  return '$h:$m:$x';
}
