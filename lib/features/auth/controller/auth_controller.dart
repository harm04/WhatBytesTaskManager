import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:whatbytes_task_manager/common/snackbar.dart';
import 'package:whatbytes_task_manager/models/user_model.dart';
import 'package:whatbytes_task_manager/providers/auth_provider.dart';

class AuthNotifier extends AsyncNotifier<UserModel?> {
  late AuthController _authController;

  @override
  Future<UserModel?> build() async {
    _authController = ref.read(authControllerProvider);
    return await _initAuthState();
  }

  Future<UserModel?> _initAuthState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userData = await _authController.getUserData(user.uid);
        return userData;
      } catch (e) {
        throw Exception('Failed to get user data: $e');
      }
    }
    return null;
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    state = const AsyncValue.loading();
    try {
      final userData = await _authController.signinWithGoogle(context);
      state = AsyncValue.data(userData);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await _authController.signOut();
    state = const AsyncValue.data(null);
  }
}

class AuthController {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthController() {
    _initializeGoogleSignIn();

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
      } else {
        print('User is signed in!');
      }
    });
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize();
    } catch (e) {
      print('Error initializing Google Sign-In: $e');
    }
  }

  Future<UserModel?> signinWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.authenticate();

      if (account == null) {
        throw Exception('Sign in cancelled');
      }

      final GoogleSignInAuthentication authentication =
          await account.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: authentication.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      if (userCredential.user != null) {
        final user = userCredential.user!;
        final userData = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? '',
          photoURL: user.photoURL ?? '',
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );

        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          await _storeUserData(userData);
          if (context.mounted) {
            showSnackbar(context, 'Welcome! Account created successfully');
          }
        } else {
          await _updateLastLogin(user.uid);
          if (context.mounted) {
            showSnackbar(context, 'Welcome back!');
          }
        }

        return userData;
      }
    } on GoogleSignInException catch (e) {
      if (context.mounted) {
        final errorMessage = switch (e.code) {
          GoogleSignInExceptionCode.canceled => 'Sign in cancelled',
          _ => 'Google sign-in failed: ${e.description}',
        };
        showSnackbar(context, errorMessage);
      }
      throw Exception('Google sign-in failed');
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        showSnackbar(context, e.message ?? 'Firebase authentication failed');
      }
      throw Exception('Firebase authentication failed');
    } catch (e) {
      if (context.mounted) {
        showSnackbar(context, 'Authentication failed: ${e.toString()}');
      }
      throw Exception('Sign in failed');
    }
    return null;
  }

  Future<void> _storeUserData(UserModel userData) async {
    try {
      await _firestore
          .collection('users')
          .doc(userData.uid)
          .set(userData.toMap());
    } catch (e) {
      print('Error storing user data: $e');
      throw Exception('Failed to store user data');
    }
  }

  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLogin': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating last login: $e');
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
    } catch (e) {
      print('Error getting user data: $e');
      throw Exception('Failed to get user data');
    }
    return null;
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}
