import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vital_step/ReceivedNotification.dart';
import 'package:vital_step/app/app.bottomsheets.dart';
import 'package:vital_step/app/app.dialogs.dart';
import 'package:vital_step/app/app.locator.dart';
import 'package:vital_step/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:vital_step/services/device_selection_service.dart';
import 'package:vital_step/services/notifications_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final StreamController<ReceivedNotification> didReceiveLocalNotificationStream =
    StreamController<ReceivedNotification>.broadcast();

/// Main VitalStep Supabase client — used for all patient, specialist,
/// assessment, and device data.
late final SupabaseClient patientSupabaseClient;

@pragma('vm:entry-point')
void notificationTapBackground(
    NotificationResponse notificationResponse) async {
  await StackedService.navigatorKey?.currentState
      ?.pushNamed(Routes.assesmentView);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  setupDialogUi();

  // ─── INITIALIZE KILL-SWITCH SUPABASE (separate legacy project) ─────────
  await Supabase.initialize(
    url: 'https://aoujgxqgixpanztyyshc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvdWpneHFnaXhwYW56dHl5c2hjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjMxOTc3ODQsImV4cCI6MjAzODc3Mzc4NH0.7oZoJa7kYpIjj48dOI_iamjxLlMqv_pek52RswBtpRs',
  );

  // ─── INITIALIZE MAIN VITALSTEP SUPABASE ────────────────────────────────
  // Project: oyqecdcpicvzwwvwaeka (vitalstep-device-sync-v2)
  // The publishable key is the anon/public key in new Supabase key format.
  patientSupabaseClient = SupabaseClient(
    'https://oyqecdcpicvzwwvwaeka.supabase.co',
    'sb_publishable_5ovuyYHtObqNMcjEFrNo6Q_Bo4dDFQi',
  );

  setupBottomSheetUi();
  await GetStorage.init();

  // Initialize DeviceSelectionService
  final deviceSelectionService = locator<DeviceSelectionService>();
  await deviceSelectionService.initialize();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings("app_icon");

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  final NotificationsService notificationsService =
      locator<NotificationsService>();
  notificationsService.handleNotification();

  // For terminated state
  final NotificationAppLaunchDetails? notificationAppLaunchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  String initialRoute = Routes.startupView;

  final response = notificationAppLaunchDetails?.notificationResponse;
  if (response != null) {
    initialRoute = Routes.assesmentView;
  }

  runApp(MainApp(initialRoute: initialRoute));

  // For foreground and background
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
    await notificationsService.handleNotification();
  }, onDidReceiveBackgroundNotificationResponse: notificationTapBackground);
}

class MainApp extends StatelessWidget {
  const MainApp({super.key, required this.initialRoute});
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      theme: ThemeData(
        primaryColor: const Color(0xFF0D9488), // VitalStep teal
      ),
      onGenerateRoute: StackedRouter().onGenerateRoute,
      navigatorKey: StackedService.navigatorKey,
      navigatorObservers: [
        StackedService.routeObserver,
      ],
    );
  }
}
