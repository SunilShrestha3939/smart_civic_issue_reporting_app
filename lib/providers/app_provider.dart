// This class will hold the state we want to manage and notify listeners when it changes. 

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Import http
import 'dart:convert'; // For JSON decoding
import 'package:smart_civic_app/models/issue.dart'; // Import Issue model
import 'package:smart_civic_app/utils/constants.dart'; // Import AppConstants

class AppProvider with ChangeNotifier { // ChangeNotifier is a mixin that provides the notifyListeners method

  // Private variables to holding state
  int _counter = 0;
  ThemeMode _themeMode = ThemeMode.light;

  String? _authToken; 
  bool _isLoggedIn = false; 

  List<Issue> _issues = []; // New: List to store fetched issues
  bool _isIssuesLoading = false; // New: Loading state for issues
  String? _issuesErrorMessage; // New: Error message for issues fetching

  // getters 
  int get counter => _counter;
  ThemeMode get themeMode => _themeMode;
  String? get authToken => _authToken;
  bool get isLoggedIn => _isLoggedIn;

  List<Issue> get issues => _issues; // Getter for issues
  bool get isIssuesLoading => _isIssuesLoading; // Getter for loading state
  String? get issuesErrorMessage => _issuesErrorMessage; // Getter for error message

  AppProvider() {
    _loadAuthToken(); //checks if a token exists from a previous session.
  }

  // Method to load the token from SharedPreferences
  Future<void> _loadAuthToken() async {
    //SharedPreferences.getInstance(): Asynchronously gets an instance of SharedPreferences, which is used for simple key-value storage locally on the device.
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _isLoggedIn = _authToken != null;
    notifyListeners(); // Notify listeners that login status might have changed
  }

  // Method to save the token
  Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _authToken = token;
    _isLoggedIn = true;
    notifyListeners();
  }

  // Method to clear the token (logout)
  Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _authToken = null;
    _isLoggedIn = false;
    _issues = [];
    notifyListeners();
  }

  // methods to modify state and notify listeners
  void incrementCounter() {
    _counter++;
    notifyListeners(); // provided by [ChangeNotifier], tells all registered listeners (widgets using this provider) that something has changed, prompting them to rebuild.
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Notify all widgets listening to this provider
  }

  // New method to fetch issues from the backend
  Future<void> fetchIssues({String? status, bool? userSpecific}) async {
    if (_authToken == null) {
      _issuesErrorMessage = 'Not authenticated. Please log in.';
      _issues = [];
      notifyListeners();
      return;
    }

    _isIssuesLoading = true;
    _issuesErrorMessage = null;
    notifyListeners(); // Notify listeners that loading has started ie show a loading spinner

    try {
      String url = '${AppConstants.baseUrl}/issues/';
        Map<String, String> queryParams = {}; //map to hold query parameters

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (userSpecific == true) {
        queryParams['user_specific'] = 'true'; 
      }

      //url += '?${queryParams.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&')}';: This line correctly constructs the URL with query parameters. 
      //Uri.encodeQueryComponent is important to handle special characters in parameter values.
      // it wraps all query parameters into a single string, ensuring that the URL is properly formatted. like ?status=open&user_specific=true
      if (queryParams.isNotEmpty) {
        // final uri = Uri.parse('${AppConstants.baseUrl}/issues/').replace(queryParameters: queryParams);
        url += '?${Uri.encodeQueryComponent(queryParams.entries.map((e) => '${e.key}=${e.value}').join('&'))}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json', // so that server knows we are sending JSON
          'Authorization': 'Token $_authToken', // Authorization header with the token, for user authentication
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);  // parse the JSON response body into a List of dynamic objects
        // responseData.map((json) => Issue.fromJson(json)).toList(): It iterates through each JSON object in the list, uses our Issue.fromJson factory constructor to convert it into an Issue object, and then collects all these Issue objects into a List<Issue>.
        final List<dynamic> issuesJson = responseData['results']; // ← adapt this key as per your API
        _issues = issuesJson.map((json) => Issue.fromJson(json)).toList();
        _issuesErrorMessage = null;
      } else if (response.statusCode == 401) {
        _issuesErrorMessage = 'Unauthorized. Please log in again.';
        _issues = [];
        // Optionally, force logout if token is invalid
        // await clearAuthToken();
      } else {
        final errorData = json.decode(response.body);
        _issuesErrorMessage = 'Failed to load issues: ${errorData['detail'] ?? response.statusCode}';
        _issues = [];
      }
    } catch (e) {
      _issuesErrorMessage = 'Network error: $e';
      _issues = [];
    } finally {
      _isIssuesLoading = false;
      notifyListeners(); // ensure the UI updates regardless of success or failure.
    }
  }
}