/// All user-facing strings. Extend with ARB/l10n when adding Arabic.
class AppStrings {
  AppStrings._();

  // Auth
  static const String login = 'Login';
  static const String register = 'Create Account';
  static const String logout = 'Logout';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String username = 'Username';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String continueWithGoogle = 'Continue with Google';
  static const String continueWithFacebook = 'Continue with Facebook';
  static const String alreadyHaveAccount = 'Already have an account? Login';
  static const String dontHaveAccount = "Don't have an account? Register";
  static const String resetEmailSent =
      'Password reset email sent. Check your inbox.';

  // Home / Navigation
  static const String tournaments = 'Tournaments';
  static const String leaderboard = 'Leaderboard';
  static const String profile = 'Profile';
  static const String admin = 'Admin';
  static const String home = 'Home';

  // Tournaments
  static const String joinTournament = 'Join Tournament';
  static const String tournamentDetails = 'Tournament Details';
  static const String entryFee = 'Entry Fee';
  static const String prizePool = 'Prize Pool';
  static const String participants = 'Participants';
  static const String maxParticipants = 'Max Participants';
  static const String startDate = 'Start Date';
  static const String endDate = 'End Date';
  static const String game = 'Game';
  static const String format = 'Format';
  static const String upcoming = 'Upcoming';
  static const String live = 'Live';
  static const String finished = 'Finished';
  static const String noTournaments = 'No tournaments available';
  static const String searchTournaments = 'Search tournaments...';
  static const String filterByStatus = 'Filter by status';
  static const String free = 'Free';

  // Rankings
  static const String globalLeaderboard = 'Global Leaderboard';
  static const String rank = 'Rank';
  static const String wins = 'Wins';
  static const String losses = 'Losses';
  static const String points = 'Points';
  static const String winRate = 'Win Rate';
  static const String noRankings = 'No rankings yet. Join a tournament!';

  // Profile
  static const String editProfile = 'Edit Profile';
  static const String myTournaments = 'My Tournaments';
  static const String myStats = 'My Stats';
  static const String uploadAvatar = 'Upload Avatar';
  static const String bio = 'Bio';
  static const String phoneNumber = 'Phone Number';

  // Payments
  static const String payment = 'Payment';
  static const String paymentMethod = 'Payment Method';
  static const String vodafoneCash = 'Vodafone Cash';
  static const String fawry = 'Fawry';
  static const String creditCard = 'Credit / Debit Card';
  static const String proceedToPayment = 'Proceed to Payment';
  static const String paymentSuccess = 'Payment Successful!';
  static const String paymentFailed = 'Payment Failed';
  static const String transactionId = 'Transaction ID';
  static const String amount = 'Amount';
  static const String payNow = 'Pay Now';

  // Admin
  static const String adminDashboard = 'Admin Dashboard';
  static const String createTournament = 'Create Tournament';
  static const String manageUsers = 'Manage Users';
  static const String managePayments = 'Manage Payments';
  static const String totalUsers = 'Total Users';
  static const String totalTournaments = 'Total Tournaments';
  static const String totalRevenue = 'Total Revenue';
  static const String approvePlayers = 'Approve Players';
  static const String approve = 'Approve';
  static const String reject = 'Reject';
  static const String ban = 'Ban User';

  // Common
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String retry = 'Retry';
  static const String loading = 'Loading...';
  static const String noData = 'No data available';
  static const String error = 'Something went wrong';
  static const String success = 'Success';
  static const String networkError =
      'No internet connection. Please check your network.';

  // Errors
  static const String invalidEmail = 'Please enter a valid email address';
  static const String weakPassword = 'Password must be at least 8 characters';
  static const String passwordMismatch = 'Passwords do not match';
  static const String requiredField = 'This field is required';
  static const String userNotFound = 'No account found with this email';
  static const String wrongPassword = 'Incorrect password';
  static const String emailAlreadyInUse =
      'An account already exists with this email';
  static const String tooManyRequests =
      'Too many attempts. Please try again later';
}
