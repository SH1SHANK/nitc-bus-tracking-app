import '../features/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_validators.dart';
import '../features/auth/create_account_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../data/auth/auth_state.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/auth/reset_password_sent_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/admin/providers/admin_provider.dart';
import '../features/home/home_screen.dart';
import '../features/map/map_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/providers/profile_provider.dart';
import '../features/schedule/timetable_screen.dart';
import '../features/settings/screens/about_screen.dart';
import '../features/settings/screens/open_source_licenses_screen.dart';
import '../features/settings/screens/privacy_policy_screen.dart';
import '../features/settings/screens/terms_of_service_screen.dart';
import 'app_shell.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'homeNav',
);
final GlobalKey<NavigatorState> _mapNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'mapNav',
);
final GlobalKey<NavigatorState> _profileNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'profileNav');

CustomTransitionPage<T> _buildSmoothPage<T>({
  required LocalKey key,
  required Widget child,
  Offset beginOffset = const Offset(0.06, 0.0),
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}

/// Creates a GoRouter instance with protected route guards and auth redirect logic.
GoRouter createRouter({
  String initialLocation = '/splash',
  Ref? ref,
  Listenable? refreshListenable,
}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      if (ref == null) return null;

      final authState = ref.read(authNotifierProvider);
      final profileAsync = ref.read(profileStateProvider);

      final loc = state.uri.path;

      // Deep link / Callback handler for auth recovery or OAuth completion
      if (loc == '/auth/callback') {
        final type = state.uri.queryParameters['type'];
        if (type == 'recovery') {
          return '/reset-password';
        }
        if (authState.isAuthenticated) {
          final profile = profileAsync.value;
          final bool isGuest = authState.isGuest;
          final bool onboardingComplete =
              isGuest || (profile?.hasCompletedOnboarding ?? false);
          return onboardingComplete ? '/' : '/onboarding';
        }
        return null;
      }

      final isAuthRoute =
          loc == '/login' ||
          loc == '/create-account' ||
          loc == '/forgot-password' ||
          loc == '/reset-password-sent';

      // Allow the animated splash screen to run its entrance sequence
      if (loc == '/splash') {
        return null;
      }

      // While initializing, let splash/login load
      if (authState.status == AuthStatus.uninitialized) {
        return null;
      }

      // If user is in password recovery flow
      if (authState.status == AuthStatus.passwordRecoveryInProgress) {
        if (loc != '/reset-password') {
          return '/reset-password';
        }
        return null;
      }

      // If accessing /reset-password without recovery state or active authentication
      if (loc == '/reset-password' && !authState.isAuthenticated) {
        return '/forgot-password';
      }

      final bool isGuest = authState.isGuest;
      final isPublicLegalRoute =
          loc == '/terms' ||
          loc == '/privacy' ||
          loc == '/licenses' ||
          loc == '/about';

      // If not authenticated or domain unauthorized (for registered accounts)
      if (!authState.isAuthenticated ||
          (!isGuest && !isNitcEmail(authState.email))) {
        if (!isAuthRoute && !isPublicLegalRoute) {
          return '/login';
        }
        return null;
      }

      // Do not treat a still-loading profile as incomplete onboarding.
      if (profileAsync.isLoading || profileAsync.hasError) {
        return null;
      }

      // If authenticated
      final profile = profileAsync.value;
      final bool onboardingComplete =
          isGuest || (profile?.hasCompletedOnboarding ?? false);

      // If onboarding is incomplete, restrict access to onboarding screen
      if (!onboardingComplete) {
        if (loc != '/onboarding' && !isPublicLegalRoute) {
          return '/onboarding';
        }
        return null;
      }

      // If onboarding is complete and user visits an auth/onboarding page, redirect to home
      if (isAuthRoute || loc == '/onboarding') {
        return '/';
      }

      // Restrict /admin to authenticated non-guest administrators
      if (loc.startsWith('/admin')) {
        if (!authState.isAuthenticated) {
          return '/login';
        }
        if (isGuest) {
          return '/';
        }
        final adminAsync = ref.read(isAdminProvider);
        if (adminAsync.hasValue && adminAsync.value == false) {
          return '/';
        }
      }

      return null;
    },
    routes: [
      // Animated Splash Route
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/splash',
        name: 'splash',
        pageBuilder:
            (context, state) => _buildSmoothPage(
              key: state.pageKey,
              child: const BusTrackerSplashScreen(),
              beginOffset: Offset.zero,
            ),
      ),
      // Fullscreen Onboarding Flow
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder:
            (context, state) => _buildSmoothPage(
              key: state.pageKey,
              child: const OnboardingScreen(),
              beginOffset: Offset.zero,
            ),
      ),

      // Auth Routes
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/login',
        name: 'login',
        pageBuilder:
            (context, state) => _buildSmoothPage(
              key: state.pageKey,
              child: const LoginScreen(),
            ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/create-account',
        name: 'createAccount',
        pageBuilder:
            (context, state) => _buildSmoothPage(
              key: state.pageKey,
              child: const CreateAccountScreen(),
            ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/forgot-password',
        name: 'forgotPassword',
        pageBuilder:
            (context, state) => _buildSmoothPage(
              key: state.pageKey,
              child: const ForgotPasswordScreen(),
            ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/reset-password-sent',
        name: 'resetPasswordSent',
        pageBuilder:
            (context, state) => _buildSmoothPage(
              key: state.pageKey,
              child: ResetPasswordSentScreen(
                email: state.uri.queryParameters['email'],
              ),
            ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/reset-password',
        name: 'resetPassword',
        pageBuilder:
            (context, state) => _buildSmoothPage(
              key: state.pageKey,
              child: const ResetPasswordScreen(),
            ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/schedule',
        name: 'schedule',
        pageBuilder:
            (context, state) => _buildSmoothPage(
              key: state.pageKey,
              child: TimetableScreen(
                initialStopId: state.uri.queryParameters['stopId'],
              ),
            ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/terms',
        name: 'terms',
        pageBuilder:
            (context, state) => _buildSmoothPage(
              key: state.pageKey,
              child: const TermsOfServiceScreen(),
            ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/privacy',
        name: 'privacy',
        pageBuilder:
            (context, state) => _buildSmoothPage(
              key: state.pageKey,
              child: const PrivacyPolicyScreen(),
            ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/licenses',
        name: 'licenses',
        pageBuilder:
            (context, state) => _buildSmoothPage(
              key: state.pageKey,
              child: const OpenSourceLicensesScreen(),
            ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/about',
        name: 'about',
        pageBuilder:
            (context, state) => _buildSmoothPage(
              key: state.pageKey,
              child: const AboutScreen(),
            ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/admin',
        name: 'admin',
        pageBuilder:
            (context, state) => _buildSmoothPage(
              key: state.pageKey,
              child: const AdminDashboardScreen(),
            ),
      ),

      // Main Navigation Shell (Home, Map, Profile, Settings)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                pageBuilder:
                    (context, state) =>
                        const NoTransitionPage(child: HomeScreen()),
              ),
            ],
          ),

          // Branch 1: Map (Spatial / Live First)
          StatefulShellBranch(
            navigatorKey: _mapNavigatorKey,
            routes: [
              GoRoute(
                path: '/map',
                name: 'map',
                pageBuilder:
                    (context, state) =>
                        const NoTransitionPage(child: MapScreen()),
              ),
            ],
          ),

          // Branch 2: Profile & Settings
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                pageBuilder:
                    (context, state) =>
                        const NoTransitionPage(child: ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Bridge Listenable to notify GoRouter when Auth or Profile state changes
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authNotifierProvider, (previous, next) => notifyListeners());
    ref.listen(profileStateProvider, (previous, next) => notifyListeners());
    ref.listen(isAdminProvider, (previous, next) => notifyListeners());
  }
}

final routerRefreshProvider = Provider<_RouterRefreshNotifier>((ref) {
  return _RouterRefreshNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerRefreshProvider);
  return createRouter(ref: ref, refreshListenable: refreshNotifier);
});
