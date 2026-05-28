class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'eKora';
  static const String appVersion = '1.0.0';

  // Collections (Firestore)
  static const String usersCollection = 'users';
  static const String tournamentsCollection = 'tournaments';
  static const String rankingsCollection = 'rankings';
  static const String paymentsCollection = 'payments';
  static const String notificationsCollection = 'notifications';
  static const String participantsSubcollection = 'participants';
  static const String matchmakingCollection = 'matchmaking_sessions';
  static const String teamsCollection = 'teams';
  static const String teamChallengesCollection = 'team_challenges';
  static const String venuesCollection = 'venues';
  static const String bookingsCollection = 'bookings';
  static const String venueSlotsCollection = 'venue_slots';
  static const String settingsCollection = 'settings';
  static const String adsCollection = 'ads';
  static const String supportChatsCollection = 'support_chats';

  // Storage paths
  static const String avatarsPath = 'avatars';
  static const String tournamentImagesPath = 'tournament_images';

  // Cache keys
  static const String cacheBoxName = 'ekora_cache';
  static const String tournamentsBoxName = 'tournaments_cache';
  static const String rankingsBoxName = 'rankings_cache';

  // Pagination
  static const int pageSize = 20;
  static const int rankingsPageSize = 50;

  // Currency
  static const String currency = 'EGP';
  static const String currencySymbol = 'ج.م';

  // Phone
  static const String egyptPhonePrefix = '+20';

  // Roles
  static const String roleUser = 'user';
  static const String roleAdmin = 'admin';

  // Tournament status
  static const String statusUpcoming = 'upcoming';
  static const String statusLive = 'live';
  static const String statusFinished = 'finished';
  static const String statusCancelled = 'cancelled';

  // Payment methods (tournament — legacy)
  static const String paymentVodafoneCash = 'vodafone_cash';
  static const String paymentFawry = 'fawry';
  static const String paymentCreditCard = 'credit_card';

  // Payment methods (venue booking — manual)
  static const String paymentInstaPay   = 'instapay';
  static const String paymentOrangeCash = 'orange_cash';
  // vodafone_cash is shared between both flows

  // Payment status (tournament — legacy)
  static const String paymentPending = 'pending';
  static const String paymentCompleted = 'completed';
  static const String paymentFailed = 'failed';
  static const String paymentRefunded = 'refunded';

  // Booking payment status (venue booking flow)
  static const String bookingAwaitingPayment     = 'awaiting_payment';
  static const String bookingPendingVerification = 'pending_verification';
  static const String bookingConfirmed           = 'confirmed';
  static const String bookingCancelled           = 'cancelled';
  static const String bookingExpired             = 'expired';

  // FCM topics
  static const String fcmTopicAll = 'all_users';
  static const String fcmTopicTournaments = 'tournament_updates';

  // Cloud Function names
  static const String cfInitiatePayment = 'initiatePayment';
  static const String cfVerifyPayment = 'verifyPayment';
  static const String cfSendNotification = 'sendTournamentNotification';
  static const String cfUpdateRankings = 'updateRankings';

  // Image constraints
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const double avatarCompressionQuality = 0.7;
}
