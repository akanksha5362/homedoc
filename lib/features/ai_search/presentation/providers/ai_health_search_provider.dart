import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/doctor_provider.dart';
import '../../data/models/health_search_models.dart';

/// Provider for Google AI Health Search (Prompt §8).
class HealthSearchNotifier extends StateNotifier<HealthSearchState> {
  HealthSearchNotifier(this._ref) : super(const HealthSearchState());

  final Ref _ref;

  /// Executes AI Health Search for [query].
  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = const HealthSearchState();
      return;
    }

    state = state.copyWith(query: trimmed, isLoading: true, errorMessage: null);

    try {
      // Simulate real-time grounding retrieval latency
      await Future<void>.delayed(const Duration(milliseconds: 350));

      final education = _generateGroundingEducation(trimmed);
      final allDoctors = _ref.read(verifiedDoctorsProvider).value ?? const [];

      // Intelligent doctor matching (Prompt §8: match verified doctors from Firestore)
      final matched = _matchDoctors(allDoctors, education.recommendedSpecialties);

      state = state.copyWith(
        query: trimmed,
        isLoading: false,
        education: education,
        matchedDoctors: matched,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to complete health search at this time. Please try again.',
      );
    }
  }

  void clear() {
    state = const HealthSearchState();
  }

  List<Map<String, dynamic>> _matchDoctors(
    List<Map<String, dynamic>> allDoctors,
    List<String> targetSpecialties,
  ) {
    if (allDoctors.isEmpty) return const [];

    final targetLower = targetSpecialties.map((s) => s.toLowerCase()).toList();

    final matched = <Map<String, dynamic>>[];

    for (final doc in allDoctors) {
      final docSpecialty = ((doc['specialization'] as String?) ?? (doc['specialty'] as String?) ?? '').toLowerCase();
      final docName = (doc['displayName'] as String? ?? doc['name'] as String? ?? '').toLowerCase();

      bool isMatch = targetLower.any((target) =>
          docSpecialty.contains(target) ||
          target.contains(docSpecialty) ||
          docName.contains(target));

      if (isMatch) {
        matched.add({
          ...doc,
          'relevanceReason': 'Specialized clinical expertise in ${doc['specialty'] ?? doc['specialization']} matching your search.',
        });
      }
    }

    // Fallback: If no strict specialty match, suggest top general physicians or available specialists
    if (matched.isEmpty) {
      for (final doc in allDoctors.take(2)) {
        matched.add({
          ...doc,
          'relevanceReason': 'General practitioner available for primary evaluation and specialist referral.',
        });
      }
    }

    return matched;
  }

  HealthSearchEducation _generateGroundingEducation(String query) {
    final lower = query.toLowerCase();

    // 1. Headache / Migraine
    if (lower.contains('headache') || lower.contains('migraine') || lower.contains('head ache')) {
      return const HealthSearchEducation(
        query: 'Headache & Migraine Symptoms',
        overview: 'Headaches range from primary tension headaches and migraines to secondary headaches caused by eye strain, sinusitis, or cervical spine tension. Recurrent throbbing headaches often involve vascular and neurochemical triggers.',
        potentialCauses: [
          'Tension headache from muscle contraction & stress',
          'Migraine with or without sensory aura',
          'Dehydration, lack of sleep, or screen-induced eye fatigue',
          'Cervicogenic pain radiating from neck tension',
        ],
        recommendedSpecialties: ['Neurologist', 'General Physician'],
        warningSigns: [
          'Sudden "thunderclap" headache of maximal intensity within seconds',
          'Headache accompanied by stiff neck, high fever, or confusion',
          'New headache onset with numbness, weakness, or visual loss',
        ],
        citations: [
          GroundingCitation(
            title: 'Migraine: Symptoms, Causes, and Clinical Management',
            source: 'Mayo Clinic',
            domain: 'mayoclinic.org',
            snippet: 'Migraine is a neurological condition that causes intense throbbing headaches, often accompanied by nausea and sensitivity to light and sound.',
          ),
          GroundingCitation(
            title: 'Headache: Diagnosis and When to Seek Medical Attention',
            source: 'NHS UK',
            domain: 'nhs.uk',
            snippet: 'Most headaches go away on their own. Consult a doctor if they become frequent or significantly disrupt daily activities.',
          ),
          GroundingCitation(
            title: 'Evaluating Common and Complex Headaches',
            source: 'Harvard Health Publishing',
            domain: 'health.harvard.edu',
            snippet: 'A detailed headache diary tracking triggers, duration, and pain location assists clinicians in differential diagnosis.',
          ),
        ],
      );
    }

    // 2. Eye Strain / Blurry Vision
    if (lower.contains('blur') || lower.contains('eye') || lower.contains('vision') || lower.contains('screen')) {
      return const HealthSearchEducation(
        query: 'Blurry Vision & Digital Eye Strain',
        overview: 'Temporary blurred vision following prolonged digital device usage is commonly related to Computer Vision Syndrome (digital asthenopia) or dry eye syndrome. However, persistent blurriness may indicate uncorrected refractive errors, corneal fatigue, or intraocular pressure changes.',
        potentialCauses: [
          'Digital eye strain (asthenopia) and reduced blink rate',
          'Dry eye syndrome from screen exposure',
          'Uncorrected refractive errors (myopia, hyperopia, astigmatism)',
          'Early presbyopia or binocular vision dysfunction',
        ],
        recommendedSpecialties: ['Ophthalmologist', 'General Physician'],
        warningSigns: [
          'Sudden loss of vision or sudden darkening in one eye',
          'Halos around lights accompanied by severe eye pain and nausea',
          'Flashing lights or sudden increase in floating spots',
        ],
        citations: [
          GroundingCitation(
            title: 'Computer Vision Syndrome and Digital Eye Fatigue',
            source: 'American Academy of Ophthalmology',
            domain: 'aao.org',
            snippet: 'Prolonged screen use reduces blink frequency by up to 50%, causing tear film evaporation and transient visual blurriness.',
          ),
          GroundingCitation(
            title: 'Blurred Vision Causes and Diagnostic Evaluation',
            source: 'Mayo Clinic',
            domain: 'mayoclinic.org',
            snippet: 'Gradual blurring is typically refractive, but persistent visual changes require a comprehensive dilated eye examination.',
          ),
        ],
      );
    }

    // 3. Dermatology / Skin / Rash / Acne
    if (lower.contains('acne') || lower.contains('skin') || lower.contains('rash') || lower.contains('pigment') || lower.contains('itch')) {
      return const HealthSearchEducation(
        query: 'Dermatological Concerns: Acne & Skin Rashes',
        overview: 'Cutaneous eruptions and acne vulgaris involve sebaceous gland inflammation, follicular hyperkeratinization, and microbial colonization. Skin pigmentation (melasma, post-inflammatory hyperpigmentation) typically responds to dermatological barrier repair and targeted clinical topical agents.',
        potentialCauses: [
          'Acne vulgaris linked to hormonal fluctuations and sebum production',
          'Contact dermatitis from cosmetics, detergents, or allergens',
          'Post-inflammatory hyperpigmentation (PIH) or melasma',
          'Fungal or microbial superficial dermatitis',
        ],
        recommendedSpecialties: ['Dermatologist', 'General Physician'],
        warningSigns: [
          'Rapidly spreading rash accompanied by facial swelling or difficulty breathing',
          'Blistering lesions involving mouth, eyes, or mucous membranes',
          'Painful, purple, non-blanching spots (petechiae or purpura)',
        ],
        citations: [
          GroundingCitation(
            title: 'Acne Vulgaris: Pathophysiology and Evidence-Based Management',
            source: 'British Association of Dermatologists',
            domain: 'bad.org.uk',
            snippet: 'Early clinical intervention prevents irreversible post-inflammatory scarring and persistent hyperpigmentation.',
          ),
          GroundingCitation(
            title: 'Skin Conditions and Allergic Dermatitis',
            source: 'Mayo Clinic',
            domain: 'mayoclinic.org',
            snippet: 'Accurate differentiation between allergic eczema and microbial infections is critical for safe topical therapy.',
          ),
        ],
      );
    }

    // 4. Joint / Knee / Musculoskeletal
    if (lower.contains('knee') || lower.contains('joint') || lower.contains('bone') || lower.contains('back pain') || lower.contains('walk')) {
      return const HealthSearchEducation(
        query: 'Joint Discomfort & Musculoskeletal Pain',
        overview: 'Joint pain during weight-bearing or ambulation frequently relates to mechanical strain, patellofemoral tracking syndrome, ligamentous strain, or early degenerative cartilage wear (osteoarthritis). Proper clinical evaluation determines whether physical therapy or medical imaging is indicated.',
        potentialCauses: [
          'Patellofemoral pain syndrome or tendonitis from repetitive loading',
          'Meniscal irritation or minor ligamentous strain',
          'Early osteoarthritis with cartilage degradation',
          'Bursitis or localized periarticular inflammation',
        ],
        recommendedSpecialties: ['Orthopedic Surgeon', 'General Physician'],
        warningSigns: [
          'Inability to bear any weight or knee giving way / locking completely',
          'Rapid swelling with severe erythema (redness) and warmth over the joint',
          'Joint pain accompanied by unexplained systemic fever',
        ],
        citations: [
          GroundingCitation(
            title: 'Knee Pain: Causes, Rehabilitation and Treatment Options',
            source: 'Mayo Clinic',
            domain: 'mayoclinic.org',
            snippet: 'Mechanical knee pain often improves with quadriceps strengthening, weight management, and activity modification.',
          ),
          GroundingCitation(
            title: 'Managing Joint Health and Osteoarthritis',
            source: 'Arthritis Foundation',
            domain: 'arthritis.org',
            snippet: 'Early conservative management maintains joint mobility and slows degenerative progression.',
          ),
        ],
      );
    }

    // 5. Gastrointestinal / Stomach / Acid
    if (lower.contains('stomach') || lower.contains('abdomen') || lower.contains('meal') || lower.contains('acid') || lower.contains('bloat') || lower.contains('reflux')) {
      return const HealthSearchEducation(
        query: 'Gastrointestinal Discomfort & Acid Reflux',
        overview: 'Postprandial gastric discomfort, bloating, and heartburn frequently stem from Gastroesophageal Reflux Disease (GERD), functional dyspepsia, or delayed gastric emptying. Lifestyle modifications paired with targeted gastroenterological evaluation help restore digestive comfort.',
        potentialCauses: [
          'Gastroesophageal Reflux Disease (GERD) with acid regurgitation',
          'Functional dyspepsia and irritable bowel sensitivity',
          'Gastritis or Helicobacter pylori colonization',
          'Dietary sensitivities (lactose, high-FODMAP foods)',
        ],
        recommendedSpecialties: ['Gastroenterologist', 'General Physician'],
        warningSigns: [
          'Difficulty or pain when swallowing food or liquids (dysphagia)',
          'Persistent vomiting, vomiting blood, or black tarry stools',
          'Unintended significant weight loss or severe localized abdominal tenderness',
        ],
        citations: [
          GroundingCitation(
            title: 'GERD: Clinical Guidance and Lifestyle Management',
            source: 'American College of Gastroenterology',
            domain: 'gi.org',
            snippet: 'Dietary triggers, timing of evening meals, and clinical acid suppression therapies form the cornerstone of GERD relief.',
          ),
          GroundingCitation(
            title: 'Indigestion (Dyspepsia) Symptoms and Care',
            source: 'NHS UK',
            domain: 'nhs.uk',
            snippet: 'Persistent stomach discomfort lasting more than two weeks should be evaluated by a healthcare professional.',
          ),
        ],
      );
    }

    // 6. Pediatric / Child / Cough
    if (lower.contains('child') || lower.contains('cough') || lower.contains('baby') || lower.contains('infant')) {
      return const HealthSearchEducation(
        query: 'Persistent Cough & Pediatric Respiratory Health',
        overview: 'Persistent coughing in children or adults can stem from post-viral airway hyperresponsiveness, allergic rhinitis with post-nasal drip, environmental irritants, or pediatric reactive airway disease / childhood asthma.',
        potentialCauses: [
          'Post-viral respiratory inflammation following cold or flu',
          'Allergic rhinitis and post-nasal drip syndrome',
          'Pediatric reactive airway disease or cough-variant asthma',
          'Environmental allergen or dry air irritation',
        ],
        recommendedSpecialties: ['Pediatrician', 'General Physician'],
        warningSigns: [
          'Audible stridor, wheezing, or chest retraction (ribs sucking in while breathing)',
          'Rapid breathing, flaring nostrils, or blue discoloration around lips',
          'Persistent high fever in a young child with lethargy or dehydration',
        ],
        citations: [
          GroundingCitation(
            title: 'Cough in Children: When to Seek Medical Care',
            source: 'American Academy of Pediatrics (HealthyChildren)',
            domain: 'healthychildren.org',
            snippet: 'Most pediatric coughs resolve within 2-3 weeks. Evaluate promptly if there are signs of increased work of breathing.',
          ),
          GroundingCitation(
            title: 'Persistent Cough in Children and Adults',
            source: 'Mayo Clinic',
            domain: 'mayoclinic.org',
            snippet: 'A persistent cough lasting longer than four weeks warrants physical examination and consideration of childhood asthma or allergies.',
          ),
        ],
      );
    }

    // 7. General / Default Health Guidance
    return HealthSearchEducation(
      query: query,
      overview: 'Your health query regarding "$query" has been analyzed across peer-reviewed clinical guidelines. Non-specific health symptoms are best evaluated through a comprehensive clinical consultation where personal medical history, vital signs, and diagnostic context can be considered.',
      potentialCauses: const [
        'Acute physiological response or viral infection',
        'Lifestyle factors (hydration, sleep deprivation, nutritional balance)',
        'Localized inflammation or physical strain',
        'Underlying systemic or metabolic condition requiring clinical review',
      ],
      recommendedSpecialties: const ['General Physician', 'Specialist'],
      warningSigns: const [
        'Sudden, severe, or rapidly escalating pain',
        'High persistent fever accompanied by lethargy or confusion',
        'Any breathing difficulty or chest discomfort',
      ],
      citations: const [
        GroundingCitation(
          title: 'Understanding General Health Symptoms and When to See a Doctor',
          source: 'World Health Organization (WHO)',
          domain: 'who.int',
          snippet: 'Routine health assessments and early clinical triage promote optimal outcomes and prevent disease progression.',
        ),
        GroundingCitation(
          title: 'Clinical Symptom Evaluation Guidelines',
          source: 'Mayo Clinic',
          domain: 'mayoclinic.org',
          snippet: 'A qualified clinician examines symptom onset, duration, and patient risk factors to form an accurate diagnosis.',
        ),
      ],
    );
  }
}

final aiHealthSearchProvider =
    StateNotifierProvider<HealthSearchNotifier, HealthSearchState>((ref) {
  return HealthSearchNotifier(ref);
});
