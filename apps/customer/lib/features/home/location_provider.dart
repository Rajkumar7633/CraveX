import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});

class LocationState {
  final bool isLoading;
  final bool hasPermission;
  final Position? currentPosition;
  final String? errorMessage;
  final String? address;

  const LocationState({
    this.isLoading = false,
    this.hasPermission = false,
    this.currentPosition,
    this.errorMessage,
    this.address,
  });

  LocationState copyWith({
    bool? isLoading,
    bool? hasPermission,
    Position? currentPosition,
    String? errorMessage,
    String? address,
  }) {
    return LocationState(
      isLoading: isLoading ?? this.isLoading,
      hasPermission: hasPermission ?? this.hasPermission,
      currentPosition: currentPosition ?? this.currentPosition,
      errorMessage: errorMessage,
      address: address ?? this.address,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(const LocationState());

  Future<bool> requestLocationPermission() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final status = await Permission.location.request();
      
      if (status.isGranted) {
        state = state.copyWith(hasPermission: true, isLoading: false);
        await getCurrentLocation();
        return true;
      } else if (status.isDenied) {
        state = state.copyWith(
          hasPermission: false,
          isLoading: false,
          errorMessage: 'Location permission denied',
        );
        return false;
      } else if (status.isPermanentlyDenied) {
        state = state.copyWith(
          hasPermission: false,
          isLoading: false,
          errorMessage: 'Location permission permanently denied. Please enable in settings.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to request location permission: $e',
      );
    }
    
    return false;
  }

  Future<void> getCurrentLocation() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      state = state.copyWith(
        currentPosition: position,
        isLoading: false,
      );
      
      // Get address from coordinates (implement geocoding if needed)
      // await _getAddressFromCoordinates(position);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to get location: $e',
      );
    }
  }

  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
