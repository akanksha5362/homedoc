import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homedoc/features/ai_search/data/models/health_search_models.dart';
import 'package:homedoc/features/ai_search/presentation/providers/ai_health_search_provider.dart';
import 'package:homedoc/shared/providers/doctor_provider.dart';

void main() {
  group('AI Health Search Models', () {
    test('GroundingCitation parses and serializes correctly', () {
      final citation = GroundingCitation.fromJson(const {
        'title': 'Migraine Management Guidelines',
        'source': 'Mayo Clinic',
        'domain': 'mayoclinic.org',
        'snippet': 'Migraine symptoms involve sensory aura and vascular changes.',
      });

      expect(citation.source, 'Mayo Clinic');
      expect(citation.domain, 'mayoclinic.org');
      expect(citation.snippet, contains('sensory aura'));

      final json = citation.toJson();
      expect(json['source'], 'Mayo Clinic');
    });

    test('HealthSearchEducation parses complete payload', () {
      final edu = HealthSearchEducation.fromJson(const {
        'query': 'recurring headaches',
        'overview': 'Headaches can have various primary and secondary etiologies.',
        'potential_causes': ['Tension', 'Migraine', 'Dehydration'],
        'recommended_specialties': ['Neurologist', 'General Physician'],
        'warning_signs': ['Sudden thunderclap pain', 'Stiff neck'],
        'citations': [
          {
            'title': 'Headache Clinical Guidelines',
            'source': 'NHS UK',
            'domain': 'nhs.uk',
            'snippet': 'Evaluate recurrent headaches with red-flag checks.',
          }
        ],
        'disclaimer': 'Educational guidance only.',
      });

      expect(edu.query, 'recurring headaches');
      expect(edu.recommendedSpecialties, contains('Neurologist'));
      expect(edu.potentialCauses, hasLength(3));
      expect(edu.citations, hasLength(1));
      expect(edu.citations.first.source, 'NHS UK');
    });
  });

  group('HealthSearchNotifier', () {
    final fakeDoctors = [
      {
        'doctorId': 'doc_neuro_1',
        'displayName': 'Dr. Alok Verma',
        'specialization': 'Neurologist',
        'hospital': 'City Neurology Center',
        'experienceYears': 14,
        'consultationFee': 800,
        'isVerified': true,
      },
      {
        'doctorId': 'doc_derm_1',
        'displayName': 'Dr. Sunita Kapoor',
        'specialization': 'Dermatologist',
        'hospital': 'Skin & Aesthetic Clinic',
        'experienceYears': 8,
        'consultationFee': 600,
        'isVerified': true,
      },
    ];

    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          verifiedDoctorsProvider.overrideWith((ref) => Stream.value(fakeDoctors)),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('starts with empty state', () {
      final state = container.read(aiHealthSearchProvider);
      expect(state.query, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.education, isNull);
      expect(state.matchedDoctors, isEmpty);
    });

    test('searches headaches and matches Neurologist with medical citations', () async {
      await container.read(verifiedDoctorsProvider.future);
      final notifier = container.read(aiHealthSearchProvider.notifier);

      await notifier.search('I have recurring headaches and light sensitivity');

      final state = container.read(aiHealthSearchProvider);
      expect(state.isLoading, isFalse);
      expect(state.education, isNotNull);
      expect(state.education!.recommendedSpecialties, contains('Neurologist'));
      expect(state.education!.citations, isNotEmpty);
      expect(state.education!.citations.any((c) => c.source.contains('Mayo Clinic')), isTrue);

      // Verify doctor matching
      expect(state.matchedDoctors, isNotEmpty);
      expect(state.matchedDoctors.first['displayName'], 'Dr. Alok Verma');
      expect(state.matchedDoctors.first['relevanceReason'], contains('Neurologist'));
    });

    test('searches skin concerns and matches Dermatologist', () async {
      await container.read(verifiedDoctorsProvider.future);
      final notifier = container.read(aiHealthSearchProvider.notifier);

      await notifier.search('I have severe acne, pigmentation and redness');

      final state = container.read(aiHealthSearchProvider);
      expect(state.isLoading, isFalse);
      expect(state.education, isNotNull);
      expect(state.education!.recommendedSpecialties, contains('Dermatologist'));
      expect(state.matchedDoctors, isNotEmpty);
      expect(state.matchedDoctors.first['displayName'], 'Dr. Sunita Kapoor');
    });

    test('clear resets query and results to initial state', () async {
      final notifier = container.read(aiHealthSearchProvider.notifier);
      await notifier.search('headache');
      expect(container.read(aiHealthSearchProvider).education, isNotNull);

      notifier.clear();
      expect(container.read(aiHealthSearchProvider).query, isEmpty);
      expect(container.read(aiHealthSearchProvider).education, isNull);
    });
  });
}
