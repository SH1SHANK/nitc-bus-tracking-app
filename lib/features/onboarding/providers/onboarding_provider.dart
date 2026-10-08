import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  'Architecture & Planning',
  'Biotechnology',
  'Materials Science & Engineering',
  'Production & Industrial Engineering',
  'Mathematics & Computing',
];

/// Available Batches
const List<String> kNitcBatches = [
  'Batch of 2029 (1st Year)',
  'Batch of 2028 (2nd Year)',
  'Batch of 2027 (3rd Year)',
  'Batch of 2026 (Final Year)',
  'Postgraduate (M.Tech / MCA / MBA / M.Sc)',
  'Doctoral Research Scholar (Ph.D)',
];

/// Available Semesters
const List<String> kNitcSemesters = [
  'Semester 1 (Monsoon)',
  'Semester 2 (Winter)',
  'Semester 3 (Monsoon)',
  'Semester 4 (Winter)',
  'Semester 5 (Monsoon)',
  'Semester 6 (Winter)',
  'Semester 7 (Monsoon)',
  'Semester 8 (Winter)',
  'Summer Term / Research Session',
];

/// Available Hostels / Campus Hubs
const List<String> kNitcHostels = [
  'Mega Hostel Hub (MBH I & II)',
  'Ladies Hostel Complex (LH)',
  'A & B Hostel Cluster',
  'C & D Hostel Cluster',
  'PG & Research Scholars Hostel',
  'East Campus Residential Quarters',
  'Day Scholar / Off-Campus Stay',
];

/// Available Primary Bus Stops
const List<String> kNitcPrimaryStops = [
  'Main Gate Central Hub',
  'Mega Hostel Terminal (MBH)',
  'East Campus & Architecture',
  'ELHC & NLHC Lecture Halls',
  'Central Library & Admin Circle',
];

class OnboardingState {
  const OnboardingState({
    this.currentStep = 0,
    this.name = 'Shashank Mergu',
    this.branch = 'Computer Science & Engineering',
    this.batch = 'Batch of 2026 (Final Year)',
    this.semester = 'Semester 6 (Winter)',
    this.username = 'shashank',
    this.isUsernameAvailable = true,
    this.isCheckingUsername = false,
    this.locationPermissionGranted = false,
    this.notificationPermissionGranted = false,
    this.hostel = 'Mega Hostel Hub (MBH I & II)',
    this.primaryStop = 'Main Gate Central Hub',
    this.agreedToTerms = true,
    this.loadingProgress = 0.0,
    this.loadingStatus =
        'Initializing your personalized campus transit feed...',
  });

  final int currentStep;
  final String name;
  final String branch;
  final String batch;
  final String semester;
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
    String? semester,
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
      semester: semester ?? this.semester,
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

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    return const OnboardingState();
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

  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void setBranch(String branch) {
    state = state.copyWith(branch: branch);
  }

  void setBatch(String batch) {
    state = state.copyWith(batch: batch);
  }

  void setSemester(String semester) {
    state = state.copyWith(semester: semester);
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

    state = state.copyWith(
      username: cleaned,
      isCheckingUsername: false,
      isUsernameAvailable:
          cleaned.isNotEmpty && !takenUsernames.contains(cleaned),
    );
  }

  void generateRandomUsername() {
    const prefixes = [
      'nitc_rider',
      'mega_cruiser',
      'campus_surfer',
      'monsoon_coder',
      'calicut_transit',
      'shuttle_champ',
      'east_campus_ace',
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
    final steps = [
      (0.20, 'Connecting to NITC Supabase Realtime Network...'),
      (0.45, 'Syncing campus shuttle routes & timetable...'),
      (0.70, 'Calculating real-time walking distances...'),
      (0.90, 'Preparing your personalized transit card...'),
      (1.00, 'All systems ready! Launching Tracklet...'),
    ];

    for (final step in steps) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      state = state.copyWith(loadingProgress: step.$1, loadingStatus: step.$2);
    }

    // Persist finalized profile
    final repo = ref.read(profileRepositoryProvider);
    final profile = Profile(
      id: 'user-${state.username}',
      name: state.name,
      username: state.username,
      email: '${state.username.toLowerCase()}@nitc.ac.in',
      department: state.branch,
      branch: state.branch,
      batch: state.batch,
      semester: state.semester,
      hostel: state.hostel,
      notificationsEnabled: state.notificationPermissionGranted,
      locationPermissionGranted: state.locationPermissionGranted,
      hasCompletedOnboarding: true,
    );

    await repo.saveProfile(profile);
    await repo.setOnboardingCompleted(true);
    ref.invalidate(profileStateProvider);

    await Future<void>.delayed(const Duration(milliseconds: 400));
    onComplete();
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(() {
      return OnboardingNotifier();
    });
