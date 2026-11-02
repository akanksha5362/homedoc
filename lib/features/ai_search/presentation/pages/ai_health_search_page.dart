import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../data/models/health_search_models.dart';
import '../providers/ai_health_search_provider.dart';

/// Google AI Health Search Screen (Master Prompt §8).
///
/// Enables patients to explore health concerns in natural language,
/// view medical-literature grounded educational summaries with real citations,
/// and connect directly with verified matching specialists from HomeDoc.
class AiHealthSearchPage extends ConsumerStatefulWidget {
  const AiHealthSearchPage({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<AiHealthSearchPage> createState() => _AiHealthSearchPageState();
}

class _AiHealthSearchPageState extends ConsumerState<AiHealthSearchPage> {
  final TextEditingController _searchController = TextEditingController();

  static const Color primaryTeal = Color(0xFF007A8A);
  static const Color lightTealSurface = Color(0xFFE6F7F6);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);

  final List<_PopularTopic> _popularTopics = const [
    _PopularTopic(
      query: 'I have recurring headaches and migraine',
      label: 'Headache & Migraine',
      icon: Icons.psychology_alt_outlined,
    ),
    _PopularTopic(
      query: 'My eyes become blurry after screen usage',
      label: 'Screen Eye Strain',
      icon: Icons.remove_red_eye_outlined,
    ),
    _PopularTopic(
      query: 'I have acne and pigmentation',
      label: 'Acne & Skin Pigmentation',
      icon: Icons.face_retouching_natural_outlined,
    ),
    _PopularTopic(
      query: 'I have knee pain when walking',
      label: 'Knee Joint Discomfort',
      icon: Icons.directions_walk_outlined,
    ),
    _PopularTopic(
      query: 'I have stomach discomfort after meals',
      label: 'Stomach Acid & Reflux',
      icon: Icons.restaurant_outlined,
    ),
    _PopularTopic(
      query: 'My child has a persistent cough',
      label: 'Pediatric Cough',
      icon: Icons.child_care_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(aiHealthSearchProvider.notifier).search(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;
    ref.read(aiHealthSearchProvider.notifier).search(query);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(aiHealthSearchProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: primaryTeal, size: 20),
            SizedBox(width: 8),
            Text(
              'AI Health Search',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: textMuted),
            tooltip: 'About Search Grounding',
            onPressed: () => _showGroundingInfoDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar Box
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _onSearchSubmitted,
                      decoration: InputDecoration(
                        hintText: 'Search health concerns (e.g. blurry eyes, acne, knee pain)...',
                        hintStyle: const TextStyle(fontSize: 13, color: textMuted),
                        prefixIcon: const Icon(Icons.search_rounded, color: primaryTeal, size: 22),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: textMuted),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(aiHealthSearchProvider.notifier).clear();
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_rounded, color: primaryTeal, size: 20),
                              onPressed: () => _onSearchSubmitted(_searchController.text),
                            ),
                          ],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.verified_outlined, color: Color(0xFF0284C7), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Google Grounded with peer-reviewed medical sources',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Main Body Content
            Expanded(
              child: searchState.isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: primaryTeal, strokeWidth: 2.5),
                          SizedBox(height: 16),
                          Text(
                            'Synthesizing medical literature & doctor matches…',
                            style: TextStyle(color: textMuted, fontSize: 13.5),
                          ),
                        ],
                      ),
                    )
                  : searchState.education != null
                      ? _buildSearchResults(context, searchState)
                      : _buildInitialView(context),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INITIAL VIEW: POPULAR TOPICS & GUIDANCE
  // ---------------------------------------------------------------------------
  Widget _buildInitialView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informational Welcome Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE6F7F6),
                  Colors.teal.shade50.withValues(alpha: 0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryTeal.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.saved_search_rounded, color: primaryTeal, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore Health Concerns',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Describe symptoms in plain language to get grounded medical guidance and book verified specialists.',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF4B5563), height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Common Search Queries Section
          const Text(
            'Common Health Queries',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final topic in _popularTopics)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    _searchController.text = topic.query;
                    _onSearchSubmitted(topic.query);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(topic.icon, size: 16, color: primaryTeal),
                        const SizedBox(width: 8),
                        Text(
                          topic.label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),

          // Search Grounding Source Credibility Notice
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined, color: primaryTeal, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verified Medical Grounding',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Results cite established clinical authorities including the Mayo Clinic, NHS, AAP, and WHO to ensure educational reliability.',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACTIVE SEARCH RESULTS
  // ---------------------------------------------------------------------------
  Widget _buildSearchResults(BuildContext context, HealthSearchState state) {
    final edu = state.education!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Recommended Medical Specialty Chip Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: lightTealSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryTeal.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.medical_information_rounded, color: primaryTeal, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RECOMMENDED SPECIALTY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: primaryTeal,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        edu.recommendedSpecialties.join(' • '),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Grounded Overview Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_stories_outlined, color: Color(0xFF2563EB), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Clinical Educational Overview',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Grounded',
                        style: TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  edu.overview,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF374151),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),

                // Potential Causes
                const Text(
                  'Potential Causes Indicated in Medical Literature:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textDark),
                ),
                const SizedBox(height: 8),
                for (final cause in edu.potentialCauses)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            cause,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Grounding Sources & Citations
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.source_outlined, color: Color(0xFF059669), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Source Citations & Medical References',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textDark),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (final citation in edu.citations)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                citation.source,
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: textDark),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              citation.domain,
                              style: const TextStyle(fontSize: 11, color: textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          citation.title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '"${citation.snippet}"',
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF4B5563)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Warning Signs / Red Flags
          if (edu.warningSigns.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'When to Seek Prompt Medical Attention',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final sign in edu.warningSigns)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              sign,
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF78350F)),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 5. Matched Verified Doctors (Intelligent Doctor Matching — Prompt §8)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Matching Doctors Near You',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              Text(
                '${state.matchedDoctors.length} found',
                style: const TextStyle(color: textMuted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (state.matchedDoctors.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder),
              ),
              child: const Center(
                child: Text(
                  'No verified doctors currently matched for this specialty.',
                  style: TextStyle(fontSize: 13, color: textMuted),
                ),
              ),
            )
          else
            for (final doc in state.matchedDoctors)
              _buildDoctorCard(context, doc),
          const SizedBox(height: 20),

          // 6. Clinical Disclaimer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: textMuted, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    edu.disclaimer,
                    style: const TextStyle(fontSize: 11.5, color: textMuted, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, Map<String, dynamic> doc) {
    final name = doc['displayName'] as String? ?? doc['name'] as String? ?? 'Doctor';
    final specialty = doc['specialization'] as String? ?? doc['specialty'] as String? ?? 'Specialist';
    final hospital = doc['hospital'] as String? ?? 'General Medical Care';
    final fee = (doc['consultationFee'] as num?) ?? 500;
    final exp = (doc['experienceYears'] as num?) ?? 0;
    final doctorId = doc['doctorId'] as String? ?? '';
    final relevance = doc['relevanceReason'] as String? ?? 'Matched specialty for your condition.';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: lightTealSurface,
                foregroundColor: primaryTeal,
                child: Icon(Icons.person, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, color: primaryTeal, size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$specialty • $hospital',
                      style: const TextStyle(fontSize: 12.5, color: textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${exp}y exp • ₹$fee consultation',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryTeal),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Relevance note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded, size: 14, color: Color(0xFF0284C7)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    relevance,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Book Appointment CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              icon: const Icon(Icons.calendar_month_rounded, size: 16),
              label: const Text('Book Consultation', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              onPressed: () {
                context.push(
                  '${RoutePaths.patientBookAppointment}?doctorId=$doctorId',
                  extra: doc,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showGroundingInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: primaryTeal),
            SizedBox(width: 8),
            Text('About AI Health Search'),
          ],
        ),
        content: const Text(
          'AI Health Search uses Google Search Grounding to evaluate natural-language symptoms against verified medical literature (Mayo Clinic, NHS, Harvard Health, WHO).\n\nIt is designed for patient health education and specialist discovery, and does not serve as an emergency triage system or substitute for clinical examination.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _PopularTopic {
  const _PopularTopic({
    required this.query,
    required this.label,
    required this.icon,
  });

  final String query;
  final String label;
  final IconData icon;
}
