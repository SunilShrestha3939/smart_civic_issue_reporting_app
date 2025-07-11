import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_civic_app/models/issue.dart';
import 'package:smart_civic_app/screens/issue_detail_screen.dart';
import 'package:smart_civic_app/providers/app_provider.dart';
import 'package:smart_civic_app/screens/issue_map_screen.dart';
import 'package:smart_civic_app/services/notification_service.dart';
import 'dart:async';
import 'package:smart_civic_app/main.dart';

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
  bool _showMyIssues = false; // State variable for "My Issues" toggle i.e only show issues reported by the current user 

  //
  // Timer object that will repeatedly call checkForStatusChanges().
  Timer? _pollingTimer;
  // Cache to store issue statuses to detect changes
  // A Map to store the last known status of each issue. This is crucial for detecting changes.
  Map<String, String> _issueStatusCache = {}; // issueId -> status
  //

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure context is fully available
    // and to perform initial fetch after the first frame has rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialLoadAndPollingSetup();
    });
  }

  Future<void> _initialLoadAndPollingSetup() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // 1. Perform the initial fetch for the main list display (with current filters)
    // This will set appProvider.isIssuesLoading = true.
    print('Initial fetch for main list with userSpecific: $_showMyIssues');
    await appProvider.fetchIssues(
      status: _selectedStatusFilter,
      userSpecific: _showMyIssues,
    );

    // 2. After the initial fetch, populate the cache *from the fetched issues*.
    // And then start the polling for *user-specific* issue changes.
    // Ensure we fetch user-specific issues for the cache, as notifications are for "my issues".
    // This *might* be a redundant fetch if _showMyIssues is already true for the main list,
    // but it ensures the cache is based on issues the user reported.
    print('Fetching user-specific issues for polling cache.');
    await appProvider.fetchIssues(userSpecific: true); // Re-fetch specific for cache

    // Populate cache with the issues that were just fetched (which should be only current user's issues)
    // We iterate directly over appProvider.issues because fetchIssues(userSpecific: true)
    // is assumed to have already filtered them.
    for (var issue in appProvider.issues) { // appProvider.issues should already contain only "my issues" now
      _issueStatusCache[issue.id] = issue.status;
    }
    print('Initial issue status cache populated with ${appProvider.issues.length} user issues.');

    // Start polling *after* initial data is loaded and cached.
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) => checkForStatusChanges());
    print('Polling started.');
  }

  Future<void> checkForStatusChanges() async {
    // 1. **Crucial check:** Only proceed if the widget is still mounted.
    // If 'mounted' is false, it means the widget has been unmounted,
    // and its 'context' is no longer valid.
    if (!mounted) {
      print('Polling skipped: Widget is unmounted.');
      return; // Stop execution if the widget is not mounted.
    }


    print('Polling check at ${DateTime.now()}');
    try {
      final issueProvider = Provider.of<AppProvider>(context, listen: false);

      // Fetch ONLY current user's issues for status checking.
      // This fetch should ideally not block the main UI if 'isIssuesLoading' is handled carefully in AppProvider
      // (e.g., a separate loading state for background polls, or no loading state if it's a silent background fetch).
      await issueProvider.fetchIssues(userSpecific: true);

      // The issues in issueProvider.issues are already the current user's issues
      // because of the preceding fetchIssues(userSpecific: true) call.
      final List<Issue> currentUserIssuesForPolling = issueProvider.issues;

      print('Checking ${currentUserIssuesForPolling.length} user issues for status changes.');

      for (var issue in currentUserIssuesForPolling) {
        final previousStatus = _issueStatusCache[issue.id];

        if (previousStatus != null && previousStatus != issue.status) {
          print('Status changed for ${issue.id} from $previousStatus to ${issue.status}');
          await notificationService.showIssueStatusNotification(
            issueId: issue.id,
            issueTitle: issue.title,
            newStatus: issue.status,
          );
          print('Notification triggered for issue ID: ${issue.id}');
        }

        _issueStatusCache[issue.id] = issue.status; // update cache
      }
    } catch (e) {
      print('Polling error: $e');
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();  // timer cancelled to prevent memory leaks
    print('Polling timer cancelled.');
    super.dispose();
  }

  // Method to re-fetch issues based on filters
  void _refreshIssues() {
    setState(() {
      // This will trigger the CircularProgressIndicator because fetchIssues
      // will likely set appProvider.isIssuesLoading to true.
      Provider.of<AppProvider>(context, listen: false)
          .fetchIssues(
            status: _selectedStatusFilter,
            userSpecific: _showMyIssues,
          );
      // We don't need _fetchIssuesFuture anymore as we directly trigger the fetch
      // and rely on the Consumer to rebuild when appProvider.isIssuesLoading changes.
    });
  }

  // @override
  // void initState() {
  //   super.initState();
  //   // Initialize the future here. We use Future.microtask to ensure provider is available.
  //   //Future.microtask is used to defer the call slightly. This is a common pattern to ensure that the BuildContext is fully initialized and available before attempting to access the Provider.
  //   _fetchIssuesFuture = Future.microtask(() =>
  //       Provider.of<AppProvider>(context, listen: false).fetchIssues());

  //   startPolling();
  // }

  // // it performs an initial fetchIssues(userSpecific: true) to populate _issueStatusCache with the current user's issues and their statuses. This ensures you have a baseline to compare against.
  // // Then, it sets up Timer.periodic(const Duration(seconds: 30), (_) => checkForStatusChanges()) to run checkForStatusChanges every 30 seconds.
  // void startPolling() {
  //   // Initial fetch to populate the cache
  //   Provider.of<AppProvider>(context, listen: false).fetchIssues(userSpecific: true).then((_) {
  //     final issues = Provider.of<AppProvider>(context, listen: false).issues;
  //     for (var issue in issues) {
  //       _issueStatusCache[issue.id] = issue.status;
  //     }
  //     print('Initial issue status cache populated.');
  //   }).catchError((e) {
  //     print('Error populating initial issue status cache: $e');
  //   });

  //   // Timer object that will repeatedly call checkForStatusChanges().
  //   _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) => checkForStatusChanges());
  // }

  // Future<void> checkForStatusChanges() async {
  //   print('Polling check at ${DateTime.now()}');
  //   try {
  //     final issueProvider = Provider.of<AppProvider>(context, listen: false);

  //     await issueProvider.fetchIssues(userSpecific: true); // fetch only current user's issues
  //     //current user issues
  //     final issues = issueProvider.issues; 

  //     for (var issue in issues) {
  //       // previous status from cache
  //       final previousStatus = _issueStatusCache[issue.id];

  //       if (previousStatus != null && previousStatus != issue.status) {
  //         print('Status changed for ${issue.id} from $previousStatus to ${issue.status}');
  //         // Trigger notification using the global instance
  //         await notificationService.showIssueStatusNotification( // trigger local notification
  //           issueId: issue.id,
  //           issueTitle: issue.title,
  //           newStatus: issue.status,
  //         );
  //         print('Notification triggered');
  //       }

  //       _issueStatusCache[issue.id] = issue.status; // update cache
  //     }
  //   } catch (e) {
  //     print('Polling error: $e');
  //   }
  // }
  
  // @override
  // void dispose() {
  //   // stop the timer when the screen is removed from the widget tree, preventing memory leaks.
  //   _pollingTimer?.cancel();
  //   super.dispose();
  // }
  // //

  // // Method to re-fetch issues based on filters
  // // reenter the fetching state briefly while the new data is fetched.
  // void _refreshIssues() {
  //   setState(() {
  //     _fetchIssuesFuture = Provider.of<AppProvider>(context, listen: false)
  //         .fetchIssues(
  //           status: _selectedStatusFilter, // Pass selected status
  //           userSpecific: _showMyIssues, // Pass "My Issues" toggle state
  //         );
  //   });
  // }

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
        );
      },
    );
  }
}