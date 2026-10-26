import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../app/config/app_config.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = true,
    this.isSubmitting = false,
    this.isOtpSent = false,
    this.errorMessage,
  });

  final UserModel? user;
  final bool isLoading;
  final bool isSubmitting;
  final bool isOtpSent;
  final String? errorMessage;

  bool get isSignedIn => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isSubmitting,
    bool? isOtpSent,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      errorMessage: clearError
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(
      this._auth,
      this._firestore,
      ) : super(const AuthState()) {
    _restoreSession();
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String? _verificationId;
  String? _pendingDisplayName;

  // ------------------------------------------------------------
  // RESTORE FIREBASE SESSION
  // ------------------------------------------------------------

  Future<void> _restoreSession() async {
    try {
      final firebaseUser = _auth.currentUser;

      if (firebaseUser == null) {
        state = const AuthState(
          user: null,
          isLoading: false,
        );
        return;
      }

      await _loadUserProfile(firebaseUser);
    } catch (error) {
      state = AuthState(
        user: null,
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  // ------------------------------------------------------------
  // SEND OTP
  // ------------------------------------------------------------

  Future<void> sendOtp({
    required String phone,
    String? displayName,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      isOtpSent: false,
      clearError: true,
    );

    try {
      final normalizedPhone = _normalizePhone(phone);

      _pendingDisplayName = displayName;

      await _auth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,

        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _signInWithCredential(credential);
          } catch (error) {
            state = AuthState(
              user: state.user,
              isLoading: false,
              isSubmitting: false,
              isOtpSent: false,
              errorMessage: _firebaseError(error),
            );
          }
        },

        verificationFailed: (FirebaseAuthException error) {
          state = AuthState(
            user: state.user,
            isLoading: false,
            isSubmitting: false,
            isOtpSent: false,
            errorMessage: _firebaseError(error),
          );
        },

        codeSent: (
            String verificationId,
            int? resendToken,
            ) {
          _verificationId = verificationId;

          state = state.copyWith(
            isSubmitting: false,
            isOtpSent: true,
            clearError: true,
          );
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (error) {
      state = AuthState(
        user: state.user,
        isLoading: false,
        isSubmitting: false,
        isOtpSent: false,
        errorMessage: _firebaseError(error),
      );
    }
  }

  // ------------------------------------------------------------
  // VERIFY OTP
  // ------------------------------------------------------------

  Future<void> verifyOtp(String otp) async {
    if (_verificationId == null) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Please request a new OTP.',
      );
      return;
    }

    if (otp.length != 6) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Please enter the 6-digit OTP.',
      );
      return;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
    );

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await _signInWithCredential(credential);
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _firebaseError(error),
      );
    }
  }

  // ------------------------------------------------------------
  // FIREBASE SIGN IN
  // ------------------------------------------------------------

  Future<void> _signInWithCredential(
      PhoneAuthCredential credential,
      ) async {
    final result = await _auth.signInWithCredential(credential);

    final firebaseUser = result.user;

    if (firebaseUser == null) {
      throw Exception('Firebase could not create the user session.');
    }

    await _loadUserProfile(firebaseUser);
  }

  // ------------------------------------------------------------
  // FIRESTORE USER PROFILE
  // ------------------------------------------------------------

  Future<void> _loadUserProfile(User firebaseUser) async {
    final userRef =
    _firestore.collection('users').doc(firebaseUser.uid);

    final snapshot = await userRef.get();

    if (!snapshot.exists) {
      final displayName =
          _pendingDisplayName ??
              firebaseUser.displayName ??
              'HomeDoc User';

      await userRef.set({
        'id': firebaseUser.uid,
        'phone': firebaseUser.phoneNumber,
        'displayName': displayName,
        'role': 'patient',
        'isActive': true,
        'isProfileComplete': false,
        'onboardingComplete': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      state = AuthState(
        user: UserModel(
          id: firebaseUser.uid,
          phone: firebaseUser.phoneNumber,
          displayName: displayName,
          role: UserRole.patient,
          isActive: true,
          isProfileComplete: false,
          onboardingComplete: false,
          createdAt: DateTime.now(),
        ),
        isLoading: false,
        isSubmitting: false,
      );

      return;
    }

    final data = snapshot.data()!;

    final role = UserRole.values.firstWhereOrNull(
          (role) => role.name == data['role'],
    ) ??
        UserRole.patient;

    DateTime? createdAt;

    final timestamp = data['createdAt'];

    if (timestamp is Timestamp) {
      createdAt = timestamp.toDate();
    }

    state = AuthState(
      user: UserModel(
        id: firebaseUser.uid,
        phone: data['phone'] as String? ??
            firebaseUser.phoneNumber,
        displayName: data['displayName'] as String? ??
            firebaseUser.displayName ??
            'HomeDoc User',
        role: role,
        isActive: data['isActive'] as bool? ?? true,
        isProfileComplete:
        data['isProfileComplete'] as bool? ?? false,
        onboardingComplete:
        data['onboardingComplete'] as bool? ?? false,
        createdAt: createdAt,
      ),
      isLoading: false,
      isSubmitting: false,
    );
  }


  // ------------------------------------------------------------
  // DOCTOR EMAIL/PASSWORD SIGN IN
  // ------------------------------------------------------------

  Future<void> signInDoctor({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
    );

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw Exception('Unable to authenticate doctor.');
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      final data = snapshot.data();

      // Never create a patient profile for a doctor.
      if (!snapshot.exists ||
          data == null ||
          data['role'] != 'doctor' ||
          data['isActive'] != true) {
        await _auth.signOut();

        state = const AuthState(
          isLoading: false,
          isSubmitting: false,
          errorMessage:
          'Access denied. An active doctor account is required.',
        );
        return;
      }

      DateTime? createdAt;
      final timestamp = data['createdAt'];

      if (timestamp is Timestamp) {
        createdAt = timestamp.toDate();
      }

      // Update shared Riverpod state so GoRouter recognizes
      // the authenticated doctor and allows the dashboard.
      state = AuthState(
        user: UserModel(
          id: firebaseUser.uid,
          phone: data['phone'] as String? ??
              firebaseUser.phoneNumber,
          displayName: data['displayName'] as String? ??
              firebaseUser.displayName ??
              'Doctor',
          role: UserRole.doctor,
          isActive: true,
          isProfileComplete:
          data['isProfileComplete'] as bool? ?? false,
          onboardingComplete:
          data['onboardingComplete'] as bool? ?? false,
          createdAt: createdAt,
        ),
        isLoading: false,
        isSubmitting: false,
      );
    } catch (error) {
      state = AuthState(
        user: null,
        isLoading: false,
        isSubmitting: false,
        errorMessage: _firebaseError(error),
      );
    }
  }


  // ------------------------------------------------------------
  // SIGN OUT
  // ------------------------------------------------------------

  Future<void> signOut() async {
    await _auth.signOut();

    _verificationId = null;
    _pendingDisplayName = null;

    state = const AuthState(
      user: null,
      isLoading: false,
    );
  }

  // ------------------------------------------------------------
  // PHONE FORMAT
  // ------------------------------------------------------------

  String _normalizePhone(String phone) {
    final cleaned = phone.trim();

    if (cleaned.startsWith('+')) {
      return cleaned;
    }

    // HomeDoc currently targets India.
    if (cleaned.length == 10) {
      return '+91$cleaned';
    }

    return cleaned;
  }

  // ------------------------------------------------------------
  // FIREBASE ERROR MESSAGES
  // ------------------------------------------------------------

  String _firebaseError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-phone-number':
          return 'Please enter a valid phone number.';

        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';

        case 'invalid-verification-code':
          return 'The OTP is incorrect. Please try again.';

        case 'session-expired':
          return 'The OTP has expired. Please request a new one.';

        case 'network-request-failed':
          return 'No internet connection. Please check your network.';

        case 'quota-exceeded':
          return 'OTP limit reached. Please try again later.';

        default:
          return error.message ?? 'Authentication failed.';
      }
    }

    return 'Something went wrong. Please try again.';
  }
}

// ------------------------------------------------------------
// FIREBASE PROVIDERS
// ------------------------------------------------------------

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authStateProvider =
StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

final secureStorageProvider = Provider((ref) => SecureStorageService());

final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError(
    'Override in ProviderScope at app startup — see app/app.dart',
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    config: ref.watch(appConfigProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});