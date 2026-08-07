// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'Casaio';

  @override
  String get tabHome => 'الرئيسية';

  @override
  String get tabCalendar => 'التقويم';

  @override
  String get tabTasks => 'المهام';

  @override
  String get tabShop => 'التسوق';

  @override
  String get tabNest => 'العش';

  @override
  String get navMain => 'التنقل الرئيسي';

  @override
  String get addToCasaio => 'إضافة إلى Casaio';

  @override
  String get addEvent => 'حدث';

  @override
  String get addTask => 'مهمة';

  @override
  String get addShoppingItem => 'صنف تسوق';

  @override
  String get addScan => 'مسح إيصال / دعوة';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonAll => 'الكل';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonDone => 'تم';

  @override
  String get commonEdit => 'تعديل';

  @override
  String get commonAdd => 'إضافة';

  @override
  String get commonNext => 'التالي';

  @override
  String get commonBack => 'رجوع';

  @override
  String get commonShare => 'مشاركة';

  @override
  String get commonOpen => 'فتح';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonLoad => 'تحميل';

  @override
  String get commonPaid => 'مدفوع';

  @override
  String get commonView => 'عرض';

  @override
  String get commonPlan => 'تخطيط';

  @override
  String get commonReview => 'مراجعة';

  @override
  String get commonRestock => 'إعادة التموين';

  @override
  String get commonSearch => 'بحث';

  @override
  String get commonNotes => 'ملاحظات';

  @override
  String get commonTitle => 'العنوان';

  @override
  String get commonAmount => 'المبلغ';

  @override
  String get commonCategory => 'الفئة';

  @override
  String get commonLocation => 'الموقع';

  @override
  String get commonSettings => 'الإعدادات';

  @override
  String get languageTitle => 'اللغة';

  @override
  String get languageSubtitle => 'لغة التطبيق على هذا الجهاز';

  @override
  String get languageSystem => 'افتراضي النظام';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get authWelcomeBack => 'مرحبًا بعودتك';

  @override
  String get authCreateAccount => 'أنشئ حساب عائلتك';

  @override
  String get authEmailHint => 'البريد الإلكتروني';

  @override
  String get authPasswordHint => 'كلمة المرور';

  @override
  String get authNameHint => 'اسمك';

  @override
  String get authSignIn => 'تسجيل الدخول';

  @override
  String get authSignUp => 'إنشاء حساب';

  @override
  String get authHaveAccount => 'لديك حساب؟ سجّل الدخول';

  @override
  String get authNeedAccount => 'جديد هنا؟ أنشئ حسابًا';

  @override
  String get authForgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get authInvalidEmail => 'أدخل بريدًا إلكترونيًا صالحًا.';

  @override
  String get authPasswordTooShort =>
      'يجب أن تكون كلمة المرور ٦ أحرف على الأقل.';

  @override
  String get authEnterName => 'أدخل اسمك.';

  @override
  String get authCheckFailed => 'تعذّر التحقق من تسجيل الدخول.';

  @override
  String get authErrorInvalidEmail => 'يبدو عنوان البريد غير صالح.';

  @override
  String get authErrorDisabled => 'تم تعطيل هذا الحساب.';

  @override
  String get authErrorBadCredential => 'البريد أو كلمة المرور غير صحيحة.';

  @override
  String get authErrorEmailInUse => 'يوجد حساب بهذا البريد مسبقًا.';

  @override
  String get authErrorWeakPassword => 'استخدم كلمة مرور من ٦ أحرف على الأقل.';

  @override
  String get authErrorTooMany => 'محاولات كثيرة. حاول بعد دقائق.';

  @override
  String get authErrorNetwork =>
      'لا يوجد اتصال. تحقق من الشبكة ثم أعد المحاولة.';

  @override
  String get authErrorNotAllowed =>
      'تسجيل الدخول بالبريد غير مفعّل لهذا المشروع بعد.';

  @override
  String get authErrorRecentLogin =>
      'لأمانك، أدخل كلمة المرور مرة أخرى للمتابعة.';

  @override
  String get authErrorGeneric => 'حدث خطأ. حاول مرة أخرى.';

  @override
  String get authErrorPermission =>
      'رُفض الوصول السحابي. سجّل الخروج ثم الدخول، أو راجع قواعد Firestore.';

  @override
  String get authErrorNotFound => 'لم يُعثر على هذا العش أو الدعوة.';

  @override
  String get authErrorAlreadyExists => 'رمز الدعوة مستخدم مسبقًا. حاول مجددًا.';

  @override
  String authErrorGenericCode(String code) {
    return 'حدث خطأ ($code). حاول مرة أخرى.';
  }

  @override
  String get authErrorInviteMissing => 'لم يُعثر على رمز الدعوة.';

  @override
  String get authErrorSignInAgain => 'سجّل الدخول مجددًا ثم ابدأ عشّك.';

  @override
  String get onboardingTitle1 => 'نظّم حياة عائلتك\nببساطة';

  @override
  String get onboardingBody1 =>
      'أدِر الأحداث والمهام والبقالة والخطط اليومية في مكان مشترك واحد.';

  @override
  String get onboardingTitle2 => 'مساعدة هادئة\nعند المسح';

  @override
  String get onboardingBody2 =>
      'ذكاء Casaio يساعد فقط عند مسح إيصال أو دعوة — يقترح حدثًا أو مصروفًا. لا يدير العش نيابة عنك.';

  @override
  String get onboardingTitle3 => 'ابقوا على تواصل\nمعًا';

  @override
  String get onboardingBody3 =>
      'شاركوا الخطط، وزّعوا المهام، وابقوا العائلة متزامنة.';

  @override
  String get onboardingGetStarted => 'ابدأ';

  @override
  String get nestSetupTitle => 'ابدأ عشّك';

  @override
  String get settingsTimeline => 'الجدول الزمني';

  @override
  String get settingsTimelineSubtitle => 'نشاط العش الأخير عبر العائلة';

  @override
  String get settingsLocator => 'المحدد';

  @override
  String get settingsLocatorSubtitle => 'خريطة العش · مواقع اختيارية لآخر ظهور';

  @override
  String get settingsPassword => 'تغيير كلمة المرور';

  @override
  String get settingsPasswordSubtitle => 'ما زلت مسجّل الدخول؟ حدّثها هنا';

  @override
  String get settingsTomorrowPreview => 'معاينة الغد';

  @override
  String get settingsTomorrowPreviewSubtitle =>
      'تذكير مسائي هادئ لفواتير الغد والرعاية والمدرسة';

  @override
  String get settingsPrivacy => 'الخصوصية والبيانات';

  @override
  String get settingsAbout => 'حول Casaio';

  @override
  String get settingsShowcase => 'تحميل بيانات العرض';

  @override
  String get settingsShowcaseSubtitle => 'للتطوير فقط — ليس في إصدارات المتجر';

  @override
  String get settingsCrash => 'فرض تعطّل تجريبي';

  @override
  String get settingsCrashSubtitle =>
      'التحقق من Crashlytics في وحدة تحكم Firebase';

  @override
  String get showcaseConfirmTitle => 'تحميل بيانات العرض؟';

  @override
  String get showcaseConfirmBody =>
      'يستبدل محتوى العش ببيانات تجريبية مصقولة ثم يزامن.';

  @override
  String get showcaseLoading => 'جارٍ تحميل بيانات العرض…';

  @override
  String get showcaseReady => 'بيانات العرض جاهزة — افتح الرئيسية للمراجعة';

  @override
  String showcaseFailed(String error) {
    return 'تعذّر تحميل العرض: $error';
  }

  @override
  String roleForMember(String name) {
    return 'دور $name';
  }

  @override
  String get roleAdult => 'بالغ';

  @override
  String get roleCoParent => 'شريك تربية';

  @override
  String get roleKid => 'طفل';

  @override
  String get roleGrandparent => 'جد / جدة';

  @override
  String get roleMember => 'عضو';

  @override
  String get filterAdults => 'البالغون';

  @override
  String get filterKids => 'الأطفال';

  @override
  String get filterGrandparents => 'الأجداد';

  @override
  String get careViewDue => 'قائمة المستحق';

  @override
  String get careViewCategory => 'حسب الفئة';

  @override
  String get careCategoryElder => 'كبار السن';

  @override
  String get careCategoryHome => 'المنزل';

  @override
  String get careCategoryPet => 'الحيوانات';

  @override
  String get careCategoryCar => 'السيارة';

  @override
  String get schoolKindSchool => 'المدرسة';

  @override
  String get schoolKindSports => 'رياضة';

  @override
  String get schoolKindPickup => 'توصيل';

  @override
  String get schoolKindClub => 'نادي';

  @override
  String get shopProduce => 'خضار وفواكه';

  @override
  String get shopDairy => 'ألبان';

  @override
  String get shopMeat => 'لحوم';

  @override
  String get shopBakery => 'مخبوزات';

  @override
  String get shopPantry => 'مؤونة';

  @override
  String get shopFrozen => 'مجمّد';

  @override
  String get shopHousehold => 'منزلي';

  @override
  String get shopGeneral => 'عام';

  @override
  String get shopMeals => 'وجبات';

  @override
  String get expenseGroceries => 'بقالة';

  @override
  String get expenseTransport => 'مواصلات';

  @override
  String get expenseKids => 'أطفال';

  @override
  String get expenseHome => 'منزل';

  @override
  String get expenseDining => 'مطاعم';

  @override
  String get expenseHealth => 'صحة';

  @override
  String get expenseGeneral => 'عام';

  @override
  String get vaultFamily => 'العائلة';

  @override
  String get vaultHealth => 'الصحة';

  @override
  String get vaultHouse => 'المنزل';

  @override
  String get vaultWork => 'العمل';

  @override
  String get vaultCar => 'السيارة';

  @override
  String get vaultFinance => 'المالية';

  @override
  String get vaultIds => 'الهويات';

  @override
  String get vaultAllFolders => 'كل المجلدات';

  @override
  String get vaultDocuments => 'المستندات';

  @override
  String get taskDueToday => 'اليوم';

  @override
  String get taskDueTomorrow => 'غدًا';

  @override
  String get taskDueIn7Days => 'خلال ٧ أيام';

  @override
  String get uploadLocal => 'محلي';

  @override
  String get uploadUploading => 'جارٍ الرفع';

  @override
  String get uploadSynced => 'مزامن';

  @override
  String get uploadFailed => 'فشل';

  @override
  String get timelineAll => 'الكل';

  @override
  String get timelineTasks => 'المهام';

  @override
  String get timelineLists => 'القوائم';

  @override
  String get timelineCare => 'الرعاية';

  @override
  String get timelineMeals => 'الوجبات';

  @override
  String get timelineVault => 'الخزنة';

  @override
  String get timelineSchool => 'المدرسة';

  @override
  String get timelineOther => 'أخرى';

  @override
  String needCareDue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بنود رعاية مستحقة',
      one: 'بند رعاية واحد مستحق',
    );
    return '$_temp0';
  }

  @override
  String get needCareDetail => 'علّم مكتملًا عند الانتهاء';

  @override
  String needSchoolDue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count توصيلات مدرسية مستحقة',
      one: 'توصيلة مدرسية واحدة مستحقة',
    );
    return '$_temp0';
  }

  @override
  String get needSchoolDetail => 'أكّد من يتولى المشوار';

  @override
  String needBillsDue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فواتير قريبة الاستحقاق',
      one: 'فاتورة واحدة قريبة الاستحقاق',
    );
    return '$_temp0';
  }

  @override
  String get needBillsDetail => 'علّمها مدفوعة بعد السداد';

  @override
  String needTasksOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مهام مفتوحة',
      one: 'مهمة واحدة مفتوحة',
    );
    return '$_temp0';
  }

  @override
  String get needTasksDetail => 'أنهِ واحدة الآن أو افتح القائمة';

  @override
  String needShoppingLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أصناف بقالة متبقية',
      one: 'صنف بقالة واحد متبقٍ',
    );
    return '$_temp0';
  }

  @override
  String get needShoppingDetail => 'أشّرها في القائمة المشتركة';

  @override
  String get needShoppingOpenList => 'فتح القائمة';

  @override
  String needRestock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أعد تموين $count أصناف معتادة',
      one: 'أعد تموين صنف معتاد',
    );
    return '$_temp0';
  }

  @override
  String get needRestockDetail => 'بناءً على ما تشترونه غالبًا';

  @override
  String get needVaultOne => 'مستند واحد ينتهي قريبًا';

  @override
  String needVaultMany(int count) {
    return '$count مستندات تنتهي قريبًا';
  }

  @override
  String get needVaultDetail => 'جوازات أو تأمين أو رخص — جدّدها قبل انتهائها';

  @override
  String get needDinnerMissing => 'لا عشاء مخططًا اليوم';

  @override
  String get needDinnerMissingDetail =>
      'أضف وجبة — يمكن إرسال المكونات للقائمة';

  @override
  String needDinnerPlanned(String title) {
    return 'العشاء: $title';
  }

  @override
  String get needDinnerPlannedDetail => 'أرسل المكونات إلى قائمة البقالة';

  @override
  String get needQuietDay => 'يوم هادئ';

  @override
  String get needQuietDetail => 'لا شيء عاجل — وقت مناسب للتخطيط';

  @override
  String needEventsToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أحداث اليوم',
      one: 'حدث واحد اليوم',
    );
    return '$_temp0';
  }

  @override
  String get needEventsDetail => 'افتح التقويم حتى لا يُفاجأ أحد';

  @override
  String get screenCare => 'الرعاية';

  @override
  String get screenSchool => 'المدرسة والأنشطة';

  @override
  String get screenMeals => 'الوجبات';

  @override
  String get screenExpenses => 'المصروفات';

  @override
  String get screenVault => 'المستندات';

  @override
  String get screenEmergency => 'الطوارئ';

  @override
  String get screenTimeline => 'الجدول الزمني';

  @override
  String get screenLocator => 'المحدد';

  @override
  String get screenPrivacy => 'الخصوصية والبيانات';

  @override
  String get screenAbout => 'حول Casaio';

  @override
  String get screenShopping => 'التسوق';

  @override
  String get calendarTitle => 'تقويم العائلة';

  @override
  String get calendarTitleAgenda => 'جدول الأعمال';

  @override
  String get calendarBrowseMonth => 'شهر';

  @override
  String get calendarBrowseWeek => 'أسبوع';

  @override
  String get calendarBrowseAgenda => 'جدول';

  @override
  String get calendarAgendaUpcoming => 'الأيام السبعة القادمة';

  @override
  String get eventRecurrence => 'يتكرر';

  @override
  String get eventRecurrenceNone => 'لا يتكرر';

  @override
  String get eventRecurrenceDaily => 'كل يوم';

  @override
  String get eventRecurrenceWeekly => 'كل أسبوع';

  @override
  String get eventRecurrenceMonthly => 'كل شهر';

  @override
  String get eventRecurrenceUntil => 'التكرار حتى (اختياري)';

  @override
  String get calendarEditSeriesHint =>
      'تُطبَّق التغييرات على السلسلة المتكررة بالكامل.';

  @override
  String get homeTodaySnapshot => 'لمحة اليوم';

  @override
  String get homeHello => 'مرحبًا';

  @override
  String get syncNotYet => 'لم تتم المزامنة بعد';

  @override
  String get syncJustNow => 'الآن';

  @override
  String syncMinutesAgo(int count) {
    return 'منذ $count د';
  }

  @override
  String syncHoursAgo(int count) {
    return 'منذ $count س';
  }

  @override
  String syncDaysAgo(int count) {
    return 'منذ $count ي';
  }

  @override
  String get syncKeptOne => 'أُبقي تعديل محلي واحد أثناء المزامنة';

  @override
  String syncKeptMany(int count) {
    return 'أُبقيت $count تعديلات محلية أثناء المزامنة';
  }

  @override
  String get syncFailedNetwork =>
      'تعذّرت المزامنة — تحقق من الاتصال. التغييرات تبقى على هذا الجهاز.';

  @override
  String get syncFailedGeneric =>
      'تعذّرت المزامنة. التغييرات تبقى على هذا الجهاز — أعد المحاولة من العش.';

  @override
  String get notifChannelGeneral => 'Casaio';

  @override
  String get notifChannelGeneralDesc => 'تذكيرات العائلة والتحديثات';

  @override
  String get notifChannelPreview => 'معاينة الغد';

  @override
  String get notifChannelPreviewDesc => 'نظرة مسائية هادئة على الغد';

  @override
  String get notifChannelBills => 'الفواتير';

  @override
  String get notifChannelBillsDesc => 'تذكيرات قبل استحقاق فواتير المنزل';

  @override
  String get notifChannelCare => 'الرعاية';

  @override
  String get notifChannelCareDesc => 'تذكيرات رعاية المنزل وكبار السن';

  @override
  String get notifChannelSchool => 'المدرسة';

  @override
  String get notifChannelSchoolDesc => 'تذكيرات المشاوير والأنشطة المدرسية';

  @override
  String get notifChannelEvents => 'الأحداث';

  @override
  String get notifChannelEventsDesc => 'تذكيرات قبل أحداث التقويم';

  @override
  String get notifChannelTasks => 'المهام';

  @override
  String get notifChannelTasksDesc => 'تذكيرات المهام المفتوحة';

  @override
  String get notifTomorrowTitle => 'غدًا في Casaio';

  @override
  String notifTomorrowBody(String parts) {
    return '$parts مستحقة غدًا';
  }

  @override
  String notifBillCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فواتير',
      one: 'فاتورة واحدة',
    );
    return '$_temp0';
  }

  @override
  String notifCareCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مهام رعاية',
      one: 'مهمة رعاية واحدة',
    );
    return '$_temp0';
  }

  @override
  String notifSchoolCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بنود مدرسية',
      one: 'بند مدرسي واحد',
    );
    return '$_temp0';
  }

  @override
  String notifEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أحداث',
      one: 'حدث واحد',
    );
    return '$_temp0';
  }

  @override
  String notifTaskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مهام',
      one: 'مهمة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get notifBillDueTomorrow => 'فاتورة مستحقة غدًا';

  @override
  String notifBillBody(String title, String amount) {
    return '$title · \$$amount';
  }

  @override
  String get notifElderCareDue => 'رعاية كبار السن مستحقة';

  @override
  String get notifCareDue => 'رعاية مستحقة';

  @override
  String get notifSchoolPickup => 'مدرسة / توصيل';

  @override
  String get notifComingUp => 'قادم قريبًا';

  @override
  String get notifTaskDue => 'مهمة مستحقة';

  @override
  String get widgetAllClear => 'لا مهام';

  @override
  String get widgetNothingScheduled => 'لا شيء مجدول';

  @override
  String get widgetNotPlanned => 'غير مخطط';

  @override
  String get widgetJoinNest => 'افتح Casaio للانضمام إلى عش';

  @override
  String get widgetQuietDay => 'يوم هادئ · استمتعوا به';

  @override
  String widgetOpenTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مهام مفتوحة',
      one: 'مهمة واحدة مفتوحة',
    );
    return '$_temp0';
  }

  @override
  String widgetOpenShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مفتوحة',
      one: 'واحدة مفتوحة',
    );
    return '$_temp0';
  }

  @override
  String get widgetJustNow => 'الآن';

  @override
  String widgetMinutesAgo(int count) {
    return 'منذ $count د';
  }

  @override
  String widgetHoursAgo(int count) {
    return 'منذ $count س';
  }

  @override
  String widgetDaysAgo(int count) {
    return 'منذ $count ي';
  }

  @override
  String get widgetEarlier => 'سابقًا';

  @override
  String get widgetToday => 'اليوم';

  @override
  String get widgetWelcome => 'مرحبًا';

  @override
  String widgetUpdated(String age) {
    return 'حُدّث $age';
  }

  @override
  String get widgetName => 'Casaio اليوم';

  @override
  String get widgetDescription =>
      'المهام المفتوحة والحدث التالي وعشاء الليلة — دون بيانات الخزنة.';

  @override
  String get locatorAll => 'الكل';

  @override
  String get locatorFresh => 'حديث';

  @override
  String get locatorStale => 'قديم';

  @override
  String get scanKindEvent => 'حدث';

  @override
  String get scanKindExpense => 'مصروف';

  @override
  String get scanKindBill => 'فاتورة';

  @override
  String get scanKindTask => 'مهمة';

  @override
  String get emptyTasksTitle => 'أضف أول مهمة';

  @override
  String get emptyShoppingTitle => 'ابدأ قائمة البقالة';

  @override
  String get emptyCareTitle => 'أضف أول جدول رعاية';

  @override
  String get emptySchoolTitle => 'أضف أول مشوار مدرسي';

  @override
  String get emptyCalendarTitle => 'أضف أول حدث';

  @override
  String get emptyMealsTitle => 'خطّط عشاء هذا الأسبوع';

  @override
  String get emptyExpensesTitle => 'سجّل أول مصروف';

  @override
  String get emptyTimelineTitle => 'لا شيء في الجدول الزمني بعد';

  @override
  String get emptyCareBody =>
      'روتين الحيوانات الأليفة أو المنزل أو السيارة أو كبار السن — علّم كمكتمل لتدوير موعد الاستحقاق التالي.';

  @override
  String get emptySchoolBody =>
      'توصيلات ورياضة وأندية — أكّد من يتولى المشوار.';

  @override
  String get authLogIn => 'تسجيل الدخول';

  @override
  String get authSignUpShort => 'إنشاء حساب';

  @override
  String get authHaveAccountLogin => 'لديك حساب؟ سجّل الدخول';

  @override
  String get authNeedAccountSignup => 'جديد هنا؟ أنشئ حسابًا';

  @override
  String get authShowPassword => 'إظهار كلمة المرور';

  @override
  String get authHidePassword => 'إخفاء كلمة المرور';

  @override
  String get authWorking => 'جارٍ العمل';

  @override
  String get commonSkip => 'تخطي';

  @override
  String get commonSignOut => 'تسجيل الخروج';

  @override
  String get commonPaste => 'لصق';

  @override
  String onboardingPageOf(int current, int total) {
    return 'الصفحة $current من $total';
  }

  @override
  String get nestSetupJoinTitle => 'الانضمام إلى عش';

  @override
  String get nestSetupCreateTitle => 'إعداد في أقل من دقيقة';

  @override
  String get nestSetupJoinBody =>
      'الصق أو اكتب الرمز المكوّن من 6 أحرف من عائلتك.';

  @override
  String get nestSetupCreateBody =>
      'أنشئ عش أسرتك. يمكنك إعادة تسميته ودعوة العائلة لاحقًا.';

  @override
  String get nestSetupNameHelper => 'يظهر على المهام المشتركة والجدول الزمني';

  @override
  String get nestSetupInviteCode => 'رمز الدعوة';

  @override
  String get nestSetupInviteHelper => 'تُزال المسافات والشرطات تلقائيًا';

  @override
  String get nestSetupNestName => 'اسم العش';

  @override
  String get nestSetupNestHelper =>
      'القيم الافتراضية مناسبة — يمكنك تغييرها لاحقًا';

  @override
  String get nestSetupAfterStart =>
      'بعد البدء، سيقدّم Casaio رمز دعوة ليتمكن أحدهم من الانضمام.';

  @override
  String get nestSetupStart => 'بدء العش';

  @override
  String get nestSetupSwitchCreate => 'إنشاء عش جديد بدلًا من ذلك';

  @override
  String get nestSetupSwitchJoin => 'لديك رمز دعوة؟';

  @override
  String get clipboardEmpty => 'الحافظة فارغة';

  @override
  String get resetPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get resetPasswordIntro =>
      'سنرسل إليك رابطًا آمنًا لاختيار كلمة مرور جديدة.';

  @override
  String get resetCheckInbox => 'تحقق من بريدك';

  @override
  String resetCheckInboxBody(String email) {
    return 'إذا وُجد حساب لـ $email، ستصلك رسالة إعادة التعيين قريبًا. افتحها على هذا الجهاز أو أي متصفح، ثم سجّل الدخول بكلمة المرور الجديدة.';
  }

  @override
  String get resetDontSee => 'لا تراها؟';

  @override
  String get resetDontSeeBody =>
      'تحقق من البريد العشوائي والعروض (يضع Gmail رسائل Firebase هناك غالبًا). انتظر دقيقة ثم أعد الإرسال.';

  @override
  String get resetSendLink => 'إرسال رابط إعادة التعيين';

  @override
  String get resetResend => 'إعادة إرسال البريد';

  @override
  String resetResendIn(int seconds) {
    return 'إعادة الإرسال خلال $seconds ث';
  }

  @override
  String get resetEmailSupport => 'راسل support@casaio.app';

  @override
  String get resetEnterEmail => 'أدخل البريد الإلكتروني لحساب Casaio.';

  @override
  String get screenBudget => 'الميزانية';

  @override
  String get screenAboutShort => 'حول';

  @override
  String get screenPrivacyShort => 'الخصوصية';

  @override
  String get screenTasks => 'المهام';

  @override
  String lastSyncedLabel(String age) {
    return 'آخر مزامنة · $age';
  }

  @override
  String get homeLists => 'القوائم';

  @override
  String get homeAddTask => 'أضف مهمة';

  @override
  String get homeNoneToday => 'لا شيء اليوم';

  @override
  String get homeNoneDue => 'لا استحقاق';

  @override
  String homeCountDue(int count) {
    return '$count مستحق';
  }

  @override
  String homeCountToday(int count) {
    return '$count اليوم';
  }

  @override
  String homeItemsCount(int count) {
    return '$count أصناف';
  }

  @override
  String homeOpenCount(int count) {
    return '$count مفتوحة';
  }

  @override
  String homeDocsCount(int count) {
    return '$count مستندات';
  }

  @override
  String get homeThisMonth => 'هذا الشهر';

  @override
  String get homeAlwaysReady => 'جاهز دائمًا';

  @override
  String get homeLocatorSubtitle => 'خريطة العش وآخر المواقع المعروفة';

  @override
  String get homeDinnerSet => 'العشاء محدد';

  @override
  String get homePlanWeek => 'خطّط الأسبوع';

  @override
  String get homeBills => 'الفواتير';

  @override
  String get deleteEventTitle => 'حذف الحدث؟';

  @override
  String get deleteDocumentTitle => 'إزالة المستند؟';

  @override
  String get clearBoughtTitle => 'مسح الأصناف المشتراة؟';

  @override
  String get leaveNestTitle => 'مغادرة هذا العش؟';

  @override
  String get deleteAccountTitle => 'حذف الحساب؟';

  @override
  String careEmptyFilter(String filter) {
    return 'لا شيء في $filter';
  }

  @override
  String careEmptyFilterHint(String filter) {
    return 'جرّب عامل تصفية آخر، أو أضف عنصر رعاية لـ $filter.';
  }

  @override
  String get careAddItem => 'إضافة عنصر رعاية';

  @override
  String schoolEmptyFilter(String filter) {
    return 'لا شيء في $filter';
  }

  @override
  String schoolEmptyFilterHint(String filter) {
    return 'جرّب عامل تصفية آخر، أو أضف نشاطًا لـ $filter.';
  }

  @override
  String get schoolAddItem => 'إضافة نشاط';

  @override
  String locatorShared(String label) {
    return 'مشارَك · $label';
  }

  @override
  String get widgetNext => 'التالي';

  @override
  String get widgetDinnerChrome => 'العشاء';

  @override
  String get widgetTasksChrome => 'المهام';

  @override
  String get inviteFamilyTitle => 'دعوة العائلة';

  @override
  String inviteCodeCopied(String code) {
    return 'تم نسخ رمز الدعوة $code — جاهز للصق';
  }

  @override
  String get inviteShareSubject => 'انضم إلى عش Casaio';

  @override
  String get inviteShareFallbackNest => 'عش عائلتنا';

  @override
  String inviteShareText(String nest, String code, String url) {
    return 'انضم إلى $nest على Casaio!\n\nرمز الدعوة: $code\n\nحمّل التطبيق: $url\nثم افتح Casaio ← لديك رمز دعوة؟ ← الصق هذا الرمز.';
  }

  @override
  String get dowSunday => 'ح';

  @override
  String get dowMonday => 'ن';

  @override
  String get dowTuesday => 'ث';

  @override
  String get dowWednesday => 'ر';

  @override
  String get dowThursday => 'خ';

  @override
  String get dowFriday => 'ج';

  @override
  String get dowSaturday => 'س';

  @override
  String get syncOverWeekAgo => 'منذ أكثر من أسبوع';

  @override
  String get calendarTitleMonth => 'تقويم العائلة';

  @override
  String get syncing => 'جارٍ المزامنة…';

  @override
  String get syncNeededRetry => 'يلزم المزامنة · أعد المحاولة';

  @override
  String get commonDismiss => 'إخفاء';

  @override
  String get commonClear => 'مسح';

  @override
  String get commonRemove => 'إزالة';

  @override
  String get commonInvite => 'دعوة';

  @override
  String get commonNotNow => 'ليس الآن';

  @override
  String get commonSeeAll => 'عرض الكل';

  @override
  String get commonGotIt => 'حسنًا';

  @override
  String get commonDiscard => 'تجاهل';

  @override
  String get loadFailedGeneric => 'تعذّر التحميل. حاول لاحقًا.';

  @override
  String get loadFailedTasks => 'تعذّر تحميل المهام.';

  @override
  String get loadFailedMeals => 'تعذّر تحميل الوجبات.';

  @override
  String get loadFailedCare => 'تعذّر تحميل عناصر الرعاية.';

  @override
  String get loadFailedSchool => 'تعذّر تحميل الأنشطة.';

  @override
  String get loadFailedShopping => 'تعذّر تحميل القائمة. حاول لاحقًا.';

  @override
  String loadFailedNest(String error) {
    return 'تعذّر تحميل العش: $error';
  }

  @override
  String get homeStillSolo => 'ما زلت وحدك';

  @override
  String homeStillSoloBody(String code) {
    return 'ادعُ شريكًا بالرمز $code ليبقى اليوم مشتركًا.';
  }

  @override
  String get homeInvitePartner => 'ادعُ شريكًا';

  @override
  String homeInvitePartnerBody(String code) {
    return 'شارك $code ليتمكن أحدهم من الانضمام إلى هذا العش.';
  }

  @override
  String get homeShareInvite => 'مشاركة الدعوة';

  @override
  String homeInviteChip(String code) {
    return 'دعوة · $code';
  }

  @override
  String get homeReminders => 'التذكيرات';

  @override
  String get homeOpenTasks => 'المهام المفتوحة';

  @override
  String get homeOpenEmergency => 'فتح بطاقة الطوارئ';

  @override
  String get homeTodayReminders => 'تذكيرات اليوم';

  @override
  String snackDoneTitle(String title) {
    return 'تم: $title';
  }

  @override
  String snackPaidTitle(String title) {
    return 'مدفوع: $title';
  }

  @override
  String snackRestockAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أُضيفت $count أصناف تموين',
      one: 'أُضيف صنف تموين واحد',
    );
    return '$_temp0';
  }

  @override
  String get emptyTasksBody =>
      'الأعمال المنزلية والتذكيرات والمهام المشتركة هنا — اضغط لإنشاء واحدة للعش.';

  @override
  String get emptyTasksNone => 'لا مهام هنا';

  @override
  String emptyTasksNoneNamed(String name) {
    return 'لا شيء لـ $name';
  }

  @override
  String get emptyTasksHint => 'جرّب عامل تصفية آخر أو أضف مهمة.';

  @override
  String get emptyTasksHintNamed => 'اضغط الكل لرؤية الجميع، أو أضف مهمة لهم.';

  @override
  String get emptyShoppingBody =>
      'أضف الحليب أو البيض أو أي شيء آخر — اختر فئة في الحقل ثم أضف.';

  @override
  String get emptyShoppingAction => 'أضف صنفًا';

  @override
  String get emptyMealsBody =>
      'أضف عشاء الليلة أو خطّط الأسبوع — ثم ادفع المكوّنات إلى التسوق بنقرة.';

  @override
  String get emptyMealsAction => 'خطّط أسبوع العشاء';

  @override
  String get emptyExpensesBody =>
      'حدّد هدف إنفاق شهريًا، سجّل بعض المصاريف، وتابع الفواتير حتى لا يفوت شيء.';

  @override
  String get emptyExpensesAction => 'تعيين ميزانية الشهر';

  @override
  String get emptyCalendarBody =>
      'المشاویر المدرسية والعشاء والمواعيد تظهر هنا — بلا بيانات تجريبية، فقط ما يخصكم.';

  @override
  String get emptyCalendarNoMatch => 'لا أحداث مطابقة';

  @override
  String get emptyCalendarNothingToday => 'لا شيء مخطط اليوم';

  @override
  String get emptyCalendarNothingDay => 'لا شيء في هذا اليوم';

  @override
  String get emptyCalendarSearchHint => 'جرّب بحثًا آخر، أو امسح عامل التصفية.';

  @override
  String get emptyCalendarDayHint => 'اضغط لجدولة شيء لهذا اليوم.';

  @override
  String get emptyCalendarClearSearch => 'مسح البحث';

  @override
  String get emptyTimelineFilter => 'لا شيء في عامل التصفية هذا';

  @override
  String get emptyTimelineBody =>
      'عندما تنجز العائلة المهام والتسوق وخطط الوجبات، يظهر النشاط هنا.';

  @override
  String get emptyTimelineFilterHint =>
      'جرّب عامل تصفية وحدة آخر، أو ارجع إلى الكل.';

  @override
  String get locatorEmptyTitle => 'لا أحد يشارك بعد';

  @override
  String get locatorEmptyBody =>
      'عندما يوافق عضو في العش ويضغط مشاركة الآن، يظهر آخر موقع معروف على الخريطة.';

  @override
  String get locatorShareNow => 'مشاركة الآن';

  @override
  String get locatorTurnOnSharing => 'تفعيل المشاركة';

  @override
  String get locatorSharingOn => 'المشاركة مفعّلة';

  @override
  String get locatorCoordsCopied => 'تم نسخ الإحداثيات';

  @override
  String get searchEvents => 'بحث في الأحداث';

  @override
  String get searchTasks => 'بحث في المهام';

  @override
  String get searchList => 'بحث في القائمة';

  @override
  String get searchExpenses => 'بحث في المصاريف والفواتير';

  @override
  String get searchVault => 'بحث بالعنوان أو الملاحظات أو المجلد';

  @override
  String get hintEventTitle => 'عنوان الحدث';

  @override
  String get hintLocationOptional => 'الموقع (اختياري)';

  @override
  String get hintNotesOptional => 'ملاحظات (اختياري)';

  @override
  String get hintTaskTitle => 'ما الذي يجب إنجازه؟';

  @override
  String get hintItemName => 'اسم الصنف';

  @override
  String get hintQty => 'الكمية (مثل 2، 1 كغ)';

  @override
  String get hintAddItem => 'أضف صنفًا';

  @override
  String get hintDishName => 'اسم الطبق';

  @override
  String get hintIngredients => 'المكوّنات (فاصلة أو سطر جديد)';

  @override
  String hintDinnerFor(String day) {
    return 'عشاء $day';
  }

  @override
  String get hintSchoolTitle => 'مثلًا تدريب كرة القدم';

  @override
  String get paidBy => 'دفع بواسطة';

  @override
  String get addBill => 'إضافة فاتورة';

  @override
  String get addBillShort => 'فاتورة';

  @override
  String get saveBudget => 'حفظ الميزانية';

  @override
  String get saveWeek => 'حفظ الأسبوع';

  @override
  String get saveProfile => 'حفظ الملف';

  @override
  String get saveDetails => 'حفظ التفاصيل';

  @override
  String get saveOffline => 'حفظ دون اتصال';

  @override
  String get deleteTask => 'حذف المهمة';

  @override
  String get deleteMeal => 'حذف الوجبة';

  @override
  String get deleteActivity => 'حذف النشاط';

  @override
  String get deleteEventAction => 'حذف الحدث';

  @override
  String get clearBought => 'مسح المشترى';

  @override
  String get clearBoughtAction => 'مسح';

  @override
  String get addToList => 'إضافة إلى القائمة';

  @override
  String get shopThisWeek => 'تسوّق هذا الأسبوع';

  @override
  String get planDinnerWeek => 'خطّط أسبوع العشاء';

  @override
  String get addIngredients => 'أضف المكوّنات إلى القائمة';

  @override
  String get mealsUpdated => 'تم تحديث أسبوع العشاء';

  @override
  String get mealsNoNewIngredients => 'لا مكوّنات جديدة للإضافة';

  @override
  String mealsAddToGroceries(int count) {
    return 'أضف $count إلى البقالة';
  }

  @override
  String mealsAddedToGroceries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أُضيفت $count أصناف إلى البقالة',
      one: 'أُضيف صنف واحد إلى البقالة',
    );
    return '$_temp0';
  }

  @override
  String get snooze1Day => 'تأجيل يومًا';

  @override
  String get skipCycle => 'تخطي هذه الدورة';

  @override
  String get createCalendarEvent => 'إنشاء حدث تقويم';

  @override
  String get addPickupTask => 'إضافة مهمة توصيل';

  @override
  String snackSnoozed(String title) {
    return 'أُجّل $title يومًا واحدًا';
  }

  @override
  String snackSkipped(String title) {
    return 'تم تخطي $title لهذه الدورة';
  }

  @override
  String snackPickupAdded(String who) {
    return 'أُضيفت مهمة التوصيل $who';
  }

  @override
  String snackCareProfileSaved(String name) {
    return 'حُفظ ملف الرعاية لـ $name';
  }

  @override
  String get careMeds => 'الأدوية';

  @override
  String get careMedsHint => 'دواء ضغط صباحًا، مساءً…';

  @override
  String get careAllergies => 'الحساسية';

  @override
  String get careAllergiesHint => 'بنسلين، فول سوداني…';

  @override
  String get careMobility => 'الحركة والدعم';

  @override
  String get careMobilityHint => 'مشاية، يحتاج مساعدة على الدرج…';

  @override
  String get careDoctor => 'الطبيب الأساسي';

  @override
  String get careDoctorHint => 'د. الاسم · العيادة';

  @override
  String get careNotesHint => 'التفضيلات والروتين…';

  @override
  String get vaultSelectShare => 'تحديد للمشاركة';

  @override
  String get vaultSharePack => 'مشاركة الحزمة';

  @override
  String get vaultScanCalendar => 'مسح إلى التقويم';

  @override
  String get vaultRetryUpload => 'إعادة رفع';

  @override
  String get vaultClearExpiry => 'مسح تذكير الانتهاء';

  @override
  String get vaultExpiryCleared => 'تم مسح تذكير الانتهاء';

  @override
  String get vaultUpdated => 'تم تحديث المستند';

  @override
  String vaultRemoveBody(String title) {
    return 'إزالة «$title» من خزنة العش.';
  }

  @override
  String vaultSharedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تمت مشاركة $count ملفات',
      one: 'تمت مشاركة ملف واحد',
    );
    return '$_temp0';
  }

  @override
  String vaultAddFailed(String error) {
    return 'تعذّرت إضافة الملف: $error';
  }

  @override
  String get vaultNotesHint => 'نصائح التجديد، آخر 4 أرقام، من يحتفظ بالأصل…';

  @override
  String nSelected(int count) {
    return '$count محدد';
  }

  @override
  String get emergencyShareCard => 'مشاركة البطاقة';

  @override
  String get emergencyCopyCard => 'نسخ البطاقة';

  @override
  String emergencyCopiedEntry(String label) {
    return 'تم نسخ $label';
  }

  @override
  String get emergencyCopied => 'تم النسخ إلى الحافظة';

  @override
  String get emergencyCardCopied => 'تم نسخ بطاقة الطوارئ';

  @override
  String get emergencyNeedData => 'أضف جهة اتصال أو ملف رعاية قبل المشاركة';

  @override
  String get emergencyNeedDataCopy => 'أضف جهة اتصال أو ملف رعاية قبل النسخ';

  @override
  String get emergencyLabel => 'التسمية';

  @override
  String get emergencyDetails => 'التفاصيل';

  @override
  String get inviteCopyCode => 'نسخ الرمز';

  @override
  String get inviteSkipForNow => 'تخطي الآن';

  @override
  String get inviteNestReady => 'العش جاهز — ادعُ العائلة';

  @override
  String get inviteNestReadyBody =>
      'شارك هذا الرمز ليتمكن أحدهم من الانضمام في أقل من دقيقة.';

  @override
  String get inviteSheetBody =>
      'أي شخص لديه Casaio يمكنه الانضمام بهذا الرمز المكوّن من 6 أحرف.';

  @override
  String inviteCodeA11y(String code) {
    return 'رمز الدعوة $code';
  }

  @override
  String get rolePickerHint =>
      'يُستخدم للمسؤولين والأنشطة المدرسية وسياق العائلة.';

  @override
  String roleUpdated(String name, String role) {
    return '$name أصبح الآن $role';
  }

  @override
  String get familyRoles => 'أدوار العائلة';

  @override
  String get yourNest => 'عشك';

  @override
  String get noMembersYet => 'لا أعضاء بعد';

  @override
  String get inviteWithCodeBelow => 'ادعُ العائلة برمزك أدناه';

  @override
  String get membersHelper =>
      'يُستخدم للمسؤولين والأنشطة المدرسية وسياق العائلة.';

  @override
  String get nestFreeNote => 'Casaio مجاني للعائلات — بلا جدار دفع.';

  @override
  String get leaveNest => 'مغادرة العش';

  @override
  String leaveNestBody(String name) {
    return 'ستفقد الوصول إلى «$name» على هذا الحساب. يحتفظ الأعضاء الآخرون بالعش وجميع البيانات المشتركة. يبقى تسجيل دخول Casaio — يمكنك إنشاء عش آخر أو الانضمام إليه.';
  }

  @override
  String get leftNest => 'غادرت العش — أنشئ أو انضم إلى آخر';

  @override
  String leaveNestFailed(String error) {
    return 'تعذّرت مغادرة العش: $error';
  }

  @override
  String get resetBackToLogin => 'العودة لتسجيل الدخول';

  @override
  String get resetUseOtherEmail => 'استخدام بريد آخر';

  @override
  String get resetPasswordUpdated => 'تم تحديث كلمة المرور';

  @override
  String get aboutTagline => 'نظام التشغيل للعائلات الحديثة';

  @override
  String aboutVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get privacyIntro => 'يحافظ Casaio على خصوصية بيانات الأسرة افتراضيًا.';

  @override
  String get privacyStoreTitle => 'ما نخزّنه';

  @override
  String get privacyStoreBody =>
      'بريد الحساب، عضوية العش، المهام، القوائم، التقويم، المصاريف، الفواتير، ملاحظات الطوارئ، بيانات ملفات الخزنة، أحداث الجدول الزمني، وإن فعّلت الخيار — آخر موقع معروف في المحدّد. تُرفع ملفات الخزنة إلى Firebase Storage ضمن عشّك عند الاتصال. لا يتتبعك المحدّد في الخلفية؛ تشارك فقط عند الضغط على مشاركة الآن.';

  @override
  String get privacySyncTitle => 'كيف تتم المزامنة';

  @override
  String get privacySyncBody =>
      'Casaio يعمل دون اتصال أولًا. تعيش البيانات على جهازك في SQLite (Drift) وتُزامَن مع Firebase عند تسجيل الدخول والاتصال. أعضاء العش فقط يمكنهم قراءة بيانات العش أو كتابتها.';

  @override
  String get privacyAiTitle => 'ذكاء اصطناعي هادئ (اختياري)';

  @override
  String get privacyAiBody =>
      'مسح المستند يرسل الصورة أو PDF الذي تختاره إلى نماذج Gemini عبر Firebase AI Logic (Vertex AI) ليقترح Casaio حدثًا أو مصروفًا أو فاتورة أو مهمة. تراجع قبل الحفظ. يبقى Casaio مجانيًا — بلا جدار دفع لميزات العائلة الأساسية.';

  @override
  String get privacyDiagTitle => 'التشخيص';

  @override
  String get privacyDiagBody =>
      'يستخدم Casaio Firebase Crashlytics وAnalytics لتحسين الاستقرار. تقارير الأعطال وأسماء الأحداث المجهولة (مثل التسجيل ونجاح/فشل المزامنة) لا تتضمن محتوى العش أو البريد أو كلمات المرور.';

  @override
  String get privacyResetTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get privacyResetBody =>
      'ترسل Firebase Authentication رسائل نسيان كلمة المرور. إن لم ترها، تحقق من البريد العشوائي والعروض. أثناء تسجيل الدخول يمكنك تغيير كلمة المرور من العش دون بريد. تحتاج مساعدة؟ support@casaio.app.';

  @override
  String get privacyNotifTitle => 'الإشعارات';

  @override
  String get privacyNotifBody =>
      'قد نسجّل رمز دفع للتذكيرات (مثل الفواتير). يمكنك إلغاء إذن الإشعارات من إعدادات النظام.';

  @override
  String get privacyContactTitle => 'التواصل';

  @override
  String get privacyContactBody =>
      'الأسئلة: privacy@casaio.app — أو افتح https://casaio.app/privacy';

  @override
  String get privacyControls => 'أدواتك';

  @override
  String get privacyExport => 'تصدير بيانات العش';

  @override
  String get privacyExportBody =>
      'يشمل JSON إعدادات الميزانية. ملفات الخزنة بيانات وصفية فقط — تبقى الملفات الثنائية في الخزنة.';

  @override
  String get privacyDeleteHint => 'يتطلب كلمة المرور. لا يمكن التراجع.';

  @override
  String get privacyNeedSignIn => 'يجب تسجيل الدخول.';

  @override
  String get privacyDeleting => 'جارٍ حذف الحساب…';

  @override
  String get privacyDeleteForever => 'حذف نهائي';

  @override
  String get privacyConfirmPassword => 'أكّد بكلمة المرور';

  @override
  String privacyDeleteBody(String email) {
    return 'هذا يزيل $email من Casaio ويمسح البيانات على هذا الجهاز. إن كنت العضو الأخير، يُحذف العش (بما فيه ملفات الخزنة). لا يمكن التراجع.';
  }

  @override
  String get privacyExportReady => 'التصدير جاهز للمشاركة';

  @override
  String privacyExportFailed(String error) {
    return 'فشل التصدير: $error';
  }

  @override
  String get scanSignIn => 'سجّل الدخول لمسح المستندات.';

  @override
  String scanPickerFailed(String error) {
    return 'تعذّر فتح منتقي الملفات: $error';
  }

  @override
  String get scanTooLarge =>
      'الملف كبير جدًا — أبقِ الصور/PDF أقل من نحو 4 ميجابايت.';

  @override
  String get scanReading => 'جارٍ قراءة المستند…\nعادة أقل من دقيقة';

  @override
  String get scanNeedTitle => 'أضف عنوانًا قبل الحفظ';

  @override
  String get scanNeedAmount => 'أدخل مبلغًا صالحًا';

  @override
  String scanSaveFailed(String error) {
    return 'تعذّر الحفظ: $error';
  }

  @override
  String get scanClearEnd => 'مسح النهاية';

  @override
  String get homeQuietTitle => 'عشك هادئ — ابدأ اليوم';

  @override
  String get homeQuietBody =>
      'ادعُ أحدًا، أو أضف أول مهمة أو حدث. بلا بيانات تجريبية — عائلتك فقط.';

  @override
  String get homeNothingToday => 'لا شيء في اليوم بعد';

  @override
  String get homeNothingTodayBody =>
      'أضف مهمة أو حدث تقويم ليجتمع العش حول شيء ما.';

  @override
  String get homeOnCalendar => 'في التقويم';

  @override
  String get homeTodayForNest => 'اليوم لعشّك';

  @override
  String get timelineBackHome => 'العودة إلى الرئيسية';

  @override
  String get timelineShowAll => 'عرض الكل';

  @override
  String get locatorPinning => 'جارٍ التثبيت…';

  @override
  String get locatorNoFreshPins =>
      'لا نقاط مباشرة الآن — جرّب الكل أو مشاركة الآن.';

  @override
  String get locatorNoStalePins => 'لا نقاط قديمة — الجميع حديث.';

  @override
  String get vaultFolder => 'المجلد';

  @override
  String get vaultPreparing => 'جارٍ التحضير…';

  @override
  String get vaultShareOpen => 'مشاركة / فتح';

  @override
  String get vaultSetExpiry => 'تعيين تذكير الانتهاء';

  @override
  String get vaultChangeExpiry => 'تغيير تاريخ الانتهاء';

  @override
  String get scanReadFailed =>
      'تعذّرت قراءة هذا الملف. جرّب JPEG/PNG أو PDF أصغر.';

  @override
  String dueLabel(String date) {
    return 'الاستحقاق · $date';
  }

  @override
  String get commonSaveChanges => 'حفظ التغييرات';

  @override
  String get commonAllDay => 'طوال اليوم';

  @override
  String get familyMember => 'فرد من العائلة';

  @override
  String get ourNest => 'عشّنا';

  @override
  String get yourAccount => 'حسابك';

  @override
  String get homePaceBusy => 'مشغول';

  @override
  String get homePaceSteady => 'ثابت';

  @override
  String get homePaceQuiet => 'هادئ';

  @override
  String get homePlanDinner => 'خطّط للعشاء';

  @override
  String get syncNow => 'زامِن الآن';

  @override
  String get syncFailedRetry => 'فشلت المزامنة، أعد المحاولة';

  @override
  String get syncFailedTapRetry => 'فشلت المزامنة · اضغط إعادة المحاولة';

  @override
  String homeThingsToday(int count) {
    return 'لديك $count أمور لليوم';
  }

  @override
  String get homeNoEventsToday =>
      'لا أحداث في التقويم اليوم — اضغط لإضافة واحد';

  @override
  String get homeUpToDate => 'محدَّث';

  @override
  String get homeActivities => 'الأنشطة';

  @override
  String get homeNestActivity => 'نشاط العش';

  @override
  String homeRecentCount(int count) {
    return '$count حديثة';
  }

  @override
  String get homeRemindersEmpty =>
      'لا شيء عاجل الآن. تبقى التذكيرات المحلية مجدولة عند استحقاق العناصر.';

  @override
  String get expensesTapEditBudget => 'اضغط لتعديل الميزانية';

  @override
  String get expensesByCategory => 'حسب الفئة';

  @override
  String get emptyExpensesNone => 'لا مصاريف بعد — اضغط + عند الإنفاق.';

  @override
  String get emptyExpensesNoneNest =>
      'لا مصاريف في هذا العش بعد. اضغط + لإضافة واحدة.';

  @override
  String get emptyExpensesSearch => 'لا مصاريف تطابق هذا البحث.';

  @override
  String get emptyBillsHint => 'تتبّع الإيجار والمرافق والاشتراكات هنا.';

  @override
  String get emptyBillsNone => 'لا فواتير مُتتبَّعة بعد.';

  @override
  String get emptyBillsSearch => 'لا فواتير تطابق هذا البحث.';

  @override
  String get dueToday => 'مستحق اليوم';

  @override
  String get dueTomorrow => 'مستحق غدًا';

  @override
  String dueInDays(int count, String date) {
    return 'مستحق خلال $count يومًا · $date';
  }

  @override
  String snackMarkedPaid(String title) {
    return 'تم تعليم «$title» كمدفوع';
  }

  @override
  String get snackMarkedUnpaid => 'تم التعليم كغير مدفوع';

  @override
  String get monthBudgetTitle => 'ميزانية الشهر';

  @override
  String get monthBudgetBody => 'هدف إنفاق عائلتك لهذا الشهر التقويمي.';

  @override
  String snackBudgetSet(String amount) {
    return 'تم تعيين ميزانية الشهر إلى $amount';
  }

  @override
  String get markUnpaid => 'تعليم كغير مدفوع';

  @override
  String get markPaid => 'تعليم كمدفوع';

  @override
  String get addExpense => 'إضافة مصروف';

  @override
  String get editExpense => 'تعديل المصروف';

  @override
  String get deleteExpense => 'حذف المصروف';

  @override
  String get editBill => 'تعديل الفاتورة';

  @override
  String get deleteBill => 'حذف الفاتورة';

  @override
  String get vaultScanHint => 'قد يكون هذا مستندًا عائليًا أو دعوة';

  @override
  String get vaultRetryAll => 'إعادة المحاولة للكل';

  @override
  String get vaultExpiringSoon => 'تنتهي قريبًا';

  @override
  String get vaultRecentFiles => 'الملفات الأخيرة';

  @override
  String get vaultSearchResults => 'نتائج البحث';

  @override
  String get vaultSavedOffline => 'محفوظ على الجهاز — سيُرفع عند الاتصال';

  @override
  String get vaultStillOffline =>
      'لا يزال دون اتصال — تبقى الملفات على هذا الجهاز';

  @override
  String vaultUploaded(String title) {
    return 'تم رفع $title';
  }

  @override
  String get vaultUploadFailedSnack => 'فشل الرفع — حاول لاحقًا';

  @override
  String vaultNoSearchMatch(String query) {
    return 'لا مستندات تطابق «$query». جرّب عنوانًا أو ملاحظة أو اسم مجلد.';
  }

  @override
  String get vaultEmptyBody =>
      'لا مستندات بعد. اضغط + لإضافة هويات أو تأمين أو أوراق المنزل.';

  @override
  String vaultEmptyFolder(String folder) {
    return 'لا شيء في $folder بعد. اضغط + لإضافة ملف هنا.';
  }

  @override
  String get expiresToday => 'تنتهي اليوم';

  @override
  String get expiresTomorrow => 'تنتهي غدًا';

  @override
  String expiresInDays(int count) {
    return 'تنتهي خلال $count يومًا';
  }

  @override
  String get vaultExpiryHelp => 'متى ينتهي هذا؟';

  @override
  String get vaultDetails => 'تفاصيل المستند';

  @override
  String vaultStatusLabel(String status) {
    return 'الحالة · $status';
  }

  @override
  String get vaultRemoveFrom => 'إزالة من الخزنة';

  @override
  String get scanWhatScanning => 'ماذا تمسح؟';

  @override
  String get scanReceipt => 'إيصال';

  @override
  String get scanReceiptHint => 'إيصال متجر — استخراج المجموع كمصروف';

  @override
  String get scanInviteEvent => 'دعوة / حدث';

  @override
  String get scanInviteHint => 'دعوة أو موعد — حدث تقويم';

  @override
  String get scanSchoolNotice => 'إشعار مدرسي';

  @override
  String get scanSchoolHint => 'إشعار مدرسي أو جدول رياضي';

  @override
  String get scanBillLabel => 'فاتورة';

  @override
  String get scanBillHint =>
      'فاتورة مرافق أو خدمة — احفظها كفاتورة بتاريخ استحقاق';

  @override
  String get scanFailed => 'فشل المسح. حاول مرة أخرى.';

  @override
  String get scanExpenseAdded => 'تمت إضافة المصروف';

  @override
  String get scanBillAdded => 'تمت إضافة الفاتورة';

  @override
  String get scanTaskAdded => 'تمت إضافة المهمة';

  @override
  String get scanEventAdded => 'تمت إضافة الحدث';

  @override
  String get scanReview => 'مراجعة المسح';

  @override
  String get scanLowConfidence =>
      'ثقة منخفضة — راجع العنوان والتاريخ والمبلغ قبل الحفظ.';

  @override
  String get scanTimed => 'موقوت';

  @override
  String get scanEndTimeOptional => 'وقت الانتهاء (اختياري)';

  @override
  String get scanAmountDue => 'المبلغ المستحق';

  @override
  String get scanAssignTo => 'تعيين إلى';

  @override
  String get scanAddExpense => 'إضافة مصروف';

  @override
  String get scanAddBill => 'إضافة فاتورة';

  @override
  String get scanAddTask => 'إضافة مهمة';

  @override
  String get scanAddEvent => 'إضافة حدث';

  @override
  String get locatorPulse => 'نبض عشّك';

  @override
  String get locatorLocations => 'مواقع العش';

  @override
  String get locatorLoadFailed => 'تعذّر تحميل مواقع العش.';

  @override
  String get locatorPrivacyNote =>
      'لا يتتبع المحدّد في الخلفية. تنتهي النقاط بصريًا بعد 24 ساعة حتى لا يعتمد العش على أماكن قديمة.';

  @override
  String get locatorSharedSnack => 'تمت مشاركة موقعك مع العش';

  @override
  String get locatorGetFailed => 'تعذّر الحصول على موقعك. حاول مرة أخرى.';

  @override
  String get locatorUpdateFailed => 'تعذّر تحديث المشاركة.';

  @override
  String locatorLastSeen(String age) {
    return 'آخر ظهور $age';
  }

  @override
  String locatorUpdatedAge(String age) {
    return 'حُدِّث $age';
  }

  @override
  String get locatorOpenMap => 'فتح الخريطة';

  @override
  String get locatorMapWake => 'تستيقظ خريطة العش عندما يشارك أحد نقطة';

  @override
  String get locatorShrinkMap => 'تصغير الخريطة';

  @override
  String get locatorExpandMap => 'توسيع الخريطة';

  @override
  String get locatorSatellite => 'قمر صناعي';

  @override
  String get locatorModernMap => 'خريطة حديثة';

  @override
  String get locatorFitAll => 'ملاءمة الكل';

  @override
  String get emergencyOfflineNote =>
      'متاح دون اتصال — تبقى المعلومات الحرجة على هذا الجهاز وتُزامَن عند الاتصال.';

  @override
  String get emergencyCareProfiles => 'ملفات الرعاية';

  @override
  String get emergencyAddHint => 'أضف جهات اتصال الطوارئ والحساسيات والأطباء.';

  @override
  String emergencyCardTitle(String nest) {
    return 'بطاقة طوارئ Casaio — $nest';
  }

  @override
  String get emergencyInfo => 'معلومات الطوارئ';

  @override
  String get schoolIntro =>
      'توصيلات المدرسة والرياضة والنوادي والاستلام. أضف نشاطًا للبدء — علّم مكتملًا لترحيل التاريخ التالي، أو أنشئ مهمة استلام لنفس اليوم.';

  @override
  String get schoolDueToday => 'مستحق اليوم';

  @override
  String snackCalendarAdded(String date) {
    return 'تمت إضافة حدث التقويم · $date';
  }

  @override
  String get schoolNewActivity => 'نشاط جديد';

  @override
  String get schoolEditActivity => 'تعديل النشاط';

  @override
  String get schoolWhoFor => 'لمن هذا؟';

  @override
  String get careIntro =>
      'ملفات كبار السن وصيانة الحيوانات الأليفة والمنزل والسيارة. علّم مكتملًا لترحيل تاريخ الاستحقاق التالي — ابدأ بجدول واحد إن كانت القائمة فارغة.';

  @override
  String get careElderProfiles => 'ملفات كبار السن';

  @override
  String get careAddMembersHint =>
      'أضف أفراد العائلة في العش، ثم عيّن دور الجد/الجدة.';

  @override
  String get careNoElders =>
      'لا ملفات لكبار السن بعد — عيّن الجد/الجدة في العش، ثم أضف الأدوية والحساسيات هنا.';

  @override
  String get careDueNow => 'مستحق الآن';

  @override
  String get careNewItem => 'عنصر رعاية جديد';

  @override
  String get careEditItem => 'تعديل عنصر الرعاية';

  @override
  String get careForWhom => 'لمن؟';

  @override
  String careProfileTitle(String name) {
    return 'ملف الرعاية · $name';
  }

  @override
  String get mealsIntro =>
      'خطّط لعشاء الأسبوع، ثم ادفع المكونات إلى قائمة البقالة المشتركة.';

  @override
  String get mealsRestOfWeek => 'بقية الأسبوع';

  @override
  String get mealsNonePlanned => 'لا وجبة مخططة — اضغط لإضافة العشاء';

  @override
  String get mealsPlanAMeal => 'خطّط لوجبة';

  @override
  String get mealsEditMeal => 'تعديل الوجبة';

  @override
  String get mealsSaveMeal => 'حفظ الوجبة';

  @override
  String get mealsPlanWeekBody =>
      'املأ الليالي التي تهمك. الأيام الفارغة تبقى فارغة.';

  @override
  String get mealsRecipeLibrary => 'مكتبة الوصفات';

  @override
  String get mealsAddRecipe => 'إضافة وصفة';

  @override
  String get mealsEditRecipe => 'تعديل الوصفة';

  @override
  String get mealsSaveRecipe => 'حفظ الوصفة';

  @override
  String get mealsApplyRecipe => 'تطبيق على هذا اليوم';

  @override
  String get mealsSaveAsRecipe => 'حفظ كوصفة';

  @override
  String get mealsNoRecipes =>
      'لا وصفات محفوظة بعد — احفظ وجبة أو أضف واحدة هنا.';

  @override
  String get mealsRecipeApplied => 'تم تطبيق الوصفة';

  @override
  String get hintRecipeNotes => 'ملاحظات (اختياري)';

  @override
  String get shopClearBoughtBody =>
      'يزيل البقالة المشطوبة من هذه القائمة. يمكنك إعادة تخزين العادات لاحقًا.';

  @override
  String get shopNothingToClear => 'لا شيء للمسح';

  @override
  String shopClearedBought(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم مسح $count عناصر مشتراة',
      one: 'تم مسح عنصر مشترى واحد',
    );
    return '$_temp0';
  }

  @override
  String get shopSharedList => 'قائمة مشتركة';

  @override
  String get shopNoMatch => 'لا عناصر تطابق هذا البحث أو التصفية.';

  @override
  String get shopEditItem => 'تعديل العنصر';

  @override
  String get shopDeleteItem => 'حذف العنصر';

  @override
  String get shopBasedOnUsual => 'بناءً على ما تشتريه عادةً';

  @override
  String get shopNewList => 'قائمة جديدة';

  @override
  String get shopListNameHint => 'اسم القائمة';

  @override
  String get shopCreateList => 'إنشاء قائمة';

  @override
  String get shopRenameList => 'إعادة تسمية القائمة';

  @override
  String get shopDeleteList => 'حذف القائمة';

  @override
  String get shopDeleteListBody => 'تزيل هذه القائمة وعناصرها من العش.';

  @override
  String get shopEmptyListTitle => 'هذه القائمة فارغة';

  @override
  String get shopEmptyListBody => 'أضف عناصر لهذا المتجر أو المناسبة.';

  @override
  String get shopRestock => 'إعادة تخزين';

  @override
  String get tasksNoMatch => 'لا مهام تطابق هذا البحث.';

  @override
  String tasksFilterFor(String name) {
    return 'تصفية مهام $name';
  }

  @override
  String get taskNew => 'مهمة جديدة';

  @override
  String get taskEdit => 'تعديل المهمة';

  @override
  String get taskHabitHint => 'تبقى مفتوحة ويُرحّل تاريخ الاستحقاق عند الإنجاز';

  @override
  String get taskAdd => 'إضافة مهمة';

  @override
  String get calendarNewEvent => 'حدث جديد';

  @override
  String get calendarEditEvent => 'تعديل الحدث';

  @override
  String get calendarDeleteBody => 'هذا يزيله من التقويم المشترك.';

  @override
  String get resetMailSubject => 'مساعدة إعادة تعيين كلمة مرور Casaio';

  @override
  String resetMailBody(String email) {
    return 'بريد الحساب: $email\n\n';
  }

  @override
  String get resetFillBoth => 'أدخل كلمة المرور الحالية والجديدة.';

  @override
  String get resetMismatch => 'كلمتا المرور الجديدتان غير متطابقتين.';

  @override
  String get onboardingScanSuggestion => 'اقتراح المسح';

  @override
  String get onboardingGroceryRun => 'تسوق البقالة · \$42.50';

  @override
  String get onboardingSuggestedExpense => 'مصروف مقترح من إيصالك';

  @override
  String get onboardingSaveExpense => 'حفظ المصروف';

  @override
  String get onboardingEditFirst => 'عدّل أولًا';

  @override
  String get paidByAnyone => 'أي شخص';

  @override
  String shopLeftCount(int count) {
    return '$count متبقية';
  }

  @override
  String shopBoughtCount(int count) {
    return '$count مشتراة';
  }

  @override
  String get taskRepeats => 'تتكرر';

  @override
  String get taskPickDate => 'اختر تاريخًا';

  @override
  String get taskCadenceDaily => 'كل يوم';

  @override
  String get taskCadenceWeekly => 'كل أسبوع';

  @override
  String get taskCadenceBiweekly => 'كل أسبوعين';

  @override
  String get taskCadenceMonthly => 'كل شهر';

  @override
  String taskCadenceEveryDays(int days) {
    return 'كل $days أيام';
  }

  @override
  String taskRepeatsCadence(String cadence) {
    return 'تتكرر · $cadence';
  }

  @override
  String get taskOpen => 'مفتوحة';

  @override
  String get locatorNearMe => 'بالقرب مني';

  @override
  String locatorAway(String distance) {
    return 'على بعد $distance';
  }

  @override
  String get locatorSignIn => 'سجّل الدخول لمشاركة موقعك.';

  @override
  String get locatorJoinNest => 'انضم إلى عش قبل مشاركة الموقع.';

  @override
  String get locatorNeedPermission => 'يلزم إذن الموقع لمشاركة مكانك.';

  @override
  String get locatorNeedServices => 'فعّل خدمات الموقع للمشاركة.';

  @override
  String vaultPackSubject(int count) {
    return 'حزمة خزنة Casaio ($count)';
  }

  @override
  String get vaultPackText => 'مشارَك من خزنة Casaio';

  @override
  String get vaultNoFilesShare => 'لا ملفات متاحة للمشاركة بعد.';

  @override
  String get privacyExportSubject => 'تصدير بيانات Casaio';

  @override
  String get privacyExportShareText =>
      'تصدير عش Casaio (JSON). لا تُضمَّن الملفات الثنائية للخزنة.';

  @override
  String mealsAddIngredientsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'إضافة $count مكوّنات؟',
      one: 'إضافة مكوّن واحد؟',
    );
    return '$_temp0';
  }

  @override
  String mealsAddIngredientsBody(String label) {
    return 'من $label — تُتخطى العناصر الموجودة في القائمة.';
  }

  @override
  String get scanEmptyResult => 'أعاد المسح نتيجة فارغة. جرّب صورة أوضح.';

  @override
  String get scanUnexpected => 'أعاد المسح استجابة غير متوقعة. جرّب صورة أخرى.';

  @override
  String get scanTimedOut => 'انتهت مهلة المسح. جرّب صورة أوضح أو ملفًا أصغر.';

  @override
  String get scanReachFailed =>
      'تعذّر الوصول إلى Vertex AI. تحقق من الاتصال وحاول مرة أخرى.';

  @override
  String get scanQuotaReached =>
      'تم بلوغ حصة الذكاء الاصطناعي اليوم. حاول لاحقًا.';

  @override
  String get scanNeedBlaze =>
      'يحتاج Vertex AI إلى خطة Firebase Blaze. رقِّ الفوترة في وحدة تحكم Firebase، فعّل Vertex AI، ثم حاول مرة أخرى.';

  @override
  String get scanVertexNotReady =>
      'Vertex AI Gemini غير جاهز. في وحدة تحكم Firebase فعّل AI Logic مع Vertex AI Gemini API (Blaze)، ثم حاول مرة أخرى.';

  @override
  String get scanFileTooLargeAi =>
      'هذا الملف كبير جدًا. استخدم صورة أو PDF أقل من نحو 4 ميجابايت.';

  @override
  String get commonCopy => 'نسخ';

  @override
  String get locatorLive => 'مباشر';

  @override
  String get locatorDirections => 'الاتجاهات';

  @override
  String get pressBackAgainToExit => 'اضغط رجوع مرة أخرى للخروج';
}
