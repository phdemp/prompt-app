import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class AuthService {
  // Web Client ID from Google Cloud Console (NOT the Android client ID)
  static const String _webClientId =
      '129933002844-2qoui67mu2u1rfvj4be8qbh2bdjvh1e6.apps.googleusercontent.com';

  final _googleSignIn = GoogleSignIn(
    serverClientId: _webClientId,
    scopes: ['email', 'profile'],
  );

  /// Signs in with Google and returns the ID token.
  /// Returns null if the user cancels sign-in.
  Future<String?> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null; // User cancelled

    final authentication = await account.authentication;
    final idToken = authentication.idToken;
    if (idToken == null) {
      throw Exception('Failed to retrieve ID token from Google.');
    }
    return idToken;
  }

  /// Sends the Google ID token to the backend and returns {token, user}.
  Future<Map<String, dynamic>> sendTokenToBackend(String idToken) async {
    final response = await http.post(
      Uri.parse('$kApiBaseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Authentication failed. Please try again.');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
