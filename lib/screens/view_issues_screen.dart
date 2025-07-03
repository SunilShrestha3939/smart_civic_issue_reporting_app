import 'package:flutter/material.dart';
import 'package:smart_civic_app/models/issue.dart';
import 'package:smart_civic_app/screens/issue_detail_screen.dart';

class ViewIssuesScreen extends StatelessWidget {
  const ViewIssuesScreen({super.key});

  // Generate some dummy issues for demonstration
  List<Issue> _generateDummyIssues() {
    return List.generate(10, (index) {
      return Issue(
        id: 'issue_${index + 1}',
        title: 'Pothole on Main Street ${index + 1}',
        description:
            'Large pothole causing issues for vehicles and pedestrians near the intersection of Main St and Oak Ave. It has been there for a while and needs urgent attention. Its size is about 2x2 feet.',
        category: index % 3 == 0
            ? 'Road Issue'
            : index % 3 == 1
                ? 'Sanitation'
                : 'Streetlight',
        status: index % 2 == 0 ? 'Pending' : 'In Progress',
        imageUrl: index % 2 == 0
            ? 'https://placehold.co/600x400/FF0000/FFFFFF?text=Pothole+Image'
            : null, // Dummy image URL
        latitude: 27.7000 + (index * 0.001), // Dummy latitude
        longitude: 85.3200 + (index * 0.001), // Dummy longitude
        reportedAt: DateTime.now().subtract(Duration(days: index)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Issue> dummyIssues = _generateDummyIssues();

    //ListView.builder: This is efficient for long lists. It only builds the widgets that are currently visible on the screen, recycling them as the user scrolls.
    // itemCount: The total number of items in the list.
    // itemBuilder: A callback function that's called for each item's index to build its widget.
    return ListView.builder(
      itemCount: 10, // Placeholder for 10 issues
      itemBuilder: (context, index) {
        final issue = dummyIssues[index]; // Get the issue for this index

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 3,
          //Inkwell wraps the Card widget to provide a ripple effect when tapped. 
          child: InkWell( 
            onTap: () {
              Navigator.of(context).push(
                // Navigate to IssueDetailScreen when tapped
                MaterialPageRoute(  // its builder function provides the context and returns the IssueDetailScreen widget.
                  builder: (context) =>
                      IssueDetailScreen(issue: issue), // Pass the issue object
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
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
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
                          color: issue.status == 'Pending'
                              ? Colors.orange
                              : issue.status == 'Resolved'
                                  ? Colors.green
                                  : Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Category: ${issue.category}',
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      'Reported on: ${issue.reportedAt.toLocal().toString().split(' ')[0]}', // Format date
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  // Add a button/gesture detector to view details
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
