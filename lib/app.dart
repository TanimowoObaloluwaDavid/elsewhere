import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/palette.dart';
import 'core/text_styles.dart';
import 'data/places.dart';
import 'screens/root_shell.dart';

class ElsewhereApp extends StatelessWidget {
  const ElsewhereApp({super.key});

  @override
  Widget build(BuildContext context) {
    final initialTab = kIsWeb
        ? tabIndexFromName(Uri.base.queryParameters['screen'])
        : 0;

    return MaterialApp(
      title: 'Elsewhere',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      scrollBehavior: const AppScrollBehavior(),
      home: RootShell(initialIndex: initialTab),
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

ThemeData buildTheme() {
  const scheme = ColorScheme.light(
    primary: Palette.clay,
    onPrimary: Palette.cream,
    secondary: Palette.olive,
    onSecondary: Palette.cream,
    surface: Palette.paper,
    onSurface: Palette.ink,
    error: Color(0xFF9E3B2C),
    onError: Palette.cream,
    outline: Palette.line,
    outlineVariant: Palette.lineSoft,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.paper,
    fontFamily: 'Figtree',
    splashFactory: InkRipple.splashFactory,
    visualDensity: VisualDensity.standard,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: Palette.ink,
      displayColor: Palette.ink,
      fontFamily: 'Figtree',
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: Palette.ink),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Palette.ink,
      contentTextStyle: AppText.body(13, color: Palette.cream),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: Palette.line,
      thickness: 1,
      space: 1,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: Palette.clay,
      selectionColor: Palette.clay.withValues(alpha: 0.18),
      selectionHandleColor: Palette.clay,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: WidgetStateProperty.all(3),
      radius: const Radius.circular(3),
      thumbColor: WidgetStateProperty.all(Palette.ink.withValues(alpha: 0.25)),
    ),
  );
}
