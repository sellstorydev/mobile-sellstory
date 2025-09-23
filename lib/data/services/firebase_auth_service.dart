import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class FirebaseAuthService {
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();

  // Email/Password Authentication
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createUserWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Google Sign-In
  Future<UserCredential> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Sign in cancelled');
      
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  final _rand = Random.secure();
  String _randomNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    return List.generate(length, (_) => charset[_rand.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  Future<void> signInWithAppleFirebase() async {
    // Create a nonce for replay protection
    final rawNonce = _randomNonce();
    final hashedNonce = _sha256ofString(rawNonce);

    // 1) Request Apple credential with nonce
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    // 2) Extract idToken
    final idToken = appleCredential.identityToken;
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'ERROR_MISSING_ID_TOKEN',
        message: 'Apple identityToken is null',
      );
    }

    if (kDebugMode) {
      // Basic diagnostics for troubleshooting
      debugPrint('[Apple Sign-In] idToken length=${idToken.length}');
      debugPrint('[Apple Sign-In] expected nonce (hashed) = $hashedNonce');
      final parts = idToken.split('.');
      if (parts.length == 3) {
        debugPrint('[Apple Sign-In] JWT header/payload present');
        try {
          final payloadB64 = base64Url.normalize(parts[1]);
          final payloadJson = utf8.decode(base64Url.decode(payloadB64));
          final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
          debugPrint('[Apple Sign-In] token.aud = ${payload['aud']}');
          debugPrint('[Apple Sign-In] token.iss = ${payload['iss']}');
          debugPrint('[Apple Sign-In] token.nonce = ${payload['nonce']}');
          debugPrint('[Apple Sign-In] token.email = ${payload['email']}');
          debugPrint(
            '[Apple Sign-In] token.email_verified = ${payload['email_verified']}',
          );
        } catch (e) {
          debugPrint('[Apple Sign-In] Failed to decode JWT payload: $e');
        }
      } else {
        debugPrint(
          '[Apple Sign-In] Unexpected idToken format: parts=${parts.length}',
        );
      }
    }

    // 3) Build OAuth credential with the raw nonce
    final oAuthCredential = OAuthProvider('apple.com').credential(
      idToken: idToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );

    // 4) Sign in to Firebase
    await _auth.signInWithCredential(oAuthCredential);
  }



  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Auth State Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current User
  User? get currentUser => _auth.currentUser;

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;


}
