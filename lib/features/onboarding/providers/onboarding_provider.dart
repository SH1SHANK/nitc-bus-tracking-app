import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../data/profile/profile.dart';
import '../../../data/profile/profile_repository.dart';
import '../../profile/providers/profile_provider.dart';

/// Available NITC Academic Branches
const List<String> kNitcBranches = [
  'Computer Science & Engineering',
  'Electronics & Communication Engineering',
  'Electrical & Electronics Engineering',
  'Mechanical Engineering',
  'Civil Engineering',
  'Chemical Engineering',
  'Architecture',
  'Biotechnology',
  'Materials Science & Engineering',
  'Production Engineering',
  'Energy Engineering',
];

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

/// Available Hostels / Campus Hubs
const List<String> kNitcHostels = [
  'Mega Hostel Boys (MBH II)',
  'Old Mega Hostel Boys (MBH I)',
  'Ladies Hostel (LH)',
  'Mega Hostel Ladies (MLH)',
  'A Hostel',
  'B Hostel',
  'C Hostel',
  'D Hostel',
  'E Hostel',
  'F Hostel',
  'G Hostel',
  'PG I',
  'PG II',
  'Day Scholar / Off-Campus Stay',
];

/// Available Primary Bus Stops
const List<String> kNitcPrimaryStops = [
  'Main Building',
  'Main Gate',
  'ATM Circle',
  'Architecture Building',
  'East Campus',
  'MHB II Hostel',
  'LH Hostel',
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
    this.locationPermissionGranted = false,
    this.notificationPermissionGranted = false,
    this.hostel = '',
    this.primaryStop = '',
    this.agreedToTerms = false,
    this.loadingProgress = 0.0,
    this.loadingStatus = 'Preparing your campus profile...',
  });

  final int currentStep;
  final String name;
  final String branch;
  final String batch;
  final String username;
  final bool? isUsernameAvailable;
  final bool isCheckingUsername;
  final bool locationPermissionGranted;
  final bool notificationPermissionGranted;
  final String hostel;
  final String primaryStop;
  final bool agreedToTerms;
  final double loadingProgress;
  final String loadingStatus;

  OnboardingState copyWith({
    int? currentStep,
    String? name,
    String? branch,
    String? batch,
    String? username,
    bool? isUsernameAvailable,
    bool? isCheckingUsername,
    bool? locationPermissionGranted,
    bool? notificationPermissionGranted,
    String? hostel,
    String? primaryStop,
    bool? agreedToTerms,
    double? loadingProgress,
    String? loadingStatus,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      name: name ?? this.name,
      branch: branch ?? this.branch,
      batch: batch ?? this.batch,
      username: username ?? this.username,
      isUsernameAvailable: isUsernameAvailable ?? this.isUsernameAvailable,
      isCheckingUsername: isCheckingUsername ?? this.isCheckingUsername,
      locationPermissionGranted:
          locationPermissionGranted ?? this.locationPermissionGranted,
      notificationPermissionGranted:
          notificationPermissionGranted ?? this.notificationPermissionGranted,
      hostel: hostel ?? this.hostel,
      primaryStop: primaryStop ?? this.primaryStop,
      agreedToTerms: agreedToTerms ?? this.agreedToTerms,
      loadingProgress: loadingProgress ?? this.loadingProgress,
      loadingStatus: loadingStatus ?? this.loadingStatus,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier(this._ref) : super(const OnboardingState());

  final Ref _ref;

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

  void setNotificationPermission(bool granted) {
    state = state.copyWith(notificationPermissionGranted: granted);
  }

  void updateUsername(String text) {
    final cleaned = text.replaceAll('@', '').trim().toLowerCase();
    final takenUsernames = ['admin', 'root', 'support', 'nitc', 'tracklet'];

    final hasValidLength = cleaned.length >= 3 && cleaned.length <= 16;
    state = state.copyWith(
      username: cleaned,
      isCheckingUsername: false,
      isUsernameAvailable: hasValidLength && !takenUsernames.contains(cleaned),
    );
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
    );
  }

  Future<void> runInitializationSequence({
    required void Function() onComplete,
  }) async {
    final repo = _ref.read(profileRepositoryProvider);
    state = state.copyWith(
      loadingProgress: 0.15,
      loadingStatus: 'Preparing your campus profile...',
    );
    final profile = Profile(
      id: 'user-${state.username}',
      name: state.name,
      username: state.username,
      email: '${state.username.toLowerCase()}@nitc.ac.in',
      department: state.branch,
      branch: state.branch,
      batch: state.batch,
      semester: '',
      hostel: state.hostel,
      notificationsEnabled: state.notificationPermissionGranted,
      locationPermissionGranted: state.locationPermissionGranted,
      hasCompletedOnboarding: true,
    );

    state = state.copyWith(
      loadingProgress: 0.55,
      loadingStatus: 'Saving your profile and preferences...',
    );
    await repo.saveProfile(profile);
    await repo.setOnboardingCompleted(true);
    _ref.invalidate(profileStateProvider);

    state = state.copyWith(
      loadingProgress: 1.0,
      loadingStatus: 'You’re all set. Welcome to Tracklet.',
    );
    await Future<void>.delayed(const Duration(milliseconds: 280));
    onComplete();
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
      return OnboardingNotifier(ref);
    });
