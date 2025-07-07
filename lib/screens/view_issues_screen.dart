import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_civic_app/models/issue.dart';
import 'package:smart_civic_app/screens/issue_detail_screen.dart';
import 'package:smart_civic_app/providers/app_provider.dart';
import 'package:smart_civic_app/screens/issue_map_screen.dart';

// class ViewIssuesScreen extends StatelessWidget {
//   const ViewIssuesScreen({super.key});

//   // Generate some dummy issues for demonstration
//   List<Issue> _generateDummyIssues() {
//     return List.generate(10, (index) {
//       return Issue(
//         id: 'issue_${index + 1}',
//         title: 'Pothole on Main Street ${index + 1}',
//         description:
//             'Large pothole causing issues for vehicles and pedestrians near the intersection of Main St and Oak Ave. It has been there for a while and needs urgent attention. Its size is about 2x2 feet.',
//         category: index % 3 == 0
//             ? 'Road Issue'
//             : index % 3 == 1
//                 ? 'Sanitation'
//                 : 'Streetlight',
//         status: index % 2 == 0 ? 'Pending' : 'In Progress',
//         imageUrl: index % 2 == 0
//             ? 'https://placehold.co/600x400/FF0000/FFFFFF?text=Pothole+Image'
//             : null, // Dummy image URL
//         latitude: 27.7000 + (index * 0.001), // Dummy latitude
//         longitude: 85.3200 + (index * 0.001), // Dummy longitude
//         reportedAt: DateTime.now().subtract(Duration(days: index)),
//       );
//     });
//   }




class ViewIssuesScreen extends StatefulWidget {
  const ViewIssuesScreen({super.key});

  @override
  State<ViewIssuesScreen> createState() => _ViewIssuesScreenState();
}

class _ViewIssuesScreenState extends State<ViewIssuesScreen> {
  // Add a Future to trigger initial data fetch
  late Future<void> _fetchIssuesFuture;

  // State variables to hold the current filter selections
  String? _selectedStatusFilter; // State variable for selected status
  bool _showMyIssues = false; // State variable for "My Issues" toggle

  @override
  void initState() {
    super.initState();
    // Initialize the future here. We use Future.microtask to ensure provider is available.
    _fetchIssuesFuture = Future.microtask(() =>
        Provider.of<AppProvider>(context, listen: false).fetchIssues());
  }

  // Method to re-fetch issues based on filters
  void _refreshIssues() {
    setState(() {
      _fetchIssuesFuture = Provider.of<AppProvider>(context, listen: false)
          .fetchIssues(
            status: _selectedStatusFilter, // Pass selected status
            userSpecific: _showMyIssues, // Pass "My Issues" toggle state
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    // final List<Issue> dummyIssues = _generateDummyIssues();

    // Use Consumer to listen to changes in AppProvider's issues state
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        if (appProvider.isIssuesLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (appProvider.issuesErrorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 50),
                  SizedBox(height: 10),
                  Text(
                    appProvider.issuesErrorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _refreshIssues, // Allow retrying fetch
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // We will show list if issues are empty and error is null, but also allow map view
        // if issues are empty to potentially show current location
        if (appProvider.issues.isEmpty && appProvider.issuesErrorMessage == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, color: Colors.grey, size: 50),
                const SizedBox(height: 10),
                const Text(
                  'No issues found.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _refreshIssues,
                  child: const Text('Refresh'),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon( // Button to view on map even if list is empty
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => IssueMapScreen(issues: appProvider.issues), // Pass current issues
                    ));
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('View on Map'),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Filter by Status',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        hint: const Text('All Statuses'),
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text('All Statuses')),
                          const DropdownMenuItem<String>(value: 'Pending', child: Text('Pending')),
                          const DropdownMenuItem<String>(value: 'In_Progress', child: Text('In Progress')),
                          const DropdownMenuItem<String>(value: 'Resolved', child: Text('Resolved')),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedStatusFilter = newValue;
                            _refreshIssues(); // Re-fetch when filter changes
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // When unselected (default):The user sees all issues reported by anyone.
                    // When tapped (selected):The app fetches and displays only issues reported by the current user.
                    // The icon changes:
                    // 👤 Icons.person → when active
                    // 👤 Icons.person_outline → when inactive
                    // If the user long presses the chip, the tooltip appears with a hint:
                    // ➤ "Show only issues reported by me"
                    Tooltip(  //explaining FilterChip purpose on long press.
                      message: 'Show only issues reported by me',
                      child: FilterChip(
                        label: const Text('My Issues'),
                        selected: _showMyIssues,
                        onSelected: (bool selected) {
                          setState(() {
                            _showMyIssues = selected;
                            _refreshIssues(); // Re-fetch when filter changes
                          });
                        },
                        avatar: Icon(_showMyIssues ? Icons.person : Icons.person_outline),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator( // Added for pull-to-refresh
                  onRefresh: () async {
                      _refreshIssues(); // Triggers the setState and data fetch
                    },
                  //ListView.builder: This is efficient for long lists. It only builds the widgets that are currently visible on the screen, recycling them as the user scrolls.
                  // itemCount: The total number of items in the list.
                  // itemBuilder: A callback function that's called for each item's index to build its widget.
                  child: ListView.builder(
                    itemCount: appProvider.issues.length,
                    itemBuilder: (context, index) {
                      final issue = appProvider.issues[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 3,
                        //Inkwell wraps the Card widget to provide a ripple effect when tapped.
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(  // its builder function provides the context and returns the IssueDetailScreen widget.
                                builder: (context) => IssueDetailScreen(issue: issue),  // Pass the issue object
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  issue.title,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  issue.description.length > 100
                                      ? '${issue.description.substring(0, 100)}...' // Truncate description
                                      : issue.description,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Status: ${issue.status}',
                                      style: TextStyle(
                                        color: issue.status == 'Pending' ? Colors.orange
                                            : issue.status == 'Resolved' ? Colors.green
                                            : Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text('Category: ${issue.category}', style: TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    'Reported on: ${issue.reportedAt.toLocal().toString().split(' ')[0]}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          // floatingActionButton: appProvider.issues.isNotEmpty ? FloatingActionButton.extended(
          //   onPressed: () {
          //     Navigator.of(context).push(MaterialPageRoute(
          //       builder: (context) => IssueMapScreen(issues: appProvider.issues),
          //     ));
          //   },
          //   label: const Text('View on Map'),
          //   icon: const Icon(Icons.map),
          //   backgroundColor: Colors.blue,
          // ) : null,
        );
      },
    );
  }
}