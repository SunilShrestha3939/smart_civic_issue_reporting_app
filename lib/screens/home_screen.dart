import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_civic_app/screens/report_issue_screen.dart';
import 'package:smart_civic_app/screens/view_issues_screen.dart';
import 'package:smart_civic_app/screens/admin_dashboard_screen.dart'; // Import AdminDashboardScreen
import 'package:smart_civic_app/providers/app_provider.dart';
import 'package:smart_civic_app/screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //_selectedIndex: A state variable to keep track of which tab is currently selected. [setState] is used to update this variable and rebuild the UI.
  int _selectedIndex = 0;

  //_widgetOptions: A List of Widgets, where each widget corresponds to a tab in the BottomNavigationBar. This makes it easy to switch between views.
  // This list will be dynamically built based on admin status
  List<Widget> _widgetOptions(bool isAdmin) { //A function that returns the list of tabs dynamically. If isAdmin is true, AdminDashboardScreen is added.
    List<Widget> options = [
      const ViewIssuesScreen(),
      const ReportIssueScreen(),
      const _ProfileSettingsScreen(),
    ];
    if (isAdmin) {
      options.add(const AdminDashboardScreen()); // Add admin dashboard if user is admin
    }
    return options;
  }

  //_onItemTapped: This callback function is triggered when a BottomNavigationBarItem is tapped. It updates _selectedIndex and calls setState to rebuild the body with the new selected widget.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.clearAuthToken(); // Clear token
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully!')),
    );
    // Navigator.of(context).pushAndRemoveUntil(..., (route) => false). This pushes the new route (LoginScreen) and removes all previous routes from the stack. This prevents the user from pressing the back button and accidentally returning to a logged-in HomeScreen.
    Navigator.of(context).pushAndRemoveUntil( // Navigate to login and clear all previous routes
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

@override
  Widget build(BuildContext context) {
    // Listen to AppProvider to react to isAdmin changes
    return Consumer<AppProvider>( //HomeScreen reacts to changes in appProvider.isAdmin.
      builder: (context, appProvider, child) {
        final bool isAdmin = appProvider.isAdmin;
        final List<Widget> currentWidgetOptions = _widgetOptions(isAdmin);

        // Ensure selected index is valid if admin status changes and a tab is removed/added ie  if an admin logs out, and the admin tab disappears
        if (_selectedIndex >= currentWidgetOptions.length) {
          _selectedIndex = 0; // Reset to default tab if current one is removed
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Smart Civic App'),
            backgroundColor: Colors.blue,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _logout,
              ),
              IconButton(
                icon: Icon(appProvider.themeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode),
                onPressed: () {
                  appProvider.toggleTheme();
                },
              ),
            ],
          ),
          body: Center(
            child: currentWidgetOptions.elementAt(_selectedIndex),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(
                icon: Icon(Icons.list),
                label: 'Issues',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.add_circle),
                label: 'Report',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
              if (isAdmin) // Conditionally add Admin tab
                const BottomNavigationBarItem(
                  icon: Icon(Icons.admin_panel_settings),
                  label: 'Admin',
                ),
            ],
            currentIndex: _selectedIndex,// Tells the navigation bar which item is currently active.
            selectedItemColor: Colors.blue,
            unselectedItemColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey, // Improve visibility in dark mode
            onTap: _onItemTapped,
          ),
          floatingActionButton: _selectedIndex == 0 // Show FAB only on 'Issues' tab
              ? FloatingActionButton( //When pressed, it changes the _selectedIndex to 1, effectively switching to the "Report" tab. This provides a quick way to report an issue from the main issues list.
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1; // Navigate to 'Report' tab
                    });
                  },
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,// Don't show FAB on other tabs
        );
      },
    );
  }
}  

// New widget to demonstrate counter and theme toggle
class _ProfileSettingsScreen extends StatelessWidget {
  const _ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Using Consumer to rebuild only this part when AppProvider changes
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Counter Value: ${appProvider.counter}', // Access counter from provider
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  appProvider.incrementCounter(); // Call method on provider
                },
                child: const Text('Increment Counter'),
              ),
              const SizedBox(height: 40),
              Text(
                'Current Theme: ${appProvider.themeMode == ThemeMode.light ? 'Light' : 'Dark'}',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  appProvider.toggleTheme(); // Call method on provider
                },
                child: const Text('Toggle Theme'),
              ),
            ],
          ),
        );
      },
    );
  }
}