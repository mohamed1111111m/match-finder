import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_payments_screen.dart';
import '../../features/admin/presentation/screens/admin_support_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/admin/presentation/screens/admin_ads_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/admin/presentation/screens/admin_venues_screen.dart';
import '../../features/admin/presentation/screens/create_tournament_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/support/presentation/screens/support_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/matchmaking/presentation/screens/create_session_screen.dart';
import '../../features/matchmaking/presentation/screens/matchmaking_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/teams/presentation/screens/create_team_screen.dart';
import '../../features/teams/presentation/screens/team_detail_screen.dart';
import '../../features/teams/presentation/screens/teams_screen.dart';
import '../../features/tournaments/presentation/screens/tournament_detail_screen.dart';
import '../../features/tournaments/presentation/screens/tournaments_screen.dart';
import '../../features/legal/presentation/screens/privacy_policy_screen.dart';
import '../../features/legal/presentation/screens/terms_screen.dart';
import '../../features/rankings/presentation/screens/leaderboard_screen.dart';
import '../../features/venues/presentation/screens/booking_payment_screen.dart';
import '../../features/venues/presentation/screens/venue_detail_screen.dart';
import '../../features/venues/presentation/screens/venues_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/main_scaffold.dart';

class AppRoutes {
  AppRoutes._();

  static const splash         = '/';
  static const login          = '/login';
  static const register       = '/register';
  static const forgotPassword = '/forgot-password';
  static const home           = '/home';
  static const venues         = '/venues';
  static const venueDetail    = '/venues/:id';
  static const matchmaking    = '/matchmaking';
  static const createSession  = '/matchmaking/create';
  static const teams          = '/teams';
  static const teamDetail     = '/teams/:id';
  static const createTeam     = '/teams/create';
  static const leaderboard    = '/leaderboard';
  static const tournaments    = '/tournaments';
  static const tournamentDetail = '/tournaments/:id';
  static const profile        = '/profile';
  static const editProfile    = '/profile/edit';
  static const chatList       = '/chat';
  static const chatScreen     = '/chat/:uid';
  static const notifications  = '/notifications';
  static const support        = '/support';
  static const adminDashboard = '/admin';
  static const adminVenues    = '/admin/venues';
  static const adminCreateTournament = '/admin/create-tournament';
  static const adminUsers     = '/admin/users';
  static const adminPayments  = '/admin/payments';
  static const adminSupport   = '/admin/support';
  static const bookingPayment = '/booking/:bookingId';
  static const privacyPolicy  = '/privacy-policy';
  static const terms          = '/terms';
}

// Notifies GoRouter to re-run redirect without recreating the router instance.
class _RouterNotifier extends ChangeNotifier {
  AsyncValue<dynamic> _authState;

  _RouterNotifier(this._authState);

  void update(AsyncValue<dynamic> next) {
    _authState = next;
    notifyListeners();
  }

  bool get isLoading => _authState is AsyncLoading;
  bool get isAuthenticated => _authState.valueOrNull != null;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref.read(authStateProvider));
  ref.listen(authStateProvider, (_, next) => notifier.update(next));

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: notifier,

    redirect: (context, state) {
      if (notifier.isLoading) return null;

      final path = state.matchedLocation;
      const authPaths = {
        AppRoutes.login, AppRoutes.register,
        AppRoutes.forgotPassword, AppRoutes.splash,
        '/onboarding',
      };
      final onAuth = authPaths.contains(path);

      if (!notifier.isAuthenticated && !onAuth) return AppRoutes.login;
      if (notifier.isAuthenticated && onAuth && path != AppRoutes.splash) {
        return AppRoutes.home;
      }
      return null;
    },

    routes: [
      // ── Onboarding ────────────────────────────────────────────────────────
      GoRoute(path: '/onboarding',
        builder: (_, __) => const OnboardingScreen()),

      // ── Auth / splash ─────────────────────────────────────────────────────
      GoRoute(path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login,
        builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen()),
      GoRoute(path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen()),

      // ── Main shell (persistent bottom nav) ───────────────────────────────
      ShellRoute(
        builder: (ctx, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: AppRoutes.home,
            builder: (_, __) => const HomeScreen()),
          GoRoute(path: AppRoutes.venues,
            builder: (_, __) => const VenuesScreen()),
          GoRoute(path: AppRoutes.matchmaking,
            builder: (_, __) => const MatchmakingScreen()),
          GoRoute(path: AppRoutes.teams,
            builder: (_, __) => const TeamsScreen()),
          GoRoute(path: AppRoutes.tournaments,
            builder: (_, __) => const TournamentsScreen()),
          GoRoute(path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Full-screen detail / form screens ─────────────────────────────────
      GoRoute(path: AppRoutes.venueDetail,
        builder: (_, s) =>
          VenueDetailScreen(venueId: s.pathParameters['id']!)),
      GoRoute(path: AppRoutes.bookingPayment,
        builder: (_, s) =>
          BookingPaymentScreen(bookingId: s.pathParameters['bookingId']!)),
      GoRoute(path: AppRoutes.createSession,
        builder: (_, __) => const CreateSessionScreen()),
      // Note: createTeam must come BEFORE teamDetail so '/teams/create'
      // is matched first and not treated as id='create'.
      GoRoute(path: AppRoutes.createTeam,
        builder: (_, __) => const CreateTeamScreen()),
      GoRoute(path: AppRoutes.teamDetail,
        builder: (_, s) =>
          TeamDetailScreen(teamId: s.pathParameters['id']!)),
      GoRoute(path: AppRoutes.tournamentDetail,
        builder: (_, s) =>
          TournamentDetailScreen(tournamentId: s.pathParameters['id']!)),
      GoRoute(path: AppRoutes.editProfile,
        builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: AppRoutes.chatList,
        builder: (_, __) => const ChatListScreen()),
      GoRoute(
        path: AppRoutes.chatScreen,
        builder: (_, s) => ChatScreen(
          otherUserId:   s.pathParameters['uid']!,
          otherUserName: s.uri.queryParameters['name'] ?? '',
        ),
      ),
      GoRoute(path: AppRoutes.leaderboard,
        builder: (_, __) => const LeaderboardScreen()),
      GoRoute(path: AppRoutes.privacyPolicy,
        builder: (_, __) => const PrivacyPolicyScreen()),
      GoRoute(path: AppRoutes.terms,
        builder: (_, __) => const TermsScreen()),
      GoRoute(path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: AppRoutes.support,
        builder: (_, __) => const SupportScreen()),

      // ── Admin ─────────────────────────────────────────────────────────────
      GoRoute(path: AppRoutes.adminDashboard,
        builder: (_, __) => const AdminDashboardScreen(),
        routes: [
          GoRoute(path: 'venues',
            builder: (_, __) => const AdminVenuesScreen()),
          GoRoute(path: 'create-tournament',
            builder: (_, __) => const CreateTournamentScreen()),
          GoRoute(path: 'users',
            builder: (_, __) => const AdminUsersScreen()),
          GoRoute(path: 'payments',
            builder: (_, __) => const AdminPaymentsScreen()),
          GoRoute(path: 'support',
            builder: (_, __) => const AdminSupportScreen()),
          GoRoute(path: 'ads',
            builder: (_, __) => const AdminAdsScreen()),
          GoRoute(path: 'tournaments',
            builder: (_, __) => const TournamentsScreen()),
        ],
      ),
    ],

    errorBuilder: (ctx, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text('الصفحة مش موجودة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ctx.go(AppRoutes.home),
              child: const Text('الرئيسية'),
            ),
          ],
        ),
      ),
    ),
  );
});
