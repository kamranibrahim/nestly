import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

String friendlyAuthError(Object error, [AppLocalizations? l10n]) {
  final t = l10n ?? lookupAppLocalizations(const Locale('en'));
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return t.authErrorInvalidEmail;
      case 'user-disabled':
        return t.authErrorDisabled;
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return t.authErrorBadCredential;
      case 'email-already-in-use':
        return t.authErrorEmailInUse;
      case 'weak-password':
        return t.authErrorWeakPassword;
      case 'too-many-requests':
        return t.authErrorTooMany;
      case 'network-request-failed':
        return t.authErrorNetwork;
      case 'operation-not-allowed':
        return t.authErrorNotAllowed;
      case 'requires-recent-login':
        return t.authErrorRecentLogin;
      default:
        return error.message ?? t.authErrorGeneric;
    }
  }

  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return t.authErrorPermission;
      case 'unavailable':
      case 'deadline-exceeded':
        return t.authErrorNetwork;
      case 'not-found':
        return t.authErrorNotFound;
      case 'already-exists':
        return t.authErrorAlreadyExists;
      default:
        return error.message?.isNotEmpty == true
            ? error.message!
            : t.authErrorGenericCode(error.code);
    }
  }

  final text = error.toString();
  if (text.startsWith('Bad state: ')) {
    return text.substring('Bad state: '.length);
  }
  if (text.contains('Invite code not found')) {
    return t.authErrorInviteMissing;
  }
  if (text.contains('Must be signed in')) {
    return t.authErrorSignInAgain;
  }
  if (text.contains('Enter the email') ||
      text.contains('Fill in your current') ||
      text.contains('don’t match') ||
      text.contains("don't match")) {
    return text;
  }
  return t.authErrorGeneric;
}
