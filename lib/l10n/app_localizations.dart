import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_af.dart';
import 'app_localizations_ar.dart';
import 'app_localizations_az.dart';
import 'app_localizations_be.dart';
import 'app_localizations_bg.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_ca.dart';
import 'app_localizations_cs.dart';
import 'app_localizations_da.dart';
import 'app_localizations_de.dart';
import 'app_localizations_el.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_et.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fil.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ga.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_ha.dart';
import 'app_localizations_he.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_hr.dart';
import 'app_localizations_hu.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ka.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ky.dart';
import 'app_localizations_lo.dart';
import 'app_localizations_lt.dart';
import 'app_localizations_lv.dart';
import 'app_localizations_mk.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_nb.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_ps.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ro.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_rw.dart';
import 'app_localizations_si.dart';
import 'app_localizations_sk.dart';
import 'app_localizations_sl.dart';
import 'app_localizations_sq.dart';
import 'app_localizations_sr.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_sw.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_uz.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';
import 'app_localizations_zu.dart';

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
    Locale('af'),
    Locale('ar'),
    Locale('az'),
    Locale('be'),
    Locale('be', 'BY'),
    Locale('bg'),
    Locale('bn'),
    Locale('ca'),
    Locale('cs'),
    Locale('da'),
    Locale('de'),
    Locale('el'),
    Locale('en'),
    Locale('es'),
    Locale('et'),
    Locale('fa'),
    Locale('fi'),
    Locale('fil'),
    Locale('fr'),
    Locale('ga'),
    Locale('gu'),
    Locale('ha'),
    Locale('he'),
    Locale('hi'),
    Locale('hr'),
    Locale('hu'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ka'),
    Locale('kk'),
    Locale('kn'),
    Locale('ko'),
    Locale('ky'),
    Locale('ky', 'KG'),
    Locale('lo'),
    Locale('lt'),
    Locale('lv'),
    Locale('mk'),
    Locale('ml'),
    Locale('mr'),
    Locale('ms'),
    Locale('nb'),
    Locale('nl'),
    Locale('pa'),
    Locale('pl'),
    Locale('ps'),
    Locale('ps', 'AF'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('pt', 'PT'),
    Locale('ro'),
    Locale('ru'),
    Locale('rw'),
    Locale('rw', 'RW'),
    Locale('si'),
    Locale('si', 'LK'),
    Locale('sk'),
    Locale('sl'),
    Locale('sq'),
    Locale('sr'),
    Locale('sv'),
    Locale('sw'),
    Locale('ta'),
    Locale('te'),
    Locale('th'),
    Locale('tr'),
    Locale('uk'),
    Locale('ur'),
    Locale('uz'),
    Locale('vi'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'HK'),
    Locale('zh', 'TW'),
    Locale('zu'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'BarQody'**
  String get appTitle;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account settings'**
  String get accountSettings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @forYou.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get forYou;

  /// No description provided for @yourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get yourProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change your name, photo, and bio'**
  String get editProfileSubtitle;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @setUsernameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your unique profile username'**
  String get setUsernameSubtitle;

  /// No description provided for @socialLinks.
  ///
  /// In en, this message translates to:
  /// **'Social Links'**
  String get socialLinks;

  /// No description provided for @socialLinksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add Instagram, WhatsApp, website and more'**
  String get socialLinksSubtitle;

  /// No description provided for @publicProfile.
  ///
  /// In en, this message translates to:
  /// **'Public profile'**
  String get publicProfile;

  /// No description provided for @publicProfileOn.
  ///
  /// In en, this message translates to:
  /// **'Anyone can find and view your profile'**
  String get publicProfileOn;

  /// No description provided for @publicProfileOff.
  ///
  /// In en, this message translates to:
  /// **'Hidden from search — others can\'t discover you'**
  String get publicProfileOff;

  /// No description provided for @shareQr.
  ///
  /// In en, this message translates to:
  /// **'Share My QR Code'**
  String get shareQr;

  /// No description provided for @shareQrSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let others scan your digital business card'**
  String get shareQrSubtitle;

  /// No description provided for @shoppingRewards.
  ///
  /// In en, this message translates to:
  /// **'Shopping & rewards'**
  String get shoppingRewards;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @myOrdersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track orders you placed from shops'**
  String get myOrdersSubtitle;

  /// No description provided for @myRewardCards.
  ///
  /// In en, this message translates to:
  /// **'My Reward Cards'**
  String get myRewardCards;

  /// No description provided for @myRewardCardsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View stamps and points from loyalty programs'**
  String get myRewardCardsSubtitle;

  /// No description provided for @workplace.
  ///
  /// In en, this message translates to:
  /// **'Workplace'**
  String get workplace;

  /// No description provided for @employeeInvitations.
  ///
  /// In en, this message translates to:
  /// **'Employee Invitations'**
  String get employeeInvitations;

  /// No description provided for @employeeInvitationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accept or decline team invitations from businesses'**
  String get employeeInvitationsSubtitle;

  /// No description provided for @workplaceCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Workplace Check-In'**
  String get workplaceCheckIn;

  /// No description provided for @workplaceCheckInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clock in and out at your job with location'**
  String get workplaceCheckInSubtitle;

  /// No description provided for @accountsAndDevices.
  ///
  /// In en, this message translates to:
  /// **'Accounts & devices'**
  String get accountsAndDevices;

  /// No description provided for @linkedDevices.
  ///
  /// In en, this message translates to:
  /// **'Linked devices'**
  String get linkedDevices;

  /// No description provided for @linkedDevicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Link another phone like WhatsApp'**
  String get linkedDevicesSubtitle;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @accountsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add or switch accounts'**
  String get accountsSubtitle;

  /// No description provided for @accountsSwitchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch between {count} accounts'**
  String accountsSwitchSubtitle(int count);

  /// No description provided for @helpAndAccount.
  ///
  /// In en, this message translates to:
  /// **'Help & account'**
  String get helpAndAccount;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// No description provided for @appLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change the language used in the app'**
  String get appLanguageSubtitle;

  /// No description provided for @searchLanguage.
  ///
  /// In en, this message translates to:
  /// **'Search language'**
  String get searchLanguage;

  /// No description provided for @phoneLanguage.
  ///
  /// In en, this message translates to:
  /// **'Phone\'s language'**
  String get phoneLanguage;

  /// No description provided for @languageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get languageUpdated;

  /// No description provided for @helpFaqs.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQs'**
  String get helpFaqs;

  /// No description provided for @helpFaqsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Answers to common questions'**
  String get helpFaqsSubtitle;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @sendFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Report a bug or suggest a new feature'**
  String get sendFeedbackSubtitle;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @logOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of this session'**
  String get logOutSubtitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @str.
  ///
  /// In en, this message translates to:
  /// **'بطاقة أعمال الرقمية'**
  String get str;

  /// No description provided for @readOnly.
  ///
  /// In en, this message translates to:
  /// **'(Read only)'**
  String get readOnly;

  /// No description provided for @n1Point100PKRExampleRule.
  ///
  /// In en, this message translates to:
  /// **'1 Point = 100 PKR (example rule)'**
  String get n1Point100PKRExampleRule;

  /// No description provided for @n10StampsRequired.
  ///
  /// In en, this message translates to:
  /// **'10 Stamps Required'**
  String get n10StampsRequired;

  /// No description provided for @n123MainStCity.
  ///
  /// In en, this message translates to:
  /// **'123 Main St, City'**
  String get n123MainStCity;

  /// No description provided for @n2DaysAgo.
  ///
  /// In en, this message translates to:
  /// **'2 Days Ago'**
  String get n2DaysAgo;

  /// No description provided for @n330CharactersLettersNumbersUnderscoresAndHyphensOnly.
  ///
  /// In en, this message translates to:
  /// **'3–30 characters. Letters, numbers, underscores and hyphens only.'**
  String get n330CharactersLettersNumbersUnderscoresAndHyphensOnly;

  /// No description provided for @aabbccdd.
  ///
  /// In en, this message translates to:
  /// **'AABBCCDD'**
  String get aabbccdd;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @accessRESTRICTED.
  ///
  /// In en, this message translates to:
  /// **'ACCESS RESTRICTED'**
  String get accessRESTRICTED;

  /// No description provided for @accountIBANAddAccountNumberHere.
  ///
  /// In en, this message translates to:
  /// **'Account / IBAN: Add account number here'**
  String get accountIBANAddAccountNumberHere;

  /// No description provided for @accountTitleTapni.
  ///
  /// In en, this message translates to:
  /// **'Account Title: Tapni'**
  String get accountTitleTapni;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @active2.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get active2;

  /// No description provided for @activeCARD.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE CARD'**
  String get activeCARD;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addANote.
  ///
  /// In en, this message translates to:
  /// **'Add a note...'**
  String get addANote;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get addAccount;

  /// No description provided for @addAtLeastOneCategoryFirst.
  ///
  /// In en, this message translates to:
  /// **'Add at least one category first'**
  String get addAtLeastOneCategoryFirst;

  /// No description provided for @addCategoriesInDisplayOrderEGFastFoodThenDesi.
  ///
  /// In en, this message translates to:
  /// **'Add categories in display order (e.g. Fast Food, then Desi)'**
  String get addCategoriesInDisplayOrderEGFastFoodThenDesi;

  /// No description provided for @addCategoriesInYourCatalogSettingsFirst.
  ///
  /// In en, this message translates to:
  /// **'Add categories in your catalog settings first.'**
  String get addCategoriesInYourCatalogSettingsFirst;

  /// No description provided for @addContact.
  ///
  /// In en, this message translates to:
  /// **'Add contact'**
  String get addContact;

  /// No description provided for @addLink.
  ///
  /// In en, this message translates to:
  /// **'Add Link'**
  String get addLink;

  /// No description provided for @addLinksToYourProfileBelow.
  ///
  /// In en, this message translates to:
  /// **'Add links to your profile below'**
  String get addLinksToYourProfileBelow;

  /// No description provided for @addLinksToYourProfileFirstThenEnableThemHere.
  ///
  /// In en, this message translates to:
  /// **'Add links to your profile first, then enable them here.'**
  String get addLinksToYourProfileFirstThenEnableThemHere;

  /// No description provided for @addLogo.
  ///
  /// In en, this message translates to:
  /// **'Add Logo'**
  String get addLogo;

  /// No description provided for @addPoints.
  ///
  /// In en, this message translates to:
  /// **'Add Points'**
  String get addPoints;

  /// No description provided for @addProgram.
  ///
  /// In en, this message translates to:
  /// **'Add Program'**
  String get addProgram;

  /// No description provided for @addStamp.
  ///
  /// In en, this message translates to:
  /// **'Add Stamp'**
  String get addStamp;

  /// No description provided for @addToGoogleWallet.
  ///
  /// In en, this message translates to:
  /// **'Add to Google Wallet'**
  String get addToGoogleWallet;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @ai.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get ai;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get allCaughtUp;

  /// No description provided for @allNotificationsMarkedAsRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read!'**
  String get allNotificationsMarkedAsRead;

  /// No description provided for @allowCamera.
  ///
  /// In en, this message translates to:
  /// **'Allow camera'**
  String get allowCamera;

  /// No description provided for @allowThisDeviceToAccessYourBarqodyAccountYouCanRemoveItAnytimeFromLinkedDevices.
  ///
  /// In en, this message translates to:
  /// **'Allow this device to access your Barqody account? You can remove it anytime from Linked devices.'**
  String
  get allowThisDeviceToAccessYourBarqodyAccountYouCanRemoveItAnytimeFromLinkedDevices;

  /// No description provided for @alreadyHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAnAccount;

  /// No description provided for @analyticsDashboard.
  ///
  /// In en, this message translates to:
  /// **'Analytics Dashboard'**
  String get analyticsDashboard;

  /// No description provided for @anySpecialRequests.
  ///
  /// In en, this message translates to:
  /// **'Any special requests...'**
  String get anySpecialRequests;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @applyDesign.
  ///
  /// In en, this message translates to:
  /// **'Apply Design'**
  String get applyDesign;

  /// No description provided for @applyTemplate.
  ///
  /// In en, this message translates to:
  /// **'Apply Template'**
  String get applyTemplate;

  /// No description provided for @ascending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// No description provided for @askYourBusinessToScanYourQRAndAddYouAsAnEmployee.
  ///
  /// In en, this message translates to:
  /// **'Ask your business to scan your QR and add you as an employee'**
  String get askYourBusinessToScanYourQRAndAddYouAsAnEmployee;

  /// No description provided for @assignCategory.
  ///
  /// In en, this message translates to:
  /// **'Assign Category'**
  String get assignCategory;

  /// No description provided for @assignedPrograms.
  ///
  /// In en, this message translates to:
  /// **'Assigned Programs'**
  String get assignedPrograms;

  /// No description provided for @atLeast6Characters.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get atLeast6Characters;

  /// No description provided for @attendanceCompletedForToday.
  ///
  /// In en, this message translates to:
  /// **'Attendance completed for today'**
  String get attendanceCompletedForToday;

  /// No description provided for @availableSlots.
  ///
  /// In en, this message translates to:
  /// **'Available slots'**
  String get availableSlots;

  /// No description provided for @background.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get background;

  /// No description provided for @backgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background color'**
  String get backgroundColor;

  /// No description provided for @bankAccount.
  ///
  /// In en, this message translates to:
  /// **'Bank Account'**
  String get bankAccount;

  /// No description provided for @bankDetails.
  ///
  /// In en, this message translates to:
  /// **'Bank Details'**
  String get bankDetails;

  /// No description provided for @bankAddBankNameHere.
  ///
  /// In en, this message translates to:
  /// **'Bank: Add bank name here'**
  String get bankAddBankNameHere;

  /// No description provided for @barqody.
  ///
  /// In en, this message translates to:
  /// **'Barqody'**
  String get barqody;

  /// No description provided for @barqodyV100.
  ///
  /// In en, this message translates to:
  /// **'barqody v1.0.0'**
  String get barqodyV100;

  /// No description provided for @bestValue.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get bestValue;

  /// No description provided for @billAmount.
  ///
  /// In en, this message translates to:
  /// **'Bill Amount'**
  String get billAmount;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'BIO'**
  String get bio;

  /// No description provided for @bio2.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio2;

  /// No description provided for @book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get book;

  /// No description provided for @bookingDate.
  ///
  /// In en, this message translates to:
  /// **'Booking date'**
  String get bookingDate;

  /// No description provided for @bookingSchedule.
  ///
  /// In en, this message translates to:
  /// **'Booking schedule'**
  String get bookingSchedule;

  /// No description provided for @bookingTime.
  ///
  /// In en, this message translates to:
  /// **'Booking time'**
  String get bookingTime;

  /// No description provided for @business.
  ///
  /// In en, this message translates to:
  /// **'BUSINESS'**
  String get business;

  /// No description provided for @businessCategory.
  ///
  /// In en, this message translates to:
  /// **'Business Category'**
  String get businessCategory;

  /// No description provided for @businessDetails.
  ///
  /// In en, this message translates to:
  /// **'Business Details'**
  String get businessDetails;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessName;

  /// No description provided for @businessOptions.
  ///
  /// In en, this message translates to:
  /// **'Business options'**
  String get businessOptions;

  /// No description provided for @businessPrograms.
  ///
  /// In en, this message translates to:
  /// **'Business Programs'**
  String get businessPrograms;

  /// No description provided for @businessUsersOnly.
  ///
  /// In en, this message translates to:
  /// **'Business Users Only'**
  String get businessUsersOnly;

  /// No description provided for @bySigningUpYouAgreeToOurTermsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'By signing up, you agree to our Terms and Conditions.'**
  String get bySigningUpYouAgreeToOurTermsAndConditions;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @cameraPermissionIsRequiredToScan.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required to scan.'**
  String get cameraPermissionIsRequiredToScan;

  /// No description provided for @cancelAnytime.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime.'**
  String get cancelAnytime;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrder;

  /// No description provided for @captureNewContact.
  ///
  /// In en, this message translates to:
  /// **'Capture New Contact'**
  String get captureNewContact;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category *'**
  String get category;

  /// No description provided for @categoryAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Category already exists'**
  String get categoryAlreadyExists;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check out'**
  String get checkOut;

  /// No description provided for @chooseAUniqueUsernameForYourProfileLink.
  ///
  /// In en, this message translates to:
  /// **'Choose a unique username for your profile link.'**
  String get chooseAUniqueUsernameForYourProfileLink;

  /// No description provided for @choosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose Plan'**
  String get choosePlan;

  /// No description provided for @chooseTemplate.
  ///
  /// In en, this message translates to:
  /// **'Choose Template'**
  String get chooseTemplate;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get codeCopied;

  /// No description provided for @commingSoon.
  ///
  /// In en, this message translates to:
  /// **'Comming Soon'**
  String get commingSoon;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @companyEmployeeCard.
  ///
  /// In en, this message translates to:
  /// **'Company Employee Card'**
  String get companyEmployeeCard;

  /// No description provided for @companyInc.
  ///
  /// In en, this message translates to:
  /// **'Company Inc.'**
  String get companyInc;

  /// No description provided for @completeTheseSteps.
  ///
  /// In en, this message translates to:
  /// **'Complete these steps'**
  String get completeTheseSteps;

  /// No description provided for @confirmAddPoints.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Add Points'**
  String get confirmAddPoints;

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get confirmBooking;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocation;

  /// No description provided for @confirmRedemption.
  ///
  /// In en, this message translates to:
  /// **'Confirm Redemption'**
  String get confirmRedemption;

  /// No description provided for @connectedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Connected Accounts'**
  String get connectedAccounts;

  /// No description provided for @contactAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Contact added successfully!'**
  String get contactAddedSuccessfully;

  /// No description provided for @contactCard.
  ///
  /// In en, this message translates to:
  /// **'Contact card'**
  String get contactCard;

  /// No description provided for @contactExchangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Contact exchanged successfully!'**
  String get contactExchangedSuccessfully;

  /// No description provided for @contactSource.
  ///
  /// In en, this message translates to:
  /// **'Contact Source'**
  String get contactSource;

  /// No description provided for @contactUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Contact updated successfully!'**
  String get contactUpdatedSuccessfully;

  /// No description provided for @contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCode;

  /// No description provided for @couldNotGetLocationPleaseEnableGPSPermission.
  ///
  /// In en, this message translates to:
  /// **'Could not get location. Please enable GPS permission.'**
  String get couldNotGetLocationPleaseEnableGPSPermission;

  /// No description provided for @couldNotSwitchAccount.
  ///
  /// In en, this message translates to:
  /// **'Could not switch account'**
  String get couldNotSwitchAccount;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @createLoyaltyProgram.
  ///
  /// In en, this message translates to:
  /// **'Create Loyalty Program'**
  String get createLoyaltyProgram;

  /// No description provided for @createNewLink.
  ///
  /// In en, this message translates to:
  /// **'Create new link'**
  String get createNewLink;

  /// No description provided for @createProgram.
  ///
  /// In en, this message translates to:
  /// **'Create Program'**
  String get createProgram;

  /// No description provided for @createReward.
  ///
  /// In en, this message translates to:
  /// **'Create Reward'**
  String get createReward;

  /// No description provided for @createStampOrPointsRewardsForCustomers.
  ///
  /// In en, this message translates to:
  /// **'Create stamp or points rewards for customers'**
  String get createStampOrPointsRewardsForCustomers;

  /// No description provided for @createYourFirstCard.
  ///
  /// In en, this message translates to:
  /// **'Create your first card'**
  String get createYourFirstCard;

  /// No description provided for @createYourFirstRewardCardForCustomers.
  ///
  /// In en, this message translates to:
  /// **'Create your first reward card for customers'**
  String get createYourFirstRewardCardForCustomers;

  /// No description provided for @creationDate.
  ///
  /// In en, this message translates to:
  /// **'Creation Date'**
  String get creationDate;

  /// No description provided for @customImagesForStampedAndUnstampedSlotsDefaultsAreUsedIfNotSet.
  ///
  /// In en, this message translates to:
  /// **'Custom images for stamped and unstamped slots. Defaults are used if not set.'**
  String get customImagesForStampedAndUnstampedSlotsDefaultsAreUsedIfNotSet;

  /// No description provided for @customLink.
  ///
  /// In en, this message translates to:
  /// **'Custom link'**
  String get customLink;

  /// No description provided for @customerDetails.
  ///
  /// In en, this message translates to:
  /// **'Customer Details'**
  String get customerDetails;

  /// No description provided for @customerEnrolledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Customer enrolled successfully'**
  String get customerEnrolledSuccessfully;

  /// No description provided for @customerIsNotEnrolledYet.
  ///
  /// In en, this message translates to:
  /// **'Customer is not enrolled yet'**
  String get customerIsNotEnrolledYet;

  /// No description provided for @customerNoShow.
  ///
  /// In en, this message translates to:
  /// **'Customer No Show'**
  String get customerNoShow;

  /// No description provided for @customerOrders.
  ///
  /// In en, this message translates to:
  /// **'Customer Orders'**
  String get customerOrders;

  /// No description provided for @customizeCardDesign.
  ///
  /// In en, this message translates to:
  /// **'Customize Card Design'**
  String get customizeCardDesign;

  /// No description provided for @customizeDesign.
  ///
  /// In en, this message translates to:
  /// **'Customize Design'**
  String get customizeDesign;

  /// No description provided for @customizeYourProfileUnlockPROTemplatesAndGetUnlimitedLeads.
  ///
  /// In en, this message translates to:
  /// **'Customize your profile, unlock PRO templates, and get unlimited leads.'**
  String get customizeYourProfileUnlockPROTemplatesAndGetUnlimitedLeads;

  /// No description provided for @customizeYourself.
  ///
  /// In en, this message translates to:
  /// **'Customize yourself'**
  String get customizeYourself;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteCard.
  ///
  /// In en, this message translates to:
  /// **'Delete card?'**
  String get deleteCard;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// No description provided for @deleteContact.
  ///
  /// In en, this message translates to:
  /// **'Delete Contact'**
  String get deleteContact;

  /// No description provided for @deleteReward.
  ///
  /// In en, this message translates to:
  /// **'Delete Reward?'**
  String get deleteReward;

  /// No description provided for @descending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @deviceLinked.
  ///
  /// In en, this message translates to:
  /// **'Device linked'**
  String get deviceLinked;

  /// No description provided for @deviceLoggedOut.
  ///
  /// In en, this message translates to:
  /// **'Device logged out'**
  String get deviceLoggedOut;

  /// No description provided for @deviceStatus.
  ///
  /// In en, this message translates to:
  /// **'Device status'**
  String get deviceStatus;

  /// No description provided for @digitalBusinessCard.
  ///
  /// In en, this message translates to:
  /// **'Digital Business Card'**
  String get digitalBusinessCard;

  /// No description provided for @digitalBUSINESSCard.
  ///
  /// In en, this message translates to:
  /// **'DIGITAL BUSINESS Card'**
  String get digitalBUSINESSCard;

  /// No description provided for @dontHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAnAccount;

  /// No description provided for @eGFastFood.
  ///
  /// In en, this message translates to:
  /// **'e.g. Fast Food'**
  String get eGFastFood;

  /// No description provided for @eGNoSugarExtraHot.
  ///
  /// In en, this message translates to:
  /// **'e.g. No sugar, extra hot...'**
  String get eGNoSugarExtraHot;

  /// No description provided for @earned50Points.
  ///
  /// In en, this message translates to:
  /// **'Earned 50 Points'**
  String get earned50Points;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editCard.
  ///
  /// In en, this message translates to:
  /// **'Edit card'**
  String get editCard;

  /// No description provided for @editDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Details'**
  String get editDetails;

  /// No description provided for @editProfile2.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile2;

  /// No description provided for @editSettings.
  ///
  /// In en, this message translates to:
  /// **'Edit Settings'**
  String get editSettings;

  /// No description provided for @editYourProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit your profile details'**
  String get editYourProfileDetails;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailPassword.
  ///
  /// In en, this message translates to:
  /// **'Email & password'**
  String get emailPassword;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @emailLoginOrScanQR.
  ///
  /// In en, this message translates to:
  /// **'Email login or scan QR'**
  String get emailLoginOrScanQR;

  /// No description provided for @employeeCard.
  ///
  /// In en, this message translates to:
  /// **'Employee Card'**
  String get employeeCard;

  /// No description provided for @employeeCARD.
  ///
  /// In en, this message translates to:
  /// **'EMPLOYEE CARD'**
  String get employeeCARD;

  /// No description provided for @employeeFacePhoto.
  ///
  /// In en, this message translates to:
  /// **'Employee Face Photo'**
  String get employeeFacePhoto;

  /// No description provided for @emptySlot.
  ///
  /// In en, this message translates to:
  /// **'Empty slot'**
  String get emptySlot;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'END'**
  String get end;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @endHour.
  ///
  /// In en, this message translates to:
  /// **'End hour'**
  String get endHour;

  /// No description provided for @enrollCustomer.
  ///
  /// In en, this message translates to:
  /// **'Enroll Customer'**
  String get enrollCustomer;

  /// No description provided for @enterBillAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter bill amount'**
  String get enterBillAmount;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get enterCode;

  /// No description provided for @enterCodeInstead.
  ///
  /// In en, this message translates to:
  /// **'Enter code instead'**
  String get enterCodeInstead;

  /// No description provided for @enterNetworkingContactDetailsBelow.
  ///
  /// In en, this message translates to:
  /// **'Enter networking contact details below.'**
  String get enterNetworkingContactDetailsBelow;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @eventBadge.
  ///
  /// In en, this message translates to:
  /// **'Event Badge'**
  String get eventBadge;

  /// No description provided for @exchangeContact.
  ///
  /// In en, this message translates to:
  /// **'Exchange Contact'**
  String get exchangeContact;

  /// No description provided for @exchangingContact.
  ///
  /// In en, this message translates to:
  /// **'Exchanging contact...'**
  String get exchangingContact;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @failedToUpdateContact.
  ///
  /// In en, this message translates to:
  /// **'Failed to update contact.'**
  String get failedToUpdateContact;

  /// No description provided for @filledSlot.
  ///
  /// In en, this message translates to:
  /// **'Filled slot'**
  String get filledSlot;

  /// No description provided for @filterContacts.
  ///
  /// In en, this message translates to:
  /// **'Filter contacts'**
  String get filterContacts;

  /// No description provided for @filterContacts2.
  ///
  /// In en, this message translates to:
  /// **'Filter Contacts'**
  String get filterContacts2;

  /// No description provided for @findPeopleOnBarQody.
  ///
  /// In en, this message translates to:
  /// **'Find people on BarQody'**
  String get findPeopleOnBarQody;

  /// No description provided for @findUser.
  ///
  /// In en, this message translates to:
  /// **'Find user'**
  String get findUser;

  /// No description provided for @findUser2.
  ///
  /// In en, this message translates to:
  /// **'Find User'**
  String get findUser2;

  /// No description provided for @findUsername.
  ///
  /// In en, this message translates to:
  /// **'Find username'**
  String get findUsername;

  /// No description provided for @forgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot?'**
  String get forgot;

  /// No description provided for @freeCoffee.
  ///
  /// In en, this message translates to:
  /// **'Free Coffee'**
  String get freeCoffee;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @go.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get go;

  /// No description provided for @goBusiness.
  ///
  /// In en, this message translates to:
  /// **'Go Business'**
  String get goBusiness;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'GUEST'**
  String get guest;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello,'**
  String get hello;

  /// No description provided for @helpCenterIsDisabledInThisUIDemo.
  ///
  /// In en, this message translates to:
  /// **'Help Center is disabled in this UI demo.'**
  String get helpCenterIsDisabledInThisUIDemo;

  /// No description provided for @hex.
  ///
  /// In en, this message translates to:
  /// **'Hex: #'**
  String get hex;

  /// No description provided for @holdTheQRCodeInsideTheFrameItScansAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Hold the QR code inside the frame — it scans automatically.'**
  String get holdTheQRCodeInsideTheFrameItScansAutomatically;

  /// No description provided for @howDoYouWantToDesignThisCard.
  ///
  /// In en, this message translates to:
  /// **'How do you want to design this card?'**
  String get howDoYouWantToDesignThisCard;

  /// No description provided for @importContacts.
  ///
  /// In en, this message translates to:
  /// **'Import contacts'**
  String get importContacts;

  /// No description provided for @importContactsIsNotAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'Import contacts is not available yet.'**
  String get importContactsIsNotAvailableYet;

  /// No description provided for @inLabel.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get inLabel;

  /// No description provided for @incomingOrders.
  ///
  /// In en, this message translates to:
  /// **'Incoming orders'**
  String get incomingOrders;

  /// No description provided for @invalidProfileURLScanAValidBarQodyCardOrQRCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid profile URL. Scan a valid BarQody card or QR code.'**
  String get invalidProfileURLScanAValidBarQodyCardOrQRCode;

  /// No description provided for @invalidQRCodeUseABarqodyLinkQR.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code. Use a Barqody link QR.'**
  String get invalidQRCodeUseABarqodyLinkQR;

  /// No description provided for @inviteEmployeesSetShiftsAndTrackPresence.
  ///
  /// In en, this message translates to:
  /// **'Invite employees, set shifts and track presence'**
  String get inviteEmployeesSetShiftsAndTrackPresence;

  /// No description provided for @invitedYouToJoinAsEmployee.
  ///
  /// In en, this message translates to:
  /// **'Invited you to join as employee'**
  String get invitedYouToJoinAsEmployee;

  /// No description provided for @janeDoe.
  ///
  /// In en, this message translates to:
  /// **'Jane Doe'**
  String get janeDoe;

  /// No description provided for @janeCompanyCom.
  ///
  /// In en, this message translates to:
  /// **'jane@company.com'**
  String get janeCompanyCom;

  /// No description provided for @jobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Title'**
  String get jobTitle;

  /// No description provided for @johnDoe.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get johnDoe;

  /// No description provided for @johnSmith.
  ///
  /// In en, this message translates to:
  /// **'John Smith'**
  String get johnSmith;

  /// No description provided for @johnEmailCom.
  ///
  /// In en, this message translates to:
  /// **'john@email.com'**
  String get johnEmailCom;

  /// No description provided for @joinedJan152026.
  ///
  /// In en, this message translates to:
  /// **'Joined: Jan 15, 2026'**
  String get joinedJan152026;

  /// No description provided for @jpg.
  ///
  /// In en, this message translates to:
  /// **'JPG'**
  String get jpg;

  /// No description provided for @keepYourAccountSafeOnlyScanQRCodesWhenYouWantToLinkADeviceYouTrust.
  ///
  /// In en, this message translates to:
  /// **'Keep your account safe. Only scan QR codes when you want to link a device you trust.'**
  String get keepYourAccountSafeOnlyScanQRCodesWhenYouWantToLinkADeviceYouTrust;

  /// No description provided for @label.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get label;

  /// No description provided for @lat.
  ///
  /// In en, this message translates to:
  /// **'Lat'**
  String get lat;

  /// No description provided for @letOthersPointTheirPhoneCameraToThisQRCodeToInstantlyViewYourNetworkingProfile.
  ///
  /// In en, this message translates to:
  /// **'Let others point their phone camera to this QR code to instantly view your networking profile.'**
  String
  get letOthersPointTheirPhoneCameraToThisQRCodeToInstantlyViewYourNetworkingProfile;

  /// No description provided for @link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// No description provided for @linkADevice.
  ///
  /// In en, this message translates to:
  /// **'Link a device'**
  String get linkADevice;

  /// No description provided for @linkByQROnAnotherPhone.
  ///
  /// In en, this message translates to:
  /// **'Link by QR on another phone'**
  String get linkByQROnAnotherPhone;

  /// No description provided for @linkCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get linkCopiedToClipboard;

  /// No description provided for @linkSettings.
  ///
  /// In en, this message translates to:
  /// **'Link Settings'**
  String get linkSettings;

  /// No description provided for @linkSettings2.
  ///
  /// In en, this message translates to:
  /// **'Link settings'**
  String get linkSettings2;

  /// No description provided for @linkThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Link this device?'**
  String get linkThisDevice;

  /// No description provided for @links.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get links;

  /// No description provided for @linksOnThisCard.
  ///
  /// In en, this message translates to:
  /// **'Links on this card'**
  String get linksOnThisCard;

  /// No description provided for @locationNotSetYet.
  ///
  /// In en, this message translates to:
  /// **'Location not set yet'**
  String get locationNotSetYet;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission required'**
  String get locationPermissionRequired;

  /// No description provided for @locationPermissionRequiredForAttendance.
  ///
  /// In en, this message translates to:
  /// **'Location permission required for attendance'**
  String get locationPermissionRequiredForAttendance;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @logInToManageYourDigitalCardAndNetwork.
  ///
  /// In en, this message translates to:
  /// **'Log in to manage your digital card and network.'**
  String get logInToManageYourDigitalCardAndNetwork;

  /// No description provided for @logInWithQRCode.
  ///
  /// In en, this message translates to:
  /// **'Log in with QR code'**
  String get logInWithQRCode;

  /// No description provided for @logOut2.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut2;

  /// No description provided for @logOutAll.
  ///
  /// In en, this message translates to:
  /// **'Log out all'**
  String get logOutAll;

  /// No description provided for @logOutDevice.
  ///
  /// In en, this message translates to:
  /// **'Log out device?'**
  String get logOutDevice;

  /// No description provided for @loyaltyPrograms.
  ///
  /// In en, this message translates to:
  /// **'Loyalty Programs'**
  String get loyaltyPrograms;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage categories'**
  String get manageCategories;

  /// No description provided for @manageContact.
  ///
  /// In en, this message translates to:
  /// **'Manage contact'**
  String get manageContact;

  /// No description provided for @manageEmployees.
  ///
  /// In en, this message translates to:
  /// **'Manage Employees'**
  String get manageEmployees;

  /// No description provided for @manageYourPersonalDetailsOtherPreferences.
  ///
  /// In en, this message translates to:
  /// **'Manage your personal details & other preferences'**
  String get manageYourPersonalDetailsOtherPreferences;

  /// No description provided for @markCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark Completed'**
  String get markCompleted;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @myCards.
  ///
  /// In en, this message translates to:
  /// **'My Cards'**
  String get myCards;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My Location'**
  String get myLocation;

  /// No description provided for @myRewards.
  ///
  /// In en, this message translates to:
  /// **'My Rewards'**
  String get myRewards;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @name2.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get name2;

  /// No description provided for @nameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameIsRequired;

  /// No description provided for @nameCompanyCom.
  ///
  /// In en, this message translates to:
  /// **'name@company.com'**
  String get nameCompanyCom;

  /// No description provided for @newCard.
  ///
  /// In en, this message translates to:
  /// **'New Card'**
  String get newCard;

  /// No description provided for @newCard2.
  ///
  /// In en, this message translates to:
  /// **'New card'**
  String get newCard2;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get newCategory;

  /// No description provided for @newReward.
  ///
  /// In en, this message translates to:
  /// **'New Reward'**
  String get newReward;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @nextCard.
  ///
  /// In en, this message translates to:
  /// **'Next card'**
  String get nextCard;

  /// No description provided for @noActiveLinksConnectedYet.
  ///
  /// In en, this message translates to:
  /// **'No active links connected yet'**
  String get noActiveLinksConnectedYet;

  /// No description provided for @noActiveRewardProgramsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No active reward programs available.'**
  String get noActiveRewardProgramsAvailable;

  /// No description provided for @noEmployeeCardsYet.
  ///
  /// In en, this message translates to:
  /// **'No employee cards yet'**
  String get noEmployeeCardsYet;

  /// No description provided for @noEmployeesAdded.
  ///
  /// In en, this message translates to:
  /// **'No employees added'**
  String get noEmployeesAdded;

  /// No description provided for @noEmployeesYet.
  ///
  /// In en, this message translates to:
  /// **'No employees yet'**
  String get noEmployeesYet;

  /// No description provided for @noEmployerFound.
  ///
  /// In en, this message translates to:
  /// **'No employer found'**
  String get noEmployerFound;

  /// No description provided for @noItemsInThisCategory.
  ///
  /// In en, this message translates to:
  /// **'No items in this category.'**
  String get noItemsInThisCategory;

  /// No description provided for @noLinkTemplatesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No link templates available'**
  String get noLinkTemplatesAvailable;

  /// No description provided for @noNewNotificationsAtThisTime.
  ///
  /// In en, this message translates to:
  /// **'No new notifications at this time.'**
  String get noNewNotificationsAtThisTime;

  /// No description provided for @noOneHasViewedYourProfileYet.
  ///
  /// In en, this message translates to:
  /// **'No one has viewed your profile yet.'**
  String get noOneHasViewedYourProfileYet;

  /// No description provided for @noPendingInvitations.
  ///
  /// In en, this message translates to:
  /// **'No pending invitations'**
  String get noPendingInvitations;

  /// No description provided for @noProgramsAssignedYetAddProgramsBelow.
  ///
  /// In en, this message translates to:
  /// **'No programs assigned yet. Add programs below.'**
  String get noProgramsAssignedYetAddProgramsBelow;

  /// No description provided for @noQRCodeFoundInThisImage.
  ///
  /// In en, this message translates to:
  /// **'No QR code found in this image.'**
  String get noQRCodeFoundInThisImage;

  /// No description provided for @noRewardProgramsYet.
  ///
  /// In en, this message translates to:
  /// **'No reward programs yet'**
  String get noRewardProgramsYet;

  /// No description provided for @noSlotsAvailableOnThisDay.
  ///
  /// In en, this message translates to:
  /// **'No slots available on this day'**
  String get noSlotsAvailableOnThisDay;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @notAvailableOnYourCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'Not available on your current plan'**
  String get notAvailableOnYourCurrentPlan;

  /// No description provided for @notCheckedInYet.
  ///
  /// In en, this message translates to:
  /// **'Not checked in yet'**
  String get notCheckedInYet;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @notificationCleared.
  ///
  /// In en, this message translates to:
  /// **'Notification cleared'**
  String get notificationCleared;

  /// No description provided for @onlyCoverProfilePhotoNameAndBioAreEditableHere.
  ///
  /// In en, this message translates to:
  /// **'Only cover, profile photo, name and bio are editable here.'**
  String get onlyCoverProfilePhotoNameAndBioAreEditableHere;

  /// No description provided for @onlyEnabledLinksShowWhenSomeoneScansThisCard.
  ///
  /// In en, this message translates to:
  /// **'Only enabled links show when someone scans this card.'**
  String get onlyEnabledLinksShowWhenSomeoneScansThisCard;

  /// No description provided for @onlyPublicProfilesAreShown.
  ///
  /// In en, this message translates to:
  /// **'Only public profiles are shown'**
  String get onlyPublicProfilesAreShown;

  /// No description provided for @onlyThisPhoneIsUsingYourAccountRightNow.
  ///
  /// In en, this message translates to:
  /// **'Only this phone is using your account right now.'**
  String get onlyThisPhoneIsUsingYourAccountRightNow;

  /// No description provided for @orCONTINUEWITH.
  ///
  /// In en, this message translates to:
  /// **'OR CONTINUE WITH'**
  String get orCONTINUEWITH;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// No description provided for @orderID.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderID;

  /// No description provided for @orderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get orderNotFound;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @paperCard.
  ///
  /// In en, this message translates to:
  /// **'Paper Card'**
  String get paperCard;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @payMonthByMonth.
  ///
  /// In en, this message translates to:
  /// **'Pay month by month'**
  String get payMonthByMonth;

  /// No description provided for @pendingACCEPTANCE.
  ///
  /// In en, this message translates to:
  /// **'PENDING ACCEPTANCE'**
  String get pendingACCEPTANCE;

  /// No description provided for @performanceOverview.
  ///
  /// In en, this message translates to:
  /// **'Performance Overview'**
  String get performanceOverview;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get personalDetails;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @pickAReadyMadeColorThemeQuickAndClean.
  ///
  /// In en, this message translates to:
  /// **'Pick a ready-made color theme. Quick and clean.'**
  String get pickAReadyMadeColorThemeQuickAndClean;

  /// No description provided for @pickColor.
  ///
  /// In en, this message translates to:
  /// **'Pick Color'**
  String get pickColor;

  /// No description provided for @pickOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pick on Map'**
  String get pickOnMap;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrder;

  /// No description provided for @planExpired.
  ///
  /// In en, this message translates to:
  /// **'Plan Expired'**
  String get planExpired;

  /// No description provided for @pleaseEnterBusinessDetailsToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please enter business details to continue'**
  String get pleaseEnterBusinessDetailsToContinue;

  /// No description provided for @pleaseEnterItemName.
  ///
  /// In en, this message translates to:
  /// **'Please enter item name'**
  String get pleaseEnterItemName;

  /// No description provided for @pleaseProvideYourBusinessDetailsBeforeUpgrading.
  ///
  /// In en, this message translates to:
  /// **'Please provide your business details before upgrading.'**
  String get pleaseProvideYourBusinessDetailsBeforeUpgrading;

  /// No description provided for @pleaseSelectACategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectACategory;

  /// No description provided for @pleaseSelectATimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Please select a time slot'**
  String get pleaseSelectATimeSlot;

  /// No description provided for @pleaseSetWorkLocationFirst.
  ///
  /// In en, this message translates to:
  /// **'Please set work location first'**
  String get pleaseSetWorkLocationFirst;

  /// No description provided for @png.
  ///
  /// In en, this message translates to:
  /// **'PNG'**
  String get png;

  /// No description provided for @pointYourCameraAtTheQRCodeOnTheOtherDevice.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at the QR code on the other device'**
  String get pointYourCameraAtTheQRCodeOnTheOtherDevice;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @pointsEarned.
  ///
  /// In en, this message translates to:
  /// **'Points Earned'**
  String get pointsEarned;

  /// No description provided for @premiumActive.
  ///
  /// In en, this message translates to:
  /// **'Premium active'**
  String get premiumActive;

  /// No description provided for @previousCard.
  ///
  /// In en, this message translates to:
  /// **'Previous card'**
  String get previousCard;

  /// No description provided for @priceRs.
  ///
  /// In en, this message translates to:
  /// **'Price (Rs)'**
  String get priceRs;

  /// No description provided for @pro.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get pro;

  /// No description provided for @proTemplate.
  ///
  /// In en, this message translates to:
  /// **'PRO template'**
  String get proTemplate;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @profileCheck.
  ///
  /// In en, this message translates to:
  /// **'Profile Check'**
  String get profileCheck;

  /// No description provided for @profileStrength.
  ///
  /// In en, this message translates to:
  /// **'Profile Strength'**
  String get profileStrength;

  /// No description provided for @profileViewers.
  ///
  /// In en, this message translates to:
  /// **'Profile Viewers'**
  String get profileViewers;

  /// No description provided for @profileViews.
  ///
  /// In en, this message translates to:
  /// **'Profile Views'**
  String get profileViews;

  /// No description provided for @programDetails.
  ///
  /// In en, this message translates to:
  /// **'Program Details'**
  String get programDetails;

  /// No description provided for @programName.
  ///
  /// In en, this message translates to:
  /// **'Program Name'**
  String get programName;

  /// No description provided for @programNotFound.
  ///
  /// In en, this message translates to:
  /// **'Program not found'**
  String get programNotFound;

  /// No description provided for @programType.
  ///
  /// In en, this message translates to:
  /// **'Program Type'**
  String get programType;

  /// No description provided for @qrCode.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get qrCode;

  /// No description provided for @qrScans.
  ///
  /// In en, this message translates to:
  /// **'QR Scans'**
  String get qrScans;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @readAll.
  ///
  /// In en, this message translates to:
  /// **'Read All'**
  String get readAll;

  /// No description provided for @readOnly2.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get readOnly2;

  /// No description provided for @received1Stamp.
  ///
  /// In en, this message translates to:
  /// **'Received 1 Stamp'**
  String get received1Stamp;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @redeemAnotherReward.
  ///
  /// In en, this message translates to:
  /// **'Redeem Another Reward'**
  String get redeemAnotherReward;

  /// No description provided for @redeemReward.
  ///
  /// In en, this message translates to:
  /// **'Redeem Reward'**
  String get redeemReward;

  /// No description provided for @redeemedFreeCoffee.
  ///
  /// In en, this message translates to:
  /// **'Redeemed Free Coffee'**
  String get redeemedFreeCoffee;

  /// No description provided for @refreshQR.
  ///
  /// In en, this message translates to:
  /// **'Refresh QR'**
  String get refreshQR;

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// No description provided for @rembiro.
  ///
  /// In en, this message translates to:
  /// **'Rembiro'**
  String get rembiro;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removeEmployee.
  ///
  /// In en, this message translates to:
  /// **'Remove Employee'**
  String get removeEmployee;

  /// No description provided for @renewPlan.
  ///
  /// In en, this message translates to:
  /// **'Renew Plan'**
  String get renewPlan;

  /// No description provided for @requestPending.
  ///
  /// In en, this message translates to:
  /// **'Request pending'**
  String get requestPending;

  /// No description provided for @requestPending2.
  ///
  /// In en, this message translates to:
  /// **'Request Pending'**
  String get requestPending2;

  /// No description provided for @requestRejected.
  ///
  /// In en, this message translates to:
  /// **'Request rejected'**
  String get requestRejected;

  /// No description provided for @requestSubscription.
  ///
  /// In en, this message translates to:
  /// **'Request subscription'**
  String get requestSubscription;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @rewardCompletedShowThisCardToRedeem.
  ///
  /// In en, this message translates to:
  /// **'Reward Completed! Show this card to redeem.'**
  String get rewardCompletedShowThisCardToRedeem;

  /// No description provided for @rewardCompleted.
  ///
  /// In en, this message translates to:
  /// **'Reward Completed! 🎉'**
  String get rewardCompleted;

  /// No description provided for @rewardDetails.
  ///
  /// In en, this message translates to:
  /// **'Reward Details'**
  String get rewardDetails;

  /// No description provided for @rewardProgram.
  ///
  /// In en, this message translates to:
  /// **'Reward Program'**
  String get rewardProgram;

  /// No description provided for @rewardPrograms.
  ///
  /// In en, this message translates to:
  /// **'Reward Programs'**
  String get rewardPrograms;

  /// No description provided for @rewardRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Reward Redeemed!'**
  String get rewardRedeemed;

  /// No description provided for @rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewards;

  /// No description provided for @rewardsEarned.
  ///
  /// In en, this message translates to:
  /// **'Rewards Earned'**
  String get rewardsEarned;

  /// No description provided for @rs1600BilledMonthly.
  ///
  /// In en, this message translates to:
  /// **'Rs 1,600 billed monthly'**
  String get rs1600BilledMonthly;

  /// No description provided for @rs8300BilledYearly.
  ///
  /// In en, this message translates to:
  /// **'Rs 8,300 billed yearly'**
  String get rs8300BilledYearly;

  /// No description provided for @saimyousufYGmailCom.
  ///
  /// In en, this message translates to:
  /// **'saimyousuf.y@gmail.com'**
  String get saimyousufYGmailCom;

  /// No description provided for @save2.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get save2;

  /// No description provided for @saveYourWorkIDCardToPhoneOrWallet.
  ///
  /// In en, this message translates to:
  /// **'Save your work ID card to phone or wallet'**
  String get saveYourWorkIDCardToPhoneOrWallet;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @scanAUserQRCodeToAddThemAsEmployee.
  ///
  /// In en, this message translates to:
  /// **'Scan a user QR code to add them as employee'**
  String get scanAUserQRCodeToAddThemAsEmployee;

  /// No description provided for @scanAnyUserOrBusinessQRToAddEmployee.
  ///
  /// In en, this message translates to:
  /// **'Scan any user or business QR to add employee'**
  String get scanAnyUserOrBusinessQRToAddEmployee;

  /// No description provided for @scanBusinessQRToRedeem.
  ///
  /// In en, this message translates to:
  /// **'Scan Business QR to Redeem'**
  String get scanBusinessQRToRedeem;

  /// No description provided for @scanCustomerQRCode.
  ///
  /// In en, this message translates to:
  /// **'Scan Customer QR Code'**
  String get scanCustomerQRCode;

  /// No description provided for @scanEmployeeProfile.
  ///
  /// In en, this message translates to:
  /// **'Scan employee profile'**
  String get scanEmployeeProfile;

  /// No description provided for @scanQR.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQR;

  /// No description provided for @scanQRShowQR.
  ///
  /// In en, this message translates to:
  /// **'Scan QR / show QR'**
  String get scanQRShowQR;

  /// No description provided for @scanQRCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQRCode;

  /// No description provided for @scanQRShownOnTheOtherDevice.
  ///
  /// In en, this message translates to:
  /// **'Scan QR shown on the other device'**
  String get scanQRShownOnTheOtherDevice;

  /// No description provided for @scanToInvite.
  ///
  /// In en, this message translates to:
  /// **'Scan to Invite'**
  String get scanToInvite;

  /// No description provided for @searchByUsername.
  ///
  /// In en, this message translates to:
  /// **'Search by username...'**
  String get searchByUsername;

  /// No description provided for @searchLinks.
  ///
  /// In en, this message translates to:
  /// **'Search links'**
  String get searchLinks;

  /// No description provided for @searchNameEmailOrCompany.
  ///
  /// In en, this message translates to:
  /// **'Search name, email or company'**
  String get searchNameEmailOrCompany;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @seeAllActivityIsMockedNewActivitiesWillAppearAsLeadsAreAdded.
  ///
  /// In en, this message translates to:
  /// **'See all activity is mocked. New activities will appear as leads are added.'**
  String get seeAllActivityIsMockedNewActivitiesWillAppearAsLeadsAreAdded;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @selectMarkers.
  ///
  /// In en, this message translates to:
  /// **'Select Markers'**
  String get selectMarkers;

  /// No description provided for @selectRegion.
  ///
  /// In en, this message translates to:
  /// **'Select Region'**
  String get selectRegion;

  /// No description provided for @setTextUnderTheLinkIcon.
  ///
  /// In en, this message translates to:
  /// **'Set text under the link icon'**
  String get setTextUnderTheLinkIcon;

  /// No description provided for @setYourOwnColorsPhotosAndBackground.
  ///
  /// In en, this message translates to:
  /// **'Set your own colors, photos and background.'**
  String get setYourOwnColorsPhotosAndBackground;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareCard.
  ///
  /// In en, this message translates to:
  /// **'Share card'**
  String get shareCard;

  /// No description provided for @shareDifferentLinksOnEachCard.
  ///
  /// In en, this message translates to:
  /// **'Share different links on each card'**
  String get shareDifferentLinksOnEachCard;

  /// No description provided for @shareProfile.
  ///
  /// In en, this message translates to:
  /// **'Share Profile'**
  String get shareProfile;

  /// No description provided for @showLink.
  ///
  /// In en, this message translates to:
  /// **'Show link'**
  String get showLink;

  /// No description provided for @showOnThisCard.
  ///
  /// In en, this message translates to:
  /// **'Show on this card'**
  String get showOnThisCard;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @slotMin.
  ///
  /// In en, this message translates to:
  /// **'Slot (min)'**
  String get slotMin;

  /// No description provided for @softwareEngineer.
  ///
  /// In en, this message translates to:
  /// **'Software Engineer'**
  String get softwareEngineer;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @sortOptions.
  ///
  /// In en, this message translates to:
  /// **'Sort Options'**
  String get sortOptions;

  /// No description provided for @specialInstructions.
  ///
  /// In en, this message translates to:
  /// **'Special instructions'**
  String get specialInstructions;

  /// No description provided for @stampCard.
  ///
  /// In en, this message translates to:
  /// **'Stamp Card'**
  String get stampCard;

  /// No description provided for @stampIcon.
  ///
  /// In en, this message translates to:
  /// **'Stamp Icon'**
  String get stampIcon;

  /// No description provided for @stamps.
  ///
  /// In en, this message translates to:
  /// **'Stamps'**
  String get stamps;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get start;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @startHour.
  ///
  /// In en, this message translates to:
  /// **'Start hour'**
  String get startHour;

  /// No description provided for @startNetworkingSmarterWithBarqody.
  ///
  /// In en, this message translates to:
  /// **'Start networking smarter with Barqody.'**
  String get startNetworkingSmarterWithBarqody;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @subscriptionRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Subscription request submitted'**
  String get subscriptionRequestSubmitted;

  /// No description provided for @subscriptionRequestSubmitted2.
  ///
  /// In en, this message translates to:
  /// **'Subscription request submitted.'**
  String get subscriptionRequestSubmitted2;

  /// No description provided for @swipeToBrowseCards.
  ///
  /// In en, this message translates to:
  /// **'Swipe to browse cards'**
  String get swipeToBrowseCards;

  /// No description provided for @takeAQuickSelfieForAttendanceVerification.
  ///
  /// In en, this message translates to:
  /// **'Take a quick selfie for attendance verification'**
  String get takeAQuickSelfieForAttendanceVerification;

  /// No description provided for @tapSocialLinksAboveToAddAndActivateProfiles.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Social Links\" above to add and activate profiles.'**
  String get tapSocialLinksAboveToAddAndActivateProfiles;

  /// No description provided for @tapOnTheMapOrUseYourCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Tap on the map or use your current location'**
  String get tapOnTheMapOrUseYourCurrentLocation;

  /// No description provided for @tapToAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to add photo'**
  String get tapToAddPhoto;

  /// No description provided for @tapToShareQRCode.
  ///
  /// In en, this message translates to:
  /// **'Tap to share QR code'**
  String get tapToShareQRCode;

  /// No description provided for @tapni.
  ///
  /// In en, this message translates to:
  /// **'tapni'**
  String get tapni;

  /// No description provided for @teamAttendance.
  ///
  /// In en, this message translates to:
  /// **'Team Attendance'**
  String get teamAttendance;

  /// No description provided for @template.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get template;

  /// No description provided for @templates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get templates;

  /// No description provided for @thankYouFeedbackSubmissionsAreMockOnly.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Feedback submissions are mock only.'**
  String get thankYouFeedbackSubmissionsAreMockOnly;

  /// No description provided for @thisCardAndItsQRCodeWillBeRemoved.
  ///
  /// In en, this message translates to:
  /// **'This card and its QR code will be removed.'**
  String get thisCardAndItsQRCodeWillBeRemoved;

  /// No description provided for @thisFeatureIsExclusivelyAvailableToBusinessUsers.
  ///
  /// In en, this message translates to:
  /// **'This feature is exclusively available to Business users.'**
  String get thisFeatureIsExclusivelyAvailableToBusinessUsers;

  /// No description provided for @thisIsAlreadyYourUsername.
  ///
  /// In en, this message translates to:
  /// **'This is already your username.'**
  String get thisIsAlreadyYourUsername;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @thisWillPermanentlyDeleteThisRewardProgramAndAllItsEnrollments.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this reward program and all its enrollments.'**
  String get thisWillPermanentlyDeleteThisRewardProgramAndAllItsEnrollments;

  /// No description provided for @todayIsYourWeekend.
  ///
  /// In en, this message translates to:
  /// **'Today is your weekend'**
  String get todayIsYourWeekend;

  /// No description provided for @today315PM.
  ///
  /// In en, this message translates to:
  /// **'Today • 3:15 PM'**
  String get today315PM;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @trackYourOrders.
  ///
  /// In en, this message translates to:
  /// **'Track your orders'**
  String get trackYourOrders;

  /// No description provided for @transactionReferenceOptional.
  ///
  /// In en, this message translates to:
  /// **'Transaction reference (optional)'**
  String get transactionReferenceOptional;

  /// No description provided for @transactionReferenceNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Transaction reference number (optional)'**
  String get transactionReferenceNumberOptional;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @tryBusinessPro.
  ///
  /// In en, this message translates to:
  /// **'Try Business Pro'**
  String get tryBusinessPro;

  /// No description provided for @tryBusinessPro2.
  ///
  /// In en, this message translates to:
  /// **'Try Business Pro.'**
  String get tryBusinessPro2;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @typeAtLeast2CharactersOfAUsernameToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type at least 2 characters of a username to search.'**
  String get typeAtLeast2CharactersOfAUsernameToSearch;

  /// No description provided for @typeThe8CharacterCodeShownUnderTheQR.
  ///
  /// In en, this message translates to:
  /// **'Type the 8-character code shown under the QR.'**
  String get typeThe8CharacterCodeShownUnderTheQR;

  /// No description provided for @underDevelopmentLoginViaEmailPasswordInstead.
  ///
  /// In en, this message translates to:
  /// **'Under Development - Login via email/password instead.'**
  String get underDevelopmentLoginViaEmailPasswordInstead;

  /// No description provided for @unstampIcon.
  ///
  /// In en, this message translates to:
  /// **'Unstamp Icon'**
  String get unstampIcon;

  /// No description provided for @upgradeNow.
  ///
  /// In en, this message translates to:
  /// **'Upgrade now'**
  String get upgradeNow;

  /// No description provided for @upgradeTo.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to'**
  String get upgradeTo;

  /// No description provided for @upgradeToTapniPRO.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Tapni PRO'**
  String get upgradeToTapniPRO;

  /// No description provided for @useATemplate.
  ///
  /// In en, this message translates to:
  /// **'Use a template'**
  String get useATemplate;

  /// No description provided for @useBarqodyOnOtherPhonesOrTabletsYouStayInControlLogOutAnyDeviceAnytime.
  ///
  /// In en, this message translates to:
  /// **'Use Barqody on other phones or tablets. You stay in control — log out any device anytime.'**
  String
  get useBarqodyOnOtherPhonesOrTabletsYouStayInControlLogOutAnyDeviceAnytime;

  /// No description provided for @useBarqodyOnYourPhoneToScanThisCode.
  ///
  /// In en, this message translates to:
  /// **'Use Barqody on your phone to scan this code'**
  String get useBarqodyOnYourPhoneToScanThisCode;

  /// No description provided for @useDefaultIcon.
  ///
  /// In en, this message translates to:
  /// **'Use default icon'**
  String get useDefaultIcon;

  /// No description provided for @useThisPhoto.
  ///
  /// In en, this message translates to:
  /// **'Use This Photo'**
  String get useThisPhoto;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'USER'**
  String get user;

  /// No description provided for @version101.
  ///
  /// In en, this message translates to:
  /// **'Version: 1.0.1'**
  String get version101;

  /// No description provided for @viewAndUpdateOrdersFromYourCustomers.
  ///
  /// In en, this message translates to:
  /// **'View and update orders from your customers'**
  String get viewAndUpdateOrdersFromYourCustomers;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @views.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get views;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @welcomeToAccountCenter.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Account Center'**
  String get welcomeToAccountCenter;

  /// No description provided for @whenABusinessAddsYouAsEmployeeYourEmployeeCardWillAppearHereYouCanCustomizeItsDe.
  ///
  /// In en, this message translates to:
  /// **'When a business adds you as employee, your employee card will appear here. You can customize its design anytime.'**
  String
  get whenABusinessAddsYouAsEmployeeYourEmployeeCardWillAppearHereYouCanCustomizeItsDe;

  /// No description provided for @whenABusinessEnrollsYouInTheirRewardProgramItWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'When a business enrolls you in their reward program, it will appear here.'**
  String get whenABusinessEnrollsYouInTheirRewardProgramItWillAppearHere;

  /// No description provided for @whenABusinessInvitesYouToTheirTeamItWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'When a business invites you to their team, it will appear here.'**
  String get whenABusinessInvitesYouToTheirTeamItWillAppearHere;

  /// No description provided for @whenTurnedOffThisLinkWontBeShownOnYourProfile.
  ///
  /// In en, this message translates to:
  /// **'When turned off this link won\'t be shown on your profile'**
  String get whenTurnedOffThisLinkWontBeShownOnYourProfile;

  /// No description provided for @writeSomethingAboutYouOrYourBrand.
  ///
  /// In en, this message translates to:
  /// **'Write something about you or your brand'**
  String get writeSomethingAboutYouOrYourBrand;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @yesterday542PM.
  ///
  /// In en, this message translates to:
  /// **'Yesterday • 5:42 PM'**
  String get yesterday542PM;

  /// No description provided for @yourCategories.
  ///
  /// In en, this message translates to:
  /// **'Your categories'**
  String get yourCategories;

  /// No description provided for @yourEmployeeCardsFromEmployers.
  ///
  /// In en, this message translates to:
  /// **'Your employee cards from employers'**
  String get yourEmployeeCardsFromEmployers;

  /// No description provided for @yourFreeCoffeeHasBeenSuccessfullyRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Your Free Coffee has been successfully redeemed.'**
  String get yourFreeCoffeeHasBeenSuccessfullyRedeemed;

  /// No description provided for @yourRewards.
  ///
  /// In en, this message translates to:
  /// **'Your Rewards'**
  String get yourRewards;

  /// No description provided for @yourSubscriptionHasEndedTapTheInfoIconForDetails.
  ///
  /// In en, this message translates to:
  /// **'Your subscription has ended. Tap the info icon for details.'**
  String get yourSubscriptionHasEndedTapTheInfoIconForDetails;

  /// No description provided for @yourname.
  ///
  /// In en, this message translates to:
  /// **'yourname'**
  String get yourname;

  /// No description provided for @n10Discount.
  ///
  /// In en, this message translates to:
  /// **'10% Discount'**
  String get n10Discount;

  /// No description provided for @avatarTAPPED.
  ///
  /// In en, this message translates to:
  /// **'AVATAR TAPPED'**
  String get avatarTAPPED;

  /// No description provided for @accountHolderName.
  ///
  /// In en, this message translates to:
  /// **'Account holder name'**
  String get accountHolderName;

  /// No description provided for @accountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account number'**
  String get accountNumber;

  /// No description provided for @activeNow.
  ///
  /// In en, this message translates to:
  /// **'Active now'**
  String get activeNow;

  /// No description provided for @addBio.
  ///
  /// In en, this message translates to:
  /// **'Add Bio'**
  String get addBio;

  /// No description provided for @addCoverPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Cover Photo'**
  String get addCoverPhoto;

  /// No description provided for @addFacePhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Face Photo'**
  String get addFacePhoto;

  /// No description provided for @addIntroVoiceNote.
  ///
  /// In en, this message translates to:
  /// **'Add Intro Voice Note'**
  String get addIntroVoiceNote;

  /// No description provided for @addProfileName.
  ///
  /// In en, this message translates to:
  /// **'Add Profile Name'**
  String get addProfileName;

  /// No description provided for @addProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Profile Photo'**
  String get addProfilePhoto;

  /// No description provided for @addSocialLinks3.
  ///
  /// In en, this message translates to:
  /// **'Add Social Links (3+)'**
  String get addSocialLinks3;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @addLink2.
  ///
  /// In en, this message translates to:
  /// **'Add link'**
  String get addLink2;

  /// No description provided for @addLinksToYourProfileBelow2.
  ///
  /// In en, this message translates to:
  /// **'Add links to your profile below '**
  String get addLinksToYourProfileBelow2;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get addToCart;

  /// No description provided for @addressOptional.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get addressOptional;

  /// No description provided for @allContactTypes.
  ///
  /// In en, this message translates to:
  /// **'All contact types'**
  String get allContactTypes;

  /// No description provided for @allowedRadiusMeters.
  ///
  /// In en, this message translates to:
  /// **'Allowed radius (meters)'**
  String get allowedRadiusMeters;

  /// No description provided for @almostThere.
  ///
  /// In en, this message translates to:
  /// **'Almost there!'**
  String get almostThere;

  /// No description provided for @alreadyEmployee.
  ///
  /// In en, this message translates to:
  /// **'Already Employee'**
  String get alreadyEmployee;

  /// No description provided for @alreadyHaveAnAccount2.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAnAccount2;

  /// No description provided for @alwaysUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Always Up To Date'**
  String get alwaysUpToDate;

  /// No description provided for @areYouSureYouWantToLogOutOfBarqody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of Barqody?'**
  String get areYouSureYouWantToLogOutOfBarqody;

  /// No description provided for @attendanceFailed.
  ///
  /// In en, this message translates to:
  /// **'Attendance failed'**
  String get attendanceFailed;

  /// No description provided for @backgroundColor2.
  ///
  /// In en, this message translates to:
  /// **'Background Color'**
  String get backgroundColor2;

  /// No description provided for @bookingFailed.
  ///
  /// In en, this message translates to:
  /// **'Booking failed'**
  String get bookingFailed;

  /// No description provided for @brieflyDescribeThisReward.
  ///
  /// In en, this message translates to:
  /// **'Briefly describe this reward...'**
  String get brieflyDescribeThisReward;

  /// No description provided for @businessVerified.
  ///
  /// In en, this message translates to:
  /// **'Business Verified'**
  String get businessVerified;

  /// No description provided for @businessEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Business email address'**
  String get businessEmailAddress;

  /// No description provided for @businessFax.
  ///
  /// In en, this message translates to:
  /// **'Business fax'**
  String get businessFax;

  /// No description provided for @businessPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Business phone number'**
  String get businessPhoneNumber;

  /// No description provided for @businessWebsite.
  ///
  /// In en, this message translates to:
  /// **'Business website'**
  String get businessWebsite;

  /// No description provided for @cameraError.
  ///
  /// In en, this message translates to:
  /// **'Camera error'**
  String get cameraError;

  /// No description provided for @captureFace.
  ///
  /// In en, this message translates to:
  /// **'Capture Face'**
  String get captureFace;

  /// No description provided for @cardCompleted.
  ///
  /// In en, this message translates to:
  /// **'Card Completed'**
  String get cardCompleted;

  /// No description provided for @cardLabel.
  ///
  /// In en, this message translates to:
  /// **'Card Label'**
  String get cardLabel;

  /// No description provided for @cardLabelName.
  ///
  /// In en, this message translates to:
  /// **'Card Label Name'**
  String get cardLabelName;

  /// No description provided for @cardPreview.
  ///
  /// In en, this message translates to:
  /// **'Card Preview'**
  String get cardPreview;

  /// No description provided for @cardTheme.
  ///
  /// In en, this message translates to:
  /// **'Card Theme'**
  String get cardTheme;

  /// No description provided for @cardCreated.
  ///
  /// In en, this message translates to:
  /// **'Card created'**
  String get cardCreated;

  /// No description provided for @cardName.
  ///
  /// In en, this message translates to:
  /// **'Card name'**
  String get cardName;

  /// No description provided for @cardSavedAsJPG.
  ///
  /// In en, this message translates to:
  /// **'Card saved as JPG'**
  String get cardSavedAsJPG;

  /// No description provided for @cardSavedAsPNG.
  ///
  /// In en, this message translates to:
  /// **'Card saved as PNG'**
  String get cardSavedAsPNG;

  /// No description provided for @cardUpdated.
  ///
  /// In en, this message translates to:
  /// **'Card updated'**
  String get cardUpdated;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @checkInFace.
  ///
  /// In en, this message translates to:
  /// **'Check-in Face'**
  String get checkInFace;

  /// No description provided for @checkInSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Check-in successful'**
  String get checkInSuccessful;

  /// No description provided for @checkOutFace.
  ///
  /// In en, this message translates to:
  /// **'Check-out Face'**
  String get checkOutFace;

  /// No description provided for @checkOutSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Check-out successful'**
  String get checkOutSuccessful;

  /// No description provided for @chooseTemplate2.
  ///
  /// In en, this message translates to:
  /// **'Choose template'**
  String get chooseTemplate2;

  /// No description provided for @contactCardBusinessAddress.
  ///
  /// In en, this message translates to:
  /// **'Contact card business address'**
  String get contactCardBusinessAddress;

  /// No description provided for @contactCardCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Contact card company name'**
  String get contactCardCompanyName;

  /// No description provided for @contactCardEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact card email'**
  String get contactCardEmail;

  /// No description provided for @contactCardHomeAddress.
  ///
  /// In en, this message translates to:
  /// **'Contact card home address'**
  String get contactCardHomeAddress;

  /// No description provided for @contactCardPhone.
  ///
  /// In en, this message translates to:
  /// **'Contact card phone'**
  String get contactCardPhone;

  /// No description provided for @contactCardWebsite.
  ///
  /// In en, this message translates to:
  /// **'Contact card website'**
  String get contactCardWebsite;

  /// No description provided for @couldNotCompleteLogin.
  ///
  /// In en, this message translates to:
  /// **'Could not complete login'**
  String get couldNotCompleteLogin;

  /// No description provided for @couldNotCreateQRCode.
  ///
  /// In en, this message translates to:
  /// **'Could not create QR code'**
  String get couldNotCreateQRCode;

  /// No description provided for @couldNotLinkDevice.
  ///
  /// In en, this message translates to:
  /// **'Could not link device'**
  String get couldNotLinkDevice;

  /// No description provided for @couldNotLogOutDevice.
  ///
  /// In en, this message translates to:
  /// **'Could not log out device'**
  String get couldNotLogOutDevice;

  /// No description provided for @couldNotOpenGoogleWallet.
  ///
  /// In en, this message translates to:
  /// **'Could not open Google Wallet'**
  String get couldNotOpenGoogleWallet;

  /// No description provided for @couldNotSaveCardDesign.
  ///
  /// In en, this message translates to:
  /// **'Could not save card design'**
  String get couldNotSaveCardDesign;

  /// No description provided for @couldNotUpdateProfileVisibility.
  ///
  /// In en, this message translates to:
  /// **'Could not update profile visibility'**
  String get couldNotUpdateProfileVisibility;

  /// No description provided for @createGallery.
  ///
  /// In en, this message translates to:
  /// **'Create Gallery'**
  String get createGallery;

  /// No description provided for @createACardToShareYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Create a card to share your profile'**
  String get createACardToShareYourProfile;

  /// No description provided for @createCard.
  ///
  /// In en, this message translates to:
  /// **'Create card'**
  String get createCard;

  /// No description provided for @customBank.
  ///
  /// In en, this message translates to:
  /// **'Custom bank'**
  String get customBank;

  /// No description provided for @customersCanBeEnrolledAndStamped.
  ///
  /// In en, this message translates to:
  /// **'Customers can be enrolled and stamped'**
  String get customersCanBeEnrolledAndStamped;

  /// No description provided for @customizeCard.
  ///
  /// In en, this message translates to:
  /// **'Customize card'**
  String get customizeCard;

  /// No description provided for @describeYourLoyaltyProgram.
  ///
  /// In en, this message translates to:
  /// **'Describe your loyalty program'**
  String get describeYourLoyaltyProgram;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @dontHaveAnAccount2.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAnAccount2;

  /// No description provided for @eeeDMMMYyyy.
  ///
  /// In en, this message translates to:
  /// **'EEE, d MMM yyyy'**
  String get eeeDMMMYyyy;

  /// No description provided for @editReward.
  ///
  /// In en, this message translates to:
  /// **'Edit Reward'**
  String get editReward;

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get editItem;

  /// No description provided for @emailAddress2.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress2;

  /// No description provided for @emailIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailIsRequired;

  /// No description provided for @employeeCards.
  ///
  /// In en, this message translates to:
  /// **'Employee Cards'**
  String get employeeCards;

  /// No description provided for @employeeRemoved.
  ///
  /// In en, this message translates to:
  /// **'Employee removed'**
  String get employeeRemoved;

  /// No description provided for @employeeSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Employee settings saved'**
  String get employeeSettingsSaved;

  /// No description provided for @enrolledBusinesses.
  ///
  /// In en, this message translates to:
  /// **'Enrolled Businesses'**
  String get enrolledBusinesses;

  /// No description provided for @enterAValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterAValidEmail;

  /// No description provided for @enterBioForTheContactCard.
  ///
  /// In en, this message translates to:
  /// **'Enter bio for the contact card'**
  String get enterBioForTheContactCard;

  /// No description provided for @enterProgramName.
  ///
  /// In en, this message translates to:
  /// **'Enter program name'**
  String get enterProgramName;

  /// No description provided for @enterYourBio.
  ///
  /// In en, this message translates to:
  /// **'Enter your bio'**
  String get enterYourBio;

  /// No description provided for @enterYourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterYourPhoneNumber;

  /// No description provided for @enterYourWebsiteURL.
  ///
  /// In en, this message translates to:
  /// **'Enter your website URL'**
  String get enterYourWebsiteURL;

  /// No description provided for @eventBadge2.
  ///
  /// In en, this message translates to:
  /// **'Event badge'**
  String get eventBadge2;

  /// No description provided for @example10StampsFreeCoffee.
  ///
  /// In en, this message translates to:
  /// **'Example: 10 Stamps = Free Coffee'**
  String get example10StampsFreeCoffee;

  /// No description provided for @facePhotoAdded.
  ///
  /// In en, this message translates to:
  /// **'Face Photo Added'**
  String get facePhotoAdded;

  /// No description provided for @failedToAddProgram.
  ///
  /// In en, this message translates to:
  /// **'Failed to add program'**
  String get failedToAddProgram;

  /// No description provided for @failedToAddStamp.
  ///
  /// In en, this message translates to:
  /// **'Failed to add stamp'**
  String get failedToAddStamp;

  /// No description provided for @failedToEnrollCustomer.
  ///
  /// In en, this message translates to:
  /// **'Failed to enroll customer'**
  String get failedToEnrollCustomer;

  /// No description provided for @failedToExchangeContact.
  ///
  /// In en, this message translates to:
  /// **'Failed to exchange contact'**
  String get failedToExchangeContact;

  /// No description provided for @failedToLoadPrograms.
  ///
  /// In en, this message translates to:
  /// **'Failed to load programs'**
  String get failedToLoadPrograms;

  /// No description provided for @failedToPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to place order'**
  String get failedToPlaceOrder;

  /// No description provided for @failedToRemove.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove'**
  String get failedToRemove;

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save'**
  String get failedToSave;

  /// No description provided for @failedToSaveJPG.
  ///
  /// In en, this message translates to:
  /// **'Failed to save JPG'**
  String get failedToSaveJPG;

  /// No description provided for @failedToSavePNG.
  ///
  /// In en, this message translates to:
  /// **'Failed to save PNG'**
  String get failedToSavePNG;

  /// No description provided for @failedToSaveQRCode.
  ///
  /// In en, this message translates to:
  /// **'Failed to save QR Code.'**
  String get failedToSaveQRCode;

  /// No description provided for @failedToSaveBusinessDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to save business details'**
  String get failedToSaveBusinessDetails;

  /// No description provided for @failedToUpdateStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update status'**
  String get failedToUpdateStatus;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @foodBeverage.
  ///
  /// In en, this message translates to:
  /// **'Food & Beverage'**
  String get foodBeverage;

  /// No description provided for @freeDessert.
  ///
  /// In en, this message translates to:
  /// **'Free Dessert'**
  String get freeDessert;

  /// No description provided for @galleryPermissionRequiredPleaseEnableItInSettings.
  ///
  /// In en, this message translates to:
  /// **'Gallery permission required. Please enable it in Settings.'**
  String get galleryPermissionRequiredPleaseEnableItInSettings;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @go2.
  ///
  /// In en, this message translates to:
  /// **'Go '**
  String get go2;

  /// No description provided for @goToToolsLinkedDevices.
  ///
  /// In en, this message translates to:
  /// **'Go to Tools → Linked devices'**
  String get goToToolsLinkedDevices;

  /// No description provided for @googleWalletSetupPending.
  ///
  /// In en, this message translates to:
  /// **'Google Wallet setup pending.'**
  String get googleWalletSetupPending;

  /// No description provided for @googleWalletSetupPendingProfileLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Google Wallet setup pending. Profile link copied.'**
  String get googleWalletSetupPendingProfileLinkCopied;

  /// No description provided for @growYourBusiness.
  ///
  /// In en, this message translates to:
  /// **'Grow your business'**
  String get growYourBusiness;

  /// No description provided for @guestUser.
  ///
  /// In en, this message translates to:
  /// **'Guest User'**
  String get guestUser;

  /// No description provided for @ibanNumber.
  ///
  /// In en, this message translates to:
  /// **'IBAN number'**
  String get ibanNumber;

  /// No description provided for @inOFFICE.
  ///
  /// In en, this message translates to:
  /// **'IN OFFICE'**
  String get inOFFICE;

  /// No description provided for @invitationPending.
  ///
  /// In en, this message translates to:
  /// **'Invitation Pending'**
  String get invitationPending;

  /// No description provided for @invitationDeclined.
  ///
  /// In en, this message translates to:
  /// **'Invitation declined'**
  String get invitationDeclined;

  /// No description provided for @invitationSentEmployeeWillBeAddedAfterTheyAccept.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent. Employee will be added after they accept.'**
  String get invitationSentEmployeeWillBeAddedAfterTheyAccept;

  /// No description provided for @inviteEmployee.
  ///
  /// In en, this message translates to:
  /// **'Invite Employee'**
  String get inviteEmployee;

  /// No description provided for @inviteAsEmployee.
  ///
  /// In en, this message translates to:
  /// **'Invite as Employee'**
  String get inviteAsEmployee;

  /// No description provided for @jobTitle2.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get jobTitle2;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @logInWithQR.
  ///
  /// In en, this message translates to:
  /// **'Log in with QR'**
  String get logInWithQR;

  /// No description provided for @logOutOfThisAccountOnlyOtherAccountsWillStayOnThisPhone.
  ///
  /// In en, this message translates to:
  /// **'Log out of this account only? Other accounts will stay on this phone.'**
  String get logOutOfThisAccountOnlyOtherAccountsWillStayOnThisPhone;

  /// No description provided for @loggedInWithGoogleDemoAccountSaimY.
  ///
  /// In en, this message translates to:
  /// **'Logged in with Google (Demo account: Saim Y)'**
  String get loggedInWithGoogleDemoAccountSaimY;

  /// No description provided for @loggingYouIn.
  ///
  /// In en, this message translates to:
  /// **'Logging you in…'**
  String get loggingYouIn;

  /// No description provided for @loginFailedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Try again.'**
  String get loginFailedTryAgain;

  /// No description provided for @mmmDYyyyHMmA.
  ///
  /// In en, this message translates to:
  /// **'MMM d, yyyy - h:mm a'**
  String get mmmDYyyyHMmA;

  /// No description provided for @mmmmYyyy.
  ///
  /// In en, this message translates to:
  /// **'MMMM yyyy'**
  String get mmmmYyyy;

  /// No description provided for @markAttendance.
  ///
  /// In en, this message translates to:
  /// **'Mark Attendance'**
  String get markAttendance;

  /// No description provided for @myName.
  ///
  /// In en, this message translates to:
  /// **'My Name'**
  String get myName;

  /// No description provided for @myTapniProfile.
  ///
  /// In en, this message translates to:
  /// **'My Tapni Profile'**
  String get myTapniProfile;

  /// No description provided for @nameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get nameCannotBeEmpty;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New '**
  String get newLabel;

  /// No description provided for @noContactsYet.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet'**
  String get noContactsYet;

  /// No description provided for @noDetailsYet.
  ///
  /// In en, this message translates to:
  /// **'No details yet'**
  String get noDetailsYet;

  /// No description provided for @noLinksAddedYetNTapAddLinkToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'No links added yet.\\nTap \"Add link\" to get started.'**
  String get noLinksAddedYetNTapAddLinkToGetStarted;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noMatches;

  /// No description provided for @noReasonProvided.
  ///
  /// In en, this message translates to:
  /// **'No reason provided.'**
  String get noReasonProvided;

  /// No description provided for @notEnrolled.
  ///
  /// In en, this message translates to:
  /// **'Not Enrolled'**
  String get notEnrolled;

  /// No description provided for @numberOfStamps.
  ///
  /// In en, this message translates to:
  /// **'Number of Stamps'**
  String get numberOfStamps;

  /// No description provided for @oneTapToShare.
  ///
  /// In en, this message translates to:
  /// **'One Tap To Share'**
  String get oneTapToShare;

  /// No description provided for @openBarqodyOnYourOtherPhone.
  ///
  /// In en, this message translates to:
  /// **'Open Barqody on your other phone'**
  String get openBarqodyOnYourOtherPhone;

  /// No description provided for @openCamera.
  ///
  /// In en, this message translates to:
  /// **'Open Camera'**
  String get openCamera;

  /// No description provided for @orderInfo.
  ///
  /// In en, this message translates to:
  /// **'Order Info'**
  String get orderInfo;

  /// No description provided for @paperCard2.
  ///
  /// In en, this message translates to:
  /// **'Paper card'**
  String get paperCard2;

  /// No description provided for @passwordMustBeAtLeast4Characters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 4 characters'**
  String get passwordMustBeAtLeast4Characters;

  /// No description provided for @passwordMustBeAtLeast6Characters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMustBeAtLeast6Characters;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @phoneIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone is required'**
  String get phoneIsRequired;

  /// No description provided for @phoneNumber2.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber2;

  /// No description provided for @pickLocation.
  ///
  /// In en, this message translates to:
  /// **'Pick Location'**
  String get pickLocation;

  /// No description provided for @pleaseEnterAPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get pleaseEnterAPassword;

  /// No description provided for @pleaseEnterAUsername.
  ///
  /// In en, this message translates to:
  /// **'Please enter a username'**
  String get pleaseEnterAUsername;

  /// No description provided for @pleaseEnterAValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterAValidEmailAddress;

  /// No description provided for @pleaseEnterAValidNumberOfStamps.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number of stamps'**
  String get pleaseEnterAValidNumberOfStamps;

  /// No description provided for @pleaseEnterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterYourEmail;

  /// No description provided for @pleaseEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterYourName;

  /// No description provided for @pleaseEnterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterYourPassword;

  /// No description provided for @pointTheCameraAtAQRCodeToScanAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at a QR code to scan automatically.'**
  String get pointTheCameraAtAQRCodeToScanAutomatically;

  /// No description provided for @pointTheCameraAtAnEventBadgeAndTapTheCameraButton.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at an event badge and tap the Camera button.'**
  String get pointTheCameraAtAnEventBadgeAndTapTheCameraButton;

  /// No description provided for @pointTheCameraAtPaperCardAndTapTheCameraButton.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at paper card and tap the Camera button.'**
  String get pointTheCameraAtPaperCardAndTapTheCameraButton;

  /// No description provided for @preparingQRCode.
  ///
  /// In en, this message translates to:
  /// **'Preparing QR code…'**
  String get preparingQRCode;

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found.'**
  String get profileNotFound;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @qrCodeSavedToGallery.
  ///
  /// In en, this message translates to:
  /// **'QR Code saved to gallery!'**
  String get qrCodeSavedToGallery;

  /// No description provided for @qrCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'QR code expired'**
  String get qrCodeExpired;

  /// No description provided for @qrCodeExpiredTapRefresh.
  ///
  /// In en, this message translates to:
  /// **'QR code expired. Tap refresh.'**
  String get qrCodeExpiredTapRefresh;

  /// No description provided for @realEstate.
  ///
  /// In en, this message translates to:
  /// **'Real Estate'**
  String get realEstate;

  /// No description provided for @receiptAttached.
  ///
  /// In en, this message translates to:
  /// **'Receipt attached'**
  String get receiptAttached;

  /// No description provided for @renewYourSubscriptionToRestoreFullAccessToYourPremiumFeaturesAndData.
  ///
  /// In en, this message translates to:
  /// **'Renew your subscription to restore full access to your premium features and data.'**
  String
  get renewYourSubscriptionToRestoreFullAccessToYourPremiumFeaturesAndData;

  /// No description provided for @retakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake Photo'**
  String get retakePhoto;

  /// No description provided for @rewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Reward Title'**
  String get rewardTitle;

  /// No description provided for @rewardUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Reward Unlocked 🎉'**
  String get rewardUnlocked;

  /// No description provided for @roleOrCompany.
  ///
  /// In en, this message translates to:
  /// **'Role or company'**
  String get roleOrCompany;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @saveContact.
  ///
  /// In en, this message translates to:
  /// **'Save Contact'**
  String get saveContact;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettings;

  /// No description provided for @saveUsername.
  ///
  /// In en, this message translates to:
  /// **'Save Username'**
  String get saveUsername;

  /// No description provided for @saveCard.
  ///
  /// In en, this message translates to:
  /// **'Save card'**
  String get saveCard;

  /// No description provided for @saveContact2.
  ///
  /// In en, this message translates to:
  /// **'Save contact'**
  String get saveContact2;

  /// No description provided for @savedLocallySyncMayHaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Saved locally. Sync may have failed.'**
  String get savedLocallySyncMayHaveFailed;

  /// No description provided for @scanAQRCodeOrAddSomeoneYouMetToBuildYourNetwork.
  ///
  /// In en, this message translates to:
  /// **'Scan a QR code or add someone you met to build your network.'**
  String get scanAQRCodeOrAddSomeoneYouMetToBuildYourNetwork;

  /// No description provided for @scannedViaQR.
  ///
  /// In en, this message translates to:
  /// **'Scanned via QR'**
  String get scannedViaQR;

  /// No description provided for @screenTheme.
  ///
  /// In en, this message translates to:
  /// **'Screen Theme'**
  String get screenTheme;

  /// No description provided for @searchFailedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Search failed. Try again.'**
  String get searchFailedTryAgain;

  /// No description provided for @selectCompany.
  ///
  /// In en, this message translates to:
  /// **'Select Company'**
  String get selectCompany;

  /// No description provided for @selectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get selectDateRange;

  /// No description provided for @selectEndDate.
  ///
  /// In en, this message translates to:
  /// **'Select End Date'**
  String get selectEndDate;

  /// No description provided for @selectStartDate.
  ///
  /// In en, this message translates to:
  /// **'Select Start Date'**
  String get selectStartDate;

  /// No description provided for @sendInvitation.
  ///
  /// In en, this message translates to:
  /// **'Send Invitation'**
  String get sendInvitation;

  /// No description provided for @sendInvitationForAttendance.
  ///
  /// In en, this message translates to:
  /// **'Send invitation for attendance'**
  String get sendInvitationForAttendance;

  /// No description provided for @shareLink.
  ///
  /// In en, this message translates to:
  /// **'Share Link'**
  String get shareLink;

  /// No description provided for @shiftTiming.
  ///
  /// In en, this message translates to:
  /// **'Shift Timing'**
  String get shiftTiming;

  /// No description provided for @smartContactCapture.
  ///
  /// In en, this message translates to:
  /// **'Smart Contact Capture'**
  String get smartContactCapture;

  /// No description provided for @stampBorderColor.
  ///
  /// In en, this message translates to:
  /// **'Stamp Border Color'**
  String get stampBorderColor;

  /// No description provided for @stampColor.
  ///
  /// In en, this message translates to:
  /// **'Stamp Color'**
  String get stampColor;

  /// No description provided for @stampIconsOptional.
  ///
  /// In en, this message translates to:
  /// **'Stamp Icons (Optional)'**
  String get stampIconsOptional;

  /// No description provided for @stampsGiven.
  ///
  /// In en, this message translates to:
  /// **'Stamps Given'**
  String get stampsGiven;

  /// No description provided for @startBuildingYourNetwork.
  ///
  /// In en, this message translates to:
  /// **'Start building your network'**
  String get startBuildingYourNetwork;

  /// No description provided for @streetName.
  ///
  /// In en, this message translates to:
  /// **'Street name'**
  String get streetName;

  /// No description provided for @switchToABusinessAccountToUnlockFullAccess.
  ///
  /// In en, this message translates to:
  /// **'Switch to a Business account to unlock full access.'**
  String get switchToABusinessAccountToUnlockFullAccess;

  /// No description provided for @tapLinkADeviceAndScanThisQR.
  ///
  /// In en, this message translates to:
  /// **'Tap Link a device and scan this QR'**
  String get tapLinkADeviceAndScanThisQR;

  /// No description provided for @tapToAddImage.
  ///
  /// In en, this message translates to:
  /// **'Tap to add image'**
  String get tapToAddImage;

  /// No description provided for @tapToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap to change'**
  String get tapToChange;

  /// No description provided for @templateAppliedLocallySyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Template applied locally. Sync failed.'**
  String get templateAppliedLocallySyncFailed;

  /// No description provided for @textColor.
  ///
  /// In en, this message translates to:
  /// **'Text Color'**
  String get textColor;

  /// No description provided for @thisAccount.
  ///
  /// In en, this message translates to:
  /// **'This account'**
  String get thisAccount;

  /// No description provided for @thisFeatureIsExclusivelyAvailableToBusinessUsers2.
  ///
  /// In en, this message translates to:
  /// **'This feature is exclusively available to Business users. '**
  String get thisFeatureIsExclusivelyAvailableToBusinessUsers2;

  /// No description provided for @thisPersonIsOnYourTeam.
  ///
  /// In en, this message translates to:
  /// **'This person is on your team'**
  String get thisPersonIsOnYourTeam;

  /// No description provided for @thisProgramIsPaused.
  ///
  /// In en, this message translates to:
  /// **'This program is paused'**
  String get thisProgramIsPaused;

  /// No description provided for @totalStamps.
  ///
  /// In en, this message translates to:
  /// **'Total Stamps'**
  String get totalStamps;

  /// No description provided for @tryADifferentNameEmailOrCompany.
  ///
  /// In en, this message translates to:
  /// **'Try a different name, email, or company.'**
  String get tryADifferentNameEmailOrCompany;

  /// No description provided for @unableToSaveProfileTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Unable to save profile. Try again.'**
  String get unableToSaveProfileTryAgain;

  /// No description provided for @unableToUpdateUsernameTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Unable to update username. Try again.'**
  String get unableToUpdateUsernameTryAgain;

  /// No description provided for @underDevelopmentLoginViaEmailPasswordInstead2.
  ///
  /// In en, this message translates to:
  /// **'Under Development - Login via email/password instead. '**
  String get underDevelopmentLoginViaEmailPasswordInstead2;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUser;

  /// No description provided for @updateGPSLocation.
  ///
  /// In en, this message translates to:
  /// **'Update GPS Location'**
  String get updateGPSLocation;

  /// No description provided for @updateStatus.
  ///
  /// In en, this message translates to:
  /// **'Update Status'**
  String get updateStatus;

  /// No description provided for @updateCart.
  ///
  /// In en, this message translates to:
  /// **'Update cart'**
  String get updateCart;

  /// No description provided for @updateItem.
  ///
  /// In en, this message translates to:
  /// **'Update item'**
  String get updateItem;

  /// No description provided for @upgradeTo2.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to '**
  String get upgradeTo2;

  /// No description provided for @upgradeToBusinessPRO.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Business PRO'**
  String get upgradeToBusinessPRO;

  /// No description provided for @uploadReceiptOptional.
  ///
  /// In en, this message translates to:
  /// **'Upload receipt (optional)'**
  String get uploadReceiptOptional;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use My Location'**
  String get useMyLocation;

  /// No description provided for @useLettersNumbersUnderscoresOrHyphensOnly.
  ///
  /// In en, this message translates to:
  /// **'Use letters, numbers, underscores or hyphens only'**
  String get useLettersNumbersUnderscoresOrHyphensOnly;

  /// No description provided for @usernameMustBeAtLeast3Characters.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get usernameMustBeAtLeast3Characters;

  /// No description provided for @usernameMustBeAtMost30Characters.
  ///
  /// In en, this message translates to:
  /// **'Username must be at most 30 characters'**
  String get usernameMustBeAtMost30Characters;

  /// No description provided for @usernameUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Username updated successfully!'**
  String get usernameUpdatedSuccessfully;

  /// No description provided for @waitingForThemToAccept.
  ///
  /// In en, this message translates to:
  /// **'Waiting for them to accept'**
  String get waitingForThemToAccept;

  /// No description provided for @websiteURL.
  ///
  /// In en, this message translates to:
  /// **'Website URL'**
  String get websiteURL;

  /// No description provided for @weekendDays.
  ///
  /// In en, this message translates to:
  /// **'Weekend Days'**
  String get weekendDays;

  /// No description provided for @workLocation.
  ///
  /// In en, this message translates to:
  /// **'Work Location'**
  String get workLocation;

  /// No description provided for @yourPROSubscriptionHasExpiredNN.
  ///
  /// In en, this message translates to:
  /// **'Your PRO subscription has expired.\\n\\n'**
  String get yourPROSubscriptionHasExpiredNN;

  /// No description provided for @yourPROSubscriptionHasExpired.
  ///
  /// In en, this message translates to:
  /// **'Your PRO subscription has expired.'**
  String get yourPROSubscriptionHasExpired;

  /// No description provided for @premiumFeaturesAreCurrentlyDisabled.
  ///
  /// In en, this message translates to:
  /// **'Premium features are currently disabled.'**
  String get premiumFeaturesAreCurrentlyDisabled;

  /// No description provided for @proLinksAreHiddenFromYourPublicProfile.
  ///
  /// In en, this message translates to:
  /// **'Pro links are hidden from your public profile.'**
  String get proLinksAreHiddenFromYourPublicProfile;

  /// No description provided for @yourBusinessDetailsAndDataAreSafe.
  ///
  /// In en, this message translates to:
  /// **'Your business details and data are safe.'**
  String get yourBusinessDetailsAndDataAreSafe;

  /// No description provided for @addCatalogItem.
  ///
  /// In en, this message translates to:
  /// **'Add {label} item'**
  String addCatalogItem(String label);

  /// No description provided for @addAtLeastOneCatalogItem.
  ///
  /// In en, this message translates to:
  /// **'Add at least one {label} item'**
  String addAtLeastOneCatalogItem(String label);

  /// No description provided for @noCatalogItemsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No {label} items available.'**
  String noCatalogItemsAvailable(String label);

  /// No description provided for @noItemsYetAddFirstCatalogItem.
  ///
  /// In en, this message translates to:
  /// **'No items yet. Add your first {label} item.'**
  String noItemsYetAddFirstCatalogItem(String label);

  /// No description provided for @noPublicProfileMatchesQuery.
  ///
  /// In en, this message translates to:
  /// **'No public profile matches \"@{query}\".'**
  String noPublicProfileMatchesQuery(String query);

  /// No description provided for @codeWithValue.
  ///
  /// In en, this message translates to:
  /// **'Code: {code}'**
  String codeWithValue(String code);

  /// No description provided for @eInvoice.
  ///
  /// In en, this message translates to:
  /// **'E-Invoice'**
  String get eInvoice;

  /// No description provided for @eInvoiceDetails.
  ///
  /// In en, this message translates to:
  /// **'E-Invoice Details'**
  String get eInvoiceDetails;

  /// No description provided for @saudiEInvoice.
  ///
  /// In en, this message translates to:
  /// **'Saudi E-Invoice'**
  String get saudiEInvoice;

  /// No description provided for @pointTheCameraAtAnyQRCodeWebsiteWifiOrProduct.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at any QR code — website, Wi‑Fi, product, or BarQody card.'**
  String get pointTheCameraAtAnyQRCodeWebsiteWifiOrProduct;

  /// No description provided for @pointTheCameraAtASaudiEInvoiceQRCode.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at a Saudi ZATCA e-invoice QR code.'**
  String get pointTheCameraAtASaudiEInvoiceQRCode;

  /// No description provided for @invalidEInvoiceQRScanAValidZATCAInvoiceQR.
  ///
  /// In en, this message translates to:
  /// **'Invalid e-invoice QR. Scan a valid ZATCA Saudi invoice QR code.'**
  String get invalidEInvoiceQRScanAValidZATCAInvoiceQR;

  /// No description provided for @scannedQr.
  ///
  /// In en, this message translates to:
  /// **'Scanned QR'**
  String get scannedQr;

  /// No description provided for @qrScanResultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Content detected from the QR code'**
  String get qrScanResultSubtitle;

  /// No description provided for @scannedContent.
  ///
  /// In en, this message translates to:
  /// **'Scanned content'**
  String get scannedContent;

  /// No description provided for @qrTypeWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website / Link'**
  String get qrTypeWebsite;

  /// No description provided for @qrTypeWifi.
  ///
  /// In en, this message translates to:
  /// **'Wi‑Fi'**
  String get qrTypeWifi;

  /// No description provided for @qrTypeEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get qrTypeEmail;

  /// No description provided for @qrTypePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get qrTypePhone;

  /// No description provided for @qrTypeSms.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get qrTypeSms;

  /// No description provided for @qrTypeText.
  ///
  /// In en, this message translates to:
  /// **'Text / Product'**
  String get qrTypeText;

  /// No description provided for @wifiNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network name (SSID)'**
  String get wifiNetwork;

  /// No description provided for @wifiPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get wifiPassword;

  /// No description provided for @wifiSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get wifiSecurity;

  /// No description provided for @openLink.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get openLink;

  /// No description provided for @openEmail.
  ///
  /// In en, this message translates to:
  /// **'Open email'**
  String get openEmail;

  /// No description provided for @callNumber.
  ///
  /// In en, this message translates to:
  /// **'Call number'**
  String get callNumber;

  /// No description provided for @sendSms.
  ///
  /// In en, this message translates to:
  /// **'Send SMS'**
  String get sendSms;

  /// No description provided for @copyContent.
  ///
  /// In en, this message translates to:
  /// **'Copy content'**
  String get copyContent;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open this link.'**
  String get couldNotOpenLink;

  /// No description provided for @sellerName.
  ///
  /// In en, this message translates to:
  /// **'Seller name'**
  String get sellerName;

  /// No description provided for @vatRegistrationNumber.
  ///
  /// In en, this message translates to:
  /// **'VAT registration number'**
  String get vatRegistrationNumber;

  /// No description provided for @invoiceDateTime.
  ///
  /// In en, this message translates to:
  /// **'Invoice date & time'**
  String get invoiceDateTime;

  /// No description provided for @invoiceTotal.
  ///
  /// In en, this message translates to:
  /// **'Invoice total'**
  String get invoiceTotal;

  /// No description provided for @vatAmount.
  ///
  /// In en, this message translates to:
  /// **'VAT amount'**
  String get vatAmount;

  /// No description provided for @invoiceHash.
  ///
  /// In en, this message translates to:
  /// **'Invoice hash'**
  String get invoiceHash;

  /// No description provided for @copyAllDetails.
  ///
  /// In en, this message translates to:
  /// **'Copy all details'**
  String get copyAllDetails;

  /// No description provided for @zatcaPhase1Invoice.
  ///
  /// In en, this message translates to:
  /// **'ZATCA Phase 1 invoice'**
  String get zatcaPhase1Invoice;

  /// No description provided for @zatcaPhase2Supported.
  ///
  /// In en, this message translates to:
  /// **'ZATCA Phase 2 supported'**
  String get zatcaPhase2Supported;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'af',
    'ar',
    'az',
    'be',
    'bg',
    'bn',
    'ca',
    'cs',
    'da',
    'de',
    'el',
    'en',
    'es',
    'et',
    'fa',
    'fi',
    'fil',
    'fr',
    'ga',
    'gu',
    'ha',
    'he',
    'hi',
    'hr',
    'hu',
    'id',
    'it',
    'ja',
    'ka',
    'kk',
    'kn',
    'ko',
    'ky',
    'lo',
    'lt',
    'lv',
    'mk',
    'ml',
    'mr',
    'ms',
    'nb',
    'nl',
    'pa',
    'pl',
    'ps',
    'pt',
    'ro',
    'ru',
    'rw',
    'si',
    'sk',
    'sl',
    'sq',
    'sr',
    'sv',
    'sw',
    'ta',
    'te',
    'th',
    'tr',
    'uk',
    'ur',
    'uz',
    'vi',
    'zh',
    'zu',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'be':
      {
        switch (locale.countryCode) {
          case 'BY':
            return AppLocalizationsBeBy();
        }
        break;
      }
    case 'ky':
      {
        switch (locale.countryCode) {
          case 'KG':
            return AppLocalizationsKyKg();
        }
        break;
      }
    case 'ps':
      {
        switch (locale.countryCode) {
          case 'AF':
            return AppLocalizationsPsAf();
        }
        break;
      }
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
          case 'PT':
            return AppLocalizationsPtPt();
        }
        break;
      }
    case 'rw':
      {
        switch (locale.countryCode) {
          case 'RW':
            return AppLocalizationsRwRw();
        }
        break;
      }
    case 'si':
      {
        switch (locale.countryCode) {
          case 'LK':
            return AppLocalizationsSiLk();
        }
        break;
      }
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'CN':
            return AppLocalizationsZhCn();
          case 'HK':
            return AppLocalizationsZhHk();
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'af':
      return AppLocalizationsAf();
    case 'ar':
      return AppLocalizationsAr();
    case 'az':
      return AppLocalizationsAz();
    case 'be':
      return AppLocalizationsBe();
    case 'bg':
      return AppLocalizationsBg();
    case 'bn':
      return AppLocalizationsBn();
    case 'ca':
      return AppLocalizationsCa();
    case 'cs':
      return AppLocalizationsCs();
    case 'da':
      return AppLocalizationsDa();
    case 'de':
      return AppLocalizationsDe();
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'et':
      return AppLocalizationsEt();
    case 'fa':
      return AppLocalizationsFa();
    case 'fi':
      return AppLocalizationsFi();
    case 'fil':
      return AppLocalizationsFil();
    case 'fr':
      return AppLocalizationsFr();
    case 'ga':
      return AppLocalizationsGa();
    case 'gu':
      return AppLocalizationsGu();
    case 'ha':
      return AppLocalizationsHa();
    case 'he':
      return AppLocalizationsHe();
    case 'hi':
      return AppLocalizationsHi();
    case 'hr':
      return AppLocalizationsHr();
    case 'hu':
      return AppLocalizationsHu();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ka':
      return AppLocalizationsKa();
    case 'kk':
      return AppLocalizationsKk();
    case 'kn':
      return AppLocalizationsKn();
    case 'ko':
      return AppLocalizationsKo();
    case 'ky':
      return AppLocalizationsKy();
    case 'lo':
      return AppLocalizationsLo();
    case 'lt':
      return AppLocalizationsLt();
    case 'lv':
      return AppLocalizationsLv();
    case 'mk':
      return AppLocalizationsMk();
    case 'ml':
      return AppLocalizationsMl();
    case 'mr':
      return AppLocalizationsMr();
    case 'ms':
      return AppLocalizationsMs();
    case 'nb':
      return AppLocalizationsNb();
    case 'nl':
      return AppLocalizationsNl();
    case 'pa':
      return AppLocalizationsPa();
    case 'pl':
      return AppLocalizationsPl();
    case 'ps':
      return AppLocalizationsPs();
    case 'pt':
      return AppLocalizationsPt();
    case 'ro':
      return AppLocalizationsRo();
    case 'ru':
      return AppLocalizationsRu();
    case 'rw':
      return AppLocalizationsRw();
    case 'si':
      return AppLocalizationsSi();
    case 'sk':
      return AppLocalizationsSk();
    case 'sl':
      return AppLocalizationsSl();
    case 'sq':
      return AppLocalizationsSq();
    case 'sr':
      return AppLocalizationsSr();
    case 'sv':
      return AppLocalizationsSv();
    case 'sw':
      return AppLocalizationsSw();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'th':
      return AppLocalizationsTh();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'ur':
      return AppLocalizationsUr();
    case 'uz':
      return AppLocalizationsUz();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
    case 'zu':
      return AppLocalizationsZu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
