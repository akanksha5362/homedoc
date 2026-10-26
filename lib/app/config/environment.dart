/// The three environments required by Day 3, Section 7.
enum Environment { development, staging, production }

/// Currently active environment. Set via `--dart-define=ENV=production`
/// at build time (see README "Running development" section) — never
/// hardcode a single environment as the default for release builds.
Environment environmentFromString(String value) {
  switch (value.toLowerCase()) {
    case 'production':
    case 'prod':
      return Environment.production;
    case 'staging':
      return Environment.staging;
    case 'development':
    case 'dev':
    default:
      return Environment.development;
  }
}
