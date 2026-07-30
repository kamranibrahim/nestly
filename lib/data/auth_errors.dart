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
      case 'requires-recent-login':
        return 'For security, enter your password again to continue.';
      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }

  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'Cloud access was denied. Sign out, sign in again, or check Firestore rules.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'No network. Check your connection and try again.';
      case 'not-found':
        return 'That nest or invite was not found.';
      case 'already-exists':
        return 'That invite code is already in use. Try again.';
      default:
        return error.message?.isNotEmpty == true
            ? error.message!
            : 'Something went wrong (${error.code}). Please try again.';
    }
  }

  final text = error.toString();
  if (text.startsWith('Bad state: ')) {
    return text.substring('Bad state: '.length);
  }
  if (text.contains('Invite code not found')) {
    return 'That invite code was not found.';
  }
  if (text.contains('Must be signed in')) {
    return 'Please sign in again, then start your nest.';
  }
  if (text.contains('Enter the email') ||
      text.contains('Fill in your current') ||
      text.contains('don’t match') ||
      text.contains("don't match")) {
    return text;
  }
  return 'Something went wrong. Please try again.';
}
