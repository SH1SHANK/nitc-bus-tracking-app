import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/validation/username_validator.dart';
import '../../../data/academic/department.dart';
import '../../../data/academic/department_repository.dart';
import '../../../data/campus/hostel.dart';
import '../../../data/campus/hostel_repository.dart';
import '../../../data/profile/profile.dart';
import '../../../data/profile/profile_repository.dart';
import '../../../data/supabase/supabase_client_provider.dart';
import '../../../data/transit/stop.dart';
import '../../../data/transit/transit_repository.dart';
import '../../profile/providers/profile_provider.dart';

/// Available Batches
const List<String> kNitcBatches = [
  'B26',
  'B25',
  'B24',
  'B23',
  'M26',
  'M25',
  'Doctoral Research Scholar (Ph.D)',
];

class OnboardingState {
  const OnboardingState({
    this.currentStep = 0,
    this.name = '',
    this.branch = '',
    this.batch = '',
    this.username = '',
    this.isUsernameAvailable,
    this.isCheckingUsername = false,
    this.usernameValidationError,
    this.locationPermissionGranted = false,
    this.hostel = '',
    this.primaryStop = '',
    this.agreedToTerms = false,
    this.loadingProgress = 0.0,
    this.loadingStatus = 'Preparing your campus profile...',
    this.departments = const [],
    this.isLoadingDepartments = false,
    this.departmentsError,
    this.hostels = const [],
    this.isLoadingHostels = false,
    this.hostelsError,
    this.stops = const [],
    this.isLoadingStops = false,
    this.stopsError,
  });

  final int currentStep;
  final String name;
  final String branch;
  final String batch;
  final String username;
  final bool? isUsernameAvailable;
  final bool isCheckingUsername;
  final String? usernameValidationError;
  final bool locationPermissionGranted;
  final String hostel;
  final String primaryStop;
  final bool agreedToTerms;
  final double loadingProgress;
  final String loadingStatus;

  // Supabase Source-of-Truth Institutional Data
  final List<Department> departments;
  final bool isLoadingDepartments;
  final String? departmentsError;

  final List<Hostel> hostels;
  final bool isLoadingHostels;
  final String? hostelsError;

  final List<Stop> stops;
  final bool isLoadingStops;
  final String? stopsError;

  static const _errorSentinel = Object();

  OnboardingState copyWith({
    int? currentStep,
    String? name,
    String? branch,
    String? batch,
    String? username,
    bool? isUsernameAvailable,
    bool? isCheckingUsername,
    Object? usernameValidationError = _errorSentinel,
    bool? locationPermissionGranted,
    String? hostel,
    String? primaryStop,
    bool? agreedToTerms,
    double? loadingProgress,
    String? loadingStatus,
    List<Department>? departments,
    bool? isLoadingDepartments,
    Object? departmentsError = _errorSentinel,
    List<Hostel>? hostels,
    bool? isLoadingHostels,
    Object? hostelsError = _errorSentinel,
    List<Stop>? stops,
    bool? isLoadingStops,
    Object? stopsError = _errorSentinel,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      name: name ?? this.name,
      branch: branch ?? this.branch,
      batch: batch ?? this.batch,
      username: username ?? this.username,
      isUsernameAvailable: isUsernameAvailable ?? this.isUsernameAvailable,
      isCheckingUsername: isCheckingUsername ?? this.isCheckingUsername,
      usernameValidationError:
          identical(usernameValidationError, _errorSentinel)
              ? this.usernameValidationError
              : usernameValidationError as String?,
      locationPermissionGranted:
          locationPermissionGranted ?? this.locationPermissionGranted,
      hostel: hostel ?? this.hostel,
      primaryStop: primaryStop ?? this.primaryStop,
      agreedToTerms: agreedToTerms ?? this.agreedToTerms,
      loadingProgress: loadingProgress ?? this.loadingProgress,
      loadingStatus: loadingStatus ?? this.loadingStatus,
      departments: departments ?? this.departments,
      isLoadingDepartments: isLoadingDepartments ?? this.isLoadingDepartments,
      departmentsError:
          identical(departmentsError, _errorSentinel)
              ? this.departmentsError
              : departmentsError as String?,
      hostels: hostels ?? this.hostels,
      isLoadingHostels: isLoadingHostels ?? this.isLoadingHostels,
      hostelsError:
          identical(hostelsError, _errorSentinel)
              ? this.hostelsError
              : hostelsError as String?,
      stops: stops ?? this.stops,
      isLoadingStops: isLoadingStops ?? this.isLoadingStops,
      stopsError:
          identical(stopsError, _errorSentinel)
              ? this.stopsError
              : stopsError as String?,
    );
  }
}

class OnboardingNotifier extends Notifier<OnboardingState> {
  bool _isInitializing = false;
  Ref get _ref => ref;

  @override
  OnboardingState build() {
    ref.onDispose(() => _usernameDebounceTimer?.cancel());
    Future.microtask(loadInstitutionalData);
    return const OnboardingState();
  }

  Future<void> loadInstitutionalData() async {
    await loadDepartments();
    await loadHostels();
    await loadStops();
  }

  Future<void> loadDepartments() async {
    if (!ref.mounted) return;
    state = state.copyWith(isLoadingDepartments: true, departmentsError: null);
    try {
      final repo = _ref.read(departmentRepositoryProvider);
      final list = await repo.getDepartments();
      if (!ref.mounted) return;
      state = state.copyWith(
        departments: list,
        isLoadingDepartments: false,
        departmentsError: null,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoadingDepartments: false,
        departmentsError: 'Could not load departments: $e',
      );
    }
  }

  Future<void> loadHostels() async {
    if (!ref.mounted) return;
    state = state.copyWith(isLoadingHostels: true, hostelsError: null);
    try {
      final repo = _ref.read(hostelRepositoryProvider);
      final list = await repo.getHostels();
      if (!ref.mounted) return;
      state = state.copyWith(
        hostels: list,
        isLoadingHostels: false,
        hostelsError: null,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoadingHostels: false,
        hostelsError: 'Could not load hostels: $e',
      );
    }
  }

  Future<void> loadStops() async {
    if (!ref.mounted) return;
    state = state.copyWith(isLoadingStops: true, stopsError: null);
    try {
      final repo = _ref.read(transitRepositoryProvider);
      final list = await repo.getStops();
      if (!ref.mounted) return;
      state = state.copyWith(
        stops: list,
        isLoadingStops: false,
        stopsError: null,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoadingStops: false,
        stopsError: 'Could not load stops: $e',
      );
    }
  }

  void nextStep() {
    if (state.currentStep < 10) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void reset() {
    state = const OnboardingState();
    loadInstitutionalData();
  }

  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void setBranch(String branch) {
    state = state.copyWith(branch: branch);
  }

  void setBatch(String batch) {
    state = state.copyWith(batch: batch);
  }

  void setHostel(String hostel) {
    state = state.copyWith(hostel: hostel);
  }

  void setPrimaryStop(String stop) {
    state = state.copyWith(primaryStop: stop);
  }

  void toggleTerms(bool agreed) {
    state = state.copyWith(agreedToTerms: agreed);
  }

  void setLocationPermission(bool granted) {
    state = state.copyWith(locationPermissionGranted: granted);
  }

  Timer? _usernameDebounceTimer;

  void updateUsername(String text) {
    _usernameDebounceTimer?.cancel();
    final cleaned = text.replaceAll('@', '').trim().toLowerCase();
    const takenUsernames = [
      'admin',
      'root',
      'support',
      'nitc',
      'bustracker',
      'tracklet',
    ];

    final validation = UsernameValidator.validate(cleaned);
    final isSynchronouslyValid =
        validation.isValid && !takenUsernames.contains(cleaned);

    state = state.copyWith(
      username: cleaned,
      isCheckingUsername: isSynchronouslyValid,
      isUsernameAvailable: isSynchronouslyValid,
      usernameValidationError:
          takenUsernames.contains(cleaned)
              ? 'Username is already taken.'
              : (!validation.isValid ? validation.errorMessage : null),
    );

    if (!isSynchronouslyValid) return;

    _usernameDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final repo = _ref.read(profileRepositoryProvider);
        final available = await repo.isUsernameAvailable(cleaned);
        if (!ref.mounted) return;
        if (state.username == cleaned) {
          state = state.copyWith(
            isCheckingUsername: false,
            isUsernameAvailable: available,
            usernameValidationError:
                available ? null : 'Username is already taken.',
          );
        }
      } catch (e) {
        if (!ref.mounted) return;
        if (state.username == cleaned) {
          state = state.copyWith(
            isCheckingUsername: false,
            isUsernameAvailable: null,
            usernameValidationError:
                'Could not verify username. Check your connection.',
          );
        }
      }
    });
  }

  void generateRandomUsername() {
    const prefixes = [
      'nitc_rider',
      'mega_cruiser',
      'campus_surfer',
      'monsoon_coder',
      'calicut_bus',
      'shuttle_champ',
      'east_campus',
      'elhc_commuter',
      'nitc_voyager',
    ];
    final randomSuffix = Random().nextInt(90) + 10;
    final randomPrefix = prefixes[Random().nextInt(prefixes.length)];
    final generated = '$randomPrefix$randomSuffix';

    state = state.copyWith(
      username: generated,
      isUsernameAvailable: true,
      isCheckingUsername: false,
      usernameValidationError: null,
    );
  }

  Future<void> runInitializationSequence({
    required void Function() onComplete,
    void Function(String error)? onError,
  }) async {
    if (_isInitializing) return;
    _isInitializing = true;
    final repo = _ref.read(profileRepositoryProvider);
    state = state.copyWith(
      loadingProgress: 0.15,
      loadingStatus: 'Preparing your campus profile...',
    );

    // Use the authenticated user's real ID and email, falling back gracefully
    // when running without Supabase credentials (e.g. development seed mode).
    final currentUser = _ref.read(supabaseClientProvider)?.auth.currentUser;
    final profile = Profile(
      id: currentUser?.id ?? 'user-${state.username}',
      name: state.name,
      username: state.username,
      email: currentUser?.email ?? '',
      department: state.branch,
      branch: state.branch,
      batch: state.batch,
      semester: '',
      hostel: state.hostel,
      notificationsEnabled: false,
      locationPermissionGranted: state.locationPermissionGranted,
      hasCompletedOnboarding: true,
    );

    try {
      state = state.copyWith(
        loadingProgress: 0.55,
        loadingStatus: 'Saving your profile and preferences...',
      );
      await repo.saveProfile(profile);
      await repo.setOnboardingCompleted(true);
      _ref.invalidate(profileStateProvider);

      if (!ref.mounted) return;
      state = state.copyWith(
        loadingProgress: 1.0,
        loadingStatus: 'You’re all set. Welcome to BusTracker.',
      );
      _isInitializing = false;
      if (!ref.mounted) return;
      onComplete();
    } catch (e) {
      _isInitializing = false;
      if (!ref.mounted) return;
      state = state.copyWith(
        loadingProgress: 0.0,
        loadingStatus: 'Failed to complete profile setup: $e',
      );
      onError?.call(e.toString());
    }
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
      OnboardingNotifier.new,
    );
