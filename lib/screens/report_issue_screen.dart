import 'dart:io';
import 'dart:convert'; // For json.encode if needed for non-file parts
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http; // Import http
import 'package:provider/provider.dart';
import 'package:smart_civic_app/providers/app_provider.dart';
import 'package:smart_civic_app/utils/constants.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedCategory; // Holds the selected category value
  final List<String> _categories = [
    'potholes',
    'traffic_light',
    'streetlight',
    'water_leakage',
    'garbage',
    'Other'
  ];

  File? _pickedImage; // hold the File object for the selected image.
  Position? _currentPosition; //The geolocator package returns a Position object, which contains latitude, longitude, timestamp, etc.

  bool _isLoading = false; // To manage loading state if needed

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- Submit Issue to Backend ---
  void _submitIssue() async {
    if (_formKey.currentState!.validate()) {
      if (_pickedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add a photo of the issue.')),
        );
        return;
      }
      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please get your current location.')),
        );
        return;
      }

      setState(() {
        _isLoading = true; // Show loading indicator
      });

      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final String? authToken = appProvider.authToken;

      if (authToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are not logged in. Please log in to report issues.')),
        );
        setState(() { _isLoading = false; });
        return;
      }

      final url = Uri.parse('${AppConstants.baseUrl}/issues/'); // Your Django issues endpoint

      // Create a multipart request for sending files (image and location) and text (description, title, category)
      var request = http.MultipartRequest('POST', url);

      // Add Authorization header
      //This adds the authorization header with the token. for authorization request 
      request.headers['Authorization'] = 'Bearer $authToken'; // Or 'Bearer $authToken' for JWT

      // Add text fields to the request
      // request.fields['title'] = _titleController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['issue_type'] = _selectedCategory!; // ! indicates it won't be null due to validator
      request.fields['latitude'] = _currentPosition!.latitude.toString();
      request.fields['longitude'] = _currentPosition!.longitude.toString();
      request.fields['reported_by'] = '1'; // Assuming '1' is the ID of the user reporting defaultly, you can change this to the actual user ID if needed.

      // Add the image file to the request
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // This key 'photo' must match the field name in your Django model/serializer
          _pickedImage!.path,
          filename: _pickedImage!.path.split('/').last,
        ),
      );

      try {
        // await request.send(): Sends the multipart request. This returns a StreamedResponse, which needs to be converted to a regular Response to get the body.
        final streamedResponse = await request.send(); // Send the multipart request
        final response = await http.Response.fromStream(streamedResponse); // Converts the streamed response to a standard http.Response object, allowing you to access statusCode and body.

        if (response.statusCode == 201) { // show a success message and clear the form.
          final responseData = json.decode(response.body);
          print('Issue reported: $responseData');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Issue reported successfully!')),
          );

          // Clear form and reset state
          _titleController.clear();
          _descriptionController.clear();
          setState(() {
            _selectedCategory = null;
            _pickedImage = null;
            _currentPosition = null;
          });
          // Optionally, navigate to the list of issues
          // Navigator.of(context).pop(); // if this screen was pushed
        } else {
          final errorData = json.decode(response.body);
          print('Error reporting issue: ${response.statusCode} - $errorData');
          String errorMessage = 'Failed to report issue. Please try again.';
          if (errorData.containsKey('non_field_errors')) {
            errorMessage = errorData['non_field_errors'][0];
          } else if (errorData.containsKey('detail')) {
            errorMessage = errorData['detail'];
          } else if (errorData.isNotEmpty) {
            errorMessage = errorData.values.first is List ? errorData.values.first[0] : errorData.values.first;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } catch (e) {
        print('Network/Other Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false; // Hide loading
        });
      }
    }
  }

  // --- Image Picker Implementation ---
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker(); //creates an instance of ImagePicker
    final XFile? image = await picker.pickImage(source: ImageSource.gallery); // Or .camera
    if (image != null) {
      setState(() {
        _pickedImage = File(image.path); // Convert XFile to File
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image selected: ${image.name}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected.')),
      );
    }
  }

  // --- Geolocation Implementation ---
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled. Please enable them.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')),
      );
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
        _currentPosition = position;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location fetched successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // So the form is scrollable if keyboard appears
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Issue Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.short_text),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title for the issue';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5, // Allow multiple lines for description
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true, // Aligns label to top for multiline
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description for the issue';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              hint: const Text('Select a category'),
              items: _categories.map((String category) {  // used map to convert list of Strings into DropdownMenuItems
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Placeholder for Image Picker
            // ListTile: act as tappable areas for "Add Photo" and "Get Current Location."
            // _pickedImagePath: Holds the path of the selected image, if any.
            // _currentLocation: Holds the current location string, if any.
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: Text(_pickedImage != null ? 'Image Selected' : 'Add Photo'),
              trailing: _pickedImage != null
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.arrow_forward_ios),
              onTap: _pickImage,
              tileColor: Colors.blue.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            if (_pickedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Container(
                  height: 200, // Adjusted height for image preview
                  alignment: Alignment.center,
                  child: Image.file(
                    _pickedImage!, // Display the actual picked image
                    fit: BoxFit.cover, // Cover the box while maintaining aspect ratio
                    width: double.infinity,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            // Placeholder for Geolocation
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.blue),
              title: Text(_currentPosition != null
                  ? 'Location: Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}'
                  : 'Get Current Location'),
              trailing: _currentPosition != null
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.arrow_forward_ios),
              onTap: _getCurrentLocation,
              tileColor: Colors.blue.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 40),
             _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitIssue,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
              child: const Text(
                'Submit Issue',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}