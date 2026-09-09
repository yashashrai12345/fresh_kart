import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication state for a single customer.
class AuthProvider extends ChangeNotifier {
  final SupabaseClient _client;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Used to listen for auth state changes (session restore, logout, etc.)
  StreamSubscription<AuthState>? _authSubscription;

  AuthProvider({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client {
    _init();
  }

  // ── Getters ──────────────────────────────────────────────────────────────

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// The phone number of the current authenticated user (e.g. "+919876543210").
  String get currentUserPhone => _currentUser?.phone ?? '';

  /// Phone without country code for display (last 10 digits).
  String get currentUserPhoneShort {
    final phone = currentUserPhone;
    if (phone.startsWith('+91') && phone.length >= 13) {
      return phone.substring(3);
    }
    return phone.replaceAll('+', '');
  }

  // ── Initialization ────────────────────────────────────────────────────────

  void _init() {
    // Restore existing session immediately
    _currentUser = _client.auth.currentUser;

    // Listen for future auth state changes (sign-in, sign-out, token refresh)
    _authSubscription = _client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      debugPrint('[AuthProvider] Auth event: $event');

      switch (event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
        case AuthChangeEvent.userUpdated:
          _currentUser = session?.user;
          break;
        case AuthChangeEvent.signedOut:
        case AuthChangeEvent.userDeleted:
          _currentUser = null;
          break;
        default:
          break;
      }
      notifyListeners();
    });
  }

  // ── OTP Authentication ────────────────────────────────────────────────────

  /// Send OTP to the given Indian phone number (10 digits, no country code).
  /// Prepends +91 automatically.
  Future<bool> sendOTP(String phoneNumber) async {
    _setLoading(true);
    _clearError();

    try {
      final fullPhone = '+91${phoneNumber.trim()}';
      await _client.auth.signInWithOtp(phone: fullPhone);
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(_mapAuthError(e.message));
      return false;
    } catch (e) {
      _setError('Failed to send OTP. Check your internet connection.');
      debugPrint('[AuthProvider] sendOTP error: $e');
      return false;
    }
  }

  /// Verify the OTP entered by the user.
  /// [phoneNumber] is 10 digits (without +91).
  Future<bool> verifyOTP(String phoneNumber, String otp) async {
    _setLoading(true);
    _clearError();

    try {
      final fullPhone = '+91${phoneNumber.trim()}';
      final response = await _client.auth.verifyOTP(
        phone: fullPhone,
        token: otp.trim(),
        type: OtpType.sms,
      );

      if (response.user != null) {
        _currentUser = response.user;
        notifyListeners();
        _setLoading(false);
        return true;
      } else {
        _setError('OTP verification failed. Please try again.');
        return false;
      }
    } on AuthException catch (e) {
      _setError(_mapAuthError(e.message));
      return false;
    } catch (e) {
      _setError('Verification failed. Check your internet connection.');
      debugPrint('[AuthProvider] verifyOTP error: $e');
      return false;
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _client.auth.signOut();
      _currentUser = null;
    } on AuthException catch (e) {
      debugPrint('[AuthProvider] signOut error: ${e.message}');
      // Even if signOut fails on the server, clear locally
      _currentUser = null;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // ── Internal Helpers ──────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  String _mapAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid') && lower.contains('otp')) {
      return 'Incorrect OTP. Please check and try again.';
    }
    if (lower.contains('expired')) {
      return 'OTP has expired. Please request a new one.';
    }
    if (lower.contains('rate limit') || lower.contains('too many')) {
      return 'Too many attempts. Please wait a moment before trying again.';
    }
    if (lower.contains('phone') && lower.contains('not')) {
      return 'Phone authentication is not enabled. Contact support.';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'Network error. Check your internet connection.';
    }
    return message;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
