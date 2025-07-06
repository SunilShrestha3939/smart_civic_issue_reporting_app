import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart
import 'package:smart_civic_app/models/issue.dart';
import 'package:smart_civic_app/screens/issue_detail_screen.dart';
import 'package:smart_civic_app/providers/app_provider.dart';
import 'package:smart_civic_app/screens/issue_map_screen.dart'; 

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<void> _fetchIssuesFuture;

  // Define available statuses
  final List<String> _statuses = ['Pending', 'In Progress', 'Resolved', 'Rejected', 'open'];

  @override
  void initState() {
    super.initState();
    _fetchIssuesFuture = Future.microtask(() =>
        Provider.of<AppProvider>(context, listen: false).fetchIssues()); // fetchIssues() is called without userSpecific: true, meaning it fetches all issues.
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

  // Charting Helper Methods  [_getIssueStatusDistribution] and [_getIssueCategoryDistribution]
  // takes the list of issues then use map to count occurrences of each status and category
  // then transform the counts into List<PieChartSectionData> which is format expected by fl_chart's PieChart widget.
  // colors are assigned based on the status or category, cycling through a predefined list of colors.
  // title property are set to show the status or category name along with the count in parentheses.

  List<PieChartSectionData> _getIssueStatusDistribution(List<Issue> issues) {
    Map<String, int> statusCounts = {};
    for (var status in _statuses) {
      statusCounts[status] = 0; // Initialize all known status counts to 0
    }
    // Count actual statuses
    for (var issue in issues) {
      statusCounts.update(issue.status, (value) => value + 1, ifAbsent: () => 1);
    }

    final colors = [
      Colors.orange, // Pending
      Colors.blue,    // In Progress
      Colors.green,   // Resolved
      Colors.red,     // Rejected
      Colors.grey,    // Fallback for any unknown status
    ];

    List<PieChartSectionData> sections = [];
    int colorIndex = 0;
    // Sort keys to maintain consistent color mapping if possible
    final sortedStatusKeys = statusCounts.keys.toList()..sort((a, b) {
      // Custom sort order based on _statuses list
      final indexA = _statuses.indexOf(a);
      final indexB = _statuses.indexOf(b);
      if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
      if (indexA != -1) return -1; // Keep known statuses first
      if (indexB != -1) return 1;
      return a.compareTo(b); // Alphabetical for unknown statuses
    });


    for (var status in sortedStatusKeys) {
      final count = statusCounts[status]!;
      if (count > 0) {
        sections.add(
          PieChartSectionData(
            color: colors[colorIndex % colors.length], // Cycle through colors
            value: count.toDouble(),
            title: '$status\n(${count})',
            radius: 50,
            titleStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            showTitle: true,
          ),
        );
      }
      colorIndex++;
    }
    return sections;
  }

  List<PieChartSectionData> _getIssueCategoryDistribution(List<Issue> issues) {
    Map<String, int> categoryCounts = {};
    for (var issue in issues) {
      categoryCounts.update(issue.category, (value) => value + 1, ifAbsent: () => 1);
    }

    final categoryColors = [
      Colors.purple,
      Colors.teal,
      Colors.brown,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
      Colors.deepOrange,
      Colors.lime,
      Colors.pink,
      Colors.lightGreen,
    ];

    List<PieChartSectionData> sections = [];
    int colorIndex = 0;
    // Sort categories alphabetically for consistent display
    final sortedCategoryKeys = categoryCounts.keys.toList()..sort();

    for (var category in sortedCategoryKeys) {
      final count = categoryCounts[category]!;
      if (count > 0) {
        sections.add(
          PieChartSectionData(
            color: categoryColors[colorIndex % categoryColors.length], // Cycle through colors
            value: count.toDouble(),
            title: '$category\n(${count})',
            radius: 50,
            titleStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            showTitle: true,
          ),
        );
      }
      colorIndex++;
    }
    return sections;
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

        // Day 13: Chart data preparation
        final statusSections = _getIssueStatusDistribution(appProvider.issues);
        final categorySections = _getIssueCategoryDistribution(appProvider.issues);

        return RefreshIndicator( // Added for pull-to-refresh
          onRefresh: () async {
              _refreshIssues(); // Triggers the setState and data fetch
            },
          // SingleChildScrollView. This is crucial because we're adding charts (which have fixed heights) and a ListView.builder inside a Column. Without it, you'd get layout errors.  
          child: SingleChildScrollView( // Use SingleChildScrollView to accommodate charts and list
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Issue Status Distribution Chart
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Issue Status Distribution (${appProvider.issues.length} total)',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200, // Fixed height for the chart
                        child: PieChart(
                          PieChartData( // it configures the chart using [sections]
                            sections: statusSections,
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
                                if (pieTouchResponse != null && pieTouchResponse.touchedSection != null) {
                                  final touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                  final section = statusSections[touchedIndex];
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${section.title}')),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // Issue Category Distribution Chart
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Issue Category Distribution',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200, // Fixed height for the chart
                        child: PieChart(
                          PieChartData(
                            sections: categorySections,
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
                                if (pieTouchResponse != null && pieTouchResponse.touchedSection != null) {
                                  final touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                  final section = categorySections[touchedIndex];
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${section.title}')),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // View Issues on Map Button (for admin)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => IssueMapScreen(issues: appProvider.issues),
                      ));
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('View All Issues on Map'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40), // Make button wider
                    ),
                  ),
                ),
                const Divider(),

                // Existing Issue List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'All Issues (Click to update status)',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                ListView.builder(
                  //shrinkWrap: true is important when ListView.builder is inside a Column (or SingleChildScrollView) to make it take only the space it needs.
                  shrinkWrap: true, // Important for nested scrollables
                  // physics: const NeverScrollableScrollPhysics() is used to prevent the ListView from having its own independent scroll, allowing the SingleChildScrollView to handle all scrolling.
                  physics: const NeverScrollableScrollPhysics(), // Disable inner scroll
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
                                'ID: ${issue.id}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                issue.description.length > 100
                                    ? '${issue.description.substring(0, 100)}...'
                                    : issue.description,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Category: ${issue.category}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: DropdownButton<String>(
                                        // value: _statuses.contains(issue.status) ? issue.status : _statuses.first,
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
              ],
            ),
          ),
        );
      },
    );
  }
}