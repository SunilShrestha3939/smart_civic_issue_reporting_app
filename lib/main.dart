import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_civic_app/screens/splash_screen.dart';
import 'package:smart_civic_app/providers/app_provider.dart';
import 'package:smart_civic_app/screens/login_screen.dart';
import 'package:smart_civic_app/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_civic_app/models/issue.dart';

//
import 'package:smart_civic_app/screens/admin_dashboard_screen.dart'; // Ensure this is imported for routing
import 'package:smart_civic_app/screens/report_issue_screen.dart'; // Ensure this is imported for routing
import 'package:smart_civic_app/screens/registration_screen.dart'; // Ensure this is imported for routing
import 'package:smart_civic_app/screens/view_issues_screen.dart'; // Ensure this is imported for routing
import 'package:smart_civic_app/screens/issue_map_screen.dart'; // Ensure this is imported for routing
import 'package:smart_civic_app/screens/issue_detail_screen.dart'; // Import IssueDetailScreen
import 'package:smart_civic_app/services/notification_service.dart'; // Import the new notification service

import 'package:smart_civic_app/models/issue.dart';

// Create an instance of the notification service globally
final NotificationService notificationService = NotificationService();
// Define a global key for the navigator state
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();



//entry point of the app
void main() async {
  // Ensures that Flutter's binding is initialized before using plugins
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the notification service
  await notificationService.init();

  runApp(
    // ChangeNotifierProvider(create: (context) => AppProvider(), child: const MyApp()): This widget makes an instance of AppProvider available to all widgets below it in the widget tree. create is a function that returns the provider instance.
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AppProvider(notificationService), // Pass the instance here!
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This is a crucial addition to link notification taps to fetching
  static AppProvider? _appProviderInstance;


  @override
  void initState() {
    super.initState();
    // Cache the AppProvider instance for use by the static notification handler
    _appProviderInstance = Provider.of<AppProvider>(context, listen: false);

    // Set a custom handler for local notification taps that will fetch the issue
    notificationService.setNotificationTapHandler(
      (String issueId) async {
        debugPrint('Navigating with issue ID from notification: $issueId');
        final Issue? issue = await _appProviderInstance?.fetchIssueById(issueId);
        if (issue != null && navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushNamed(
            '/issue_detail',
            arguments: issue, // Pass the fetched Issue object
          );
        } else {
          debugPrint('Failed to fetch issue for ID: $issueId or navigator is null.');
        }
      },
    );

    // Initialize notification listener when app is launched from terminated state by a notification tap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialNotification();
    });
  }

  // This method handles notifications that launched the app from a terminated state
  Future<void> _handleInitialNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final String? issueId = prefs.getString('pending_notification_issue_id');

    if (issueId != null) {
      await prefs.remove('pending_notification_issue_id'); // Remove it immediately to prevent duplicate handling

      // Use the cached _appProviderInstance to fetch the issue
      final Issue? issue = await _appProviderInstance?.fetchIssueById(issueId);

      if (issue != null && navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamed(
          '/issue_detail',
          arguments: issue, // Pass the actual Issue object
        );
      } else {
        debugPrint('Issue not found for ID $issueId or navigator state is null.');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return MaterialApp(
          title: 'Smart Civic App',
          debugShowCheckedModeBanner: false,
          // Assign the global key to the MaterialApp's navigator
          navigatorKey: navigatorKey, // Crucial for navigation from outside widgets
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: appProvider.themeMode == ThemeMode.light
                  ? Brightness.light
                  : Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
            ),
          ),
          initialRoute: '/', // Set initial route to SplashScreen
          onGenerateRoute: (settings) {
            if (settings.name == '/issue_detail') {
              final Issue issue = settings.arguments as Issue;
              return MaterialPageRoute(
                builder: (context) => IssueDetailScreen(issue: issue),
              );
            };
            // Define other routes here
            if (settings.name == '/login') {
              return MaterialPageRoute(builder: (context) => const LoginScreen());
            } else if (settings.name == '/home') {
              return MaterialPageRoute(builder: (context) => const HomeScreen());
            } else if (settings.name == '/admin_dashboard') {
              return MaterialPageRoute(builder: (context) => const AdminDashboardScreen());
            } else if (settings.name == '/report_issue') {
              return MaterialPageRoute(builder: (context) => const ReportIssueScreen());
            } else if (settings.name == '/registration') {
              return MaterialPageRoute(builder: (context) => const RegistrationScreen());
            } else if (settings.name == '/view_issues') {
              return MaterialPageRoute(builder: (context) => const ViewIssuesScreen());
            } else if (settings.name == '/issue_map') {
              // return MaterialPageRoute(builder: (context) => const IssueMapScreen());
            }
            // Default route
            return MaterialPageRoute(
              builder: (context) => const SplashScreen(),
            );
          },
        );
      },
    );
  }
}









// //describers the overall structure and theme of our application.
// class MyApp extends StatelessWidget { // stateless because it contains (title, theme, and initial route) that do not change during apps lifecycle.
//   const MyApp({super.key});

//   // This method is responsible for returning the widget tree that this widget describes. The BuildContext object holds the location of a widget in the widget tree.
//   @override
//   Widget build(BuildContext context) {
//     //Consumer<AppProvider>(...): This widget is a way to "listen" to changes in AppProvider. Whenever notifyListeners() is called in AppProvider, the builder function of Consumer will be re-executed, rebuilding only the parts of the UI that depend on the provider's state.
//     return Consumer<AppProvider>( // Listen to AppProvider for theme changes
//       builder: (context, appProvider, child) {
//         return MaterialApp( // it sets up the navigarion stack, theme, and other app-wide 
//           title: 'Smart Civic App',
//           theme: ThemeData(
//             primarySwatch: Colors.blue,
//             brightness: Brightness.light, // Default light theme
//           ),
//           darkTheme: ThemeData(
//             primarySwatch: Colors.blue,
//             brightness: Brightness.dark, // Dark theme
//             scaffoldBackgroundColor: Colors.grey[900],
//             appBarTheme: AppBarTheme(
//               backgroundColor: Colors.grey[850],
//             ),
//             cardColor: Colors.grey[800],
//             textTheme: const TextTheme(
//               bodyLarge: TextStyle(color: Colors.white),
//               bodyMedium: TextStyle(color: Colors.white70),
//               titleLarge: TextStyle(color: Colors.white),
//               titleMedium: TextStyle(color: Colors.white),
//               displayLarge: TextStyle(color: Colors.white), // Added for larger texts
//               displayMedium: TextStyle(color: Colors.white),
//               displaySmall: TextStyle(color: Colors.white),
//               headlineMedium: TextStyle(color: Colors.white),
//               headlineSmall: TextStyle(color: Colors.white),
//               titleSmall: TextStyle(color: Colors.white70),
//               labelLarge: TextStyle(color: Colors.white),
//             ),
//             iconTheme: const IconThemeData(color: Colors.white), // Ensure icons are visible
//           ),
//           themeMode: appProvider.themeMode, // control the themeMode of MaterialApp directly from our AppProvider.
//           // Use FutureBuilder to show splash screen while token is loading ie checking if user is logged in based on the stored token.
//           // then redirect based on login status
          
//           // home: FutureBuilder(
//           //   future: appProvider.isLoggedIn ? Future.value(true) : Future.value(false), // This is not ideal, should load token first.
//           //   // Let's modify the root to make sure token loading happens correctly.
//           //   // A better way is to use a separate widget that handles initial auth check.
//           //   builder: (context, snapshot) {
//           //     // AppProvider's constructor already loads the token.
//           //     // So, we just need to check appProvider.isLoggedIn.
//           //     // The splash screen already handles the delay.
//           //     // We'll let the splash screen determine the first route based on AppProvider's state.
//           //     return const SplashScreen();
//           //   },
//           // ),

//           home: const SplashScreen(), // Show splash screen first
//           // Define named routes
//           routes: {
//             '/login': (context) => const LoginScreen(),
//             '/home': (context) => const HomeScreen(),
//           },
//         );
//       },
//     );
//   }
// }