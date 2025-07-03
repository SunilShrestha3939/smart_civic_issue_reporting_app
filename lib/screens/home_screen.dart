import 'package:flutter/material.dart';
import 'package:smart_civic_app/screens/report_issue_screen.dart'; // We'll create this next
import 'package:smart_civic_app/screens/view_issues_screen.dart'; // We'll create this next

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //_selectedIndex: A state variable to keep track of which tab is currently selected. [setState] is used to update this variable and rebuild the UI.
  int _selectedIndex = 0;

  //_widgetOptions: A List of Widgets, where each widget corresponds to a tab in the BottomNavigationBar. This makes it easy to switch between views.
  static const List<Widget> _widgetOptions = <Widget>[
    ViewIssuesScreen(), // Placeholder for viewing issues
    ReportIssueScreen(), // Screen for reporting a new issue
    Text('Profile Screen Placeholder', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)), // Example Profile screen
  ];

  //_onItemTapped: This callback function is triggered when a BottomNavigationBarItem is tapped. It updates _selectedIndex and calls setState to rebuild the body with the new selected widget.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Civic App'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // TODO: Implement actual logout logic (clear token, navigate to login)
              Navigator.of(context).pushReplacementNamed('/'); // Go back to splash or login
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out! (Actual logout not implemented yet)')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[   // list
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Issues',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex, // Tells the navigation bar which item is currently active.
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped, //callback function called when a tab is tapped.
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
          : null, // Don't show FAB on other tabs
    );
  }
}