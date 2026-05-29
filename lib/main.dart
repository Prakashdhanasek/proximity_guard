import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:developer';
import 'controllers/auth_controller.dart';
import 'controllers/vehicle_controller.dart';
import 'controllers/checklist_controller.dart';
import 'controllers/pre_trip_controller.dart';
import 'controllers/trip_controller.dart';
import 'controllers/settings_controller.dart';
import 'l10n/app_localizations.dart';
import 'views/theme/app_theme.dart';
import 'views/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const ProximityGuardDriveApp());
}

class ProximityGuardDriveApp extends StatelessWidget {
  const ProximityGuardDriveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => VehicleController()),
        ChangeNotifierProvider(create: (_) => ChecklistController()),
        ChangeNotifierProvider(create: (_) => PreTripController()),
        ChangeNotifierProvider(create: (_) => TripController()),
        ChangeNotifierProvider(create: (_) => SettingsController()),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) => MaterialApp(
          title: 'Proximity Guard Drive',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          locale: Locale(settings.locale),
          supportedLocales: SettingsController.supportedLocales.keys
              .map((code) => Locale(code))
              .toList(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
          double height = MediaQuery.of(context).size.height;
          double width = MediaQuery.of(context).size.width;

          // Set orientation based on device type
          final shortestSide = MediaQuery.of(context).size.shortestSide;
          if (shortestSide >= 600) {
            // Tablet: allow both portrait and landscape
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]);
          } else {
            // Mobile: portrait only
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]);
          }

          // Decide scaling based on device size
          double scale;

          if (height <= 640 && width <= 320) {
            scale = 0.7;
            log("very small phone");
          } else if (height <= 800 && width <= 480) {
            scale = 0.8;
            log("small phone");
          } else if ((height == 1136 && width == 640) ||
              (height == 1334 && width == 750)) {
            scale = 0.95;
            log("iPhone SE / iPhone 6/7/8");
          } else if ((height == 1792 && width == 828) ||
              (height == 2436 && width == 1125)) {
            scale = 1.0;
            log("iPhone XR / iPhone X / XS / 11 Pro");
          } else if ((height == 2532 && width == 1170) ||
              (height == 2778 && width == 1284) ||
              (height == 2796 && width == 1290)) {
            scale = 1.1;
            log("iPhone 12/13/14 Pro Max");
          } else if (height <= 1280 && width <= 720) {
            scale = 0.9;
            log("normal phone");
          } else if (height <= 1920 && width <= 1080) {
            scale = 1.0;
            log("large phone (phablet)");
          } else if (height <= 2048 && width <= 1536) {
            scale = 1.2;
            log("small tablet");
          } else if (height <= 2560 && width <= 2048) {
            scale = 1.5;
            log("large tablet");
          } else if (height <= 2960 && width <= 1440) {
            scale = 1.3;
            log("high-res large phone");
          } else if (height <= 2200 && width <= 1080) {
            scale = 1.1;
            log("foldable phone");
          } else if (height > 2560 || width > 1600) {
            scale = 1.6;
            log("ultra-large device");
          } else {
            scale = 1.0;
            log("default device scale");
          }

          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
            ),
            child: child!,
          );
        },
        home: const SplashScreen(),
        ),
      ),
    );
  }
}
