import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Casaio'**
  String get appName;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get tabCalendar;

  /// No description provided for @tabTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tabTasks;

  /// No description provided for @tabShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get tabShop;

  /// No description provided for @tabNest.
  ///
  /// In en, this message translates to:
  /// **'Nest'**
  String get tabNest;

  /// No description provided for @navMain.
  ///
  /// In en, this message translates to:
  /// **'Main navigation'**
  String get navMain;

  /// No description provided for @addToCasaio.
  ///
  /// In en, this message translates to:
  /// **'Add to Casaio'**
  String get addToCasaio;

  /// No description provided for @addEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get addEvent;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get addTask;

  /// No description provided for @addShoppingItem.
  ///
  /// In en, this message translates to:
  /// **'Shopping item'**
  String get addShoppingItem;

  /// No description provided for @addScan.
  ///
  /// In en, this message translates to:
  /// **'Scan receipt / invite'**
  String get addScan;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @commonOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get commonOpen;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonLoad.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get commonLoad;

  /// No description provided for @commonPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get commonPaid;

  /// No description provided for @commonView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get commonView;

  /// No description provided for @commonPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get commonPlan;

  /// No description provided for @commonReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get commonReview;

  /// No description provided for @commonRestock.
  ///
  /// In en, this message translates to:
  /// **'Restock'**
  String get commonRestock;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get commonNotes;

  /// No description provided for @commonTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get commonTitle;

  /// No description provided for @commonAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get commonAmount;

  /// No description provided for @commonCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get commonCategory;

  /// No description provided for @commonLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get commonLocation;

  /// No description provided for @commonSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get commonSettings;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App language for this device'**
  String get languageSubtitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authWelcomeBack;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your family account'**
  String get authCreateAccount;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailHint;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordHint;

  /// No description provided for @authNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get authNameHint;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSignUp;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authHaveAccount;

  /// No description provided for @authNeedAccount.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get authNeedAccount;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get authInvalidEmail;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get authPasswordTooShort;

  /// No description provided for @authEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name.'**
  String get authEnterName;

  /// No description provided for @authCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check sign-in.'**
  String get authCheckFailed;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That email address looks invalid.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get authErrorDisabled;

  /// No description provided for @authErrorBadCredential.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get authErrorBadCredential;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists for that email.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Use a password with at least 6 characters.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in a few minutes.'**
  String get authErrorTooMany;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No network. Check your connection and try again.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Email sign-in is not enabled yet for this project.'**
  String get authErrorNotAllowed;

  /// No description provided for @authErrorRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'For security, enter your password again to continue.'**
  String get authErrorRecentLogin;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrorGeneric;

  /// No description provided for @authErrorPermission.
  ///
  /// In en, this message translates to:
  /// **'Cloud access was denied. Sign out, sign in again, or check Firestore rules.'**
  String get authErrorPermission;

  /// No description provided for @authErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'That nest or invite was not found.'**
  String get authErrorNotFound;

  /// No description provided for @authErrorAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'That invite code is already in use. Try again.'**
  String get authErrorAlreadyExists;

  /// No description provided for @authErrorGenericCode.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong ({code}). Please try again.'**
  String authErrorGenericCode(String code);

  /// No description provided for @authErrorInviteMissing.
  ///
  /// In en, this message translates to:
  /// **'That invite code was not found.'**
  String get authErrorInviteMissing;

  /// No description provided for @authErrorSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again, then start your nest.'**
  String get authErrorSignInAgain;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Perfectly Organize\nYour Family Life'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Manage events, chores, groceries, and daily plans in one simple shared place.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Quiet help when\nyou scan'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'Casaio’s AI only assists when you scan a receipt or invite — it suggests an event or expense. It doesn’t run your nest for you.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Stay Connected\nTogether'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'Share plans, assign tasks, and keep your whole family perfectly in sync.'**
  String get onboardingBody3;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @nestSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Start your nest'**
  String get nestSetupTitle;

  /// No description provided for @settingsTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get settingsTimeline;

  /// No description provided for @settingsTimelineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recent nest activity across the family'**
  String get settingsTimelineSubtitle;

  /// No description provided for @settingsLocator.
  ///
  /// In en, this message translates to:
  /// **'Locator'**
  String get settingsLocator;

  /// No description provided for @settingsLocatorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live nest map · opt-in last-known pins'**
  String get settingsLocatorSubtitle;

  /// No description provided for @settingsPassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsPassword;

  /// No description provided for @settingsPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Still signed in? Update it here'**
  String get settingsPasswordSubtitle;

  /// No description provided for @settingsTomorrowPreview.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow preview'**
  String get settingsTomorrowPreview;

  /// No description provided for @settingsTomorrowPreviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quiet evening reminder for tomorrow’s bills, care, and school'**
  String get settingsTomorrowPreviewSubtitle;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get settingsPrivacy;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About Casaio'**
  String get settingsAbout;

  /// No description provided for @settingsShowcase.
  ///
  /// In en, this message translates to:
  /// **'Load App Store showcase'**
  String get settingsShowcase;

  /// No description provided for @settingsShowcaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Debug/profile only — not in App Store builds'**
  String get settingsShowcaseSubtitle;

  /// No description provided for @settingsCrash.
  ///
  /// In en, this message translates to:
  /// **'Force test crash'**
  String get settingsCrash;

  /// No description provided for @settingsCrashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Crashlytics in Firebase console'**
  String get settingsCrashSubtitle;

  /// No description provided for @showcaseConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Load showcase data?'**
  String get showcaseConfirmTitle;

  /// No description provided for @showcaseConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Replaces nest content with polished App Store sample data (family, calendar, tasks, shopping, vault, and more), then syncs.'**
  String get showcaseConfirmBody;

  /// No description provided for @showcaseLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading showcase data…'**
  String get showcaseLoading;

  /// No description provided for @showcaseReady.
  ///
  /// In en, this message translates to:
  /// **'Showcase data ready — open Home to review'**
  String get showcaseReady;

  /// No description provided for @showcaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load showcase: {error}'**
  String showcaseFailed(String error);

  /// No description provided for @roleForMember.
  ///
  /// In en, this message translates to:
  /// **'Role for {name}'**
  String roleForMember(String name);

  /// No description provided for @roleAdult.
  ///
  /// In en, this message translates to:
  /// **'Adult'**
  String get roleAdult;

  /// No description provided for @roleCoParent.
  ///
  /// In en, this message translates to:
  /// **'Co-parent'**
  String get roleCoParent;

  /// No description provided for @roleKid.
  ///
  /// In en, this message translates to:
  /// **'Kid'**
  String get roleKid;

  /// No description provided for @roleGrandparent.
  ///
  /// In en, this message translates to:
  /// **'Grandparent'**
  String get roleGrandparent;

  /// No description provided for @roleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get roleMember;

  /// No description provided for @filterAdults.
  ///
  /// In en, this message translates to:
  /// **'Adults'**
  String get filterAdults;

  /// No description provided for @filterKids.
  ///
  /// In en, this message translates to:
  /// **'Kids'**
  String get filterKids;

  /// No description provided for @filterGrandparents.
  ///
  /// In en, this message translates to:
  /// **'Grandparents'**
  String get filterGrandparents;

  /// No description provided for @careViewDue.
  ///
  /// In en, this message translates to:
  /// **'Due list'**
  String get careViewDue;

  /// No description provided for @careViewCategory.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get careViewCategory;

  /// No description provided for @careCategoryElder.
  ///
  /// In en, this message translates to:
  /// **'Elder'**
  String get careCategoryElder;

  /// No description provided for @careCategoryHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get careCategoryHome;

  /// No description provided for @careCategoryPet.
  ///
  /// In en, this message translates to:
  /// **'Pet'**
  String get careCategoryPet;

  /// No description provided for @careCategoryCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get careCategoryCar;

  /// No description provided for @schoolKindSchool.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get schoolKindSchool;

  /// No description provided for @schoolKindSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get schoolKindSports;

  /// No description provided for @schoolKindPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get schoolKindPickup;

  /// No description provided for @schoolKindClub.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get schoolKindClub;

  /// No description provided for @shopProduce.
  ///
  /// In en, this message translates to:
  /// **'Produce'**
  String get shopProduce;

  /// No description provided for @shopDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy'**
  String get shopDairy;

  /// No description provided for @shopMeat.
  ///
  /// In en, this message translates to:
  /// **'Meat'**
  String get shopMeat;

  /// No description provided for @shopBakery.
  ///
  /// In en, this message translates to:
  /// **'Bakery'**
  String get shopBakery;

  /// No description provided for @shopPantry.
  ///
  /// In en, this message translates to:
  /// **'Pantry'**
  String get shopPantry;

  /// No description provided for @shopFrozen.
  ///
  /// In en, this message translates to:
  /// **'Frozen'**
  String get shopFrozen;

  /// No description provided for @shopHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get shopHousehold;

  /// No description provided for @shopGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get shopGeneral;

  /// No description provided for @shopMeals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get shopMeals;

  /// No description provided for @expenseGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get expenseGroceries;

  /// No description provided for @expenseTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get expenseTransport;

  /// No description provided for @expenseKids.
  ///
  /// In en, this message translates to:
  /// **'Kids'**
  String get expenseKids;

  /// No description provided for @expenseHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get expenseHome;

  /// No description provided for @expenseDining.
  ///
  /// In en, this message translates to:
  /// **'Dining'**
  String get expenseDining;

  /// No description provided for @expenseHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get expenseHealth;

  /// No description provided for @expenseGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get expenseGeneral;

  /// No description provided for @vaultFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get vaultFamily;

  /// No description provided for @vaultHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get vaultHealth;

  /// No description provided for @vaultHouse.
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get vaultHouse;

  /// No description provided for @vaultWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get vaultWork;

  /// No description provided for @vaultCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get vaultCar;

  /// No description provided for @vaultFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get vaultFinance;

  /// No description provided for @vaultIds.
  ///
  /// In en, this message translates to:
  /// **'IDs'**
  String get vaultIds;

  /// No description provided for @vaultAllFolders.
  ///
  /// In en, this message translates to:
  /// **'All folders'**
  String get vaultAllFolders;

  /// No description provided for @vaultDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get vaultDocuments;

  /// No description provided for @taskDueToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get taskDueToday;

  /// No description provided for @taskDueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get taskDueTomorrow;

  /// No description provided for @taskDueIn7Days.
  ///
  /// In en, this message translates to:
  /// **'In 7 days'**
  String get taskDueIn7Days;

  /// No description provided for @uploadLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get uploadLocal;

  /// No description provided for @uploadUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get uploadUploading;

  /// No description provided for @uploadSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get uploadSynced;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get uploadFailed;

  /// No description provided for @timelineAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get timelineAll;

  /// No description provided for @timelineTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get timelineTasks;

  /// No description provided for @timelineLists.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get timelineLists;

  /// No description provided for @timelineCare.
  ///
  /// In en, this message translates to:
  /// **'Care'**
  String get timelineCare;

  /// No description provided for @timelineMeals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get timelineMeals;

  /// No description provided for @timelineVault.
  ///
  /// In en, this message translates to:
  /// **'Vault'**
  String get timelineVault;

  /// No description provided for @timelineSchool.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get timelineSchool;

  /// No description provided for @timelineFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get timelineFamily;

  /// No description provided for @timelineOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get timelineOther;

  /// No description provided for @timelinePostLabel.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get timelinePostLabel;

  /// No description provided for @timelineAnnouncementLabel.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get timelineAnnouncementLabel;

  /// No description provided for @timelineActivityLabel.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get timelineActivityLabel;

  /// No description provided for @timelinePostHint.
  ///
  /// In en, this message translates to:
  /// **'Share something with the family…'**
  String get timelinePostHint;

  /// No description provided for @timelinePostButton.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get timelinePostButton;

  /// No description provided for @timelineCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get timelineCommentLabel;

  /// No description provided for @timelineCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment…'**
  String get timelineCommentHint;

  /// No description provided for @timelineCommentButton.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get timelineCommentButton;

  /// No description provided for @timelineCommentsToggle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Comments} =1{1 comment} other{{count} comments}}'**
  String timelineCommentsToggle(int count);

  /// No description provided for @timelinePinnedLabel.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get timelinePinnedLabel;

  /// No description provided for @timelinePinAction.
  ///
  /// In en, this message translates to:
  /// **'Pin to top'**
  String get timelinePinAction;

  /// No description provided for @timelineUnpinAction.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get timelineUnpinAction;

  /// No description provided for @timelineAnnouncementHint.
  ///
  /// In en, this message translates to:
  /// **'Share an announcement with the family…'**
  String get timelineAnnouncementHint;

  /// No description provided for @timelineAnnounceButton.
  ///
  /// In en, this message translates to:
  /// **'Announce'**
  String get timelineAnnounceButton;

  /// No description provided for @needCareDue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 care item due} other{{count} care items due}}'**
  String needCareDue(int count);

  /// No description provided for @needCareDetail.
  ///
  /// In en, this message translates to:
  /// **'Mark done when finished'**
  String get needCareDetail;

  /// No description provided for @needSchoolDue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 school / pickup due} other{{count} school / pickups due}}'**
  String needSchoolDue(int count);

  /// No description provided for @needSchoolDetail.
  ///
  /// In en, this message translates to:
  /// **'Confirm who’s covering the run'**
  String get needSchoolDetail;

  /// No description provided for @needBillsDue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bill due soon} other{{count} bills due soon}}'**
  String needBillsDue(int count);

  /// No description provided for @needBillsDetail.
  ///
  /// In en, this message translates to:
  /// **'Mark paid when you’ve settled them'**
  String get needBillsDetail;

  /// No description provided for @needTasksOpen.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 open task} other{{count} open tasks}}'**
  String needTasksOpen(int count);

  /// No description provided for @needTasksDetail.
  ///
  /// In en, this message translates to:
  /// **'Finish one now or open the list'**
  String get needTasksDetail;

  /// No description provided for @needShoppingLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 grocery item left} other{{count} grocery items left}}'**
  String needShoppingLeft(int count);

  /// No description provided for @needShoppingDetail.
  ///
  /// In en, this message translates to:
  /// **'Check them off on the shared list'**
  String get needShoppingDetail;

  /// No description provided for @needShoppingOpenList.
  ///
  /// In en, this message translates to:
  /// **'Open list'**
  String get needShoppingOpenList;

  /// No description provided for @needRestock.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Restock 1 usual item} other{Restock {count} usual items}}'**
  String needRestock(int count);

  /// No description provided for @needRestockDetail.
  ///
  /// In en, this message translates to:
  /// **'Based on what you buy often'**
  String get needRestockDetail;

  /// No description provided for @needVaultOne.
  ///
  /// In en, this message translates to:
  /// **'1 document expires soon'**
  String get needVaultOne;

  /// No description provided for @needVaultMany.
  ///
  /// In en, this message translates to:
  /// **'{count} documents expire soon'**
  String needVaultMany(int count);

  /// No description provided for @needVaultDetail.
  ///
  /// In en, this message translates to:
  /// **'Passports, insurance, or licenses — renew before they lapse'**
  String get needVaultDetail;

  /// No description provided for @needDinnerMissing.
  ///
  /// In en, this message translates to:
  /// **'No dinner planned today'**
  String get needDinnerMissing;

  /// No description provided for @needDinnerMissingDetail.
  ///
  /// In en, this message translates to:
  /// **'Add a meal — ingredients can go to the list'**
  String get needDinnerMissingDetail;

  /// No description provided for @needDinnerPlanned.
  ///
  /// In en, this message translates to:
  /// **'Dinner: {title}'**
  String needDinnerPlanned(String title);

  /// No description provided for @needDinnerPlannedDetail.
  ///
  /// In en, this message translates to:
  /// **'Push ingredients to the grocery list'**
  String get needDinnerPlannedDetail;

  /// No description provided for @needQuietDay.
  ///
  /// In en, this message translates to:
  /// **'Quiet day'**
  String get needQuietDay;

  /// No description provided for @needQuietDetail.
  ///
  /// In en, this message translates to:
  /// **'Nothing urgent — a good time to plan ahead'**
  String get needQuietDetail;

  /// No description provided for @needEventsToday.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 event today} other{{count} events today}}'**
  String needEventsToday(int count);

  /// No description provided for @needEventsDetail.
  ///
  /// In en, this message translates to:
  /// **'Open Calendar so nobody is surprised'**
  String get needEventsDetail;

  /// No description provided for @screenCare.
  ///
  /// In en, this message translates to:
  /// **'Care'**
  String get screenCare;

  /// No description provided for @screenSchool.
  ///
  /// In en, this message translates to:
  /// **'School & activities'**
  String get screenSchool;

  /// No description provided for @screenMeals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get screenMeals;

  /// No description provided for @screenExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get screenExpenses;

  /// No description provided for @screenVault.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get screenVault;

  /// No description provided for @screenEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get screenEmergency;

  /// No description provided for @screenTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get screenTimeline;

  /// No description provided for @screenLocator.
  ///
  /// In en, this message translates to:
  /// **'Locator'**
  String get screenLocator;

  /// No description provided for @screenPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get screenPrivacy;

  /// No description provided for @screenAbout.
  ///
  /// In en, this message translates to:
  /// **'About Casaio'**
  String get screenAbout;

  /// No description provided for @screenShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get screenShopping;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Family calendar'**
  String get calendarTitle;

  /// No description provided for @calendarTitleAgenda.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get calendarTitleAgenda;

  /// No description provided for @calendarBrowseMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get calendarBrowseMonth;

  /// No description provided for @calendarBrowseWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get calendarBrowseWeek;

  /// No description provided for @calendarBrowseAgenda.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get calendarBrowseAgenda;

  /// No description provided for @calendarAgendaUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Next 7 days'**
  String get calendarAgendaUpcoming;

  /// No description provided for @eventRecurrence.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get eventRecurrence;

  /// No description provided for @eventRecurrenceNone.
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get eventRecurrenceNone;

  /// No description provided for @eventRecurrenceDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get eventRecurrenceDaily;

  /// No description provided for @eventRecurrenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get eventRecurrenceWeekly;

  /// No description provided for @eventRecurrenceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get eventRecurrenceMonthly;

  /// No description provided for @eventRecurrenceUntil.
  ///
  /// In en, this message translates to:
  /// **'Repeat until (optional)'**
  String get eventRecurrenceUntil;

  /// No description provided for @calendarEditSeriesHint.
  ///
  /// In en, this message translates to:
  /// **'Changes apply to the whole repeating series.'**
  String get calendarEditSeriesHint;

  /// No description provided for @homeTodaySnapshot.
  ///
  /// In en, this message translates to:
  /// **'Today snapshot'**
  String get homeTodaySnapshot;

  /// No description provided for @homeHello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get homeHello;

  /// No description provided for @syncNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get syncNotYet;

  /// No description provided for @syncJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get syncJustNow;

  /// No description provided for @syncMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String syncMinutesAgo(int count);

  /// No description provided for @syncHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String syncHoursAgo(int count);

  /// No description provided for @syncDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String syncDaysAgo(int count);

  /// No description provided for @syncKeptOne.
  ///
  /// In en, this message translates to:
  /// **'Kept 1 local edit while syncing'**
  String get syncKeptOne;

  /// No description provided for @syncKeptMany.
  ///
  /// In en, this message translates to:
  /// **'Kept {count} local edits while syncing'**
  String syncKeptMany(int count);

  /// No description provided for @syncFailedNetwork.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t sync — check your connection. Changes stay on this device.'**
  String get syncFailedNetwork;

  /// No description provided for @syncFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t sync. Changes stay on this device — retry from Nest.'**
  String get syncFailedGeneric;

  /// No description provided for @notifChannelGeneral.
  ///
  /// In en, this message translates to:
  /// **'Casaio'**
  String get notifChannelGeneral;

  /// No description provided for @notifChannelGeneralDesc.
  ///
  /// In en, this message translates to:
  /// **'Family reminders and updates'**
  String get notifChannelGeneralDesc;

  /// No description provided for @notifChannelPreview.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow preview'**
  String get notifChannelPreview;

  /// No description provided for @notifChannelPreviewDesc.
  ///
  /// In en, this message translates to:
  /// **'A quiet evening look at tomorrow'**
  String get notifChannelPreviewDesc;

  /// No description provided for @notifChannelBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get notifChannelBills;

  /// No description provided for @notifChannelBillsDesc.
  ///
  /// In en, this message translates to:
  /// **'Reminders before household bills are due'**
  String get notifChannelBillsDesc;

  /// No description provided for @notifChannelCare.
  ///
  /// In en, this message translates to:
  /// **'Care'**
  String get notifChannelCare;

  /// No description provided for @notifChannelCareDesc.
  ///
  /// In en, this message translates to:
  /// **'Reminders for household and elder care'**
  String get notifChannelCareDesc;

  /// No description provided for @notifChannelSchool.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get notifChannelSchool;

  /// No description provided for @notifChannelSchoolDesc.
  ///
  /// In en, this message translates to:
  /// **'Reminders for school runs and activities'**
  String get notifChannelSchoolDesc;

  /// No description provided for @notifChannelEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get notifChannelEvents;

  /// No description provided for @notifChannelEventsDesc.
  ///
  /// In en, this message translates to:
  /// **'Reminders before calendar events'**
  String get notifChannelEventsDesc;

  /// No description provided for @notifChannelTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get notifChannelTasks;

  /// No description provided for @notifChannelTasksDesc.
  ///
  /// In en, this message translates to:
  /// **'Reminders for open nest tasks'**
  String get notifChannelTasksDesc;

  /// No description provided for @notifTomorrowTitle.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow in Casaio'**
  String get notifTomorrowTitle;

  /// No description provided for @notifTomorrowBody.
  ///
  /// In en, this message translates to:
  /// **'{parts} due tomorrow'**
  String notifTomorrowBody(String parts);

  /// No description provided for @notifBillCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bill} other{{count} bills}}'**
  String notifBillCount(int count);

  /// No description provided for @notifCareCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 care task} other{{count} care tasks}}'**
  String notifCareCount(int count);

  /// No description provided for @notifSchoolCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 school item} other{{count} school items}}'**
  String notifSchoolCount(int count);

  /// No description provided for @notifEventCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 event} other{{count} events}}'**
  String notifEventCount(int count);

  /// No description provided for @notifTaskCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task} other{{count} tasks}}'**
  String notifTaskCount(int count);

  /// No description provided for @notifBillDueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Bill due tomorrow'**
  String get notifBillDueTomorrow;

  /// No description provided for @notifBillBody.
  ///
  /// In en, this message translates to:
  /// **'{title} · \${amount}'**
  String notifBillBody(String title, String amount);

  /// No description provided for @notifElderCareDue.
  ///
  /// In en, this message translates to:
  /// **'Elder care due'**
  String get notifElderCareDue;

  /// No description provided for @notifCareDue.
  ///
  /// In en, this message translates to:
  /// **'Care due'**
  String get notifCareDue;

  /// No description provided for @notifSchoolPickup.
  ///
  /// In en, this message translates to:
  /// **'School / pickup'**
  String get notifSchoolPickup;

  /// No description provided for @notifComingUp.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get notifComingUp;

  /// No description provided for @notifTaskDue.
  ///
  /// In en, this message translates to:
  /// **'Task due'**
  String get notifTaskDue;

  /// No description provided for @notifChannelTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get notifChannelTimeline;

  /// No description provided for @notifChannelTimelineDesc.
  ///
  /// In en, this message translates to:
  /// **'When someone mentions you on the family timeline'**
  String get notifChannelTimelineDesc;

  /// No description provided for @notifTimelineMentionTitle.
  ///
  /// In en, this message translates to:
  /// **'{author} mentioned you'**
  String notifTimelineMentionTitle(String author);

  /// No description provided for @widgetAllClear.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get widgetAllClear;

  /// No description provided for @widgetNothingScheduled.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled'**
  String get widgetNothingScheduled;

  /// No description provided for @widgetNotPlanned.
  ///
  /// In en, this message translates to:
  /// **'Not planned'**
  String get widgetNotPlanned;

  /// No description provided for @widgetJoinNest.
  ///
  /// In en, this message translates to:
  /// **'Open Casaio to join a nest'**
  String get widgetJoinNest;

  /// No description provided for @widgetQuietDay.
  ///
  /// In en, this message translates to:
  /// **'Quiet day · enjoy it'**
  String get widgetQuietDay;

  /// No description provided for @widgetOpenTasks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 open task} other{{count} open tasks}}'**
  String widgetOpenTasks(int count);

  /// No description provided for @widgetOpenShort.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 open} other{{count} open}}'**
  String widgetOpenShort(int count);

  /// No description provided for @widgetJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get widgetJustNow;

  /// No description provided for @widgetMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String widgetMinutesAgo(int count);

  /// No description provided for @widgetHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String widgetHoursAgo(int count);

  /// No description provided for @widgetDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String widgetDaysAgo(int count);

  /// No description provided for @widgetEarlier.
  ///
  /// In en, this message translates to:
  /// **'earlier'**
  String get widgetEarlier;

  /// No description provided for @widgetToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get widgetToday;

  /// No description provided for @widgetWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get widgetWelcome;

  /// No description provided for @widgetUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {age}'**
  String widgetUpdated(String age);

  /// No description provided for @widgetName.
  ///
  /// In en, this message translates to:
  /// **'Casaio Today'**
  String get widgetName;

  /// No description provided for @widgetDescription.
  ///
  /// In en, this message translates to:
  /// **'Open tasks, next event, and tonight’s dinner — no vault data.'**
  String get widgetDescription;

  /// No description provided for @locatorAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get locatorAll;

  /// No description provided for @locatorFresh.
  ///
  /// In en, this message translates to:
  /// **'Fresh'**
  String get locatorFresh;

  /// No description provided for @locatorStale.
  ///
  /// In en, this message translates to:
  /// **'Stale'**
  String get locatorStale;

  /// No description provided for @scanKindEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get scanKindEvent;

  /// No description provided for @scanKindExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get scanKindExpense;

  /// No description provided for @scanKindBill.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get scanKindBill;

  /// No description provided for @scanKindTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get scanKindTask;

  /// No description provided for @emptyTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first task'**
  String get emptyTasksTitle;

  /// No description provided for @emptyShoppingTitle.
  ///
  /// In en, this message translates to:
  /// **'Start the grocery list'**
  String get emptyShoppingTitle;

  /// No description provided for @emptyCareTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first care schedule'**
  String get emptyCareTitle;

  /// No description provided for @emptySchoolTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first school run'**
  String get emptySchoolTitle;

  /// No description provided for @emptyCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first event'**
  String get emptyCalendarTitle;

  /// No description provided for @emptyMealsTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan this week’s dinners'**
  String get emptyMealsTitle;

  /// No description provided for @emptyExpensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Log your first expense'**
  String get emptyExpensesTitle;

  /// No description provided for @emptyTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing on the timeline yet'**
  String get emptyTimelineTitle;

  /// No description provided for @emptyCareBody.
  ///
  /// In en, this message translates to:
  /// **'Pet, home, car, or elder routines — mark done to roll the next due date.'**
  String get emptyCareBody;

  /// No description provided for @emptySchoolBody.
  ///
  /// In en, this message translates to:
  /// **'Pickups, sports, and clubs — confirm who’s covering the run.'**
  String get emptySchoolBody;

  /// No description provided for @authLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get authLogIn;

  /// No description provided for @authSignUpShort.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authSignUpShort;

  /// No description provided for @authHaveAccountLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get authHaveAccountLogin;

  /// No description provided for @authNeedAccountSignup.
  ///
  /// In en, this message translates to:
  /// **'Need an account? Sign up'**
  String get authNeedAccountSignup;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authWorking.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get authWorking;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// No description provided for @commonSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get commonSignOut;

  /// No description provided for @commonPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get commonPaste;

  /// No description provided for @onboardingPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String onboardingPageOf(int current, int total);

  /// No description provided for @nestSetupJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join nest'**
  String get nestSetupJoinTitle;

  /// No description provided for @nestSetupCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up in under a minute'**
  String get nestSetupCreateTitle;

  /// No description provided for @nestSetupJoinBody.
  ///
  /// In en, this message translates to:
  /// **'Paste or type the 6-character code from your family.'**
  String get nestSetupJoinBody;

  /// No description provided for @nestSetupCreateBody.
  ///
  /// In en, this message translates to:
  /// **'Create your household nest. You can rename it and invite family later.'**
  String get nestSetupCreateBody;

  /// No description provided for @nestSetupNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Shown on shared tasks and timeline'**
  String get nestSetupNameHelper;

  /// No description provided for @nestSetupInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get nestSetupInviteCode;

  /// No description provided for @nestSetupInviteHelper.
  ///
  /// In en, this message translates to:
  /// **'Spaces and dashes are stripped automatically'**
  String get nestSetupInviteHelper;

  /// No description provided for @nestSetupNestName.
  ///
  /// In en, this message translates to:
  /// **'Nest name'**
  String get nestSetupNestName;

  /// No description provided for @nestSetupNestHelper.
  ///
  /// In en, this message translates to:
  /// **'Defaults are fine — you can change this later'**
  String get nestSetupNestHelper;

  /// No description provided for @nestSetupAfterStart.
  ///
  /// In en, this message translates to:
  /// **'After you start, Casaio will offer an invite code so someone can join.'**
  String get nestSetupAfterStart;

  /// No description provided for @nestSetupStart.
  ///
  /// In en, this message translates to:
  /// **'Start nest'**
  String get nestSetupStart;

  /// No description provided for @nestSetupSwitchCreate.
  ///
  /// In en, this message translates to:
  /// **'Create a new nest instead'**
  String get nestSetupSwitchCreate;

  /// No description provided for @nestSetupSwitchJoin.
  ///
  /// In en, this message translates to:
  /// **'Have an invite code?'**
  String get nestSetupSwitchJoin;

  /// No description provided for @clipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Clipboard is empty'**
  String get clipboardEmpty;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordIntro.
  ///
  /// In en, this message translates to:
  /// **'We’ll email you a secure link to choose a new password.'**
  String get resetPasswordIntro;

  /// No description provided for @resetCheckInbox.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox'**
  String get resetCheckInbox;

  /// No description provided for @resetCheckInboxBody.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for {email}, you’ll get a reset link shortly. Open it on this device or any browser, then log in with your new password.'**
  String resetCheckInboxBody(String email);

  /// No description provided for @resetDontSee.
  ///
  /// In en, this message translates to:
  /// **'Don’t see it?'**
  String get resetDontSee;

  /// No description provided for @resetDontSeeBody.
  ///
  /// In en, this message translates to:
  /// **'Check Spam and Promotions (Gmail often files Firebase emails there). Wait a minute, then resend.'**
  String get resetDontSeeBody;

  /// No description provided for @resetSendLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get resetSendLink;

  /// No description provided for @resetResend.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get resetResend;

  /// No description provided for @resetResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resetResendIn(int seconds);

  /// No description provided for @resetEmailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email support@casaio.app'**
  String get resetEmailSupport;

  /// No description provided for @resetEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter the email for your Casaio account.'**
  String get resetEnterEmail;

  /// No description provided for @screenBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get screenBudget;

  /// No description provided for @screenAboutShort.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get screenAboutShort;

  /// No description provided for @screenPrivacyShort.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get screenPrivacyShort;

  /// No description provided for @screenTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get screenTasks;

  /// No description provided for @lastSyncedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last synced · {age}'**
  String lastSyncedLabel(String age);

  /// No description provided for @homeLists.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get homeLists;

  /// No description provided for @homeAddTask.
  ///
  /// In en, this message translates to:
  /// **'Add a task'**
  String get homeAddTask;

  /// No description provided for @homeNoneToday.
  ///
  /// In en, this message translates to:
  /// **'None today'**
  String get homeNoneToday;

  /// No description provided for @homeNoneDue.
  ///
  /// In en, this message translates to:
  /// **'None due'**
  String get homeNoneDue;

  /// No description provided for @homeCountDue.
  ///
  /// In en, this message translates to:
  /// **'{count} due'**
  String homeCountDue(int count);

  /// No description provided for @homeCountToday.
  ///
  /// In en, this message translates to:
  /// **'{count} today'**
  String homeCountToday(int count);

  /// No description provided for @homeItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String homeItemsCount(int count);

  /// No description provided for @homeOpenCount.
  ///
  /// In en, this message translates to:
  /// **'{count} open'**
  String homeOpenCount(int count);

  /// No description provided for @homeDocsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} docs'**
  String homeDocsCount(int count);

  /// No description provided for @homeThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get homeThisMonth;

  /// No description provided for @homeAlwaysReady.
  ///
  /// In en, this message translates to:
  /// **'Always ready'**
  String get homeAlwaysReady;

  /// No description provided for @homeLocatorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nest map & last-known pins'**
  String get homeLocatorSubtitle;

  /// No description provided for @homeDinnerSet.
  ///
  /// In en, this message translates to:
  /// **'Dinner set'**
  String get homeDinnerSet;

  /// No description provided for @homePlanWeek.
  ///
  /// In en, this message translates to:
  /// **'Plan week'**
  String get homePlanWeek;

  /// No description provided for @homeBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get homeBills;

  /// No description provided for @deleteEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete event?'**
  String get deleteEventTitle;

  /// No description provided for @deleteDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove document?'**
  String get deleteDocumentTitle;

  /// No description provided for @clearBoughtTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear bought items?'**
  String get clearBoughtTitle;

  /// No description provided for @leaveNestTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this nest?'**
  String get leaveNestTitle;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountTitle;

  /// No description provided for @careEmptyFilter.
  ///
  /// In en, this message translates to:
  /// **'Nothing in {filter}'**
  String careEmptyFilter(String filter);

  /// No description provided for @careEmptyFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Try another filter, or add a {filter} care item.'**
  String careEmptyFilterHint(String filter);

  /// No description provided for @careAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add care item'**
  String get careAddItem;

  /// No description provided for @schoolEmptyFilter.
  ///
  /// In en, this message translates to:
  /// **'Nothing in {filter}'**
  String schoolEmptyFilter(String filter);

  /// No description provided for @schoolEmptyFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Try another filter, or add a {filter} activity.'**
  String schoolEmptyFilterHint(String filter);

  /// No description provided for @schoolAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add activity'**
  String get schoolAddItem;

  /// No description provided for @locatorShared.
  ///
  /// In en, this message translates to:
  /// **'Shared · {label}'**
  String locatorShared(String label);

  /// No description provided for @widgetNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get widgetNext;

  /// No description provided for @widgetDinnerChrome.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get widgetDinnerChrome;

  /// No description provided for @widgetTasksChrome.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get widgetTasksChrome;

  /// No description provided for @inviteFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite family'**
  String get inviteFamilyTitle;

  /// No description provided for @inviteCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite code {code} copied — ready to paste'**
  String inviteCodeCopied(String code);

  /// No description provided for @inviteShareSubject.
  ///
  /// In en, this message translates to:
  /// **'Join my Casaio nest'**
  String get inviteShareSubject;

  /// No description provided for @inviteShareFallbackNest.
  ///
  /// In en, this message translates to:
  /// **'our family nest'**
  String get inviteShareFallbackNest;

  /// No description provided for @inviteShareText.
  ///
  /// In en, this message translates to:
  /// **'Join {nest} on Casaio!\n\nInvite code: {code}\n\nGet the app: {url}\nThen open Casaio → Have an invite code? → paste this code.'**
  String inviteShareText(String nest, String code, String url);

  /// No description provided for @dowSunday.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get dowSunday;

  /// No description provided for @dowMonday.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get dowMonday;

  /// No description provided for @dowTuesday.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get dowTuesday;

  /// No description provided for @dowWednesday.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get dowWednesday;

  /// No description provided for @dowThursday.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get dowThursday;

  /// No description provided for @dowFriday.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get dowFriday;

  /// No description provided for @dowSaturday.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get dowSaturday;

  /// No description provided for @syncOverWeekAgo.
  ///
  /// In en, this message translates to:
  /// **'over a week ago'**
  String get syncOverWeekAgo;

  /// No description provided for @calendarTitleMonth.
  ///
  /// In en, this message translates to:
  /// **'Family calendar'**
  String get calendarTitleMonth;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncing;

  /// No description provided for @syncNeededRetry.
  ///
  /// In en, this message translates to:
  /// **'Sync needed · Retry'**
  String get syncNeededRetry;

  /// No description provided for @commonDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get commonDismiss;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get commonInvite;

  /// No description provided for @commonNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get commonNotNow;

  /// No description provided for @commonSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get commonSeeAll;

  /// No description provided for @commonGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get commonGotIt;

  /// No description provided for @commonDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get commonDiscard;

  /// No description provided for @loadFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not load. Try again later.'**
  String get loadFailedGeneric;

  /// No description provided for @loadFailedTasks.
  ///
  /// In en, this message translates to:
  /// **'Could not load tasks.'**
  String get loadFailedTasks;

  /// No description provided for @loadFailedMeals.
  ///
  /// In en, this message translates to:
  /// **'Could not load meals.'**
  String get loadFailedMeals;

  /// No description provided for @loadFailedCare.
  ///
  /// In en, this message translates to:
  /// **'Could not load care items.'**
  String get loadFailedCare;

  /// No description provided for @loadFailedSchool.
  ///
  /// In en, this message translates to:
  /// **'Could not load activities.'**
  String get loadFailedSchool;

  /// No description provided for @loadFailedShopping.
  ///
  /// In en, this message translates to:
  /// **'Could not load list. Try again later.'**
  String get loadFailedShopping;

  /// No description provided for @loadFailedNest.
  ///
  /// In en, this message translates to:
  /// **'Could not load nest: {error}'**
  String loadFailedNest(String error);

  /// No description provided for @homeStillSolo.
  ///
  /// In en, this message translates to:
  /// **'Still flying solo'**
  String get homeStillSolo;

  /// No description provided for @homeStillSoloBody.
  ///
  /// In en, this message translates to:
  /// **'Invite a partner with {code} so Today stays shared.'**
  String homeStillSoloBody(String code);

  /// No description provided for @homeInvitePartner.
  ///
  /// In en, this message translates to:
  /// **'Invite a partner'**
  String get homeInvitePartner;

  /// No description provided for @homeInvitePartnerBody.
  ///
  /// In en, this message translates to:
  /// **'Share {code} so someone can join this nest.'**
  String homeInvitePartnerBody(String code);

  /// No description provided for @homeShareInvite.
  ///
  /// In en, this message translates to:
  /// **'Share invite'**
  String get homeShareInvite;

  /// No description provided for @homeInviteChip.
  ///
  /// In en, this message translates to:
  /// **'Invite · {code}'**
  String homeInviteChip(String code);

  /// No description provided for @homeReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get homeReminders;

  /// No description provided for @homeOpenTasks.
  ///
  /// In en, this message translates to:
  /// **'Open tasks'**
  String get homeOpenTasks;

  /// No description provided for @homeOpenEmergency.
  ///
  /// In en, this message translates to:
  /// **'Open emergency card'**
  String get homeOpenEmergency;

  /// No description provided for @homeTodayReminders.
  ///
  /// In en, this message translates to:
  /// **'Today reminders'**
  String get homeTodayReminders;

  /// No description provided for @snackDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Done: {title}'**
  String snackDoneTitle(String title);

  /// No description provided for @snackPaidTitle.
  ///
  /// In en, this message translates to:
  /// **'Paid: {title}'**
  String snackPaidTitle(String title);

  /// No description provided for @snackRestockAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Added 1 restock item} other{Added {count} restock items}}'**
  String snackRestockAdded(int count);

  /// No description provided for @emptyTasksBody.
  ///
  /// In en, this message translates to:
  /// **'Chores, reminders, and shared to-dos live here — tap to create one for the nest.'**
  String get emptyTasksBody;

  /// No description provided for @emptyTasksNone.
  ///
  /// In en, this message translates to:
  /// **'No tasks here'**
  String get emptyTasksNone;

  /// No description provided for @emptyTasksNoneNamed.
  ///
  /// In en, this message translates to:
  /// **'Nothing for {name}'**
  String emptyTasksNoneNamed(String name);

  /// No description provided for @emptyTasksHint.
  ///
  /// In en, this message translates to:
  /// **'Try another filter or add a task.'**
  String get emptyTasksHint;

  /// No description provided for @emptyTasksHintNamed.
  ///
  /// In en, this message translates to:
  /// **'Tap All to see everyone, or add a task for them.'**
  String get emptyTasksHintNamed;

  /// No description provided for @emptyShoppingBody.
  ///
  /// In en, this message translates to:
  /// **'Add milk, eggs, or anything else — pick a category in the field, then add.'**
  String get emptyShoppingBody;

  /// No description provided for @emptyShoppingAction.
  ///
  /// In en, this message translates to:
  /// **'Add an item'**
  String get emptyShoppingAction;

  /// No description provided for @emptyMealsBody.
  ///
  /// In en, this message translates to:
  /// **'Add tonight’s meal or sketch the week — then push ingredients to Shopping in one tap.'**
  String get emptyMealsBody;

  /// No description provided for @emptyMealsAction.
  ///
  /// In en, this message translates to:
  /// **'Plan dinner week'**
  String get emptyMealsAction;

  /// No description provided for @emptyExpensesBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a monthly spending target, log a few expenses, and track bills so nothing slips.'**
  String get emptyExpensesBody;

  /// No description provided for @emptyExpensesAction.
  ///
  /// In en, this message translates to:
  /// **'Set month budget'**
  String get emptyExpensesAction;

  /// No description provided for @emptyCalendarBody.
  ///
  /// In en, this message translates to:
  /// **'School runs, dinners, and appointments land here — no demo data, just yours.'**
  String get emptyCalendarBody;

  /// No description provided for @emptyCalendarNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No events match'**
  String get emptyCalendarNoMatch;

  /// No description provided for @emptyCalendarNothingToday.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned today'**
  String get emptyCalendarNothingToday;

  /// No description provided for @emptyCalendarNothingDay.
  ///
  /// In en, this message translates to:
  /// **'Nothing on this day'**
  String get emptyCalendarNothingDay;

  /// No description provided for @emptyCalendarSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different search, or clear the filter.'**
  String get emptyCalendarSearchHint;

  /// No description provided for @emptyCalendarDayHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to schedule something for this day.'**
  String get emptyCalendarDayHint;

  /// No description provided for @emptyCalendarClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get emptyCalendarClearSearch;

  /// No description provided for @emptyTimelineFilter.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this filter'**
  String get emptyTimelineFilter;

  /// No description provided for @emptyTimelineBody.
  ///
  /// In en, this message translates to:
  /// **'As the family checks off tasks, shops, and plans meals, activity shows up here.'**
  String get emptyTimelineBody;

  /// No description provided for @emptyTimelineFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Try another module filter, or clear back to All.'**
  String get emptyTimelineFilterHint;

  /// No description provided for @locatorEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No one is sharing yet'**
  String get locatorEmptyTitle;

  /// No description provided for @locatorEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'When a nest member opts in and taps Share now, their last-known pin shows up on the map.'**
  String get locatorEmptyBody;

  /// No description provided for @locatorShareNow.
  ///
  /// In en, this message translates to:
  /// **'Share now'**
  String get locatorShareNow;

  /// No description provided for @locatorTurnOnSharing.
  ///
  /// In en, this message translates to:
  /// **'Turn on sharing'**
  String get locatorTurnOnSharing;

  /// No description provided for @locatorSharingOn.
  ///
  /// In en, this message translates to:
  /// **'Sharing on'**
  String get locatorSharingOn;

  /// No description provided for @locatorCoordsCopied.
  ///
  /// In en, this message translates to:
  /// **'Coordinates copied'**
  String get locatorCoordsCopied;

  /// No description provided for @searchEvents.
  ///
  /// In en, this message translates to:
  /// **'Search events'**
  String get searchEvents;

  /// No description provided for @searchTasks.
  ///
  /// In en, this message translates to:
  /// **'Search tasks'**
  String get searchTasks;

  /// No description provided for @searchList.
  ///
  /// In en, this message translates to:
  /// **'Search list'**
  String get searchList;

  /// No description provided for @searchExpenses.
  ///
  /// In en, this message translates to:
  /// **'Search expenses & bills'**
  String get searchExpenses;

  /// No description provided for @searchVault.
  ///
  /// In en, this message translates to:
  /// **'Search by title, notes, or folder'**
  String get searchVault;

  /// No description provided for @hintEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Event title'**
  String get hintEventTitle;

  /// No description provided for @hintLocationOptional.
  ///
  /// In en, this message translates to:
  /// **'Location (optional)'**
  String get hintLocationOptional;

  /// No description provided for @hintNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get hintNotesOptional;

  /// No description provided for @hintTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'What needs doing?'**
  String get hintTaskTitle;

  /// No description provided for @hintItemName.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get hintItemName;

  /// No description provided for @hintQty.
  ///
  /// In en, this message translates to:
  /// **'Qty (e.g. 2, 1 kg)'**
  String get hintQty;

  /// No description provided for @hintAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add an item'**
  String get hintAddItem;

  /// No description provided for @hintDishName.
  ///
  /// In en, this message translates to:
  /// **'Dish name'**
  String get hintDishName;

  /// No description provided for @hintIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients (comma or new line)'**
  String get hintIngredients;

  /// No description provided for @hintDinnerFor.
  ///
  /// In en, this message translates to:
  /// **'Dinner for {day}'**
  String hintDinnerFor(String day);

  /// No description provided for @hintSchoolTitle.
  ///
  /// In en, this message translates to:
  /// **'e.g. Soccer practice'**
  String get hintSchoolTitle;

  /// No description provided for @paidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get paidBy;

  /// No description provided for @addBill.
  ///
  /// In en, this message translates to:
  /// **'Add a bill'**
  String get addBill;

  /// No description provided for @addBillShort.
  ///
  /// In en, this message translates to:
  /// **'Add bill'**
  String get addBillShort;

  /// No description provided for @billRepeats.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get billRepeats;

  /// No description provided for @billCadenceNone.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get billCadenceNone;

  /// No description provided for @billRepeatsCadence.
  ///
  /// In en, this message translates to:
  /// **'Repeats · {cadence}'**
  String billRepeatsCadence(String cadence);

  /// No description provided for @saveBudget.
  ///
  /// In en, this message translates to:
  /// **'Save budget'**
  String get saveBudget;

  /// No description provided for @saveWeek.
  ///
  /// In en, this message translates to:
  /// **'Save week'**
  String get saveWeek;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get saveProfile;

  /// No description provided for @saveDetails.
  ///
  /// In en, this message translates to:
  /// **'Save details'**
  String get saveDetails;

  /// No description provided for @saveOffline.
  ///
  /// In en, this message translates to:
  /// **'Save offline'**
  String get saveOffline;

  /// No description provided for @deleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete task'**
  String get deleteTask;

  /// No description provided for @deleteMeal.
  ///
  /// In en, this message translates to:
  /// **'Delete meal'**
  String get deleteMeal;

  /// No description provided for @deleteActivity.
  ///
  /// In en, this message translates to:
  /// **'Delete activity'**
  String get deleteActivity;

  /// No description provided for @deleteEventAction.
  ///
  /// In en, this message translates to:
  /// **'Delete event'**
  String get deleteEventAction;

  /// No description provided for @clearBought.
  ///
  /// In en, this message translates to:
  /// **'Clear bought'**
  String get clearBought;

  /// No description provided for @clearBoughtAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearBoughtAction;

  /// No description provided for @addToList.
  ///
  /// In en, this message translates to:
  /// **'Add to list'**
  String get addToList;

  /// No description provided for @shopThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Shop this week'**
  String get shopThisWeek;

  /// No description provided for @planDinnerWeek.
  ///
  /// In en, this message translates to:
  /// **'Plan dinner week'**
  String get planDinnerWeek;

  /// No description provided for @addIngredients.
  ///
  /// In en, this message translates to:
  /// **'Add ingredients to list'**
  String get addIngredients;

  /// No description provided for @mealsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Dinner week updated'**
  String get mealsUpdated;

  /// No description provided for @mealsNoNewIngredients.
  ///
  /// In en, this message translates to:
  /// **'No new ingredients to add'**
  String get mealsNoNewIngredients;

  /// No description provided for @mealsAddToGroceries.
  ///
  /// In en, this message translates to:
  /// **'Add {count} to groceries'**
  String mealsAddToGroceries(int count);

  /// No description provided for @mealsAddedToGroceries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Added 1 item to groceries} other{Added {count} items to groceries}}'**
  String mealsAddedToGroceries(int count);

  /// No description provided for @snooze1Day.
  ///
  /// In en, this message translates to:
  /// **'Snooze 1 day'**
  String get snooze1Day;

  /// No description provided for @skipCycle.
  ///
  /// In en, this message translates to:
  /// **'Skip this cycle'**
  String get skipCycle;

  /// No description provided for @createCalendarEvent.
  ///
  /// In en, this message translates to:
  /// **'Create calendar event'**
  String get createCalendarEvent;

  /// No description provided for @addPickupTask.
  ///
  /// In en, this message translates to:
  /// **'Add pickup task'**
  String get addPickupTask;

  /// No description provided for @snackSnoozed.
  ///
  /// In en, this message translates to:
  /// **'Snoozed {title} by 1 day'**
  String snackSnoozed(String title);

  /// No description provided for @snackSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped {title} this cycle'**
  String snackSkipped(String title);

  /// No description provided for @snackPickupAdded.
  ///
  /// In en, this message translates to:
  /// **'Pickup task added {who}'**
  String snackPickupAdded(String who);

  /// No description provided for @snackCareProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved care profile for {name}'**
  String snackCareProfileSaved(String name);

  /// No description provided for @careMeds.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get careMeds;

  /// No description provided for @careMedsHint.
  ///
  /// In en, this message translates to:
  /// **'Morning BP med, evening…'**
  String get careMedsHint;

  /// No description provided for @careAllergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get careAllergies;

  /// No description provided for @careAllergiesHint.
  ///
  /// In en, this message translates to:
  /// **'Penicillin, peanuts…'**
  String get careAllergiesHint;

  /// No description provided for @careMobility.
  ///
  /// In en, this message translates to:
  /// **'Mobility & support'**
  String get careMobility;

  /// No description provided for @careMobilityHint.
  ///
  /// In en, this message translates to:
  /// **'Walker, needs help stairs…'**
  String get careMobilityHint;

  /// No description provided for @careDoctor.
  ///
  /// In en, this message translates to:
  /// **'Primary doctor'**
  String get careDoctor;

  /// No description provided for @careDoctorHint.
  ///
  /// In en, this message translates to:
  /// **'Dr. Name · clinic'**
  String get careDoctorHint;

  /// No description provided for @careNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Preferences, routines…'**
  String get careNotesHint;

  /// No description provided for @vaultSelectShare.
  ///
  /// In en, this message translates to:
  /// **'Select to share'**
  String get vaultSelectShare;

  /// No description provided for @vaultSharePack.
  ///
  /// In en, this message translates to:
  /// **'Share pack'**
  String get vaultSharePack;

  /// No description provided for @vaultScanCalendar.
  ///
  /// In en, this message translates to:
  /// **'Scan to calendar'**
  String get vaultScanCalendar;

  /// No description provided for @vaultRetryUpload.
  ///
  /// In en, this message translates to:
  /// **'Retry upload'**
  String get vaultRetryUpload;

  /// No description provided for @vaultClearExpiry.
  ///
  /// In en, this message translates to:
  /// **'Clear expiry reminder'**
  String get vaultClearExpiry;

  /// No description provided for @vaultExpiryCleared.
  ///
  /// In en, this message translates to:
  /// **'Expiry reminder cleared'**
  String get vaultExpiryCleared;

  /// No description provided for @vaultUpdated.
  ///
  /// In en, this message translates to:
  /// **'Document updated'**
  String get vaultUpdated;

  /// No description provided for @vaultRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'Remove “{title}” from the nest vault.'**
  String vaultRemoveBody(String title);

  /// No description provided for @vaultSharedFiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Shared 1 file} other{Shared {count} files}}'**
  String vaultSharedFiles(int count);

  /// No description provided for @vaultAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not add file: {error}'**
  String vaultAddFailed(String error);

  /// No description provided for @vaultNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Renewal tips, last-4, who holds the original…'**
  String get vaultNotesHint;

  /// No description provided for @nSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String nSelected(int count);

  /// No description provided for @emergencyShareCard.
  ///
  /// In en, this message translates to:
  /// **'Share card'**
  String get emergencyShareCard;

  /// No description provided for @emergencyCopyCard.
  ///
  /// In en, this message translates to:
  /// **'Copy card'**
  String get emergencyCopyCard;

  /// No description provided for @emergencyCopiedEntry.
  ///
  /// In en, this message translates to:
  /// **'Copied {label}'**
  String emergencyCopiedEntry(String label);

  /// No description provided for @emergencyCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get emergencyCopied;

  /// No description provided for @emergencyCardCopied.
  ///
  /// In en, this message translates to:
  /// **'Emergency card copied'**
  String get emergencyCardCopied;

  /// No description provided for @emergencyNeedData.
  ///
  /// In en, this message translates to:
  /// **'Add a contact or care profile before sharing'**
  String get emergencyNeedData;

  /// No description provided for @emergencyNeedDataCopy.
  ///
  /// In en, this message translates to:
  /// **'Add a contact or care profile before copying'**
  String get emergencyNeedDataCopy;

  /// No description provided for @emergencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get emergencyLabel;

  /// No description provided for @emergencyDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get emergencyDetails;

  /// No description provided for @inviteCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get inviteCopyCode;

  /// No description provided for @inviteSkipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get inviteSkipForNow;

  /// No description provided for @inviteNestReady.
  ///
  /// In en, this message translates to:
  /// **'Nest ready — invite family'**
  String get inviteNestReady;

  /// No description provided for @inviteNestReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Share this code so someone can join in under a minute.'**
  String get inviteNestReadyBody;

  /// No description provided for @inviteSheetBody.
  ///
  /// In en, this message translates to:
  /// **'Anyone with Casaio can join using this 6-character code.'**
  String get inviteSheetBody;

  /// No description provided for @inviteCodeA11y.
  ///
  /// In en, this message translates to:
  /// **'Invite code {code}'**
  String inviteCodeA11y(String code);

  /// No description provided for @rolePickerHint.
  ///
  /// In en, this message translates to:
  /// **'Used for assignees, school activities, and family context.'**
  String get rolePickerHint;

  /// No description provided for @roleUpdated.
  ///
  /// In en, this message translates to:
  /// **'{name} is now {role}'**
  String roleUpdated(String name, String role);

  /// No description provided for @familyRoles.
  ///
  /// In en, this message translates to:
  /// **'Family roles'**
  String get familyRoles;

  /// No description provided for @yourNest.
  ///
  /// In en, this message translates to:
  /// **'Your nest'**
  String get yourNest;

  /// No description provided for @noMembersYet.
  ///
  /// In en, this message translates to:
  /// **'No members yet'**
  String get noMembersYet;

  /// No description provided for @inviteWithCodeBelow.
  ///
  /// In en, this message translates to:
  /// **'Invite family with your code below'**
  String get inviteWithCodeBelow;

  /// No description provided for @membersHelper.
  ///
  /// In en, this message translates to:
  /// **'Used for assignees, school activities, and family context.'**
  String get membersHelper;

  /// No description provided for @nestFreeNote.
  ///
  /// In en, this message translates to:
  /// **'Casaio is free for families — no paywall.'**
  String get nestFreeNote;

  /// No description provided for @leaveNest.
  ///
  /// In en, this message translates to:
  /// **'Leave nest'**
  String get leaveNest;

  /// No description provided for @leaveNestBody.
  ///
  /// In en, this message translates to:
  /// **'You’ll lose access to “{name}” on this account. Other members keep the nest and all shared data. Your Casaio login stays — you can create or join another nest.'**
  String leaveNestBody(String name);

  /// No description provided for @leftNest.
  ///
  /// In en, this message translates to:
  /// **'Left nest — create or join another'**
  String get leftNest;

  /// No description provided for @leaveNestFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t leave nest: {error}'**
  String leaveNestFailed(String error);

  /// No description provided for @resetBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to log in'**
  String get resetBackToLogin;

  /// No description provided for @resetUseOtherEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get resetUseOtherEmail;

  /// No description provided for @resetPasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get resetPasswordUpdated;

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'The operating system for modern families'**
  String get aboutTagline;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// No description provided for @privacyIntro.
  ///
  /// In en, this message translates to:
  /// **'Casaio keeps household data private by default.'**
  String get privacyIntro;

  /// No description provided for @privacyStoreTitle.
  ///
  /// In en, this message translates to:
  /// **'What we store'**
  String get privacyStoreTitle;

  /// No description provided for @privacyStoreBody.
  ///
  /// In en, this message translates to:
  /// **'Account email, nest membership, tasks, lists, calendar, expenses, bills, emergency notes, vault file metadata, family timeline events, and — if you opt in — a last-known Locator pin. Vault files upload to Firebase Storage under your nest when you are online. Locator never tracks you in the background; you share only when you tap Share now.'**
  String get privacyStoreBody;

  /// No description provided for @privacySyncTitle.
  ///
  /// In en, this message translates to:
  /// **'How it syncs'**
  String get privacySyncTitle;

  /// No description provided for @privacySyncBody.
  ///
  /// In en, this message translates to:
  /// **'Casaio is offline-first. Data lives on your device in SQLite (Drift) and syncs to Firebase when signed in and connected. Only nest members can read or write nest data.'**
  String get privacySyncBody;

  /// No description provided for @privacyAiTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiet AI (optional)'**
  String get privacyAiTitle;

  /// No description provided for @privacyAiBody.
  ///
  /// In en, this message translates to:
  /// **'Document scan sends the photo or PDF you choose to Google’s Gemini models through Firebase AI Logic (Vertex AI) so Casaio can draft an event, expense, bill, or task. You review before anything is saved. Casaio stays free — there is no paywall for core family features.'**
  String get privacyAiBody;

  /// No description provided for @privacyDiagTitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get privacyDiagTitle;

  /// No description provided for @privacyDiagBody.
  ///
  /// In en, this message translates to:
  /// **'Casaio uses Firebase Crashlytics and Analytics to improve stability. Crash reports and anonymous event names (for example sign-up, sync success/fail) do not include nest content, emails, or passwords.'**
  String get privacyDiagBody;

  /// No description provided for @privacyResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Password reset'**
  String get privacyResetTitle;

  /// No description provided for @privacyResetBody.
  ///
  /// In en, this message translates to:
  /// **'Forgot-password emails are sent by Firebase Authentication. If you don’t see one, check Spam and Promotions. While signed in, you can change your password from Nest without email. Need help? support@casaio.app.'**
  String get privacyResetBody;

  /// No description provided for @privacyNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get privacyNotifTitle;

  /// No description provided for @privacyNotifBody.
  ///
  /// In en, this message translates to:
  /// **'We may register a push token for reminders (for example bills). You can revoke notification permission in system settings.'**
  String get privacyNotifBody;

  /// No description provided for @privacyContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get privacyContactTitle;

  /// No description provided for @privacyContactBody.
  ///
  /// In en, this message translates to:
  /// **'Questions: privacy@casaio.app — or open https://casaio.app/privacy'**
  String get privacyContactBody;

  /// No description provided for @privacyControls.
  ///
  /// In en, this message translates to:
  /// **'Your controls'**
  String get privacyControls;

  /// No description provided for @privacyExport.
  ///
  /// In en, this message translates to:
  /// **'Export nest data'**
  String get privacyExport;

  /// No description provided for @privacyExportBody.
  ///
  /// In en, this message translates to:
  /// **'JSON includes budget settings. Vault files are metadata only — binaries stay in Vault.'**
  String get privacyExportBody;

  /// No description provided for @privacyDeleteHint.
  ///
  /// In en, this message translates to:
  /// **'Requires your password. Cannot be undone.'**
  String get privacyDeleteHint;

  /// No description provided for @privacyNeedSignIn.
  ///
  /// In en, this message translates to:
  /// **'You need to be signed in.'**
  String get privacyNeedSignIn;

  /// No description provided for @privacyDeleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting account…'**
  String get privacyDeleting;

  /// No description provided for @privacyDeleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get privacyDeleteForever;

  /// No description provided for @privacyConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm with password'**
  String get privacyConfirmPassword;

  /// No description provided for @privacyDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This removes {email} from Casaio and clears data on this device. If you are the last member, the nest (including vault files) is deleted. This cannot be undone.'**
  String privacyDeleteBody(String email);

  /// No description provided for @privacyExportReady.
  ///
  /// In en, this message translates to:
  /// **'Export ready to share'**
  String get privacyExportReady;

  /// No description provided for @privacyExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String privacyExportFailed(String error);

  /// No description provided for @scanSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to scan documents.'**
  String get scanSignIn;

  /// No description provided for @scanPickerFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the file picker: {error}'**
  String scanPickerFailed(String error);

  /// No description provided for @scanTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File is too large — keep photos/PDFs under ~4 MB.'**
  String get scanTooLarge;

  /// No description provided for @scanReading.
  ///
  /// In en, this message translates to:
  /// **'Reading document…\nUsually under a minute'**
  String get scanReading;

  /// No description provided for @scanNeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a title before saving'**
  String get scanNeedTitle;

  /// No description provided for @scanNeedAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get scanNeedAmount;

  /// No description provided for @scanSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String scanSaveFailed(String error);

  /// No description provided for @scanClearEnd.
  ///
  /// In en, this message translates to:
  /// **'Clear end'**
  String get scanClearEnd;

  /// No description provided for @homeQuietTitle.
  ///
  /// In en, this message translates to:
  /// **'Your nest is quiet — start Today'**
  String get homeQuietTitle;

  /// No description provided for @homeQuietBody.
  ///
  /// In en, this message translates to:
  /// **'Invite someone, or add your first task or event. No demo data — just your family.'**
  String get homeQuietBody;

  /// No description provided for @homeNothingToday.
  ///
  /// In en, this message translates to:
  /// **'Nothing on Today yet'**
  String get homeNothingToday;

  /// No description provided for @homeNothingTodayBody.
  ///
  /// In en, this message translates to:
  /// **'Add a task or calendar event so the nest has something to gather around.'**
  String get homeNothingTodayBody;

  /// No description provided for @homeOnCalendar.
  ///
  /// In en, this message translates to:
  /// **'On the calendar'**
  String get homeOnCalendar;

  /// No description provided for @homeTodayForNest.
  ///
  /// In en, this message translates to:
  /// **'Today for your nest'**
  String get homeTodayForNest;

  /// No description provided for @timelineBackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get timelineBackHome;

  /// No description provided for @timelineShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get timelineShowAll;

  /// No description provided for @locatorPinning.
  ///
  /// In en, this message translates to:
  /// **'Pinning…'**
  String get locatorPinning;

  /// No description provided for @locatorNoFreshPins.
  ///
  /// In en, this message translates to:
  /// **'No live pins right now — try All or Share now.'**
  String get locatorNoFreshPins;

  /// No description provided for @locatorNoStalePins.
  ///
  /// In en, this message translates to:
  /// **'No stale pins — everyone’s fresh.'**
  String get locatorNoStalePins;

  /// No description provided for @vaultFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get vaultFolder;

  /// No description provided for @vaultPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get vaultPreparing;

  /// No description provided for @vaultShareOpen.
  ///
  /// In en, this message translates to:
  /// **'Share / open'**
  String get vaultShareOpen;

  /// No description provided for @vaultSetExpiry.
  ///
  /// In en, this message translates to:
  /// **'Set expiry reminder'**
  String get vaultSetExpiry;

  /// No description provided for @vaultChangeExpiry.
  ///
  /// In en, this message translates to:
  /// **'Change expiry date'**
  String get vaultChangeExpiry;

  /// No description provided for @scanReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read that file. Try a smaller JPEG/PNG or PDF.'**
  String get scanReadFailed;

  /// No description provided for @dueLabel.
  ///
  /// In en, this message translates to:
  /// **'Due · {date}'**
  String dueLabel(String date);

  /// No description provided for @commonSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get commonSaveChanges;

  /// No description provided for @commonAllDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get commonAllDay;

  /// No description provided for @familyMember.
  ///
  /// In en, this message translates to:
  /// **'Family member'**
  String get familyMember;

  /// No description provided for @ourNest.
  ///
  /// In en, this message translates to:
  /// **'Our nest'**
  String get ourNest;

  /// No description provided for @yourAccount.
  ///
  /// In en, this message translates to:
  /// **'your account'**
  String get yourAccount;

  /// No description provided for @homePaceBusy.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get homePaceBusy;

  /// No description provided for @homePaceSteady.
  ///
  /// In en, this message translates to:
  /// **'Steady'**
  String get homePaceSteady;

  /// No description provided for @homePaceQuiet.
  ///
  /// In en, this message translates to:
  /// **'Quiet'**
  String get homePaceQuiet;

  /// No description provided for @homePlanDinner.
  ///
  /// In en, this message translates to:
  /// **'Plan dinner'**
  String get homePlanDinner;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Sync failed, retry'**
  String get syncFailedRetry;

  /// No description provided for @syncFailedTapRetry.
  ///
  /// In en, this message translates to:
  /// **'Sync failed · tap Retry to try again'**
  String get syncFailedTapRetry;

  /// No description provided for @homeThingsToday.
  ///
  /// In en, this message translates to:
  /// **'You have {count} things for today'**
  String homeThingsToday(int count);

  /// No description provided for @homeNoEventsToday.
  ///
  /// In en, this message translates to:
  /// **'No events on the calendar today — tap to add one'**
  String get homeNoEventsToday;

  /// No description provided for @homeUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get homeUpToDate;

  /// No description provided for @homeActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get homeActivities;

  /// No description provided for @homeNestActivity.
  ///
  /// In en, this message translates to:
  /// **'Nest activity'**
  String get homeNestActivity;

  /// No description provided for @homeRecentCount.
  ///
  /// In en, this message translates to:
  /// **'{count} recent'**
  String homeRecentCount(int count);

  /// No description provided for @homeRemindersEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing urgent right now. Local reminders stay scheduled when items are due.'**
  String get homeRemindersEmpty;

  /// No description provided for @expensesTapEditBudget.
  ///
  /// In en, this message translates to:
  /// **'Tap to edit budget'**
  String get expensesTapEditBudget;

  /// No description provided for @expensesByCategory.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get expensesByCategory;

  /// No description provided for @emptyExpensesNone.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet — tap + when you spend.'**
  String get emptyExpensesNone;

  /// No description provided for @emptyExpensesNoneNest.
  ///
  /// In en, this message translates to:
  /// **'No expenses this nest yet. Tap + to add one.'**
  String get emptyExpensesNoneNest;

  /// No description provided for @emptyExpensesSearch.
  ///
  /// In en, this message translates to:
  /// **'No expenses match this search.'**
  String get emptyExpensesSearch;

  /// No description provided for @emptyBillsHint.
  ///
  /// In en, this message translates to:
  /// **'Track rent, utilities, and subscriptions here.'**
  String get emptyBillsHint;

  /// No description provided for @emptyBillsNone.
  ///
  /// In en, this message translates to:
  /// **'No bills tracked yet.'**
  String get emptyBillsNone;

  /// No description provided for @emptyBillsSearch.
  ///
  /// In en, this message translates to:
  /// **'No bills match this search.'**
  String get emptyBillsSearch;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// No description provided for @dueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get dueTomorrow;

  /// No description provided for @dueInDays.
  ///
  /// In en, this message translates to:
  /// **'Due in {count} days · {date}'**
  String dueInDays(int count, String date);

  /// No description provided for @snackMarkedPaid.
  ///
  /// In en, this message translates to:
  /// **'Marked “{title}” paid'**
  String snackMarkedPaid(String title);

  /// No description provided for @snackMarkedUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Marked unpaid'**
  String get snackMarkedUnpaid;

  /// No description provided for @monthBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Month budget'**
  String get monthBudgetTitle;

  /// No description provided for @monthBudgetBody.
  ///
  /// In en, this message translates to:
  /// **'Your family’s spending target for this calendar month.'**
  String get monthBudgetBody;

  /// No description provided for @snackBudgetSet.
  ///
  /// In en, this message translates to:
  /// **'Month budget set to {amount}'**
  String snackBudgetSet(String amount);

  /// No description provided for @markUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Mark unpaid'**
  String get markUnpaid;

  /// No description provided for @markPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark paid'**
  String get markPaid;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpense;

  /// No description provided for @editExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get editExpense;

  /// No description provided for @deleteExpense.
  ///
  /// In en, this message translates to:
  /// **'Delete expense'**
  String get deleteExpense;

  /// No description provided for @editBill.
  ///
  /// In en, this message translates to:
  /// **'Edit bill'**
  String get editBill;

  /// No description provided for @deleteBill.
  ///
  /// In en, this message translates to:
  /// **'Delete bill'**
  String get deleteBill;

  /// No description provided for @vaultScanHint.
  ///
  /// In en, this message translates to:
  /// **'This may be a family document or invitation'**
  String get vaultScanHint;

  /// No description provided for @vaultRetryAll.
  ///
  /// In en, this message translates to:
  /// **'Retry all'**
  String get vaultRetryAll;

  /// No description provided for @vaultExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get vaultExpiringSoon;

  /// No description provided for @vaultRecentFiles.
  ///
  /// In en, this message translates to:
  /// **'Recent files'**
  String get vaultRecentFiles;

  /// No description provided for @vaultSearchResults.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get vaultSearchResults;

  /// No description provided for @vaultSavedOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved on device — will upload when online'**
  String get vaultSavedOffline;

  /// No description provided for @vaultStillOffline.
  ///
  /// In en, this message translates to:
  /// **'Still offline — files stay on this device'**
  String get vaultStillOffline;

  /// No description provided for @vaultUploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded {title}'**
  String vaultUploaded(String title);

  /// No description provided for @vaultUploadFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Upload failed — try again later'**
  String get vaultUploadFailedSnack;

  /// No description provided for @vaultNoSearchMatch.
  ///
  /// In en, this message translates to:
  /// **'No documents match “{query}”. Try a title, note, or folder name.'**
  String vaultNoSearchMatch(String query);

  /// No description provided for @vaultEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'No documents yet. Tap + to add IDs, insurance, or house papers.'**
  String get vaultEmptyBody;

  /// No description provided for @vaultEmptyFolder.
  ///
  /// In en, this message translates to:
  /// **'Nothing in {folder} yet. Tap + to add a file here.'**
  String vaultEmptyFolder(String folder);

  /// No description provided for @expiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today'**
  String get expiresToday;

  /// No description provided for @expiresTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Expires tomorrow'**
  String get expiresTomorrow;

  /// No description provided for @expiresInDays.
  ///
  /// In en, this message translates to:
  /// **'Expires in {count} days'**
  String expiresInDays(int count);

  /// No description provided for @vaultExpiryHelp.
  ///
  /// In en, this message translates to:
  /// **'When does this expire?'**
  String get vaultExpiryHelp;

  /// No description provided for @vaultDetails.
  ///
  /// In en, this message translates to:
  /// **'Document details'**
  String get vaultDetails;

  /// No description provided for @vaultStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status · {status}'**
  String vaultStatusLabel(String status);

  /// No description provided for @vaultRemoveFrom.
  ///
  /// In en, this message translates to:
  /// **'Remove from vault'**
  String get vaultRemoveFrom;

  /// No description provided for @scanWhatScanning.
  ///
  /// In en, this message translates to:
  /// **'What are you scanning?'**
  String get scanWhatScanning;

  /// No description provided for @scanReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get scanReceipt;

  /// No description provided for @scanReceiptHint.
  ///
  /// In en, this message translates to:
  /// **'Store receipt — extract total as expense'**
  String get scanReceiptHint;

  /// No description provided for @scanInviteEvent.
  ///
  /// In en, this message translates to:
  /// **'Invite / event'**
  String get scanInviteEvent;

  /// No description provided for @scanInviteHint.
  ///
  /// In en, this message translates to:
  /// **'Invitation or appointment — calendar event'**
  String get scanInviteHint;

  /// No description provided for @scanSchoolNotice.
  ///
  /// In en, this message translates to:
  /// **'School notice'**
  String get scanSchoolNotice;

  /// No description provided for @scanSchoolHint.
  ///
  /// In en, this message translates to:
  /// **'School notice or sports schedule'**
  String get scanSchoolHint;

  /// No description provided for @scanBillLabel.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get scanBillLabel;

  /// No description provided for @scanBillHint.
  ///
  /// In en, this message translates to:
  /// **'Utility or service bill — save as bill with due date'**
  String get scanBillHint;

  /// No description provided for @scanFailed.
  ///
  /// In en, this message translates to:
  /// **'Scan failed. Try again.'**
  String get scanFailed;

  /// No description provided for @scanExpenseAdded.
  ///
  /// In en, this message translates to:
  /// **'Expense added'**
  String get scanExpenseAdded;

  /// No description provided for @scanBillAdded.
  ///
  /// In en, this message translates to:
  /// **'Bill added'**
  String get scanBillAdded;

  /// No description provided for @scanTaskAdded.
  ///
  /// In en, this message translates to:
  /// **'Task added'**
  String get scanTaskAdded;

  /// No description provided for @scanEventAdded.
  ///
  /// In en, this message translates to:
  /// **'Event added'**
  String get scanEventAdded;

  /// No description provided for @scanReview.
  ///
  /// In en, this message translates to:
  /// **'Review scan'**
  String get scanReview;

  /// No description provided for @scanLowConfidence.
  ///
  /// In en, this message translates to:
  /// **'Low confidence — double-check the title, date, and amount before saving.'**
  String get scanLowConfidence;

  /// No description provided for @scanTimed.
  ///
  /// In en, this message translates to:
  /// **'Timed'**
  String get scanTimed;

  /// No description provided for @scanEndTimeOptional.
  ///
  /// In en, this message translates to:
  /// **'End time (optional)'**
  String get scanEndTimeOptional;

  /// No description provided for @scanAmountDue.
  ///
  /// In en, this message translates to:
  /// **'Amount due'**
  String get scanAmountDue;

  /// No description provided for @scanAssignTo.
  ///
  /// In en, this message translates to:
  /// **'Assign to'**
  String get scanAssignTo;

  /// No description provided for @scanAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get scanAddExpense;

  /// No description provided for @scanAddBill.
  ///
  /// In en, this message translates to:
  /// **'Add bill'**
  String get scanAddBill;

  /// No description provided for @scanAddTask.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get scanAddTask;

  /// No description provided for @scanAddEvent.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get scanAddEvent;

  /// No description provided for @locatorPulse.
  ///
  /// In en, this message translates to:
  /// **'Your nest pulse'**
  String get locatorPulse;

  /// No description provided for @locatorLocations.
  ///
  /// In en, this message translates to:
  /// **'Nest locations'**
  String get locatorLocations;

  /// No description provided for @locatorLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load nest locations.'**
  String get locatorLoadFailed;

  /// No description provided for @locatorPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Locator never tracks in the background. Pins expire visually after 24 hours so the nest doesn’t rely on outdated places.'**
  String get locatorPrivacyNote;

  /// No description provided for @locatorSharedSnack.
  ///
  /// In en, this message translates to:
  /// **'Shared your location with the nest'**
  String get locatorSharedSnack;

  /// No description provided for @locatorGetFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location. Try again.'**
  String get locatorGetFailed;

  /// No description provided for @locatorUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update sharing.'**
  String get locatorUpdateFailed;

  /// No description provided for @locatorLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {age}'**
  String locatorLastSeen(String age);

  /// No description provided for @locatorUpdatedAge.
  ///
  /// In en, this message translates to:
  /// **'Updated {age}'**
  String locatorUpdatedAge(String age);

  /// No description provided for @locatorOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Open map'**
  String get locatorOpenMap;

  /// No description provided for @locatorMapWake.
  ///
  /// In en, this message translates to:
  /// **'Nest map wakes up when someone shares a pin'**
  String get locatorMapWake;

  /// No description provided for @locatorShrinkMap.
  ///
  /// In en, this message translates to:
  /// **'Shrink map'**
  String get locatorShrinkMap;

  /// No description provided for @locatorExpandMap.
  ///
  /// In en, this message translates to:
  /// **'Expand map'**
  String get locatorExpandMap;

  /// No description provided for @locatorSatellite.
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get locatorSatellite;

  /// No description provided for @locatorModernMap.
  ///
  /// In en, this message translates to:
  /// **'Modern map'**
  String get locatorModernMap;

  /// No description provided for @locatorFitAll.
  ///
  /// In en, this message translates to:
  /// **'Fit all'**
  String get locatorFitAll;

  /// No description provided for @emergencyOfflineNote.
  ///
  /// In en, this message translates to:
  /// **'Available offline — critical info stays on this device and syncs when you are online.'**
  String get emergencyOfflineNote;

  /// No description provided for @emergencyCareProfiles.
  ///
  /// In en, this message translates to:
  /// **'Care profiles'**
  String get emergencyCareProfiles;

  /// No description provided for @emergencyAddHint.
  ///
  /// In en, this message translates to:
  /// **'Add emergency contacts, allergies, and doctors.'**
  String get emergencyAddHint;

  /// No description provided for @emergencyCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Casaio emergency card — {nest}'**
  String emergencyCardTitle(String nest);

  /// No description provided for @emergencyInfo.
  ///
  /// In en, this message translates to:
  /// **'Emergency info'**
  String get emergencyInfo;

  /// No description provided for @schoolIntro.
  ///
  /// In en, this message translates to:
  /// **'School runs, sports, clubs, and pickups. Add one activity to get started — mark done to roll the next date, or create a same-day pickup task.'**
  String get schoolIntro;

  /// No description provided for @schoolDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get schoolDueToday;

  /// No description provided for @snackCalendarAdded.
  ///
  /// In en, this message translates to:
  /// **'Calendar event added · {date}'**
  String snackCalendarAdded(String date);

  /// No description provided for @schoolNewActivity.
  ///
  /// In en, this message translates to:
  /// **'New activity'**
  String get schoolNewActivity;

  /// No description provided for @schoolEditActivity.
  ///
  /// In en, this message translates to:
  /// **'Edit activity'**
  String get schoolEditActivity;

  /// No description provided for @schoolWhoFor.
  ///
  /// In en, this message translates to:
  /// **'Who is this for?'**
  String get schoolWhoFor;

  /// No description provided for @careIntro.
  ///
  /// In en, this message translates to:
  /// **'Elder profiles plus pet, home, and car upkeep. Mark done to roll the next due date — start with one schedule if the list is empty.'**
  String get careIntro;

  /// No description provided for @careElderProfiles.
  ///
  /// In en, this message translates to:
  /// **'Elder profiles'**
  String get careElderProfiles;

  /// No description provided for @careAddMembersHint.
  ///
  /// In en, this message translates to:
  /// **'Add family members in Nest, then set a Grandparent role.'**
  String get careAddMembersHint;

  /// No description provided for @careNoElders.
  ///
  /// In en, this message translates to:
  /// **'No elder profiles yet — set Grandparent in Nest, then add meds and allergies here.'**
  String get careNoElders;

  /// No description provided for @careDueNow.
  ///
  /// In en, this message translates to:
  /// **'Due now'**
  String get careDueNow;

  /// No description provided for @careNewItem.
  ///
  /// In en, this message translates to:
  /// **'New care item'**
  String get careNewItem;

  /// No description provided for @careEditItem.
  ///
  /// In en, this message translates to:
  /// **'Edit care item'**
  String get careEditItem;

  /// No description provided for @careForWhom.
  ///
  /// In en, this message translates to:
  /// **'For whom?'**
  String get careForWhom;

  /// No description provided for @careProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Care profile · {name}'**
  String careProfileTitle(String name);

  /// No description provided for @mealsIntro.
  ///
  /// In en, this message translates to:
  /// **'Plan dinners for the week, then push ingredients to the shared grocery list.'**
  String get mealsIntro;

  /// No description provided for @mealsRestOfWeek.
  ///
  /// In en, this message translates to:
  /// **'Rest of week'**
  String get mealsRestOfWeek;

  /// No description provided for @mealsNonePlanned.
  ///
  /// In en, this message translates to:
  /// **'No meal planned — tap to add dinner'**
  String get mealsNonePlanned;

  /// No description provided for @mealsPlanAMeal.
  ///
  /// In en, this message translates to:
  /// **'Plan a meal'**
  String get mealsPlanAMeal;

  /// No description provided for @mealsEditMeal.
  ///
  /// In en, this message translates to:
  /// **'Edit meal'**
  String get mealsEditMeal;

  /// No description provided for @mealsSaveMeal.
  ///
  /// In en, this message translates to:
  /// **'Save meal'**
  String get mealsSaveMeal;

  /// No description provided for @mealsPlanWeekBody.
  ///
  /// In en, this message translates to:
  /// **'Fill the nights you care about. Blank days stay empty.'**
  String get mealsPlanWeekBody;

  /// No description provided for @mealsRecipeLibrary.
  ///
  /// In en, this message translates to:
  /// **'Recipe library'**
  String get mealsRecipeLibrary;

  /// No description provided for @mealsAddRecipe.
  ///
  /// In en, this message translates to:
  /// **'Add recipe'**
  String get mealsAddRecipe;

  /// No description provided for @mealsEditRecipe.
  ///
  /// In en, this message translates to:
  /// **'Edit recipe'**
  String get mealsEditRecipe;

  /// No description provided for @mealsSaveRecipe.
  ///
  /// In en, this message translates to:
  /// **'Save recipe'**
  String get mealsSaveRecipe;

  /// No description provided for @mealsApplyRecipe.
  ///
  /// In en, this message translates to:
  /// **'Apply to this day'**
  String get mealsApplyRecipe;

  /// No description provided for @mealsSaveAsRecipe.
  ///
  /// In en, this message translates to:
  /// **'Save as recipe'**
  String get mealsSaveAsRecipe;

  /// No description provided for @mealsNoRecipes.
  ///
  /// In en, this message translates to:
  /// **'No saved recipes yet — save a meal slot or add one here.'**
  String get mealsNoRecipes;

  /// No description provided for @mealsRecipeApplied.
  ///
  /// In en, this message translates to:
  /// **'Recipe applied'**
  String get mealsRecipeApplied;

  /// No description provided for @hintRecipeNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get hintRecipeNotes;

  /// No description provided for @shopClearBoughtBody.
  ///
  /// In en, this message translates to:
  /// **'Removes checked-off groceries from this list. You can still restock habits later.'**
  String get shopClearBoughtBody;

  /// No description provided for @shopNothingToClear.
  ///
  /// In en, this message translates to:
  /// **'Nothing to clear'**
  String get shopNothingToClear;

  /// No description provided for @shopClearedBought.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Cleared 1 bought item} other{Cleared {count} bought items}}'**
  String shopClearedBought(int count);

  /// No description provided for @shopSharedList.
  ///
  /// In en, this message translates to:
  /// **'Shared list'**
  String get shopSharedList;

  /// No description provided for @shopNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No items match this search or filter.'**
  String get shopNoMatch;

  /// No description provided for @shopEditItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get shopEditItem;

  /// No description provided for @shopDeleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete item'**
  String get shopDeleteItem;

  /// No description provided for @shopBasedOnUsual.
  ///
  /// In en, this message translates to:
  /// **'Based on what you usually buy'**
  String get shopBasedOnUsual;

  /// No description provided for @shopNewList.
  ///
  /// In en, this message translates to:
  /// **'New list'**
  String get shopNewList;

  /// No description provided for @shopListNameHint.
  ///
  /// In en, this message translates to:
  /// **'List name'**
  String get shopListNameHint;

  /// No description provided for @shopCreateList.
  ///
  /// In en, this message translates to:
  /// **'Create list'**
  String get shopCreateList;

  /// No description provided for @shopRenameList.
  ///
  /// In en, this message translates to:
  /// **'Rename list'**
  String get shopRenameList;

  /// No description provided for @shopDeleteList.
  ///
  /// In en, this message translates to:
  /// **'Delete list'**
  String get shopDeleteList;

  /// No description provided for @shopDeleteListBody.
  ///
  /// In en, this message translates to:
  /// **'Removes this list and its items from your nest.'**
  String get shopDeleteListBody;

  /// No description provided for @shopEmptyListTitle.
  ///
  /// In en, this message translates to:
  /// **'This list is empty'**
  String get shopEmptyListTitle;

  /// No description provided for @shopEmptyListBody.
  ///
  /// In en, this message translates to:
  /// **'Add items for this store or occasion.'**
  String get shopEmptyListBody;

  /// No description provided for @shopRestock.
  ///
  /// In en, this message translates to:
  /// **'Restock'**
  String get shopRestock;

  /// No description provided for @tasksNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No tasks match this search.'**
  String get tasksNoMatch;

  /// No description provided for @tasksFilterFor.
  ///
  /// In en, this message translates to:
  /// **'Filter tasks for {name}'**
  String tasksFilterFor(String name);

  /// No description provided for @taskNew.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get taskNew;

  /// No description provided for @taskEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get taskEdit;

  /// No description provided for @taskHabitHint.
  ///
  /// In en, this message translates to:
  /// **'Stays open and advances the due date when done'**
  String get taskHabitHint;

  /// No description provided for @taskAdd.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get taskAdd;

  /// No description provided for @calendarNewEvent.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get calendarNewEvent;

  /// No description provided for @calendarEditEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get calendarEditEvent;

  /// No description provided for @calendarDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This removes it from the shared calendar.'**
  String get calendarDeleteBody;

  /// No description provided for @resetMailSubject.
  ///
  /// In en, this message translates to:
  /// **'Casaio password reset help'**
  String get resetMailSubject;

  /// No description provided for @resetMailBody.
  ///
  /// In en, this message translates to:
  /// **'Account email: {email}\n\n'**
  String resetMailBody(String email);

  /// No description provided for @resetFillBoth.
  ///
  /// In en, this message translates to:
  /// **'Fill in your current and new password.'**
  String get resetFillBoth;

  /// No description provided for @resetMismatch.
  ///
  /// In en, this message translates to:
  /// **'New passwords don’t match.'**
  String get resetMismatch;

  /// No description provided for @onboardingScanSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Scan suggestion'**
  String get onboardingScanSuggestion;

  /// No description provided for @onboardingGroceryRun.
  ///
  /// In en, this message translates to:
  /// **'Grocery run · \$42.50'**
  String get onboardingGroceryRun;

  /// No description provided for @onboardingSuggestedExpense.
  ///
  /// In en, this message translates to:
  /// **'Suggested expense from your receipt'**
  String get onboardingSuggestedExpense;

  /// No description provided for @onboardingSaveExpense.
  ///
  /// In en, this message translates to:
  /// **'Save expense'**
  String get onboardingSaveExpense;

  /// No description provided for @onboardingEditFirst.
  ///
  /// In en, this message translates to:
  /// **'Edit first'**
  String get onboardingEditFirst;

  /// No description provided for @paidByAnyone.
  ///
  /// In en, this message translates to:
  /// **'Anyone'**
  String get paidByAnyone;

  /// No description provided for @shopLeftCount.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String shopLeftCount(int count);

  /// No description provided for @shopBoughtCount.
  ///
  /// In en, this message translates to:
  /// **'{count} bought'**
  String shopBoughtCount(int count);

  /// No description provided for @taskRepeats.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get taskRepeats;

  /// No description provided for @taskPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get taskPickDate;

  /// No description provided for @taskCadenceDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get taskCadenceDaily;

  /// No description provided for @taskCadenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get taskCadenceWeekly;

  /// No description provided for @taskCadenceBiweekly.
  ///
  /// In en, this message translates to:
  /// **'Every 2 weeks'**
  String get taskCadenceBiweekly;

  /// No description provided for @taskCadenceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get taskCadenceMonthly;

  /// No description provided for @taskCadenceEveryDays.
  ///
  /// In en, this message translates to:
  /// **'Every {days} days'**
  String taskCadenceEveryDays(int days);

  /// No description provided for @taskRepeatsCadence.
  ///
  /// In en, this message translates to:
  /// **'Repeats · {cadence}'**
  String taskRepeatsCadence(String cadence);

  /// No description provided for @taskOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get taskOpen;

  /// No description provided for @locatorNearMe.
  ///
  /// In en, this message translates to:
  /// **'Near me'**
  String get locatorNearMe;

  /// No description provided for @locatorAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String locatorAway(String distance);

  /// No description provided for @locatorSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to share your location.'**
  String get locatorSignIn;

  /// No description provided for @locatorJoinNest.
  ///
  /// In en, this message translates to:
  /// **'Join a nest before sharing location.'**
  String get locatorJoinNest;

  /// No description provided for @locatorNeedPermission.
  ///
  /// In en, this message translates to:
  /// **'Location permission is needed to share where you are.'**
  String get locatorNeedPermission;

  /// No description provided for @locatorNeedServices.
  ///
  /// In en, this message translates to:
  /// **'Turn on Location Services to share.'**
  String get locatorNeedServices;

  /// No description provided for @vaultPackSubject.
  ///
  /// In en, this message translates to:
  /// **'Casaio vault pack ({count})'**
  String vaultPackSubject(int count);

  /// No description provided for @vaultPackText.
  ///
  /// In en, this message translates to:
  /// **'Shared from Casaio vault'**
  String get vaultPackText;

  /// No description provided for @vaultNoFilesShare.
  ///
  /// In en, this message translates to:
  /// **'No files available to share yet.'**
  String get vaultNoFilesShare;

  /// No description provided for @privacyExportSubject.
  ///
  /// In en, this message translates to:
  /// **'Casaio data export'**
  String get privacyExportSubject;

  /// No description provided for @privacyExportShareText.
  ///
  /// In en, this message translates to:
  /// **'Your Casaio nest export (JSON). Vault file binaries are not included.'**
  String get privacyExportShareText;

  /// No description provided for @mealsAddIngredientsTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add 1 ingredient?} other{Add {count} ingredients?}}'**
  String mealsAddIngredientsTitle(int count);

  /// No description provided for @mealsAddIngredientsBody.
  ///
  /// In en, this message translates to:
  /// **'From {label} — already-on-list items are skipped.'**
  String mealsAddIngredientsBody(String label);

  /// No description provided for @scanEmptyResult.
  ///
  /// In en, this message translates to:
  /// **'Scan returned an empty result. Try a clearer photo.'**
  String get scanEmptyResult;

  /// No description provided for @scanUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Scan returned an unexpected response. Try another photo.'**
  String get scanUnexpected;

  /// No description provided for @scanTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Scan timed out. Try a clearer photo or a smaller file.'**
  String get scanTimedOut;

  /// No description provided for @scanReachFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reach Vertex AI. Check your connection and try again.'**
  String get scanReachFailed;

  /// No description provided for @scanQuotaReached.
  ///
  /// In en, this message translates to:
  /// **'AI quota reached for today. Try again later.'**
  String get scanQuotaReached;

  /// No description provided for @scanNeedBlaze.
  ///
  /// In en, this message translates to:
  /// **'Vertex AI needs the Firebase Blaze plan. Upgrade billing in Firebase Console, enable Vertex AI, then try again.'**
  String get scanNeedBlaze;

  /// No description provided for @scanVertexNotReady.
  ///
  /// In en, this message translates to:
  /// **'Vertex AI Gemini is not ready. In Firebase Console enable AI Logic with the Vertex AI Gemini API (Blaze), then try again.'**
  String get scanVertexNotReady;

  /// No description provided for @scanFileTooLargeAi.
  ///
  /// In en, this message translates to:
  /// **'That file is too large. Use a photo or PDF under about 4 MB.'**
  String get scanFileTooLargeAi;

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @locatorLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get locatorLive;

  /// No description provided for @locatorDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get locatorDirections;

  /// No description provided for @pressBackAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get pressBackAgainToExit;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
