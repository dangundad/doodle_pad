// ================================================
// DangunDad Flutter App - main.dart Template
// ================================================

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';

import 'package:doodle_pad/app/admob/ads_helper.dart';
import 'package:doodle_pad/app/bindings/app_binding.dart';
import 'package:doodle_pad/app/routes/app_pages.dart';
import 'package:doodle_pad/app/services/hive_service.dart';
import 'package:doodle_pad/app/theme/app_theme.dart';
import 'package:doodle_pad/app/translate/translate.dart';
import 'package:doodle_pad/firebase_options.dart';

Future<bool> _initFirebaseSafely() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } catch (error) {
    debugPrint('Firebase initialization failed: $error');
    return false;
  }
}

Future<(bool, Object?, StackTrace?)> _initCoreServicesSafely() async {
  try {
    await AppBinding.initializeCoreServices();
    return (true, null, null);
  } catch (error, stackTrace) {
    return (false, error, stackTrace);
  }
}

void _configureCrashReporting({required bool firebaseReady}) {
  if (!firebaseReady) return;

  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
    return true;
  };
}

Future<void> _reportStartupError(
  Object error, {
  required bool firebaseReady,
  required StackTrace stackTrace,
  String? reason,
}) async {
  if (!firebaseReady) {
    debugPrint('${reason ?? 'Startup error'}: $error');
    return;
  }

  await FirebaseCrashlytics.instance.recordError(
    error,
    stackTrace,
    reason: reason,
    fatal: false,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Debug print disable in release mode
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  final firebaseFuture = _initFirebaseSafely();
  final coreServicesFuture = _initCoreServicesSafely();
  final orientationFuture = SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final systemUiFuture = SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top],
  );

  final firebaseReady = await firebaseFuture;
  _configureCrashReporting(firebaseReady: firebaseReady);

  final (coreServicesReady, coreError, coreStackTrace) =
      await coreServicesFuture;
  if (!coreServicesReady) {
    await _reportStartupError(
      coreError!,
      firebaseReady: firebaseReady,
      stackTrace: coreStackTrace!,
      reason: 'Core service initialization failed',
    );
  }

  await Future.wait([orientationFuture, systemUiFuture]);

  runApp(const DoodlePadApp());
}

class DoodlePadApp extends StatefulWidget {
  const DoodlePadApp({super.key});

  @override
  State<DoodlePadApp> createState() => _DoodlePadAppState();
}

class _DoodlePadAppState extends State<DoodlePadApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeAds());
    });
  }

  Future<void> _initializeAds() async {
    try {
      await AdHelper.initializeConsentAndAds();
    } catch (e) {
      debugPrint('AdMob initialization failed: $e');
    }
  }

  Widget _buildFallbackApp() {
    return ToastificationWrapper(
      child: GetMaterialApp(
        supportedLocales: Languages.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        translations: Languages(),
        locale: const Locale('en'),
        fallbackLocale: const Locale('en'),
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        if (!Get.isRegistered<HiveService>()) {
          return _buildFallbackApp();
        }

        return ToastificationWrapper(
          child: GetMaterialApp(
            supportedLocales: Languages.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            translations: Languages(),
            locale: Get.locale ?? Get.deviceLocale ?? const Locale('en'),
            fallbackLocale: const Locale('en'),
            debugShowCheckedModeBanner: false,
            defaultTransition: Transition.fadeIn,
            initialBinding: AppBinding(),
            themeMode: ThemeMode.system,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            scrollBehavior: ScrollBehavior().copyWith(overscroll: false),
            navigatorKey: Get.key,
            getPages: AppPages.routes,
            initialRoute: AppPages.INITIAL,
          ),
        );
      },
    );
  }
}
