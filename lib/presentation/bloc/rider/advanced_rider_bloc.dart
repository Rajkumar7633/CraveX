import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zomato_clone/domain/entities/rider.dart';
import 'package:zomato_clone/domain/repositories/rider_repository.dart';

// Advanced Rider BLoC with real-time location tracking and assignment
part 'advanced_rider_bloc_event.dart';
part 'advanced_rider_bloc_state.dart';

class AdvancedRiderBloc extends Bloc<AdvancedRiderEvent, AdvancedRiderState> {
  final RiderRepository riderRepository;

  AdvancedRiderBloc(this.riderRepository) : super(const AdvancedRiderInitial()) {
    on<GetRiderLocation>(_onGetRiderLocation);
    on<UpdateRiderLocation>(_onUpdateRiderLocation);
    on<AssignBestRider>(_onAssignBestRider);
    on<TrackRider>(_onTrackRider);
    on<GetRiderEarnings>(_onGetRiderEarnings);
    on<HandleRiderRejection>(_onHandleRiderRejection);
  }

  Future<void> _onGetRiderLocation(
    GetRiderLocation event,
    Emitter<AdvancedRiderState> emit,
  ) async {
    try {
      final location = await riderRepository.getRiderLocation(event.riderId);
      emit(AdvancedRiderLocationLoaded(location));
    } catch (e) {
      emit(AdvancedRiderError(e.toString()));
    }
  }

  Future<void> _onUpdateRiderLocation(
    UpdateRiderLocation event,
    Emitter<AdvancedRiderState> emit,
  ) async {
    try {
      await riderRepository.updateRiderLocation(
        event.riderId,
        event.latitude,
        event.longitude,
      );
      emit(const AdvancedRiderLocationUpdated());
    } catch (e) {
      emit(AdvancedRiderError(e.toString()));
    }
  }

  Future<void> _onAssignBestRider(
    AssignBestRider event,
    Emitter<AdvancedRiderState> emit,
  ) async {
    emit(const AdvancedRiderLoading());
    try {
      final assignment = await riderRepository.assignBestRider(
        event.orderId,
        event.restaurantLat,
        event.restaurantLng,
        event.customerLat,
        event.customerLng,
      );
      emit(AdvancedRiderAssigned(assignment));
    } catch (e) {
      emit(AdvancedRiderError(e.toString()));
    }
  }

  Future<void> _onTrackRider(
    TrackRider event,
    Emitter<AdvancedRiderState> emit,
  ) async {
    try {
      final location = await riderRepository.getRiderLocation(event.riderId);
      emit(AdvancedRiderTracking(location));
    } catch (e) {
      emit(AdvancedRiderError(e.toString()));
    }
  }

  Future<void> _onGetRiderEarnings(
    GetRiderEarnings event,
    Emitter<AdvancedRiderState> emit,
  ) async {
    try {
      final earnings = await riderRepository.getRiderEarnings(
        event.riderId,
        event.startDate,
        event.endDate,
      );
      emit(AdvancedRiderEarningsLoaded(earnings));
    } catch (e) {
      emit(AdvancedRiderError(e.toString()));
    }
  }

  Future<void> _onHandleRiderRejection(
    HandleRiderRejection event,
    Emitter<AdvancedRiderState> emit,
  ) async {
    try {
      await riderRepository.handleRiderRejection(event.riderId, event.orderId);
      emit(const AdvancedRiderRejectionHandled());
    } catch (e) {
      emit(AdvancedRiderError(e.toString()));
    }
  }
}
