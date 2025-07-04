// This class will hold the state we want to manage and notify listeners when it changes. 

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider with ChangeNotifier { // ChangeNotifier is a mixin that provides the notifyListeners method

  // Private variables to holding state
  int _counter = 0;
  ThemeMode _themeMode = ThemeMode.light;

  String? _authToken; 
  bool _isLoggedIn = false; 

  // getters 
  int get counter => _counter;
  ThemeMode get themeMode => _themeMode;
  String? get authToken => _authToken;
  bool get isLoggedIn => _isLoggedIn;

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

  // In a real app, you might have methods for:
  // - User authentication status (isLoggedIn, user data)
  // - List of issues (fetched from backend)
  // - App settings
}