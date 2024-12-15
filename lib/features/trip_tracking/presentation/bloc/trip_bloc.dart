import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/trip.dart';
import '../../data/models/monument.dart';
import '../../data/services/location_service.dart';
import 'trip_event.dart';
import 'trip_state.dart';

class TripBloc extends Bloc<TripEvent, TripState> {
  final LocationService _locationService;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<Monument>? _monumentSubscription;
  Timer? _idleTimer;
  Timer? _displayTimer;
  int _idleCounter = 0;
  final _uuid = const Uuid();

  TripBloc({required LocationService locationService})
      : _locationService = locationService,
        super(const TripState()) {
    on<StartTrip>(_onStartTrip);
    on<EndTrip>(_onEndTrip);
    on<UpdateTripDetails>(_onUpdateTripDetails);
    on<MonumentReached>(_onMonumentReached);
    on<LocationUpdated>(_onLocationUpdated);
    on<IdleTimeout>(_onIdleTimeout);
    on<LoadPastTrips>(_onLoadPastTrips);
    on<ResetTripState>(_onResetTripState); 

    _initializeLocationTracking();
  }

  Future<void> _initializeLocationTracking() async {
    final hasPermission = await _locationService.requestLocationPermission();
    if (!hasPermission) {
      emit(state.copyWith(error: 'Location permission denied'));
      return;
    }

    _locationSubscription = _locationService.locationStream.listen(
      (position) {
        add(LocationUpdated(LatLng(position.latitude, position.longitude)));
      },
    );

    _monumentSubscription = _locationService.monumentStream.listen(
      (monument) {
        if (state.currentLocation != null) {
          add(MonumentReached(
            monument: monument,
            location: state.currentLocation!,
          ));
        }
      },
    );

    _locationService.startLocationTracking();
  }

  

  Future<void> _onStartTrip(
    StartTrip event,
    Emitter<TripState> emit,
  ) async {
    if (state.currentTrip != null) {
      emit(state.copyWith(error: 'A trip is already in progress'));
      return;
    }

    final trip = Trip(
      id: _uuid.v4(),
      userId: event.userId,
      startTime: DateTime.now(),
      startMonumentId: event.startMonument.id,
      checkpoints: [],
    );

    emit(state.copyWith(
      currentTrip: trip,
      isTracking: true,
      error: null,
    ));
  }

 Future<void> _onEndTrip(
    EndTrip event,
    Emitter<TripState> emit,
  ) async {
    if (state.currentTrip == null) {
      emit(state.copyWith(error: 'No active trip to end'));
      return;
    }

    try {
      emit(state.copyWith(isLoading: true, error: null));

      // Get the current trip with all its details
      final currentTrip = state.currentTrip!;
      final endedTrip = currentTrip.copyWith(
        endTime: DateTime.now(),
        endMonumentId: event.endMonument.id,
        isActive: false,
      );

      // Simulate saving trip to a database (adjust as per your backend)
      await Future.delayed(const Duration(milliseconds: 500));
      // TODO: Replace with actual save logic (e.g., API call)

      // Add the completed trip to the pastTrips list
      emit(state.copyWith(
        currentTrip: null,
        pastTrips: [...state.pastTrips, endedTrip],
        isTracking: false,
        isLoading: false,
      ));

      // Automatically reset the trip state after completing the trip
      add(ResetTripState());
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

Future<void> _onResetTripState(
  ResetTripState event,
  Emitter<TripState> emit,
) async {
  // Reset trip-related state while preserving current location
  emit(state.copyWith(
    currentTrip: null,
    isTracking: false,
    error: null,
    isLoading: false,
    currentLocation: state.currentLocation,
  ));
}


  Future<void> _onUpdateTripDetails(
    UpdateTripDetails event,
    Emitter<TripState> emit,
  ) async {
    if (state.currentTrip == null) {
      emit(state.copyWith(error: 'No active trip to update'));
      return;
    }

    final updatedTrip = state.currentTrip!.copyWith(
      vehicleType: event.vehicleType,
      purpose: event.purpose,
      occupancy: event.occupancy,
    );

    emit(state.copyWith(
      currentTrip: updatedTrip,
      error: null,
    ));
  }

  Future<void> _onMonumentReached(
    MonumentReached event,
    Emitter<TripState> emit,
  ) async {
    if (state.currentTrip == null) return;

    final checkpoint = TripCheckpoint(
      monumentId: event.monument.id,
      timestamp: DateTime.now(),
      latitude: event.location.latitude,
      longitude: event.location.longitude,
    );

    final updatedTrip = state.currentTrip!.copyWith(
      checkpoints: [...state.currentTrip!.checkpoints, checkpoint],
    );

    emit(state.copyWith(
      currentTrip: updatedTrip,
      error: null,
    ));
  }

  Future<void> _onLocationUpdated(
    LocationUpdated event,
    Emitter<TripState> emit,
  ) async {
    emit(state.copyWith(
      currentLocation: event.location,
      error: null,
    ));
  }

  Future<void> _onIdleTimeout(
    IdleTimeout event,
    Emitter<TripState> emit,
  ) async {
    if (state.currentTrip != null) {
      // Auto-end the trip if it's been idle for too long
      final lastCheckpoint = state.currentTrip!.checkpoints.lastOrNull;
      if (lastCheckpoint != null) {
        add(EndTrip(
          endMonument: sampleMonuments.firstWhere(
            (m) => m.id == lastCheckpoint.monumentId,
          ),
        ));
      }
    }
  }

  Future<void> _onLoadPastTrips(
    LoadPastTrips event,
    Emitter<TripState> emit,
  ) async {
    // TODO: Implement loading past trips from storage
    emit(state.copyWith(
      pastTrips: [], // Load from storage
      error: null,
    ));
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    _monumentSubscription?.cancel();
    _locationService.dispose();
    return super.close();
  }
}
