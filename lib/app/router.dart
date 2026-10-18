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
import '../design_system/tokens/motion.dart';
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

/// Fade page transition for root initialization (splash, onboarding).
CustomTransitionPage<T> _buildFadePage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: TrackletMotion.medium,
    reverseTransitionDuration: TrackletMotion.standard,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) {
        return child;
      }
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: TrackletMotion.easeOut,
        reverseCurve: TrackletMotion.easeIn,
      );
      return FadeTransition(opacity: curvedAnimation, child: child);
    },
  );
}

/// Directional horizontal push transition with secondary parallax depth.
CustomTransitionPage<T> _buildHorizontalPage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: TrackletMotion.medium,
    reverseTransitionDuration: TrackletMotion.standard,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) {
        return child;
      }
      final primaryCurved = CurvedAnimation(
        parent: animation,
        curve: TrackletMotion.easeOut,
        reverseCurve: TrackletMotion.easeIn,
      );
      final secondaryCurved = CurvedAnimation(
        parent: secondaryAnimation,
        curve: TrackletMotion.easeOut,
        reverseCurve: TrackletMotion.easeIn,
      );

      final primaryOffset = Tween<Offset>(
        begin: const Offset(0.08, 0.0),
        end: Offset.zero,
      ).animate(primaryCurved);

      final secondaryOffset = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.03, 0.0),
      ).animate(secondaryCurved);

      final primaryFade = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(primaryCurved);

      final secondaryFade = Tween<double>(
        begin: 1.0,
        end: 0.88,
      ).animate(secondaryCurved);

      return SlideTransition(
        position: secondaryOffset,
        child: FadeTransition(
          opacity: secondaryFade,
          child: SlideTransition(
            position: primaryOffset,
            child: FadeTransition(opacity: primaryFade, child: child),
          ),
        ),
      );
    },
  );
}

/// Modal vertical slide-up transition for overlay destinations and utility sheets.
CustomTransitionPage<T> _buildModalPage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: TrackletMotion.medium,
    reverseTransitionDuration: TrackletMotion.standard,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) {
        return child;
      }
      final primaryCurved = CurvedAnimation(
        parent: animation,
        curve: TrackletMotion.easeOut,
        reverseCurve: TrackletMotion.easeIn,
      );
      final secondaryCurved = CurvedAnimation(
        parent: secondaryAnimation,
        curve: TrackletMotion.easeOut,
        reverseCurve: TrackletMotion.easeIn,
      );

      final primaryOffset = Tween<Offset>(
        begin: const Offset(0.0, 0.08),
        end: Offset.zero,
      ).animate(primaryCurved);

      final primaryFade = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(primaryCurved);

      final secondaryScale = Tween<double>(
        begin: 1.0,
        end: 0.96,
      ).animate(secondaryCurved);

      final secondaryFade = Tween<double>(
        begin: 1.0,
        end: 0.90,
      ).animate(secondaryCurved);

      return ScaleTransition(
        scale: secondaryScale,
        child: FadeTransition(
          opacity: secondaryFade,
          child: SlideTransition(
            position: primaryOffset,
            child: FadeTransition(opacity: primaryFade, child: child),
          ),
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
    onException: (context, state, router) {
      router.go('/');
    },
    routes: [
      // Direct aliases for common routes
      GoRoute(path: '/home', redirect: (context, state) => '/'),
      GoRoute(path: '/timetable', redirect: (context, state) => '/schedule'),
      // Animated Splash Route
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/splash',
        name: 'splash',
        pageBuilder:
            (context, state) => _buildFadePage(
              key: state.pageKey,
              child: const BusTrackerSplashScreen(),
            ),
      ),
      // Fullscreen Onboarding Flow
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder:
            (context, state) => _buildFadePage(
              key: state.pageKey,
              child: const OnboardingScreen(),
            ),
      ),

      // Auth Routes (Horizontal Push with Parallax Depth)
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/login',
        name: 'login',
        pageBuilder:
            (context, state) => _buildHorizontalPage(
              key: state.pageKey,
              child: const LoginScreen(),
            ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/create-account',
        name: 'createAccount',
        pageBuilder:
            (context, state) => _buildHorizontalPage(
              key: state.pageKey,
              child: const CreateAccountScreen(),
            ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/forgot-password',
        name: 'forgotPassword',
        pageBuilder:
            (context, state) => _buildHorizontalPage(
              key: state.pageKey,
              child: const ForgotPasswordScreen(),
            ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/reset-password-sent',
        name: 'resetPasswordSent',
        pageBuilder:
            (context, state) => _buildHorizontalPage(
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
            (context, state) => _buildHorizontalPage(
              key: state.pageKey,
              child: const ResetPasswordScreen(),
            ),
      ),

      // Modal & Detail Routes (Vertical Slide-Up Presentation)
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/schedule',
        name: 'schedule',
        pageBuilder:
            (context, state) => _buildModalPage(
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
            (context, state) => _buildModalPage(
              key: state.pageKey,
              child: const TermsOfServiceScreen(),
            ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/privacy',
        name: 'privacy',
        pageBuilder:
            (context, state) => _buildModalPage(
              key: state.pageKey,
              child: const PrivacyPolicyScreen(),
            ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/licenses',
        name: 'licenses',
        pageBuilder:
            (context, state) => _buildModalPage(
              key: state.pageKey,
              child: const OpenSourceLicensesScreen(),
            ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/about',
        name: 'about',
        pageBuilder:
            (context, state) =>
                _buildModalPage(key: state.pageKey, child: const AboutScreen()),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/admin',
        name: 'admin',
        pageBuilder:
            (context, state) => _buildModalPage(
              key: state.pageKey,
              child: const AdminDashboardScreen(),
            ),
      ),

      // Main Navigation Shell (Home, Map, Profile, Settings)
      StatefulShellRoute(
        navigatorContainerBuilder: (context, navigationShell, children) {
          return _AnimatedBranchContainer(
            currentIndex: navigationShell.currentIndex,
            children: children,
          );
        },
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

/// Fluid animated branch container preserving navigator state while providing
/// smooth cross-fade and subtle micro-scaling transitions between shell tabs.
class _AnimatedBranchContainer extends StatelessWidget {
  const _AnimatedBranchContainer({
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return Stack(
      fit: StackFit.expand,
      children: List<Widget>.generate(children.length, (index) {
        final isActive = index == currentIndex;

        if (disableAnimations) {
          return Offstage(
            offstage: !isActive,
            child: TickerMode(enabled: isActive, child: children[index]),
          );
        }

        return IgnorePointer(
          ignoring: !isActive,
          child: AnimatedOpacity(
            opacity: isActive ? 1.0 : 0.0,
            duration: TrackletMotion.tabSwitch,
            curve: TrackletMotion.easeOut,
            child: AnimatedScale(
              scale: isActive ? 1.0 : 0.985,
              duration: TrackletMotion.tabSwitch,
              curve: TrackletMotion.easeOut,
              child: TickerMode(enabled: isActive, child: children[index]),
            ),
          ),
        );
      }),
    );
  }
}
