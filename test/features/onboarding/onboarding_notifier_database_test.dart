import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracklet/data/academic/department.dart';
import 'package:tracklet/data/academic/department_repository.dart';
import 'package:tracklet/data/campus/hostel.dart';
import 'package:tracklet/data/campus/hostel_repository.dart';
import 'package:tracklet/data/profile/profile.dart';
import 'package:tracklet/data/profile/profile_repository.dart';
import 'package:tracklet/features/onboarding/providers/onboarding_provider.dart';

class MockDepartmentRepo implements DepartmentRepository {
  MockDepartmentRepo({this.shouldThrow = false, this.emptyList = false});

  bool shouldThrow;
  bool emptyList;

  @override
  Future<List<Department>> getDepartments() async {
    if (shouldThrow) {
      throw Exception('Network connection failed');
    }
    if (emptyList) {
      return const [];
    }
    return const [
      Department(id: 'CS', name: 'Computer Science & Engineering'),
      Department(id: 'EC', name: 'Electronics & Communication Engineering'),
    ];
  }
}

class MockHostelRepo implements HostelRepository {
  MockHostelRepo({this.shouldThrow = false, this.emptyList = false});

  bool shouldThrow;
  bool emptyList;

  @override
  Future<List<Hostel>> getHostels() async {
    if (shouldThrow) {
      throw Exception('Authorization required');
    }
    if (emptyList) {
      return const [];
    }
    return const [
      Hostel(id: 'MBH_1', name: 'Mega Hostel (MBH - Phase 1)'),
      Hostel(id: 'LH_MAIN', name: 'Ladies Hostel (LH - Main Block)'),
    ];
  }
}

class MockProfileRepo implements ProfileRepository {
  Profile? savedProfile;
  bool? onboardingCompleted;
  bool shouldThrowOnSave = false;

  @override
  Future<Profile> getProfile() async =>
      savedProfile ??
      const Profile(id: '1', name: 'Test', email: 'test@nitc.ac.in');

  @override
  Future<void> saveProfile(Profile profile) async {
    if (shouldThrowOnSave) {
      throw Exception('Database write failed');
    }
    savedProfile = profile;
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    if (shouldThrowOnSave) {
      throw Exception('Database RPC execution failed');
    }
    onboardingCompleted = completed;
  }

  @override
  Future<bool> isUsernameAvailable(String username) async => true;

  @override
  Future<Profile> changeUsername(String newUsername) async {
    final updated = (savedProfile ??
            const Profile(id: '1', name: 'Test', email: 'test@nitc.ac.in'))
        .copyWith(username: newUsername);
    savedProfile = updated;
    return updated;
  }
}

void main() {
  group('OnboardingNotifier Database-Driven Tests', () {
    test('loads institutional data on creation', () async {
      final mockDeptRepo = MockDepartmentRepo();
      final mockHostelRepo = MockHostelRepo();
      final mockProfileRepo = MockProfileRepo();

      final container = ProviderContainer(
        overrides: [
          departmentRepositoryProvider.overrideWithValue(mockDeptRepo),
          hostelRepositoryProvider.overrideWithValue(mockHostelRepo),
          profileRepositoryProvider.overrideWithValue(mockProfileRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(onboardingProvider.notifier);
      await notifier.loadInstitutionalData();

      final state = container.read(onboardingProvider);
      expect(state.departments.length, 2);
      expect(state.departments.first.name, 'Computer Science & Engineering');
      expect(state.hostels.length, 2);
      expect(state.hostels.first.name, 'Mega Hostel (MBH - Phase 1)');
      expect(state.isLoadingDepartments, isFalse);
      expect(state.isLoadingHostels, isFalse);
      expect(state.departmentsError, isNull);
      expect(state.hostelsError, isNull);
    });

    test(
      'handles and surfaces database failure without silent fallbacks',
      () async {
        final failingDeptRepo = MockDepartmentRepo(shouldThrow: true);
        final failingHostelRepo = MockHostelRepo(shouldThrow: true);
        final mockProfileRepo = MockProfileRepo();

        final container = ProviderContainer(
          overrides: [
            departmentRepositoryProvider.overrideWithValue(failingDeptRepo),
            hostelRepositoryProvider.overrideWithValue(failingHostelRepo),
            profileRepositoryProvider.overrideWithValue(mockProfileRepo),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(onboardingProvider.notifier);
        await notifier.loadInstitutionalData();

        final state = container.read(onboardingProvider);
        expect(state.departments, isEmpty);
        expect(state.hostels, isEmpty);
        expect(state.isLoadingDepartments, isFalse);
        expect(state.isLoadingHostels, isFalse);
        expect(state.departmentsError, contains('Network connection failed'));
        expect(state.hostelsError, contains('Authorization required'));
      },
    );

    test('retrying after failure recovers and clears error states', () async {
      final deptRepo = MockDepartmentRepo(shouldThrow: true);
      final hostelRepo = MockHostelRepo(shouldThrow: true);
      final mockProfileRepo = MockProfileRepo();

      final container = ProviderContainer(
        overrides: [
          departmentRepositoryProvider.overrideWithValue(deptRepo),
          hostelRepositoryProvider.overrideWithValue(hostelRepo),
          profileRepositoryProvider.overrideWithValue(mockProfileRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(onboardingProvider.notifier);
      await notifier.loadInstitutionalData();
      expect(container.read(onboardingProvider).departmentsError, isNotNull);

      // Fix network condition
      deptRepo.shouldThrow = false;
      hostelRepo.shouldThrow = false;

      await notifier.loadDepartments();
      await notifier.loadHostels();

      final state = container.read(onboardingProvider);
      expect(state.departments.length, 2);
      expect(state.hostels.length, 2);
      expect(state.departmentsError, isNull);
      expect(state.hostelsError, isNull);
    });

    test(
      'handles genuine empty responses distinguishable from errors',
      () async {
        final emptyDeptRepo = MockDepartmentRepo(emptyList: true);
        final emptyHostelRepo = MockHostelRepo(emptyList: true);
        final mockProfileRepo = MockProfileRepo();

        final container = ProviderContainer(
          overrides: [
            departmentRepositoryProvider.overrideWithValue(emptyDeptRepo),
            hostelRepositoryProvider.overrideWithValue(emptyHostelRepo),
            profileRepositoryProvider.overrideWithValue(mockProfileRepo),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(onboardingProvider.notifier);
        await notifier.loadInstitutionalData();

        final state = container.read(onboardingProvider);
        expect(state.departments, isEmpty);
        expect(state.hostels, isEmpty);
        expect(state.departmentsError, isNull);
        expect(state.hostelsError, isNull);
      },
    );

    test(
      'runInitializationSequence saves profile and marks onboarding completed',
      () async {
        final mockDeptRepo = MockDepartmentRepo();
        final mockHostelRepo = MockHostelRepo();
        final mockProfileRepo = MockProfileRepo();

        final container = ProviderContainer(
          overrides: [
            departmentRepositoryProvider.overrideWithValue(mockDeptRepo),
            hostelRepositoryProvider.overrideWithValue(mockHostelRepo),
            profileRepositoryProvider.overrideWithValue(mockProfileRepo),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(onboardingProvider.notifier);
        notifier.setName('Ananya Sharma');
        notifier.setBranch('Computer Science & Engineering');
        notifier.setBatch('B26');
        notifier.setHostel('Ladies Hostel (LH - Main Block)');
        notifier.updateUsername('ananya');
        notifier.setLocationPermission(true);

        var completed = false;
        await notifier.runInitializationSequence(
          onComplete: () {
            completed = true;
          },
        );

        expect(completed, isTrue);
        expect(mockProfileRepo.savedProfile?.name, 'Ananya Sharma');
        expect(mockProfileRepo.savedProfile?.username, 'ananya');
        expect(mockProfileRepo.onboardingCompleted, isTrue);
      },
    );

    test(
      'failed onboarding persistence does not mark completion and surfaces error',
      () async {
        final mockDeptRepo = MockDepartmentRepo();
        final mockHostelRepo = MockHostelRepo();
        final failingProfileRepo = MockProfileRepo()..shouldThrowOnSave = true;

        final container = ProviderContainer(
          overrides: [
            departmentRepositoryProvider.overrideWithValue(mockDeptRepo),
            hostelRepositoryProvider.overrideWithValue(mockHostelRepo),
            profileRepositoryProvider.overrideWithValue(failingProfileRepo),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(onboardingProvider.notifier);
        notifier.setName('Ananya Sharma');
        notifier.setBranch('Computer Science & Engineering');
        notifier.setBatch('B26');
        notifier.setHostel('Ladies Hostel (LH - Main Block)');
        notifier.updateUsername('ananya');

        var completed = false;
        String? errorMessage;
        await notifier.runInitializationSequence(
          onComplete: () {
            completed = true;
          },
          onError: (String err) {
            errorMessage = err;
          },
        );

        expect(completed, isFalse);
        expect(errorMessage, contains('Database write failed'));
        expect(failingProfileRepo.onboardingCompleted, isNot(true));
        expect(
          container.read(onboardingProvider).loadingStatus,
          contains('Failed to complete profile setup'),
        );
      },
    );
  });
}
