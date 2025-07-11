// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter/material.dart';

// // import 'package:provider/provider.dart'; // Import provider to access AppProvider
// // import 'package:smart_civic_app/models/issue.dart'; // Import Issue model
// // import 'package:smart_civic_app/providers/app_provider.dart'; 

// // Define a global key for the navigator state (as already in main.dart)
// // This needs to be the same global key instance used in MaterialApp
// // Re-declare it if it's not truly global or make sure it's accessible.
// // For consistency, I'll assume it's defined and passed around or globally accessible.
// // If it's only in main.dart, you might need to make it accessible here.
// // For simplicity, let's assume `navigatorKey` from main.dart is accessible via an import or passed.
// // Or, ensure you only declare `final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();` once in main.dart.
// // If you declare it here AND in main.dart, they are different keys.
// // The best approach is to pass the navigatorKey to NotificationService if it's not truly global.

// // For demonstration, let's assume you manage to pass the navigatorKey from main.dart or it's accessible.
// // If it's globally defined in main.dart and visible, then it's fine.
// // Assuming it's the same navigatorKey from main.dart:
// import 'package:smart_civic_app/main.dart'; // Import main.dart to access its global navigatorKey



// // Define a global key for the navigator state
// // This allows us to navigate from contexts where we don't have direct access
// // to a BuildContext, like from a notification callback.
// // final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// // Define a type for the tap handler
// typedef NotificationTapHandler = Future<void> Function(String issueId);

// class NotificationService {
  
//   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   // This method is now public so it can be accessed from main.dart
//   FlutterLocalNotificationsPlugin get flutterLocalNotificationsPluginInstance => _flutterLocalNotificationsPlugin;

//   Future<void> init() async {
//     // --- Android Initialization ---
//     // Make sure '@mipmap/ic_launcher' exists in your Android project.
//     // This is the default icon that will be displayed in the notification bar.
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     // --- iOS Initialization ---
//     // Request permissions for alerts, badges, and sounds
//     const DarwinInitializationSettings initializationSettingsIOS =
//         DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//     );

//     // Combine settings for all supported platforms
//     const InitializationSettings initializationSettings =
//         InitializationSettings(
//       android: initializationSettingsAndroid,
//       iOS: initializationSettingsIOS,
//     );

//     // Initialize the plugin with the settings.
//     // The `onDidReceiveNotificationResponse` handles taps on foreground/background notifications.
//     // The `onDidReceiveBackgroundNotificationResponse` handles taps on terminated app notifications (static method).
//     await _flutterLocalNotificationsPlugin.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
//       onDidReceiveBackgroundNotificationResponse:
//           _onDidReceiveBackgroundNotificationResponse, // Assign static method
//     );

//     // --- Request Permissions (Android 13+ specific) ---
//     // On Android 13 (API 33) and above, you need to explicitly request notification permissions.
//     // It's good practice to call this after initialization.
//     if (navigatorKey.currentContext != null &&
//     Theme.of(navigatorKey.currentContext!).platform == TargetPlatform.android) {
//       final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
//           _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
//               AndroidFlutterLocalNotificationsPlugin>();
      
//       // Request permission for showing notifications
//       final bool? grantedNotificationPermission =
//           await androidImplementation?.requestNotificationsPermission();
      
//       // Optionally request permission for exact alarms if you plan to use `zonedSchedule` with `androidAllowWhileIdle: true`
//       // final bool? grantedExactAlarmPermission =
//       //     await androidImplementation?.requestExactAlarmsPermission();

//       debugPrint('Android notification permission granted: $grantedNotificationPermission');
//       // debugPrint('Android exact alarm permission granted: $grantedExactAlarmPermission');
//     }
//   }

//   // --- Foreground/Background Notification Tap Handler ---
//   // This is called when a notification is tapped and the app is in the foreground or background.
//   void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) {

//     debugPrint('Notification tapped: ${notificationResponse.id}');

//     final String? payload = notificationResponse.payload;
//     if (payload != null) {
//       debugPrint('Notification payload received in onDidReceiveNotificationResponse: $payload');
//       // Navigate using the global navigator key.
//       // Ensure the context is available before attempting to navigate.
//       if (navigatorKey.currentState != null) {
//         print('Navigator state is available. Navigating to issue detail screen with payload: $payload');
//         navigatorKey.currentState!.pushNamed(
//           '/issue_detail', // This route must be defined in your MaterialApp
//           arguments: payload, // The payload (issue ID)
//         );
//       } else {
//         debugPrint('Navigator state is null. Cannot navigate from notification.');
//       }
//     }
//   }

//   // --- Terminated App Notification Tap Handler ---
//   // This static method is crucial for handling notifications when the app is terminated.
//   // The `@pragma('vm:entry-point')` annotation is required for Flutter to find and execute this method.
//   @pragma('vm:entry-point')
//   static void _onDidReceiveBackgroundNotificationResponse(NotificationResponse notificationResponse) async{
//     final String? payload = notificationResponse.payload;
//     if (payload != null) {
//       debugPrint('Background notification payload received in _onDidReceiveBackgroundNotificationResponse: $payload');
//       // Save the payload to shared preferences so it can be used later in main.dart
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString('pending_notification_issue_id', payload);

//       // In a terminated state, direct navigation here might not work reliably
//       // because the Flutter engine might not be fully initialized or the navigator
//       // might not be ready. The _handleInitialNotification in main.dart is designed
//       // to pick this up when the app eventually starts.
//       // However, if the app *becomes* active from background due to this tap,
//       // this navigation might work. It's safer to rely on _handleInitialNotification.
//       if (navigatorKey.currentState != null) {
//         // Attempting to navigate here, but _handleInitialNotification is the primary mechanism
//         // for terminated app launches. This will push the issueId string.
//         navigatorKey.currentState!.pushNamed(
//           '/issue_detail',
//           arguments: payload, // Pass the issueId (String)
//         );
//       } else {
//         debugPrint('Navigator state is null in background handler. Will rely on initial notification check.');
//       }
//     }
//   }

//   // Method to display a local notification
//   Future<void> showIssueStatusNotification({
//     required String issueId,
//     required String issueTitle,
//     required String newStatus,
//   }) async {
//     print('Showing notification for issue $issueId');
//     // Android-specific notification details
//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//         AndroidNotificationDetails(
//       'issue_status_channel_id', // Unique ID for the notification channel
//       'Issue Status Updates',     // User-visible name for the channel
//       channelDescription: 'Notifications for changes in issue status of reported issues.',
//       importance: Importance.high, // High importance for heads-up notifications
//       priority: Priority.high,
//       ticker: 'ticker',
//       playSound: true,
//       enableVibration: true,
//     );

//     // iOS/macOS-specific notification details
//     // const DarwinNotificationDetails iOSPlatformChannelSpecifics =
//     //     DarwinNotificationDetails(
//     //   sound: 'default.wav', // Default notification sound
//     //   presentAlert: true,
//     //   presentBadge: true,
//     //   presentSound: true,
//     // );

//     // Combine platform-specific details
//     const NotificationDetails platformChannelSpecifics = NotificationDetails(
//       android: androidPlatformChannelSpecifics,
//       // iOS: iOSPlatformChannelSpecifics,
//     );

//     // Show the notification
//     try{
//       print('Attempting to show notification for issue $issueId');
//       await _flutterLocalNotificationsPlugin.show(
//         issueId.hashCode, // Unique ID for this notification (can be a random int or counter)
//         'Issue Status Updated: $issueTitle', // Notification title
//         'Your issue "$issueTitle" is now "$newStatus". Tap to view details.', // Notification body
//         // 'The status of "$issueTitle" has changed to "$newStatus".',
//         platformChannelSpecifics,
//         payload: issueId, // Data to be passed when the notification is tapped must be a string
//       );
//       print('Notification for issue $issueId shown successfully');
//     } catch (e) {
//       print('Error showing notification for issue $issueId: $e'); 
//     }
//   }
// }



// notification_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_civic_app/main.dart'; // Import to access the global navigatorKey

// Define a type for the tap handler
typedef NotificationTapHandler = Future<void> Function(String issueId);

class NotificationService {
  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  // Plugin instance
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Tap handler to be set by the UI layer (MyApp)
  NotificationTapHandler? _notificationTapHandler;

  // Setter for the tap handler
  void setNotificationTapHandler(NotificationTapHandler handler) {
    _notificationTapHandler = handler;
  }

  // Initialization method
  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // General initialization settings
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      // This callback is triggered when a notification is tapped while the app is in the foreground or background.
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      // THIS IS THE KEY CHANGE for background/terminated app launches
      onDidReceiveBackgroundNotificationResponse: _onDidReceiveBackgroundNotificationResponse,
    );

    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // This line might cause an error if currentContext is null during very early app startup
    // It's generally safer to check if navigatorKey.currentContext is null before using it,
    // or to assume that for Android 13+ permission request, context might not be strictly needed
    // as it's a system dialog. However, for theme/platform check, context is useful.
    if (navigatorKey.currentContext != null && Theme.of(navigatorKey.currentContext!).platform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final bool? grantedNotificationPermission =
          await androidImplementation?.requestNotificationsPermission();

      debugPrint('Android notification permission granted: $grantedNotificationPermission');
    }
  }

  // Callback for when a notification is tapped (app is foreground or background)
  void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    if (payload != null && payload.isNotEmpty) {
      debugPrint('Notification payload received in onDidReceiveNotificationResponse: $payload');
      // Instead of navigating directly, call the registered handler
      _notificationTapHandler?.call(payload);
    }
  }

  // Static callback for when a notification is tapped (app is terminated/killed)
  // This method *must* be a static or top-level function.
  // It runs in an isolated context when the app is launched by a notification tap from a terminated state.
  @pragma('vm:entry-point') // Required for background execution on Android
  static void _onDidReceiveBackgroundNotificationResponse(NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (payload != null && payload.isNotEmpty) {
      debugPrint('Background notification payload received: $payload');
      // We cannot directly navigate here as the Flutter engine might not be fully initialized
      // and we don't have a BuildContext.
      // Instead, we save the payload to SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_notification_issue_id', payload);
      debugPrint('Pending notification issue ID saved: $payload');
    }
  }

  // Method to show an issue status update notification
  Future<void> showIssueStatusNotification({
    required String issueId,
    required String issueTitle,
    required String newStatus,
  }) async {
    // Android Notification Channel (required for Android 8.0+)
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'issue_status_channel', // Channel ID
      'Issue Status Updates', // Channel Name
      channelDescription: 'Notifications for updates on your reported issues.',
      importance: Importance.high, // Makes it a heads-up notification
      priority: Priority.high,
      ticker: 'Issue Status Update',
      playSound: true,
      enableVibration: true,
    );

    // iOS Notification Details
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Platform-specific notification details
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Show the notification
    await _flutterLocalNotificationsPlugin.show(
      issueId.hashCode, // Unique ID for the notification (using hash of issueId for consistency)
      'Issue Status Update',
      'Your issue "$issueTitle" has been updated to: $newStatus',
      platformChannelSpecifics,
      payload: issueId, // Payload will be the issueId string
    );
    debugPrint('Notification shown for issue ID: $issueId with status: $newStatus');
  }
}