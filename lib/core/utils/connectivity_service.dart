import 'package:connectivity_plus/connectivity_plus.dart';

/// Coarse connectivity state (Day 3 §20). This intentionally does NOT try
/// to distinguish "poor connection" from "online" via a full latency-probe
/// system at foundation stage — that's a real feature to design later
/// (e.g. surfaced through the API client's timeout behavior instead). This
/// class answers the simpler, foundational question: is there a network
/// interface at all.
enum ConnectivityState { online, offline }

class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<ConnectivityState> current() async {
    final results = await _connectivity.checkConnectivity();
    return _mapResults(results);
  }

  Stream<ConnectivityState> get onChange =>
      _connectivity.onConnectivityChanged.map(_mapResults);

  ConnectivityState _mapResults(List<ConnectivityResult> results) {
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    return hasConnection ? ConnectivityState.online : ConnectivityState.offline;
  }
}
