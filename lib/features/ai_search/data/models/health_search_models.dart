import 'package:equatable/equatable.dart';

/// A verified medical literature source citation (Prompt §8: Google Search Grounding).
class GroundingCitation extends Equatable {
  const GroundingCitation({
    required this.title,
    required this.source,
    required this.domain,
    required this.snippet,
  });

  final String title;
  final String source;
  final String domain;
  final String snippet;

  factory GroundingCitation.fromJson(Map<String, dynamic> json) => GroundingCitation(
        title: json['title'] as String? ?? 'Medical Resource',
        source: json['source'] as String? ?? 'Clinical Reference',
        domain: json['domain'] as String? ?? 'health.gov',
        snippet: json['snippet'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'source': source,
        'domain': domain,
        'snippet': snippet,
      };

  @override
  List<Object?> get props => [title, source, domain, snippet];
}

/// Concise educational health summary grounded in medical sources.
class HealthSearchEducation extends Equatable {
  const HealthSearchEducation({
    required this.query,
    required this.overview,
    required this.potentialCauses,
    required this.recommendedSpecialties,
    required this.warningSigns,
    required this.citations,
    this.disclaimer = 'Source-grounded educational information. Not a medical diagnosis or treatment prescription.',
  });

  final String query;
  final String overview;
  final List<String> potentialCauses;
  final List<String> recommendedSpecialties;
  final List<String> warningSigns;
  final List<GroundingCitation> citations;
  final String disclaimer;

  factory HealthSearchEducation.fromJson(Map<String, dynamic> json) => HealthSearchEducation(
        query: json['query'] as String? ?? '',
        overview: json['overview'] as String? ?? '',
        potentialCauses: (json['potential_causes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        recommendedSpecialties:
            (json['recommended_specialties'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        warningSigns: (json['warning_signs'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        citations: (json['citations'] as List<dynamic>?)
                ?.map((e) => GroundingCitation.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        disclaimer: json['disclaimer'] as String? ??
            'Source-grounded educational information. Not a medical diagnosis or treatment prescription.',
      );

  @override
  List<Object?> get props => [
        query,
        overview,
        potentialCauses,
        recommendedSpecialties,
        warningSigns,
        citations,
        disclaimer,
      ];
}

/// State of an AI Health Search query.
class HealthSearchState extends Equatable {
  const HealthSearchState({
    this.query = '',
    this.isLoading = false,
    this.education,
    this.matchedDoctors = const [],
    this.errorMessage,
  });

  final String query;
  final bool isLoading;
  final HealthSearchEducation? education;
  final List<Map<String, dynamic>> matchedDoctors;
  final String? errorMessage;

  HealthSearchState copyWith({
    String? query,
    bool? isLoading,
    HealthSearchEducation? education,
    List<Map<String, dynamic>>? matchedDoctors,
    String? errorMessage,
  }) {
    return HealthSearchState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      education: education ?? this.education,
      matchedDoctors: matchedDoctors ?? this.matchedDoctors,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [query, isLoading, education, matchedDoctors, errorMessage];
}
