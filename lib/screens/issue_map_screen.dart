import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Import flutter_map
import 'package:latlong2/latlong.dart'; // Import latlong2 for LatLng
import 'package:geolocator/geolocator.dart'; // For current location
import 'package:smart_civic_app/models/issue.dart'; // Import Issue model

class IssueMapScreen extends StatefulWidget {
  final List<Issue> issues;

  const IssueMapScreen({super.key, required this.issues});

  @override
  State<IssueMapScreen> createState() => _IssueMapScreenState();
}

class _IssueMapScreenState extends State<IssueMapScreen> {
  LatLng? _currentLocation;
  // allows programmatic control of the map
  // MapController is used to control the map's camera position, zoom level, etc.
  final MapController _mapController = MapController();
  bool _isLoadingLocation = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  /// Determine the current position of the device.
  /// When the location services are not enabled or permissions
  /// are denied, then it will return an error.
  
  /// _determinePosition(): This method uses geolocator to:
  // Check if location services are enabled.
  // Check/request location permissions.
  // Get the current device position (LatLng).
  // Updates _currentLocation and _isLoadingLocation states.
  // Handles various error scenarios for permissions and service availability.

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _locationError = 'Location services are disabled. Please enable them.';
      setState(() { _isLoadingLocation = false; });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _locationError = 'Location permissions are denied. Cannot show your current location.';
        setState(() { _isLoadingLocation = false; });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _locationError = 'Location permissions are permanently denied. Please enable them from app settings.';
      setState(() { _isLoadingLocation = false; });
      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      Position position = await Geolocator.getCurrentPosition(
        // The deprecated 'desiredAccuracy' has been replaced by 'settings'
        // For high accuracy, you can use LocationSettings with a desired accuracy.
        // You might want to use platform-specific settings for more fine-grained control.
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, // Set desired accuracy here
        ),
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
        _locationError = null;
        _mapController.move(
          _currentLocation!,
          _mapController.camera.zoom, // Correct way in flutter_map v8+
        );
      });
    } catch (e) {
      _locationError = 'Failed to get current location: $e';
      setState(() { _isLoadingLocation = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine initial center of the map
    LatLng initialCenter = const LatLng(27.7172, 85.3240); // Default to Kathmandu, Nepal
    double initialZoom = 13.0;

    if (widget.issues.isNotEmpty && _currentLocation == null) {
      // If no current location but issues exist, center on the first issue
      initialCenter = LatLng(widget.issues.first.latitude, widget.issues.first.longitude);
      initialZoom = 15.0; // Zoom in a bit more if centering on a specific issue
    } else if (_currentLocation != null) {
      initialCenter = _currentLocation!; // Center on current location if available
    }

    // Create markers from issues
    // Marker Creation:
      // It iterates through the widget.issues list.
      // For each issue, it creates a Marker with its LatLng point.
      // The child of the Marker is a Column containing a location_pin icon and a small text label for the issue title. GestureDetector around the child allows for a SnackBar when a marker is tapped.
      // A separate marker for _currentLocation (blue my_location icon) is added if the user's location is successfully obtained.
    List<Marker> markers = widget.issues.map((issue) {
      return Marker(
        point: LatLng(issue.latitude, issue.longitude),
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Issue: ${issue.title}\nStatus: ${issue.status}')),
            );
          },
          child: Column(
            children: [
              Icon(Icons.location_pin, color: Colors.red, size: 40),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  issue.title.length > 15 ? '${issue.title.substring(0, 12)}...' : issue.title,
                  style: TextStyle(color: Colors.white, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    // Add user's current location marker if available
    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 80,
          height: 80,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 40),
        ),
      );
    }

    return Scaffold(
      // Displays loading indicator, error icon, or a button to re-center on the user's location.
      appBar: AppBar(
        title: const Text('Issue Locations on Map'),
        backgroundColor: Colors.blue,
        actions: [
          if (_isLoadingLocation)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.white),
            )
          else if (_locationError != null)
            IconButton(
              icon: const Icon(Icons.error, color: Colors.yellow),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_locationError!)),
                );
              },
            )
          else if (_currentLocation != null)
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: () {
                _mapController.move(
                _currentLocation!,
                _mapController.camera.zoom, 
              );
              },
            ),
        ],
      ),
      body: FlutterMap(
        // controller is used to control the map's camera position, zoom level, etc.
        mapController: _mapController,
        // defines initial center and zoom level of the map
        options: MapOptions(
          // map's initial center prioritizes: user's current location > first issue location > default Kathmandu coordinates.
          initialCenter: initialCenter,
          initialZoom: initialZoom,
          minZoom: 2,
          maxZoom: 18,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all, // same functionality as interactiveFlags in v7
          ),
          onTap: (tapPosition, latLng) {
            print("Map tapped at: $latLng");
          },
          onMapReady: () {
            print("Map is ready");
          },
        ),
        children: [
          //TileLayer: Specifies the map tile provider. https://tile.openstreetmap.org/{z}/{x}/{y}.png is the standard OpenStreetMap tile URL. Crucially, userAgentPackageName is required by OpenStreetMap's Tile Usage Policy. Replace com.yourcompany.smartcivicapp with your actual package name.
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.smartcivicapp', // IMPORTANT for OpenStreetMap policy
          ),
          MarkerLayer(  //This layer displays all the markers created from your issues and the user's current location.
            markers: markers,
          ),
        ],
      ),
    );
  }
}

