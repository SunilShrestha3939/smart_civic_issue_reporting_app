// lib/screens/issue_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:smart_civic_app/models/issue.dart'; // Import our Issue model

class IssueDetailScreen extends StatelessWidget {
  final Issue issue; // The issue object passed from the previous screen

  const IssueDetailScreen({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Details'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              issue.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Category: ${issue.category}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Text(
              'Status: ${issue.status}',
              style: TextStyle(
                fontSize: 16,
                color: issue.status == 'Pending' ? Colors.orange
                    : issue.status == 'Resolved' ? Colors.green
                    : Colors.blue, // Default for 'In Progress' or other
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Description:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Text(
              issue.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (issue.imageUrl != null && issue.imageUrl!.isNotEmpty) // only display if imageUrl is not null or empty
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attached Photo:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  // For now, we'll use a placeholder or network image if URL is valid
                  // Later, if images are stored locally, you might use Image.file
                  Image.network(  // display the image from the URL
                    issue.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {  // fallback for error handling
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Text('Image not available or failed to load',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            if (issue.latitude != null && issue.longitude != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Latitude: ${issue.latitude!.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Longitude: ${issue.longitude!.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  // TODO: Add a map widget here on Day 14
                ],
              ),
            Text(
              'Reported On: ${issue.reportedAt.toLocal().toString().split('.')[0]}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}