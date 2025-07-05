// lib/screens/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_civic_app/models/issue.dart';
import 'package:smart_civic_app/screens/issue_detail_screen.dart';
import 'package:smart_civic_app/providers/app_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<void> _fetchIssuesFuture;

  // Define available statuses
  final List<String> _statuses = ['Pending', 'In Progress', 'Resolved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _fetchIssuesFuture = Future.microtask(() =>
        Provider.of<AppProvider>(context, listen: false).fetchIssues()); // FfetchIssues() is called without userSpecific: true, meaning it fetches all issues.
  }

  void _refreshIssues() {
    setState(() {
      _fetchIssuesFuture = Provider.of<AppProvider>(context, listen: false).fetchIssues();
    });
  }

  // Handle status update
  Future<void> _updateStatus(Issue issue, String newStatus) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    bool success = await appProvider.updateIssueStatus(issue.id, newStatus);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status for ${issue.title} updated to $newStatus')),
      );
      // We don't need to call _refreshIssues() on success because AppProvider.updateIssueStatus already updates the local _issues list and calls notifyListeners(), which automatically rebuilds this Consumer widget.
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appProvider.issuesErrorMessage ?? 'Failed to update status.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        if (!appProvider.isAdmin) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, color: Colors.red, size: 60),
                  SizedBox(height: 20),
                  Text(
                    'Access Denied: You must be an administrator to view this dashboard.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Go back to previous screen
                    },
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

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
                    onPressed: _refreshIssues,
                    child: const Text('Retry Fetch Issues'),
                  ),
                ],
              ),
            ),
          );
        }

        if (appProvider.issues.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, color: Colors.grey, size: 50),
                const SizedBox(height: 10),
                const Text(
                  'No issues found in the system.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _refreshIssues,
                  child: const Text('Refresh Issues'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator( // Added for pull-to-refresh
                onRefresh: () async {
                    _refreshIssues(); // Triggers the setState and data fetch
                  },
          child: ListView.builder(
            itemCount: appProvider.issues.length,
            itemBuilder: (context, index) {
              final issue = appProvider.issues[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => IssueDetailScreen(issue: issue),
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
                          'ID: ${issue.id}', // Display issue ID for admin context
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Reported by: ${issue.reportedAt.toLocal().toString().split(' ')[0]}', // Assuming reportedAt can imply reporter for now, but ideally backend sends reporter info
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Category: ${issue.category}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            // Day 11/12: Status Update Dropdown
                            Expanded( // Use Expanded to give dropdown space
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: DropdownButton<String>(
                                  value: issue.status,
                                  icon: const Icon(Icons.arrow_drop_down),
                                  elevation: 16,
                                  style: const TextStyle(color: Colors.deepPurple),
                                  underline: Container(
                                    height: 2,
                                    color: Colors.deepPurpleAccent,
                                  ),
                                  onChanged: (String? newValue) {
                                    if (newValue != null && newValue != issue.status) {
                                      _updateStatus(issue, newValue);
                                    }
                                  },
                                  items: _statuses.map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: TextStyle(
                                          color: value == 'Pending' ? Colors.orange
                                              : value == 'Resolved' ? Colors.green
                                              : value == 'Rejected' ? Colors.red
                                              : Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}