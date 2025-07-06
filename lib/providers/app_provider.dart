// This class will hold the state we want to manage and notify listeners when it changes. 

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Import http
import 'dart:convert'; // For JSON decoding
import 'package:smart_civic_app/utils/constants.dart'; // Import AppConstants
import 'package:smart_civic_app/models/user.dart'; // Import User model
import 'package:smart_civic_app/models/issue.dart'; // Import Issue model

class AppProvider with ChangeNotifier { // ChangeNotifier is a mixin that provides the notifyListeners method

  // Private variables to holding state
  int _counter = 0;
  ThemeMode _themeMode = ThemeMode.light;

  String? _authToken; 
  bool _isLoggedIn = false;
  bool _forcedLogout = false; // Track if a forced logout is needed 

  User? _currentUser; // Current user object
  bool _isAdmin = false; // track if the user is an admin

  List<Issue> _issues = []; // List to store fetched issues
  bool _isIssuesLoading = false; // Loading state for issues
  String? _issuesErrorMessage; // Error message for issues fetching

  // getters 
  int get counter => _counter;
  ThemeMode get themeMode => _themeMode;
  String? get authToken => _authToken;
  bool get isLoggedIn => _isLoggedIn;
  bool get forcedLogout => _forcedLogout; 
  User? get currentUser => _currentUser;
  bool get isAdmin => _isAdmin;

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

    if (_isLoggedIn) {
      await fetchUserDetails(); // Fetch user details if already logged in
    }
    notifyListeners(); // Notify listeners of initial state
  }

  // Method to save the token
  Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _authToken = token;
    _isLoggedIn = true;

    await fetchUserDetails(); // Fetch user details after saving token
    notifyListeners();
  }

  // Method to clear the token (logout)
  Future<void> clearAuthToken({bool forceLogout = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _authToken = null;
    _isLoggedIn = false;

    _currentUser = null;
    _isAdmin = false;
    _issues = [];
    _forcedLogout = forceLogout;

    notifyListeners();
  }

  // New method to fetch current user details (including admin status)
  Future<void> fetchUserDetails() async {
    if (_authToken == null) {
      _currentUser = null;
      _isAdmin = false;
      notifyListeners();
      return;
    }

    try {
      print('Fetching user details with token: $_authToken');
      print('Fetching user details from: ${AppConstants.baseUrl}/user/');

      final url = Uri.parse('${AppConstants.baseUrl}/user/');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken', // Assuming Token authentication
        },
      );

      print('Response status (User): ${response.statusCode}');

      if (response.statusCode == 200) {
        print('User details fetched successfully: ${response.body}');
        final List<dynamic> responseList = json.decode(response.body);
       if (responseList.isNotEmpty) {
        final Map<String, dynamic> userJson = responseList[0];  // Use the first user
        _currentUser = User.fromJson(userJson);
        _isAdmin = _currentUser!.isStaff;
      } // Set admin status based on is_staff flag

        print(_isAdmin ? '###User is an admin' : '###User is not an admin');

      } else if (response.statusCode == 401) {
        // Token invalid or expired, force logout
        await clearAuthToken(forceLogout: true);
      } else {
        print('Failed to fetch user details: ${response.statusCode} ${response.body}');
        _currentUser = null;
        _isAdmin = false;
        // Optionally, handle specific errors here
      }
    } catch (e) {
      print('Error fetching user details: $e');
      _currentUser = null;
      _isAdmin = false;
      // Handle network errors
    }
    notifyListeners(); // Notify after user details are loaded/updated
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

      print('Fetching issues from URL: $url'); // Debugging log
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json', // so that server knows we are sending JSON
          'Authorization': 'Bearer $_authToken', // Authorization header with the token, for user authentication
        },
      );

      print('Response status (Issues): ${response.statusCode}'); // Debugging log

      if (response.statusCode == 200) {
        
        print('Issues fetched successfully: ${response.body}'); // Debugging log
        
        // final Map<String, dynamic> responseData = json.decode(response.body);  // parse the JSON response body into a List of dynamic objects
        // responseData.map((json) => Issue.fromJson(json)).toList(): It iterates through each JSON object in the list, uses our Issue.fromJson factory constructor to convert it into an Issue object, and then collects all these Issue objects into a List<Issue>.

        // final List<dynamic> issuesJson = responseData['results']; // ← adapt this key as per your API
        final List<dynamic> issuesJson = json.decode(response.body);
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

  // Day 12: New method to update issue status for admin dashboard
  Future<bool> updateIssueStatus(String issueId, String newStatus) async {
    if (_authToken == null || !_isAdmin) { // Only allow admin to update
      _issuesErrorMessage = 'Access denied. You must be an administrator and logged in to update status.';
      notifyListeners();
      return false;
    }

    print('Updating issue $issueId status to $newStatus'); // Debugging log

    final url = Uri.parse('${AppConstants.baseUrl}/issues/$issueId/');
    try {
      final response = await http.patch( // Use PATCH for partial update
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        // Find the issue in the current list and update its status locally
        // This avoids a full re-fetch which is more efficient.
        // indexWhere returns the index of the first match or -1 if not found.
        int index = _issues.indexWhere((issue) => issue.id == issueId);
        if (index != -1) {  
          // Create a new Issue object with the updated status
          // response.body contains the updated issue as JSON.
          // json.decode(response.body) parses it into a Map<String, dynamic>.
          // Issue.fromJson(...) creates a fresh Issue object from the response.
          _issues[index] = Issue.fromJson(json.decode(response.body));
        }
        notifyListeners(); // Notify UI that a specific issue might have changed
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) { // 403 Forbidden for insufficient permissions
        _issuesErrorMessage = 'Unauthorized to update status. Please log in as an administrator.';
        await clearAuthToken(forceLogout: true); // Token invalid or not admin, force logout
        notifyListeners();
        return false;
      } else {
        final errorData = json.decode(response.body);
        _issuesErrorMessage = 'Failed to update status: ${errorData['detail'] ?? response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _issuesErrorMessage = 'Network error during status update: $e';
      notifyListeners();
      return false;
    }
  }

}