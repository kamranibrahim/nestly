import 'package:firebase_auth/firebase_auth.dart';

String friendlyAuthError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Use a password with at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a few minutes.';
      case 'network-request-failed':
        return 'No network. Check your connection and try again.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled yet for this project.';
      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }
  final text = error.toString();
  if (text.contains('Invite code not found')) {
    return 'That invite code was not found.';
  }
  return 'Something went wrong. Please try again.';
}
