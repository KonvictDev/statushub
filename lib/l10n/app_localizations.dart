import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('en'),
    Locale('hi'),
    Locale('kn'),
    Locale('ml'),
    Locale('ta'),
    Locale('te'),
  ];

  /// No description provided for @noImageSelected.
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get noImageSelected;

  /// No description provided for @pickImage.
  ///
  /// In en, this message translates to:
  /// **'Pick Image'**
  String get pickImage;

  /// No description provided for @processSticker.
  ///
  /// In en, this message translates to:
  /// **'Process Sticker'**
  String get processSticker;

  /// No description provided for @textOptions.
  ///
  /// In en, this message translates to:
  /// **'Text Options'**
  String get textOptions;

  /// No description provided for @editText.
  ///
  /// In en, this message translates to:
  /// **'Edit Text'**
  String get editText;

  /// No description provided for @textColor.
  ///
  /// In en, this message translates to:
  /// **'Text Color'**
  String get textColor;

  /// No description provided for @textTheme.
  ///
  /// In en, this message translates to:
  /// **'Text Theme'**
  String get textTheme;

  /// No description provided for @removeTheme.
  ///
  /// In en, this message translates to:
  /// **'Remove Theme'**
  String get removeTheme;

  /// No description provided for @bgColor.
  ///
  /// In en, this message translates to:
  /// **'BG Color'**
  String get bgColor;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text Size:'**
  String get textSize;

  /// No description provided for @borderOptions.
  ///
  /// In en, this message translates to:
  /// **'Border Options'**
  String get borderOptions;

  /// No description provided for @borderColor.
  ///
  /// In en, this message translates to:
  /// **'Border Color'**
  String get borderColor;

  /// No description provided for @width.
  ///
  /// In en, this message translates to:
  /// **'Width:'**
  String get width;

  /// No description provided for @appShareDetails.
  ///
  /// In en, this message translates to:
  /// **'📱 Shared via MyAwesomeApp\n✨ Download now: https://play.google.com/store/apps/details?id=com.appsbyanandakumar.statushub'**
  String get appShareDetails;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @repost.
  ///
  /// In en, this message translates to:
  /// **'Repost'**
  String get repost;

  /// No description provided for @saveToGallery.
  ///
  /// In en, this message translates to:
  /// **'Save to Gallery'**
  String get saveToGallery;

  /// No description provided for @statusHub.
  ///
  /// In en, this message translates to:
  /// **'Status Hub'**
  String get statusHub;

  /// No description provided for @hotStatus.
  ///
  /// In en, this message translates to:
  /// **'Hot Status'**
  String get hotStatus;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @failedToLoadStatuses.
  ///
  /// In en, this message translates to:
  /// **'Failed to load statuses'**
  String get failedToLoadStatuses;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// No description provided for @videos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get videos;

  /// No description provided for @cropImage.
  ///
  /// In en, this message translates to:
  /// **'Crop Image'**
  String get cropImage;

  /// No description provided for @editImage.
  ///
  /// In en, this message translates to:
  /// **'Edit Image'**
  String get editImage;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @crop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get crop;

  /// No description provided for @removeBg.
  ///
  /// In en, this message translates to:
  /// **'Remove BG'**
  String get removeBg;

  /// No description provided for @backgroundRemoved.
  ///
  /// In en, this message translates to:
  /// **'Background removed successfully'**
  String get backgroundRemoved;

  /// No description provided for @errorRemovingBg.
  ///
  /// In en, this message translates to:
  /// **'Error removing background'**
  String get errorRemovingBg;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @cache.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get cache;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared ✅'**
  String get cacheCleared;

  /// No description provided for @usedSuffix.
  ///
  /// In en, this message translates to:
  /// **'MB used'**
  String get usedSuffix;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose light, dark, or system mode'**
  String get chooseTheme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @tamil.
  ///
  /// In en, this message translates to:
  /// **'தமிழ்'**
  String get tamil;

  /// No description provided for @malayalam.
  ///
  /// In en, this message translates to:
  /// **'മലയാളം'**
  String get malayalam;

  /// No description provided for @telugu.
  ///
  /// In en, this message translates to:
  /// **'തെലുങ്ക്'**
  String get telugu;

  /// No description provided for @kannada.
  ///
  /// In en, this message translates to:
  /// **'കന്നഡ'**
  String get kannada;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get hindi;

  /// No description provided for @rateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get rateUs;

  /// No description provided for @rateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Love the app? Leave a review!'**
  String get rateSubtitle;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @shareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell your friends about us'**
  String get shareSubtitle;

  /// No description provided for @shareMessage.
  ///
  /// In en, this message translates to:
  /// **'Check out this awesome app: https://play.google.com/store/apps/details?id=com.appsbyanandakumar.statushub'**
  String get shareMessage;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @failedToOpenWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Failed to open Whatsapp'**
  String get failedToOpenWhatsApp;

  /// No description provided for @feedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let us know your thoughts'**
  String get feedbackSubtitle;

  /// No description provided for @feedbackMessage.
  ///
  /// In en, this message translates to:
  /// **'Feedback: Please contact us at support@example.com'**
  String get feedbackMessage;

  /// No description provided for @statusDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp doesn’t officially allow saving statuses.This feature is unofficial — please use it responsibly.'**
  String get statusDisclaimer;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read how we handle your data'**
  String get privacySubtitle;

  /// No description provided for @privacyUrl.
  ///
  /// In en, this message translates to:
  /// **'View our privacy policy: https://example.com/privacy'**
  String get privacyUrl;

  /// No description provided for @appInfo.
  ///
  /// In en, this message translates to:
  /// **'App Info'**
  String get appInfo;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get version;

  /// No description provided for @featuresTitle.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get featuresTitle;

  /// No description provided for @featureDirectMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Direct Message'**
  String get featureDirectMessageTitle;

  /// No description provided for @featureDirectMessageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send messages without saving numbers.'**
  String get featureDirectMessageSubtitle;

  /// No description provided for @featureMessageEncryptTitle.
  ///
  /// In en, this message translates to:
  /// **'Secret Message'**
  String get featureMessageEncryptTitle;

  /// No description provided for @featureMessageEncryptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send messages with encryption.'**
  String get featureMessageEncryptSubtitle;

  /// No description provided for @featureRecoverMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Recover Messages'**
  String get featureRecoverMessageTitle;

  /// No description provided for @featureRecoverMessageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Retrieve recently deleted chats.'**
  String get featureRecoverMessageSubtitle;

  /// No description provided for @featureGamesTitle.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get featureGamesTitle;

  /// No description provided for @featureGamesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pass your time here'**
  String get featureGamesSubtitle;

  /// No description provided for @sortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get sortRecent;

  /// No description provided for @sortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get sortOldest;

  /// No description provided for @noStatusesFound.
  ///
  /// In en, this message translates to:
  /// **'No statuses found'**
  String get noStatusesFound;

  /// No description provided for @noStatusesHint.
  ///
  /// In en, this message translates to:
  /// **'Make sure you have viewed or saved statuses'**
  String get noStatusesHint;

  /// No description provided for @directMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Direct Message'**
  String get directMessageTitle;

  /// No description provided for @directMessageHeader.
  ///
  /// In en, this message translates to:
  /// **'Message Without Saving Contact'**
  String get directMessageHeader;

  /// No description provided for @directMessageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a phone number and an optional message to start a chat.'**
  String get directMessageSubtitle;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// No description provided for @phoneNumberError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 10-digit number'**
  String get phoneNumberError;

  /// No description provided for @optionalMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Optional Message'**
  String get optionalMessageLabel;

  /// No description provided for @sendMessageButton.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessageButton;

  /// No description provided for @sendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sendingLabel;

  /// No description provided for @errorLaunchWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Could not launch WhatsApp. Error:'**
  String get errorLaunchWhatsapp;

  /// No description provided for @enterMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter your message'**
  String get enterMessageLabel;

  /// No description provided for @encryptionModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Encryption Mode'**
  String get encryptionModeLabel;

  /// No description provided for @emojiMode.
  ///
  /// In en, this message translates to:
  /// **'Emoji Mode'**
  String get emojiMode;

  /// No description provided for @symbolMode.
  ///
  /// In en, this message translates to:
  /// **'Symbol Mode'**
  String get symbolMode;

  /// No description provided for @encryptButton.
  ///
  /// In en, this message translates to:
  /// **'Encrypt'**
  String get encryptButton;

  /// No description provided for @decryptButton.
  ///
  /// In en, this message translates to:
  /// **'Decrypt'**
  String get decryptButton;

  /// No description provided for @copyResultButton.
  ///
  /// In en, this message translates to:
  /// **'Copy Result'**
  String get copyResultButton;

  /// No description provided for @enterMessageError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a message'**
  String get enterMessageError;

  /// No description provided for @noResultToCopy.
  ///
  /// In en, this message translates to:
  /// **'There is no result to copy'**
  String get noResultToCopy;

  /// No description provided for @resultCopied.
  ///
  /// In en, this message translates to:
  /// **'Result copied to clipboard!'**
  String get resultCopied;

  /// No description provided for @resultPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Your result will appear here.'**
  String get resultPlaceholder;

  /// No description provided for @messageTitle.
  ///
  /// In en, this message translates to:
  /// **'Secret Message'**
  String get messageTitle;
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
    'en',
    'hi',
    'kn',
    'ml',
    'ta',
    'te',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
