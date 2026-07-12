import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  return ConnectivityNotifier();
});

class ConnectivityState {
  final bool isConnected;
  final ConnectivityResult? connectionType;

  const ConnectivityState({
    this.isConnected = true,
    this.connectionType,
  });

  ConnectivityState copyWith({
    bool? isConnected,
    ConnectivityResult? connectionType,
  }) {
    return ConnectivityState(
      isConnected: isConnected ?? this.isConnected,
      connectionType: connectionType ?? this.connectionType,
    );
  }
}

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  final Connectivity _connectivity;
  
  ConnectivityNotifier()
      : _connectivity = Connectivity(),
        super(const ConnectivityState()) {
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionState(results);
    
    _connectivity.onConnectivityChanged.listen(_updateConnectionState);
  }

  void _updateConnectionState(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      state = const ConnectivityState(isConnected: false);
      return;
    }

    final result = results.first;
    state = ConnectivityState(
      isConnected: result != ConnectivityResult.none,
      connectionType: result,
    );
  }

  Future<bool> checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionState(results);
    return state.isConnected;
  }
}
