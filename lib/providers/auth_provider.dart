import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

/// Lightweight representation of the authenticated customer.
class AuthUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;

  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
  });
}

/// Authentication state for Fresh Kart customer.
/// Uses Firebase Google Authentication for 1-tap sign-in.
class AuthProvider extends ChangeNotifier {
  AuthUser? _currentUser;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  StreamSubscription<fb.User?>? _authSubscription;

  AuthProvider() {
    _init();
  }

  // ── Getters ──────────────────────────────────────────────────────────────

  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isGoogleLoading => _isGoogleLoading;
  String? get errorMessage => _errorMessage;

  /// User unique ID.
  String get currentUserId => _currentUser?.id ?? '';

  /// User email address (e.g. "customer@gmail.com").
  String get currentUserEmail => _currentUser?.email ?? '';

  /// Display name from Google profile or fallback.
  String get currentUserName {
    final name = _currentUser?.displayName;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    if (currentUserEmail.isNotEmpty) {
      final prefix = currentUserEmail.split('@').first;
      return prefix.isNotEmpty
          ? '${prefix[0].toUpperCase()}${prefix.substring(1)}'
          : 'Customer';
    }
    return 'Customer';
  }

  /// Profile picture URL from Google.
  String get currentUserAvatar => _currentUser?.photoUrl ?? '';

  /// Phone number if present.
  String get currentUserPhone => _currentUser?.phoneNumber ?? '';

  /// Short phone for display (without +91).
  String get currentUserPhoneShort {
    final phone = currentUserPhone;
    if (phone.startsWith('+91') && phone.length >= 13) {
      return phone.substring(3);
    }
    return phone.replaceAll('+', '');
  }

  // ── Initialization ────────────────────────────────────────────────────────

  void _init() {
    try {
      final fb.User? current = fb.FirebaseAuth.instance.currentUser;
      if (current != null) {
        _currentUser = AuthUser(
          id: current.uid,
          email: current.email ?? '',
          displayName: current.displayName,
          photoUrl: current.photoURL,
          phoneNumber: current.phoneNumber,
        );
        _syncUserMetadata(_currentUser);
      }

      _authSubscription =
          fb.FirebaseAuth.instance.authStateChanges().listen((fb.User? user) {
        if (user != null) {
          _currentUser = AuthUser(
            id: user.uid,
            email: user.email ?? '',
            displayName: user.displayName,
            photoUrl: user.photoURL,
            phoneNumber: user.phoneNumber,
          );
          _syncUserMetadata(_currentUser);
          // Register FCM token whenever auth state is restored
          NotificationService.registerToken(user.uid);
        } else {
          _currentUser = null;
        }
        _isLoading = false;
        _isGoogleLoading = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('[AuthProvider] FirebaseAuth initialization note: $e');
    }
  }

  // ── Firebase Google Sign-In ───────────────────────────────────────────────

  /// Initiates native Google account chooser and authenticates via Firebase.
  Future<bool> signInWithGoogle() async {
    _isGoogleLoading = true;
    _setLoading(true);
    _clearError();

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled Google selection bottom sheet
        _isGoogleLoading = false;
        _setLoading(false);
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final fb.OAuthCredential credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final fb.UserCredential userCredential =
          await fb.FirebaseAuth.instance.signInWithCredential(credential);

      final fb.User? firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        _currentUser = AuthUser(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? googleUser.email,
          displayName: firebaseUser.displayName ?? googleUser.displayName,
          photoUrl: firebaseUser.photoURL ?? googleUser.photoUrl,
          phoneNumber: firebaseUser.phoneNumber,
        );
        _syncUserMetadata(_currentUser);
        // Register FCM token for push notifications
        await NotificationService.registerToken(firebaseUser.uid);
        _isGoogleLoading = false;
        _setLoading(false);
        notifyListeners();
        return true;
      }

      _setError('Failed to retrieve user information from Google.');
      return false;
    } on fb.FirebaseAuthException catch (e) {
      _isGoogleLoading = false;
      _setError(_mapFirebaseError(e.code, e.message));
      return false;
    } catch (e) {
      _isGoogleLoading = false;
      _setError(
          'Google sign-in failed. Please ensure google-services.json is added and SHA-1 is configured in Firebase.');
      debugPrint('[AuthProvider] Firebase Google signIn error: $e');
      return false;
    }
  }

  // ── Optional helper stubs (for test suite backwards compatibility) ─────────

  Future<bool> sendOTP(String phoneNumber) async {
    _setError('Phone OTP is disabled. Please sign in with Google.');
    return false;
  }

  Future<bool> verifyOTP(String phoneNumber, String otp) async {
    _setError('Phone OTP is disabled. Please sign in with Google.');
    return false;
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────

  /// Signs out from both Firebase and GoogleSignIn.
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await fb.FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      _currentUser = null;
    } catch (e) {
      debugPrint('[AuthProvider] signOut error: $e');
      _currentUser = null;
    } finally {
      _setLoading(false);
      _isGoogleLoading = false;
      notifyListeners();
    }
  }

  // ── Internal Helpers ──────────────────────────────────────────────────────

  void _syncUserMetadata(AuthUser? user) {
    if (user == null) return;
    try {
      final name = user.displayName;
      final phone = user.phoneNumber;

      if (name != null &&
          name.trim().isNotEmpty &&
          StorageService.getSavedName().isEmpty) {
        StorageService.saveCustomerDetails(
          name: name.trim(),
          phone: StorageService.getSavedPhone(),
          address: StorageService.getSavedAddress(),
        );
      }

      if (phone != null &&
          phone.isNotEmpty &&
          StorageService.getSavedPhone().isEmpty) {
        final short = phone.startsWith('+91') && phone.length >= 13
            ? phone.substring(3)
            : phone.replaceAll('+', '');
        StorageService.saveCustomerDetails(
          name: StorageService.getSavedName(),
          phone: short,
          address: StorageService.getSavedAddress(),
        );
      }
    } catch (e) {
      debugPrint('[AuthProvider] syncUserMetadata error: $e');
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    _isGoogleLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  String _mapFirebaseError(String code, String? message) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different credential.';
      case 'invalid-credential':
        return 'Invalid Google credentials. Please try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'Google sign-in is not enabled in Firebase Console (Authentication > Sign-in method).';
      default:
        return message ?? 'Authentication failed ($code).';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
