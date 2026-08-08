// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Casaio';

  @override
  String get tabHome => 'Home';

  @override
  String get tabCalendar => 'Calendar';

  @override
  String get tabTasks => 'Tasks';

  @override
  String get tabShop => 'Shop';

  @override
  String get tabNest => 'Nest';

  @override
  String get navMain => 'Main navigation';

  @override
  String get addToCasaio => 'Add to Casaio';

  @override
  String get addEvent => 'Event';

  @override
  String get addTask => 'Task';

  @override
  String get addShoppingItem => 'Shopping item';

  @override
  String get addScan => 'Scan receipt / invite';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonAll => 'All';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonDone => 'Done';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonNext => 'Next';

  @override
  String get commonBack => 'Back';

  @override
  String get commonShare => 'Share';

  @override
  String get commonOpen => 'Open';

  @override
  String get commonClose => 'Close';

  @override
  String get commonLoad => 'Load';

  @override
  String get commonPaid => 'Paid';

  @override
  String get commonView => 'View';

  @override
  String get commonPlan => 'Plan';

  @override
  String get commonReview => 'Review';

  @override
  String get commonRestock => 'Restock';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonNotes => 'Notes';

  @override
  String get commonTitle => 'Title';

  @override
  String get commonAmount => 'Amount';

  @override
  String get commonCategory => 'Category';

  @override
  String get commonLocation => 'Location';

  @override
  String get commonSettings => 'Settings';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSubtitle => 'App language for this device';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get authWelcomeBack => 'Welcome back';

  @override
  String get authCreateAccount => 'Create your family account';

  @override
  String get authEmailHint => 'Email';

  @override
  String get authPasswordHint => 'Password';

  @override
  String get authNameHint => 'Your name';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignUp => 'Create account';

  @override
  String get authHaveAccount => 'Already have an account? Sign in';

  @override
  String get authNeedAccount => 'New here? Create an account';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authInvalidEmail => 'Enter a valid email address.';

  @override
  String get authPasswordTooShort => 'Password must be at least 6 characters.';

  @override
  String get authEnterName => 'Enter your name.';

  @override
  String get authCheckFailed => 'Could not check sign-in.';

  @override
  String get authErrorInvalidEmail => 'That email address looks invalid.';

  @override
  String get authErrorDisabled => 'This account has been disabled.';

  @override
  String get authErrorBadCredential => 'Email or password is incorrect.';

  @override
  String get authErrorEmailInUse => 'An account already exists for that email.';

  @override
  String get authErrorWeakPassword =>
      'Use a password with at least 6 characters.';

  @override
  String get authErrorTooMany =>
      'Too many attempts. Try again in a few minutes.';

  @override
  String get authErrorNetwork =>
      'No network. Check your connection and try again.';

  @override
  String get authErrorNotAllowed =>
      'Email sign-in is not enabled yet for this project.';

  @override
  String get authErrorRecentLogin =>
      'For security, enter your password again to continue.';

  @override
  String get authErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get authErrorPermission =>
      'Cloud access was denied. Sign out, sign in again, or check Firestore rules.';

  @override
  String get authErrorNotFound => 'That nest or invite was not found.';

  @override
  String get authErrorAlreadyExists =>
      'That invite code is already in use. Try again.';

  @override
  String authErrorGenericCode(String code) {
    return 'Something went wrong ($code). Please try again.';
  }

  @override
  String get authErrorInviteMissing => 'That invite code was not found.';

  @override
  String get authErrorSignInAgain =>
      'Please sign in again, then start your nest.';

  @override
  String get onboardingTitle1 => 'Perfectly Organize\nYour Family Life';

  @override
  String get onboardingBody1 =>
      'Manage events, chores, groceries, and daily plans in one simple shared place.';

  @override
  String get onboardingTitle2 => 'Quiet help when\nyou scan';

  @override
  String get onboardingBody2 =>
      'Casaio’s AI only assists when you scan a receipt or invite — it suggests an event or expense. It doesn’t run your nest for you.';

  @override
  String get onboardingTitle3 => 'Stay Connected\nTogether';

  @override
  String get onboardingBody3 =>
      'Share plans, assign tasks, and keep your whole family perfectly in sync.';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get nestSetupTitle => 'Start your nest';

  @override
  String get settingsTimeline => 'Timeline';

  @override
  String get settingsTimelineSubtitle =>
      'Recent nest activity across the family';

  @override
  String get settingsLocator => 'Locator';

  @override
  String get settingsLocatorSubtitle =>
      'Live nest map · opt-in last-known pins';

  @override
  String get settingsPassword => 'Change password';

  @override
  String get settingsPasswordSubtitle => 'Still signed in? Update it here';

  @override
  String get settingsTomorrowPreview => 'Tomorrow preview';

  @override
  String get settingsTomorrowPreviewSubtitle =>
      'Quiet evening reminder for tomorrow’s bills, care, and school';

  @override
  String get settingsPrivacy => 'Privacy & data';

  @override
  String get settingsAbout => 'About Casaio';

  @override
  String get settingsShowcase => 'Load App Store showcase';

  @override
  String get settingsShowcaseSubtitle =>
      'Debug/profile only — not in App Store builds';

  @override
  String get settingsCrash => 'Force test crash';

  @override
  String get settingsCrashSubtitle => 'Verify Crashlytics in Firebase console';

  @override
  String get showcaseConfirmTitle => 'Load showcase data?';

  @override
  String get showcaseConfirmBody =>
      'Replaces nest content with polished App Store sample data (family, calendar, tasks, shopping, vault, and more), then syncs.';

  @override
  String get showcaseLoading => 'Loading showcase data…';

  @override
  String get showcaseReady => 'Showcase data ready — open Home to review';

  @override
  String showcaseFailed(String error) {
    return 'Could not load showcase: $error';
  }

  @override
  String roleForMember(String name) {
    return 'Role for $name';
  }

  @override
  String get roleAdult => 'Adult';

  @override
  String get roleCoParent => 'Co-parent';

  @override
  String get roleKid => 'Kid';

  @override
  String get roleGrandparent => 'Grandparent';

  @override
  String get roleMember => 'Member';

  @override
  String get filterAdults => 'Adults';

  @override
  String get filterKids => 'Kids';

  @override
  String get filterGrandparents => 'Grandparents';

  @override
  String get careViewDue => 'Due list';

  @override
  String get careViewCategory => 'By category';

  @override
  String get careCategoryElder => 'Elder';

  @override
  String get careCategoryHome => 'Home';

  @override
  String get careCategoryPet => 'Pet';

  @override
  String get careCategoryCar => 'Car';

  @override
  String get schoolKindSchool => 'School';

  @override
  String get schoolKindSports => 'Sports';

  @override
  String get schoolKindPickup => 'Pickup';

  @override
  String get schoolKindClub => 'Club';

  @override
  String get shopProduce => 'Produce';

  @override
  String get shopDairy => 'Dairy';

  @override
  String get shopMeat => 'Meat';

  @override
  String get shopBakery => 'Bakery';

  @override
  String get shopPantry => 'Pantry';

  @override
  String get shopFrozen => 'Frozen';

  @override
  String get shopHousehold => 'Household';

  @override
  String get shopGeneral => 'General';

  @override
  String get shopMeals => 'Meals';

  @override
  String get expenseGroceries => 'Groceries';

  @override
  String get expenseTransport => 'Transport';

  @override
  String get expenseKids => 'Kids';

  @override
  String get expenseHome => 'Home';

  @override
  String get expenseDining => 'Dining';

  @override
  String get expenseHealth => 'Health';

  @override
  String get expenseGeneral => 'General';

  @override
  String get vaultFamily => 'Family';

  @override
  String get vaultHealth => 'Health';

  @override
  String get vaultHouse => 'House';

  @override
  String get vaultWork => 'Work';

  @override
  String get vaultCar => 'Car';

  @override
  String get vaultFinance => 'Finance';

  @override
  String get vaultIds => 'IDs';

  @override
  String get vaultAllFolders => 'All folders';

  @override
  String get vaultDocuments => 'Documents';

  @override
  String get taskDueToday => 'Today';

  @override
  String get taskDueTomorrow => 'Tomorrow';

  @override
  String get taskDueIn7Days => 'In 7 days';

  @override
  String get uploadLocal => 'Local';

  @override
  String get uploadUploading => 'Uploading';

  @override
  String get uploadSynced => 'Synced';

  @override
  String get uploadFailed => 'Failed';

  @override
  String get timelineAll => 'All';

  @override
  String get timelineTasks => 'Tasks';

  @override
  String get timelineLists => 'Lists';

  @override
  String get timelineCare => 'Care';

  @override
  String get timelineMeals => 'Meals';

  @override
  String get timelineVault => 'Vault';

  @override
  String get timelineSchool => 'School';

  @override
  String get timelineOther => 'Other';

  @override
  String needCareDue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count care items due',
      one: '1 care item due',
    );
    return '$_temp0';
  }

  @override
  String get needCareDetail => 'Mark done when finished';

  @override
  String needSchoolDue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count school / pickups due',
      one: '1 school / pickup due',
    );
    return '$_temp0';
  }

  @override
  String get needSchoolDetail => 'Confirm who’s covering the run';

  @override
  String needBillsDue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bills due soon',
      one: '1 bill due soon',
    );
    return '$_temp0';
  }

  @override
  String get needBillsDetail => 'Mark paid when you’ve settled them';

  @override
  String needTasksOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open tasks',
      one: '1 open task',
    );
    return '$_temp0';
  }

  @override
  String get needTasksDetail => 'Finish one now or open the list';

  @override
  String needShoppingLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grocery items left',
      one: '1 grocery item left',
    );
    return '$_temp0';
  }

  @override
  String get needShoppingDetail => 'Check them off on the shared list';

  @override
  String get needShoppingOpenList => 'Open list';

  @override
  String needRestock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Restock $count usual items',
      one: 'Restock 1 usual item',
    );
    return '$_temp0';
  }

  @override
  String get needRestockDetail => 'Based on what you buy often';

  @override
  String get needVaultOne => '1 document expires soon';

  @override
  String needVaultMany(int count) {
    return '$count documents expire soon';
  }

  @override
  String get needVaultDetail =>
      'Passports, insurance, or licenses — renew before they lapse';

  @override
  String get needDinnerMissing => 'No dinner planned today';

  @override
  String get needDinnerMissingDetail =>
      'Add a meal — ingredients can go to the list';

  @override
  String needDinnerPlanned(String title) {
    return 'Dinner: $title';
  }

  @override
  String get needDinnerPlannedDetail => 'Push ingredients to the grocery list';

  @override
  String get needQuietDay => 'Quiet day';

  @override
  String get needQuietDetail => 'Nothing urgent — a good time to plan ahead';

  @override
  String needEventsToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events today',
      one: '1 event today',
    );
    return '$_temp0';
  }

  @override
  String get needEventsDetail => 'Open Calendar so nobody is surprised';

  @override
  String get screenCare => 'Care';

  @override
  String get screenSchool => 'School & activities';

  @override
  String get screenMeals => 'Meals';

  @override
  String get screenExpenses => 'Expenses';

  @override
  String get screenVault => 'Documents';

  @override
  String get screenEmergency => 'Emergency';

  @override
  String get screenTimeline => 'Timeline';

  @override
  String get screenLocator => 'Locator';

  @override
  String get screenPrivacy => 'Privacy & data';

  @override
  String get screenAbout => 'About Casaio';

  @override
  String get screenShopping => 'Shopping';

  @override
  String get calendarTitle => 'Family calendar';

  @override
  String get calendarTitleAgenda => 'Agenda';

  @override
  String get calendarBrowseMonth => 'Month';

  @override
  String get calendarBrowseWeek => 'Week';

  @override
  String get calendarBrowseAgenda => 'Agenda';

  @override
  String get calendarAgendaUpcoming => 'Next 7 days';

  @override
  String get eventRecurrence => 'Repeats';

  @override
  String get eventRecurrenceNone => 'Does not repeat';

  @override
  String get eventRecurrenceDaily => 'Every day';

  @override
  String get eventRecurrenceWeekly => 'Every week';

  @override
  String get eventRecurrenceMonthly => 'Every month';

  @override
  String get eventRecurrenceUntil => 'Repeat until (optional)';

  @override
  String get calendarEditSeriesHint =>
      'Changes apply to the whole repeating series.';

  @override
  String get homeTodaySnapshot => 'Today snapshot';

  @override
  String get homeHello => 'Hello';

  @override
  String get syncNotYet => 'Not synced yet';

  @override
  String get syncJustNow => 'Just now';

  @override
  String syncMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String syncHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String syncDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get syncKeptOne => 'Kept 1 local edit while syncing';

  @override
  String syncKeptMany(int count) {
    return 'Kept $count local edits while syncing';
  }

  @override
  String get syncFailedNetwork =>
      'Couldn’t sync — check your connection. Changes stay on this device.';

  @override
  String get syncFailedGeneric =>
      'Couldn’t sync. Changes stay on this device — retry from Nest.';

  @override
  String get notifChannelGeneral => 'Casaio';

  @override
  String get notifChannelGeneralDesc => 'Family reminders and updates';

  @override
  String get notifChannelPreview => 'Tomorrow preview';

  @override
  String get notifChannelPreviewDesc => 'A quiet evening look at tomorrow';

  @override
  String get notifChannelBills => 'Bills';

  @override
  String get notifChannelBillsDesc =>
      'Reminders before household bills are due';

  @override
  String get notifChannelCare => 'Care';

  @override
  String get notifChannelCareDesc => 'Reminders for household and elder care';

  @override
  String get notifChannelSchool => 'School';

  @override
  String get notifChannelSchoolDesc =>
      'Reminders for school runs and activities';

  @override
  String get notifChannelEvents => 'Events';

  @override
  String get notifChannelEventsDesc => 'Reminders before calendar events';

  @override
  String get notifChannelTasks => 'Tasks';

  @override
  String get notifChannelTasksDesc => 'Reminders for open nest tasks';

  @override
  String get notifTomorrowTitle => 'Tomorrow in Casaio';

  @override
  String notifTomorrowBody(String parts) {
    return '$parts due tomorrow';
  }

  @override
  String notifBillCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bills',
      one: '1 bill',
    );
    return '$_temp0';
  }

  @override
  String notifCareCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count care tasks',
      one: '1 care task',
    );
    return '$_temp0';
  }

  @override
  String notifSchoolCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count school items',
      one: '1 school item',
    );
    return '$_temp0';
  }

  @override
  String notifEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events',
      one: '1 event',
    );
    return '$_temp0';
  }

  @override
  String notifTaskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
    );
    return '$_temp0';
  }

  @override
  String get notifBillDueTomorrow => 'Bill due tomorrow';

  @override
  String notifBillBody(String title, String amount) {
    return '$title · \$$amount';
  }

  @override
  String get notifElderCareDue => 'Elder care due';

  @override
  String get notifCareDue => 'Care due';

  @override
  String get notifSchoolPickup => 'School / pickup';

  @override
  String get notifComingUp => 'Coming up';

  @override
  String get notifTaskDue => 'Task due';

  @override
  String get widgetAllClear => 'All clear';

  @override
  String get widgetNothingScheduled => 'Nothing scheduled';

  @override
  String get widgetNotPlanned => 'Not planned';

  @override
  String get widgetJoinNest => 'Open Casaio to join a nest';

  @override
  String get widgetQuietDay => 'Quiet day · enjoy it';

  @override
  String widgetOpenTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open tasks',
      one: '1 open task',
    );
    return '$_temp0';
  }

  @override
  String widgetOpenShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open',
      one: '1 open',
    );
    return '$_temp0';
  }

  @override
  String get widgetJustNow => 'just now';

  @override
  String widgetMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String widgetHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String widgetDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get widgetEarlier => 'earlier';

  @override
  String get widgetToday => 'Today';

  @override
  String get widgetWelcome => 'Welcome';

  @override
  String widgetUpdated(String age) {
    return 'Updated $age';
  }

  @override
  String get widgetName => 'Casaio Today';

  @override
  String get widgetDescription =>
      'Open tasks, next event, and tonight’s dinner — no vault data.';

  @override
  String get locatorAll => 'All';

  @override
  String get locatorFresh => 'Fresh';

  @override
  String get locatorStale => 'Stale';

  @override
  String get scanKindEvent => 'Event';

  @override
  String get scanKindExpense => 'Expense';

  @override
  String get scanKindBill => 'Bill';

  @override
  String get scanKindTask => 'Task';

  @override
  String get emptyTasksTitle => 'Add your first task';

  @override
  String get emptyShoppingTitle => 'Start the grocery list';

  @override
  String get emptyCareTitle => 'Add your first care schedule';

  @override
  String get emptySchoolTitle => 'Add your first school run';

  @override
  String get emptyCalendarTitle => 'Add your first event';

  @override
  String get emptyMealsTitle => 'Plan this week’s dinners';

  @override
  String get emptyExpensesTitle => 'Log your first expense';

  @override
  String get emptyTimelineTitle => 'Nothing on the timeline yet';

  @override
  String get emptyCareBody =>
      'Pet, home, car, or elder routines — mark done to roll the next due date.';

  @override
  String get emptySchoolBody =>
      'Pickups, sports, and clubs — confirm who’s covering the run.';

  @override
  String get authLogIn => 'Log in';

  @override
  String get authSignUpShort => 'Sign up';

  @override
  String get authHaveAccountLogin => 'Already have an account? Log in';

  @override
  String get authNeedAccountSignup => 'Need an account? Sign up';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authWorking => 'Working';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonSignOut => 'Sign out';

  @override
  String get commonPaste => 'Paste';

  @override
  String onboardingPageOf(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get nestSetupJoinTitle => 'Join nest';

  @override
  String get nestSetupCreateTitle => 'Set up in under a minute';

  @override
  String get nestSetupJoinBody =>
      'Paste or type the 6-character code from your family.';

  @override
  String get nestSetupCreateBody =>
      'Create your household nest. You can rename it and invite family later.';

  @override
  String get nestSetupNameHelper => 'Shown on shared tasks and timeline';

  @override
  String get nestSetupInviteCode => 'Invite code';

  @override
  String get nestSetupInviteHelper =>
      'Spaces and dashes are stripped automatically';

  @override
  String get nestSetupNestName => 'Nest name';

  @override
  String get nestSetupNestHelper =>
      'Defaults are fine — you can change this later';

  @override
  String get nestSetupAfterStart =>
      'After you start, Casaio will offer an invite code so someone can join.';

  @override
  String get nestSetupStart => 'Start nest';

  @override
  String get nestSetupSwitchCreate => 'Create a new nest instead';

  @override
  String get nestSetupSwitchJoin => 'Have an invite code?';

  @override
  String get clipboardEmpty => 'Clipboard is empty';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get resetPasswordIntro =>
      'We’ll email you a secure link to choose a new password.';

  @override
  String get resetCheckInbox => 'Check your inbox';

  @override
  String resetCheckInboxBody(String email) {
    return 'If an account exists for $email, you’ll get a reset link shortly. Open it on this device or any browser, then log in with your new password.';
  }

  @override
  String get resetDontSee => 'Don’t see it?';

  @override
  String get resetDontSeeBody =>
      'Check Spam and Promotions (Gmail often files Firebase emails there). Wait a minute, then resend.';

  @override
  String get resetSendLink => 'Send reset link';

  @override
  String get resetResend => 'Resend email';

  @override
  String resetResendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get resetEmailSupport => 'Email support@casaio.app';

  @override
  String get resetEnterEmail => 'Enter the email for your Casaio account.';

  @override
  String get screenBudget => 'Budget';

  @override
  String get screenAboutShort => 'About';

  @override
  String get screenPrivacyShort => 'Privacy';

  @override
  String get screenTasks => 'Tasks';

  @override
  String lastSyncedLabel(String age) {
    return 'Last synced · $age';
  }

  @override
  String get homeLists => 'Lists';

  @override
  String get homeAddTask => 'Add a task';

  @override
  String get homeNoneToday => 'None today';

  @override
  String get homeNoneDue => 'None due';

  @override
  String homeCountDue(int count) {
    return '$count due';
  }

  @override
  String homeCountToday(int count) {
    return '$count today';
  }

  @override
  String homeItemsCount(int count) {
    return '$count items';
  }

  @override
  String homeOpenCount(int count) {
    return '$count open';
  }

  @override
  String homeDocsCount(int count) {
    return '$count docs';
  }

  @override
  String get homeThisMonth => 'This month';

  @override
  String get homeAlwaysReady => 'Always ready';

  @override
  String get homeLocatorSubtitle => 'Nest map & last-known pins';

  @override
  String get homeDinnerSet => 'Dinner set';

  @override
  String get homePlanWeek => 'Plan week';

  @override
  String get homeBills => 'Bills';

  @override
  String get deleteEventTitle => 'Delete event?';

  @override
  String get deleteDocumentTitle => 'Remove document?';

  @override
  String get clearBoughtTitle => 'Clear bought items?';

  @override
  String get leaveNestTitle => 'Leave this nest?';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String careEmptyFilter(String filter) {
    return 'Nothing in $filter';
  }

  @override
  String careEmptyFilterHint(String filter) {
    return 'Try another filter, or add a $filter care item.';
  }

  @override
  String get careAddItem => 'Add care item';

  @override
  String schoolEmptyFilter(String filter) {
    return 'Nothing in $filter';
  }

  @override
  String schoolEmptyFilterHint(String filter) {
    return 'Try another filter, or add a $filter activity.';
  }

  @override
  String get schoolAddItem => 'Add activity';

  @override
  String locatorShared(String label) {
    return 'Shared · $label';
  }

  @override
  String get widgetNext => 'Next';

  @override
  String get widgetDinnerChrome => 'Dinner';

  @override
  String get widgetTasksChrome => 'Tasks';

  @override
  String get inviteFamilyTitle => 'Invite family';

  @override
  String inviteCodeCopied(String code) {
    return 'Invite code $code copied — ready to paste';
  }

  @override
  String get inviteShareSubject => 'Join my Casaio nest';

  @override
  String get inviteShareFallbackNest => 'our family nest';

  @override
  String inviteShareText(String nest, String code, String url) {
    return 'Join $nest on Casaio!\n\nInvite code: $code\n\nGet the app: $url\nThen open Casaio → Have an invite code? → paste this code.';
  }

  @override
  String get dowSunday => 'S';

  @override
  String get dowMonday => 'M';

  @override
  String get dowTuesday => 'T';

  @override
  String get dowWednesday => 'W';

  @override
  String get dowThursday => 'T';

  @override
  String get dowFriday => 'F';

  @override
  String get dowSaturday => 'S';

  @override
  String get syncOverWeekAgo => 'over a week ago';

  @override
  String get calendarTitleMonth => 'Family calendar';

  @override
  String get syncing => 'Syncing…';

  @override
  String get syncNeededRetry => 'Sync needed · Retry';

  @override
  String get commonDismiss => 'Dismiss';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonInvite => 'Invite';

  @override
  String get commonNotNow => 'Not now';

  @override
  String get commonSeeAll => 'See all';

  @override
  String get commonGotIt => 'Got it';

  @override
  String get commonDiscard => 'Discard';

  @override
  String get loadFailedGeneric => 'Could not load. Try again later.';

  @override
  String get loadFailedTasks => 'Could not load tasks.';

  @override
  String get loadFailedMeals => 'Could not load meals.';

  @override
  String get loadFailedCare => 'Could not load care items.';

  @override
  String get loadFailedSchool => 'Could not load activities.';

  @override
  String get loadFailedShopping => 'Could not load list. Try again later.';

  @override
  String loadFailedNest(String error) {
    return 'Could not load nest: $error';
  }

  @override
  String get homeStillSolo => 'Still flying solo';

  @override
  String homeStillSoloBody(String code) {
    return 'Invite a partner with $code so Today stays shared.';
  }

  @override
  String get homeInvitePartner => 'Invite a partner';

  @override
  String homeInvitePartnerBody(String code) {
    return 'Share $code so someone can join this nest.';
  }

  @override
  String get homeShareInvite => 'Share invite';

  @override
  String homeInviteChip(String code) {
    return 'Invite · $code';
  }

  @override
  String get homeReminders => 'Reminders';

  @override
  String get homeOpenTasks => 'Open tasks';

  @override
  String get homeOpenEmergency => 'Open emergency card';

  @override
  String get homeTodayReminders => 'Today reminders';

  @override
  String snackDoneTitle(String title) {
    return 'Done: $title';
  }

  @override
  String snackPaidTitle(String title) {
    return 'Paid: $title';
  }

  @override
  String snackRestockAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count restock items',
      one: 'Added 1 restock item',
    );
    return '$_temp0';
  }

  @override
  String get emptyTasksBody =>
      'Chores, reminders, and shared to-dos live here — tap to create one for the nest.';

  @override
  String get emptyTasksNone => 'No tasks here';

  @override
  String emptyTasksNoneNamed(String name) {
    return 'Nothing for $name';
  }

  @override
  String get emptyTasksHint => 'Try another filter or add a task.';

  @override
  String get emptyTasksHintNamed =>
      'Tap All to see everyone, or add a task for them.';

  @override
  String get emptyShoppingBody =>
      'Add milk, eggs, or anything else — pick a category in the field, then add.';

  @override
  String get emptyShoppingAction => 'Add an item';

  @override
  String get emptyMealsBody =>
      'Add tonight’s meal or sketch the week — then push ingredients to Shopping in one tap.';

  @override
  String get emptyMealsAction => 'Plan dinner week';

  @override
  String get emptyExpensesBody =>
      'Pick a monthly spending target, log a few expenses, and track bills so nothing slips.';

  @override
  String get emptyExpensesAction => 'Set month budget';

  @override
  String get emptyCalendarBody =>
      'School runs, dinners, and appointments land here — no demo data, just yours.';

  @override
  String get emptyCalendarNoMatch => 'No events match';

  @override
  String get emptyCalendarNothingToday => 'Nothing planned today';

  @override
  String get emptyCalendarNothingDay => 'Nothing on this day';

  @override
  String get emptyCalendarSearchHint =>
      'Try a different search, or clear the filter.';

  @override
  String get emptyCalendarDayHint => 'Tap to schedule something for this day.';

  @override
  String get emptyCalendarClearSearch => 'Clear search';

  @override
  String get emptyTimelineFilter => 'Nothing in this filter';

  @override
  String get emptyTimelineBody =>
      'As the family checks off tasks, shops, and plans meals, activity shows up here.';

  @override
  String get emptyTimelineFilterHint =>
      'Try another module filter, or clear back to All.';

  @override
  String get locatorEmptyTitle => 'No one is sharing yet';

  @override
  String get locatorEmptyBody =>
      'When a nest member opts in and taps Share now, their last-known pin shows up on the map.';

  @override
  String get locatorShareNow => 'Share now';

  @override
  String get locatorTurnOnSharing => 'Turn on sharing';

  @override
  String get locatorSharingOn => 'Sharing on';

  @override
  String get locatorCoordsCopied => 'Coordinates copied';

  @override
  String get searchEvents => 'Search events';

  @override
  String get searchTasks => 'Search tasks';

  @override
  String get searchList => 'Search list';

  @override
  String get searchExpenses => 'Search expenses & bills';

  @override
  String get searchVault => 'Search by title, notes, or folder';

  @override
  String get hintEventTitle => 'Event title';

  @override
  String get hintLocationOptional => 'Location (optional)';

  @override
  String get hintNotesOptional => 'Notes (optional)';

  @override
  String get hintTaskTitle => 'What needs doing?';

  @override
  String get hintItemName => 'Item name';

  @override
  String get hintQty => 'Qty (e.g. 2, 1 kg)';

  @override
  String get hintAddItem => 'Add an item';

  @override
  String get hintDishName => 'Dish name';

  @override
  String get hintIngredients => 'Ingredients (comma or new line)';

  @override
  String hintDinnerFor(String day) {
    return 'Dinner for $day';
  }

  @override
  String get hintSchoolTitle => 'e.g. Soccer practice';

  @override
  String get paidBy => 'Paid by';

  @override
  String get addBill => 'Add a bill';

  @override
  String get addBillShort => 'Add bill';

  @override
  String get billRepeats => 'Repeats';

  @override
  String get billCadenceNone => 'One-time';

  @override
  String billRepeatsCadence(String cadence) {
    return 'Repeats · $cadence';
  }

  @override
  String get saveBudget => 'Save budget';

  @override
  String get saveWeek => 'Save week';

  @override
  String get saveProfile => 'Save profile';

  @override
  String get saveDetails => 'Save details';

  @override
  String get saveOffline => 'Save offline';

  @override
  String get deleteTask => 'Delete task';

  @override
  String get deleteMeal => 'Delete meal';

  @override
  String get deleteActivity => 'Delete activity';

  @override
  String get deleteEventAction => 'Delete event';

  @override
  String get clearBought => 'Clear bought';

  @override
  String get clearBoughtAction => 'Clear';

  @override
  String get addToList => 'Add to list';

  @override
  String get shopThisWeek => 'Shop this week';

  @override
  String get planDinnerWeek => 'Plan dinner week';

  @override
  String get addIngredients => 'Add ingredients to list';

  @override
  String get mealsUpdated => 'Dinner week updated';

  @override
  String get mealsNoNewIngredients => 'No new ingredients to add';

  @override
  String mealsAddToGroceries(int count) {
    return 'Add $count to groceries';
  }

  @override
  String mealsAddedToGroceries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count items to groceries',
      one: 'Added 1 item to groceries',
    );
    return '$_temp0';
  }

  @override
  String get snooze1Day => 'Snooze 1 day';

  @override
  String get skipCycle => 'Skip this cycle';

  @override
  String get createCalendarEvent => 'Create calendar event';

  @override
  String get addPickupTask => 'Add pickup task';

  @override
  String snackSnoozed(String title) {
    return 'Snoozed $title by 1 day';
  }

  @override
  String snackSkipped(String title) {
    return 'Skipped $title this cycle';
  }

  @override
  String snackPickupAdded(String who) {
    return 'Pickup task added $who';
  }

  @override
  String snackCareProfileSaved(String name) {
    return 'Saved care profile for $name';
  }

  @override
  String get careMeds => 'Medications';

  @override
  String get careMedsHint => 'Morning BP med, evening…';

  @override
  String get careAllergies => 'Allergies';

  @override
  String get careAllergiesHint => 'Penicillin, peanuts…';

  @override
  String get careMobility => 'Mobility & support';

  @override
  String get careMobilityHint => 'Walker, needs help stairs…';

  @override
  String get careDoctor => 'Primary doctor';

  @override
  String get careDoctorHint => 'Dr. Name · clinic';

  @override
  String get careNotesHint => 'Preferences, routines…';

  @override
  String get vaultSelectShare => 'Select to share';

  @override
  String get vaultSharePack => 'Share pack';

  @override
  String get vaultScanCalendar => 'Scan to calendar';

  @override
  String get vaultRetryUpload => 'Retry upload';

  @override
  String get vaultClearExpiry => 'Clear expiry reminder';

  @override
  String get vaultExpiryCleared => 'Expiry reminder cleared';

  @override
  String get vaultUpdated => 'Document updated';

  @override
  String vaultRemoveBody(String title) {
    return 'Remove “$title” from the nest vault.';
  }

  @override
  String vaultSharedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Shared $count files',
      one: 'Shared 1 file',
    );
    return '$_temp0';
  }

  @override
  String vaultAddFailed(String error) {
    return 'Could not add file: $error';
  }

  @override
  String get vaultNotesHint => 'Renewal tips, last-4, who holds the original…';

  @override
  String nSelected(int count) {
    return '$count selected';
  }

  @override
  String get emergencyShareCard => 'Share card';

  @override
  String get emergencyCopyCard => 'Copy card';

  @override
  String emergencyCopiedEntry(String label) {
    return 'Copied $label';
  }

  @override
  String get emergencyCopied => 'Copied to clipboard';

  @override
  String get emergencyCardCopied => 'Emergency card copied';

  @override
  String get emergencyNeedData =>
      'Add a contact or care profile before sharing';

  @override
  String get emergencyNeedDataCopy =>
      'Add a contact or care profile before copying';

  @override
  String get emergencyLabel => 'Label';

  @override
  String get emergencyDetails => 'Details';

  @override
  String get inviteCopyCode => 'Copy code';

  @override
  String get inviteSkipForNow => 'Skip for now';

  @override
  String get inviteNestReady => 'Nest ready — invite family';

  @override
  String get inviteNestReadyBody =>
      'Share this code so someone can join in under a minute.';

  @override
  String get inviteSheetBody =>
      'Anyone with Casaio can join using this 6-character code.';

  @override
  String inviteCodeA11y(String code) {
    return 'Invite code $code';
  }

  @override
  String get rolePickerHint =>
      'Used for assignees, school activities, and family context.';

  @override
  String roleUpdated(String name, String role) {
    return '$name is now $role';
  }

  @override
  String get familyRoles => 'Family roles';

  @override
  String get yourNest => 'Your nest';

  @override
  String get noMembersYet => 'No members yet';

  @override
  String get inviteWithCodeBelow => 'Invite family with your code below';

  @override
  String get membersHelper =>
      'Used for assignees, school activities, and family context.';

  @override
  String get nestFreeNote => 'Casaio is free for families — no paywall.';

  @override
  String get leaveNest => 'Leave nest';

  @override
  String leaveNestBody(String name) {
    return 'You’ll lose access to “$name” on this account. Other members keep the nest and all shared data. Your Casaio login stays — you can create or join another nest.';
  }

  @override
  String get leftNest => 'Left nest — create or join another';

  @override
  String leaveNestFailed(String error) {
    return 'Couldn’t leave nest: $error';
  }

  @override
  String get resetBackToLogin => 'Back to log in';

  @override
  String get resetUseOtherEmail => 'Use a different email';

  @override
  String get resetPasswordUpdated => 'Password updated';

  @override
  String get aboutTagline => 'The operating system for modern families';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get privacyIntro => 'Casaio keeps household data private by default.';

  @override
  String get privacyStoreTitle => 'What we store';

  @override
  String get privacyStoreBody =>
      'Account email, nest membership, tasks, lists, calendar, expenses, bills, emergency notes, vault file metadata, family timeline events, and — if you opt in — a last-known Locator pin. Vault files upload to Firebase Storage under your nest when you are online. Locator never tracks you in the background; you share only when you tap Share now.';

  @override
  String get privacySyncTitle => 'How it syncs';

  @override
  String get privacySyncBody =>
      'Casaio is offline-first. Data lives on your device in SQLite (Drift) and syncs to Firebase when signed in and connected. Only nest members can read or write nest data.';

  @override
  String get privacyAiTitle => 'Quiet AI (optional)';

  @override
  String get privacyAiBody =>
      'Document scan sends the photo or PDF you choose to Google’s Gemini models through Firebase AI Logic (Vertex AI) so Casaio can draft an event, expense, bill, or task. You review before anything is saved. Casaio stays free — there is no paywall for core family features.';

  @override
  String get privacyDiagTitle => 'Diagnostics';

  @override
  String get privacyDiagBody =>
      'Casaio uses Firebase Crashlytics and Analytics to improve stability. Crash reports and anonymous event names (for example sign-up, sync success/fail) do not include nest content, emails, or passwords.';

  @override
  String get privacyResetTitle => 'Password reset';

  @override
  String get privacyResetBody =>
      'Forgot-password emails are sent by Firebase Authentication. If you don’t see one, check Spam and Promotions. While signed in, you can change your password from Nest without email. Need help? support@casaio.app.';

  @override
  String get privacyNotifTitle => 'Notifications';

  @override
  String get privacyNotifBody =>
      'We may register a push token for reminders (for example bills). You can revoke notification permission in system settings.';

  @override
  String get privacyContactTitle => 'Contact';

  @override
  String get privacyContactBody =>
      'Questions: privacy@casaio.app — or open https://casaio.app/privacy';

  @override
  String get privacyControls => 'Your controls';

  @override
  String get privacyExport => 'Export nest data';

  @override
  String get privacyExportBody =>
      'JSON includes budget settings. Vault files are metadata only — binaries stay in Vault.';

  @override
  String get privacyDeleteHint => 'Requires your password. Cannot be undone.';

  @override
  String get privacyNeedSignIn => 'You need to be signed in.';

  @override
  String get privacyDeleting => 'Deleting account…';

  @override
  String get privacyDeleteForever => 'Delete forever';

  @override
  String get privacyConfirmPassword => 'Confirm with password';

  @override
  String privacyDeleteBody(String email) {
    return 'This removes $email from Casaio and clears data on this device. If you are the last member, the nest (including vault files) is deleted. This cannot be undone.';
  }

  @override
  String get privacyExportReady => 'Export ready to share';

  @override
  String privacyExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get scanSignIn => 'Sign in to scan documents.';

  @override
  String scanPickerFailed(String error) {
    return 'Could not open the file picker: $error';
  }

  @override
  String get scanTooLarge =>
      'File is too large — keep photos/PDFs under ~4 MB.';

  @override
  String get scanReading => 'Reading document…\nUsually under a minute';

  @override
  String get scanNeedTitle => 'Add a title before saving';

  @override
  String get scanNeedAmount => 'Enter a valid amount';

  @override
  String scanSaveFailed(String error) {
    return 'Could not save: $error';
  }

  @override
  String get scanClearEnd => 'Clear end';

  @override
  String get homeQuietTitle => 'Your nest is quiet — start Today';

  @override
  String get homeQuietBody =>
      'Invite someone, or add your first task or event. No demo data — just your family.';

  @override
  String get homeNothingToday => 'Nothing on Today yet';

  @override
  String get homeNothingTodayBody =>
      'Add a task or calendar event so the nest has something to gather around.';

  @override
  String get homeOnCalendar => 'On the calendar';

  @override
  String get homeTodayForNest => 'Today for your nest';

  @override
  String get timelineBackHome => 'Back to Home';

  @override
  String get timelineShowAll => 'Show all';

  @override
  String get locatorPinning => 'Pinning…';

  @override
  String get locatorNoFreshPins =>
      'No live pins right now — try All or Share now.';

  @override
  String get locatorNoStalePins => 'No stale pins — everyone’s fresh.';

  @override
  String get vaultFolder => 'Folder';

  @override
  String get vaultPreparing => 'Preparing…';

  @override
  String get vaultShareOpen => 'Share / open';

  @override
  String get vaultSetExpiry => 'Set expiry reminder';

  @override
  String get vaultChangeExpiry => 'Change expiry date';

  @override
  String get scanReadFailed =>
      'Could not read that file. Try a smaller JPEG/PNG or PDF.';

  @override
  String dueLabel(String date) {
    return 'Due · $date';
  }

  @override
  String get commonSaveChanges => 'Save changes';

  @override
  String get commonAllDay => 'All day';

  @override
  String get familyMember => 'Family member';

  @override
  String get ourNest => 'Our nest';

  @override
  String get yourAccount => 'your account';

  @override
  String get homePaceBusy => 'Busy';

  @override
  String get homePaceSteady => 'Steady';

  @override
  String get homePaceQuiet => 'Quiet';

  @override
  String get homePlanDinner => 'Plan dinner';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncFailedRetry => 'Sync failed, retry';

  @override
  String get syncFailedTapRetry => 'Sync failed · tap Retry to try again';

  @override
  String homeThingsToday(int count) {
    return 'You have $count things for today';
  }

  @override
  String get homeNoEventsToday =>
      'No events on the calendar today — tap to add one';

  @override
  String get homeUpToDate => 'Up to date';

  @override
  String get homeActivities => 'Activities';

  @override
  String get homeNestActivity => 'Nest activity';

  @override
  String homeRecentCount(int count) {
    return '$count recent';
  }

  @override
  String get homeRemindersEmpty =>
      'Nothing urgent right now. Local reminders stay scheduled when items are due.';

  @override
  String get expensesTapEditBudget => 'Tap to edit budget';

  @override
  String get expensesByCategory => 'By category';

  @override
  String get emptyExpensesNone => 'No expenses yet — tap + when you spend.';

  @override
  String get emptyExpensesNoneNest =>
      'No expenses this nest yet. Tap + to add one.';

  @override
  String get emptyExpensesSearch => 'No expenses match this search.';

  @override
  String get emptyBillsHint => 'Track rent, utilities, and subscriptions here.';

  @override
  String get emptyBillsNone => 'No bills tracked yet.';

  @override
  String get emptyBillsSearch => 'No bills match this search.';

  @override
  String get dueToday => 'Due today';

  @override
  String get dueTomorrow => 'Due tomorrow';

  @override
  String dueInDays(int count, String date) {
    return 'Due in $count days · $date';
  }

  @override
  String snackMarkedPaid(String title) {
    return 'Marked “$title” paid';
  }

  @override
  String get snackMarkedUnpaid => 'Marked unpaid';

  @override
  String get monthBudgetTitle => 'Month budget';

  @override
  String get monthBudgetBody =>
      'Your family’s spending target for this calendar month.';

  @override
  String snackBudgetSet(String amount) {
    return 'Month budget set to $amount';
  }

  @override
  String get markUnpaid => 'Mark unpaid';

  @override
  String get markPaid => 'Mark paid';

  @override
  String get addExpense => 'Add expense';

  @override
  String get editExpense => 'Edit expense';

  @override
  String get deleteExpense => 'Delete expense';

  @override
  String get editBill => 'Edit bill';

  @override
  String get deleteBill => 'Delete bill';

  @override
  String get vaultScanHint => 'This may be a family document or invitation';

  @override
  String get vaultRetryAll => 'Retry all';

  @override
  String get vaultExpiringSoon => 'Expiring soon';

  @override
  String get vaultRecentFiles => 'Recent files';

  @override
  String get vaultSearchResults => 'Search results';

  @override
  String get vaultSavedOffline => 'Saved on device — will upload when online';

  @override
  String get vaultStillOffline => 'Still offline — files stay on this device';

  @override
  String vaultUploaded(String title) {
    return 'Uploaded $title';
  }

  @override
  String get vaultUploadFailedSnack => 'Upload failed — try again later';

  @override
  String vaultNoSearchMatch(String query) {
    return 'No documents match “$query”. Try a title, note, or folder name.';
  }

  @override
  String get vaultEmptyBody =>
      'No documents yet. Tap + to add IDs, insurance, or house papers.';

  @override
  String vaultEmptyFolder(String folder) {
    return 'Nothing in $folder yet. Tap + to add a file here.';
  }

  @override
  String get expiresToday => 'Expires today';

  @override
  String get expiresTomorrow => 'Expires tomorrow';

  @override
  String expiresInDays(int count) {
    return 'Expires in $count days';
  }

  @override
  String get vaultExpiryHelp => 'When does this expire?';

  @override
  String get vaultDetails => 'Document details';

  @override
  String vaultStatusLabel(String status) {
    return 'Status · $status';
  }

  @override
  String get vaultRemoveFrom => 'Remove from vault';

  @override
  String get scanWhatScanning => 'What are you scanning?';

  @override
  String get scanReceipt => 'Receipt';

  @override
  String get scanReceiptHint => 'Store receipt — extract total as expense';

  @override
  String get scanInviteEvent => 'Invite / event';

  @override
  String get scanInviteHint => 'Invitation or appointment — calendar event';

  @override
  String get scanSchoolNotice => 'School notice';

  @override
  String get scanSchoolHint => 'School notice or sports schedule';

  @override
  String get scanBillLabel => 'Bill';

  @override
  String get scanBillHint =>
      'Utility or service bill — save as bill with due date';

  @override
  String get scanFailed => 'Scan failed. Try again.';

  @override
  String get scanExpenseAdded => 'Expense added';

  @override
  String get scanBillAdded => 'Bill added';

  @override
  String get scanTaskAdded => 'Task added';

  @override
  String get scanEventAdded => 'Event added';

  @override
  String get scanReview => 'Review scan';

  @override
  String get scanLowConfidence =>
      'Low confidence — double-check the title, date, and amount before saving.';

  @override
  String get scanTimed => 'Timed';

  @override
  String get scanEndTimeOptional => 'End time (optional)';

  @override
  String get scanAmountDue => 'Amount due';

  @override
  String get scanAssignTo => 'Assign to';

  @override
  String get scanAddExpense => 'Add expense';

  @override
  String get scanAddBill => 'Add bill';

  @override
  String get scanAddTask => 'Add task';

  @override
  String get scanAddEvent => 'Add event';

  @override
  String get locatorPulse => 'Your nest pulse';

  @override
  String get locatorLocations => 'Nest locations';

  @override
  String get locatorLoadFailed => 'Could not load nest locations.';

  @override
  String get locatorPrivacyNote =>
      'Locator never tracks in the background. Pins expire visually after 24 hours so the nest doesn’t rely on outdated places.';

  @override
  String get locatorSharedSnack => 'Shared your location with the nest';

  @override
  String get locatorGetFailed => 'Could not get your location. Try again.';

  @override
  String get locatorUpdateFailed => 'Could not update sharing.';

  @override
  String locatorLastSeen(String age) {
    return 'Last seen $age';
  }

  @override
  String locatorUpdatedAge(String age) {
    return 'Updated $age';
  }

  @override
  String get locatorOpenMap => 'Open map';

  @override
  String get locatorMapWake => 'Nest map wakes up when someone shares a pin';

  @override
  String get locatorShrinkMap => 'Shrink map';

  @override
  String get locatorExpandMap => 'Expand map';

  @override
  String get locatorSatellite => 'Satellite';

  @override
  String get locatorModernMap => 'Modern map';

  @override
  String get locatorFitAll => 'Fit all';

  @override
  String get emergencyOfflineNote =>
      'Available offline — critical info stays on this device and syncs when you are online.';

  @override
  String get emergencyCareProfiles => 'Care profiles';

  @override
  String get emergencyAddHint =>
      'Add emergency contacts, allergies, and doctors.';

  @override
  String emergencyCardTitle(String nest) {
    return 'Casaio emergency card — $nest';
  }

  @override
  String get emergencyInfo => 'Emergency info';

  @override
  String get schoolIntro =>
      'School runs, sports, clubs, and pickups. Add one activity to get started — mark done to roll the next date, or create a same-day pickup task.';

  @override
  String get schoolDueToday => 'Due today';

  @override
  String snackCalendarAdded(String date) {
    return 'Calendar event added · $date';
  }

  @override
  String get schoolNewActivity => 'New activity';

  @override
  String get schoolEditActivity => 'Edit activity';

  @override
  String get schoolWhoFor => 'Who is this for?';

  @override
  String get careIntro =>
      'Elder profiles plus pet, home, and car upkeep. Mark done to roll the next due date — start with one schedule if the list is empty.';

  @override
  String get careElderProfiles => 'Elder profiles';

  @override
  String get careAddMembersHint =>
      'Add family members in Nest, then set a Grandparent role.';

  @override
  String get careNoElders =>
      'No elder profiles yet — set Grandparent in Nest, then add meds and allergies here.';

  @override
  String get careDueNow => 'Due now';

  @override
  String get careNewItem => 'New care item';

  @override
  String get careEditItem => 'Edit care item';

  @override
  String get careForWhom => 'For whom?';

  @override
  String careProfileTitle(String name) {
    return 'Care profile · $name';
  }

  @override
  String get mealsIntro =>
      'Plan dinners for the week, then push ingredients to the shared grocery list.';

  @override
  String get mealsRestOfWeek => 'Rest of week';

  @override
  String get mealsNonePlanned => 'No meal planned — tap to add dinner';

  @override
  String get mealsPlanAMeal => 'Plan a meal';

  @override
  String get mealsEditMeal => 'Edit meal';

  @override
  String get mealsSaveMeal => 'Save meal';

  @override
  String get mealsPlanWeekBody =>
      'Fill the nights you care about. Blank days stay empty.';

  @override
  String get mealsRecipeLibrary => 'Recipe library';

  @override
  String get mealsAddRecipe => 'Add recipe';

  @override
  String get mealsEditRecipe => 'Edit recipe';

  @override
  String get mealsSaveRecipe => 'Save recipe';

  @override
  String get mealsApplyRecipe => 'Apply to this day';

  @override
  String get mealsSaveAsRecipe => 'Save as recipe';

  @override
  String get mealsNoRecipes =>
      'No saved recipes yet — save a meal slot or add one here.';

  @override
  String get mealsRecipeApplied => 'Recipe applied';

  @override
  String get hintRecipeNotes => 'Notes (optional)';

  @override
  String get shopClearBoughtBody =>
      'Removes checked-off groceries from this list. You can still restock habits later.';

  @override
  String get shopNothingToClear => 'Nothing to clear';

  @override
  String shopClearedBought(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cleared $count bought items',
      one: 'Cleared 1 bought item',
    );
    return '$_temp0';
  }

  @override
  String get shopSharedList => 'Shared list';

  @override
  String get shopNoMatch => 'No items match this search or filter.';

  @override
  String get shopEditItem => 'Edit item';

  @override
  String get shopDeleteItem => 'Delete item';

  @override
  String get shopBasedOnUsual => 'Based on what you usually buy';

  @override
  String get shopNewList => 'New list';

  @override
  String get shopListNameHint => 'List name';

  @override
  String get shopCreateList => 'Create list';

  @override
  String get shopRenameList => 'Rename list';

  @override
  String get shopDeleteList => 'Delete list';

  @override
  String get shopDeleteListBody =>
      'Removes this list and its items from your nest.';

  @override
  String get shopEmptyListTitle => 'This list is empty';

  @override
  String get shopEmptyListBody => 'Add items for this store or occasion.';

  @override
  String get shopRestock => 'Restock';

  @override
  String get tasksNoMatch => 'No tasks match this search.';

  @override
  String tasksFilterFor(String name) {
    return 'Filter tasks for $name';
  }

  @override
  String get taskNew => 'New task';

  @override
  String get taskEdit => 'Edit task';

  @override
  String get taskHabitHint => 'Stays open and advances the due date when done';

  @override
  String get taskAdd => 'Add task';

  @override
  String get calendarNewEvent => 'New event';

  @override
  String get calendarEditEvent => 'Edit event';

  @override
  String get calendarDeleteBody => 'This removes it from the shared calendar.';

  @override
  String get resetMailSubject => 'Casaio password reset help';

  @override
  String resetMailBody(String email) {
    return 'Account email: $email\n\n';
  }

  @override
  String get resetFillBoth => 'Fill in your current and new password.';

  @override
  String get resetMismatch => 'New passwords don’t match.';

  @override
  String get onboardingScanSuggestion => 'Scan suggestion';

  @override
  String get onboardingGroceryRun => 'Grocery run · \$42.50';

  @override
  String get onboardingSuggestedExpense =>
      'Suggested expense from your receipt';

  @override
  String get onboardingSaveExpense => 'Save expense';

  @override
  String get onboardingEditFirst => 'Edit first';

  @override
  String get paidByAnyone => 'Anyone';

  @override
  String shopLeftCount(int count) {
    return '$count left';
  }

  @override
  String shopBoughtCount(int count) {
    return '$count bought';
  }

  @override
  String get taskRepeats => 'Repeats';

  @override
  String get taskPickDate => 'Pick date';

  @override
  String get taskCadenceDaily => 'Every day';

  @override
  String get taskCadenceWeekly => 'Every week';

  @override
  String get taskCadenceBiweekly => 'Every 2 weeks';

  @override
  String get taskCadenceMonthly => 'Every month';

  @override
  String taskCadenceEveryDays(int days) {
    return 'Every $days days';
  }

  @override
  String taskRepeatsCadence(String cadence) {
    return 'Repeats · $cadence';
  }

  @override
  String get taskOpen => 'Open';

  @override
  String get locatorNearMe => 'Near me';

  @override
  String locatorAway(String distance) {
    return '$distance away';
  }

  @override
  String get locatorSignIn => 'Sign in to share your location.';

  @override
  String get locatorJoinNest => 'Join a nest before sharing location.';

  @override
  String get locatorNeedPermission =>
      'Location permission is needed to share where you are.';

  @override
  String get locatorNeedServices => 'Turn on Location Services to share.';

  @override
  String vaultPackSubject(int count) {
    return 'Casaio vault pack ($count)';
  }

  @override
  String get vaultPackText => 'Shared from Casaio vault';

  @override
  String get vaultNoFilesShare => 'No files available to share yet.';

  @override
  String get privacyExportSubject => 'Casaio data export';

  @override
  String get privacyExportShareText =>
      'Your Casaio nest export (JSON). Vault file binaries are not included.';

  @override
  String mealsAddIngredientsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count ingredients?',
      one: 'Add 1 ingredient?',
    );
    return '$_temp0';
  }

  @override
  String mealsAddIngredientsBody(String label) {
    return 'From $label — already-on-list items are skipped.';
  }

  @override
  String get scanEmptyResult =>
      'Scan returned an empty result. Try a clearer photo.';

  @override
  String get scanUnexpected =>
      'Scan returned an unexpected response. Try another photo.';

  @override
  String get scanTimedOut =>
      'Scan timed out. Try a clearer photo or a smaller file.';

  @override
  String get scanReachFailed =>
      'Could not reach Vertex AI. Check your connection and try again.';

  @override
  String get scanQuotaReached => 'AI quota reached for today. Try again later.';

  @override
  String get scanNeedBlaze =>
      'Vertex AI needs the Firebase Blaze plan. Upgrade billing in Firebase Console, enable Vertex AI, then try again.';

  @override
  String get scanVertexNotReady =>
      'Vertex AI Gemini is not ready. In Firebase Console enable AI Logic with the Vertex AI Gemini API (Blaze), then try again.';

  @override
  String get scanFileTooLargeAi =>
      'That file is too large. Use a photo or PDF under about 4 MB.';

  @override
  String get commonCopy => 'Copy';

  @override
  String get locatorLive => 'Live';

  @override
  String get locatorDirections => 'Directions';

  @override
  String get pressBackAgainToExit => 'Press back again to exit';
}
