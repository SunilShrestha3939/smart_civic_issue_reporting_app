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
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      status: json['status'] as String,
      imageUrl: json['image_url'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      reportedAt: DateTime.parse(json['reported_at'] as String), // Assuming ISO 8601 string
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