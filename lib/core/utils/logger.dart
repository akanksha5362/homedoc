import 'package:logger/logger.dart' as pkg;

/// Thin wrapper around `package:logger`, namespaced per-caller.
///
/// HARD RULE (Day 3 §21): never pass any of the following to these
/// methods — access tokens, passwords, medical record contents, payment
/// details, or any raw patient-identifying data. Log *that an action
/// happened*, not the sensitive payload itself, e.g.:
///   log.info('Prescription fetched'); // OK
///   log.info('Prescription: $prescription'); // NOT OK — never do this
class AppLogger {
  AppLogger(String tag) : _logger = pkg.Logger(printer: pkg.PrettyPrinter(methodCount: 0)), _tag = tag;

  final pkg.Logger _logger;
  final String _tag;

  void debug(String message) => _logger.d('[$_tag] $message');
  void info(String message) => _logger.i('[$_tag] $message');
  void warning(String message) => _logger.w('[$_tag] $message');
  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.e('[$_tag] $message', error: error, stackTrace: stackTrace);
}
