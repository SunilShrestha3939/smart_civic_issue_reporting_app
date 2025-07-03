import 'dart:io'; // Import for File class

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:geolocator/geolocator.dart'; 

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
    'Road Issue',
    'Sanitation',
    'Streetlight',
    'Water Supply',
    'Public Safety',
    'Other'
  ];

  File? _pickedImage; // hold the File object for the selected image.
  Position? _currentPosition; //The geolocator package returns a Position object, which contains latitude, longitude, timestamp, etc.

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitIssue() {
    if (_formKey.currentState!.validate()) {
      // For now, just print the values.
      // On a later day, we will integrate with the backend here.
      print('Submitting Issue:');
      print('Title: ${_titleController.text}');
      print('Description: ${_descriptionController.text}');
      print('Category: ${_selectedCategory ?? 'Not Selected'}');
      print('Image Path: ${_pickedImage?.path ?? 'No Image'}'); // Access path from File
      print('Location: ${_currentPosition != null ? 'Lat: ${_currentPosition!.latitude}, Lng: ${_currentPosition!.longitude}' : 'No Location'}');

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Issue submitted successfully! (Frontend only)')),
      );

      // Clear the form fields after submission
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedCategory = null; // Reset dropdown
        _pickedImage = null; // Clear image preview
        _currentPosition = null; // Clear location
      });
      // Optionally navigate back to the issues list
      // Navigator.of(context).pop(); // If this was a separate screen pushed on stack
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
            ElevatedButton(
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