// lib/models/issue.dart

class Issue {
  final String id;
  final String title;
  final String description;
  final String category;
  final String status;
  final String? imageUrl; // Optional image URL
  final double? latitude; // Optional latitude
  final double? longitude; // Optional longitude
  final DateTime reportedAt;

  Issue({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    this.imageUrl,
    this.latitude,
    this.longitude,
    required this.reportedAt,
  });

  // Factory constructor to create an Issue from a JSON map (useful for backend integration later)
  // backend bata aako data lai parse into Issue object
  // This is a factory constructor. It's used to create an Issue object from a Map (typically parsed from a JSON response from your backend).
  factory Issue.fromJson(Map<String, dynamic> json) {
  return Issue(
    id: json['id'].toString(), // Convert int to String
    title: json['issue_type'] ?? 'No Title', // Use issue_type instead of title
    description: json['description'] ?? '',
    category: json['issue_type'] ?? 'General', // Use issue_type as category fallback
    status: json['status'] ?? '',
    imageUrl: json['image'] ?? '',
    latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
    longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
    reportedAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );
}

  // Method to convert Issue to JSON map (useful for backend integration later)
  // Issue object lai JSON map ma convert garne
  // Converts an Issue object back into a Map, which is useful when sending data to your backend.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'image_url': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'reported_at': reportedAt.toIso8601String(),
    };
  }
}