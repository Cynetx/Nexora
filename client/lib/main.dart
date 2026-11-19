import 'dart:io';

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'splash.dart';
import 'store.dart';
import 'vpn_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();

  // هنگام بستن اپ (Ctrl+C, SIGTERM, یا بستن پنجره) همه پروسه‌های Xray کشته شوند
  _registerShutdown();

  runApp(const App());
}

void _registerShutdown() {
  if (Platform.isAndroid || Platform.isIOS) return;
  void cleanup() {
    try {
      VpnService.I.shutdown();
    } catch (_) {}
  }

  try {
    ProcessSignal.sigterm.watch().listen((_) {
      cleanup();
      exit(0);
    });
  } catch (_) {}
  try {
    ProcessSignal.sigint.watch().listen((_) {
      cleanup();
      exit(0);
    });
  } catch (_) {}
}

ThemeData _theme(Brightness b) {
  final p = b == Brightness.dark ? P.dark : P.light;
  return ThemeData(
    brightness: b,
    useMaterial3: true,
    fontFamily: 'Vazirmatn',
    scaffoldBackgroundColor: p.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: p.accent, brightness: b),
    // سبک‌تر برای گوشی‌های ضعیف: موج لمسی ساده (به‌جای InkSparkle که شیدر دارد) و انتقال صفحه‌ی سبک
    splashFactory: InkRipple.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
    }),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: Store.themeMode,
      builder: (context, mode, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Nexora VPN',
        themeMode: mode,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        themeAnimationDuration: Duration.zero,
        locale: const Locale('fa'),
        supportedLocales: const [Locale('fa'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SplashGate(),
      ),
    );
  }
}
