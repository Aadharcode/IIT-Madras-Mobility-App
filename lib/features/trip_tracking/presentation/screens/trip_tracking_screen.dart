import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/monument.dart';
import '../bloc/trip_bloc.dart';
import '../bloc/trip_event.dart';
import '../bloc/trip_state.dart';
import '../widgets/trip_details_form.dart';
import 'trip_history_screen.dart';

class TripTrackingScreen extends StatefulWidget {
  final String userId;

  const TripTrackingScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen> {
  GoogleMapController? _mapController;
  final Set<Circle> _monumentZones = {};
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeMonuments();
  }

  void _initializeMonuments() async {
  for (final monument in sampleMonuments) {
    final marker = Marker(
      markerId: MarkerId(monument.id),
      position: monument.position,
      infoWindow: InfoWindow(
        title: monument.name,
        snippet: 'Radius: ${monument.radius.toStringAsFixed(1)}m', // Add more details here
      ),
      // icon: await BitmapDescriptor.fromAssetImage(
      //   const ImageConfiguration(size: Size(48, 48)),
      //   'assets/icons/monument_marker.png', // Use a custom marker icon
      // ),
      onTap: () {
        _mapController?.showMarkerInfoWindow(MarkerId(monument.id));
      },
    );
    _markers.add(marker);

    // Add corresponding circle for the monument zone
    _monumentZones.add(
      Circle(
        circleId: CircleId(monument.id),
        center: monument.position,
        radius: monument.radius,
        fillColor: Colors.blue.withOpacity(0.15),
        strokeColor: Colors.blue.withOpacity(0.5),
        strokeWidth: 2,
      ),
    );
  }
  setState(() {}); // Refresh UI to display the updated markers and circles
}


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<TripBloc, TripState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }

        if (state.currentLocation != null && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(state.currentLocation!),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(12.991214, 80.233276),
                  zoom: 15,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,
                circles: _monumentZones,
                markers: _markers,
                mapType: MapType.normal,
                onMapCreated: (controller) {
                  _mapController = controller;
                  controller.setMapStyle('''[
                      {
                        "featureType": "poi",
                        "elementType": "labels",
                        "stylers": [{"visibility": "off"}]
                      }
                    ]''');
                },
              ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(theme, state),
                    const Spacer(),
                    if (state.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (!state.isTracking && state.currentTrip == null)
                    const Center(child: Text('No trip selected')),
                      _buildStartTripButton(theme),
                  ],
                ),
              ),
              _buildFloatingButtons(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, TripState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildHistoryButton(theme),
          ),
          if (state.currentTrip != null) ...[
            const SizedBox(width: 16),
            _buildStopButton(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryButton(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TripHistoryScreen(userId: widget.userId),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.history, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text('Trip History', style: theme.textTheme.titleMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStopButton(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.error.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTripEndDialog(context),
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.stop_rounded, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildStartTripButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () => _showTripStartDialog(context),
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Start Trip'),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFloatingButtons(TripState state) {
    return Positioned(
      right: 16,
      bottom: state.isTracking || state.currentTrip != null ? 16 : 100,
      child: Column(
        children: [
          _buildMapControlButton(Icons.my_location, () {
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(
                state.currentLocation ?? const LatLng(12.991214, 80.233276),
              ),
            );
          }),
          const SizedBox(height: 8),
          _buildMapControlButton(Icons.add, () {
            _mapController?.animateCamera(CameraUpdate.zoomIn());
          }),
          const SizedBox(height: 8),
          _buildMapControlButton(Icons.remove, () {
            _mapController?.animateCamera(CameraUpdate.zoomOut());
          }),
        ],
      ),
    );
  }

  Widget _buildMapControlButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon),
          ),
        ),
      ),
    );
  }

  void _showTripStartDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Start Trip'),
        content: const Text('Are you ready to start tracking your trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<TripBloc>().add(
                    StartTrip(
                      userId: widget.userId,
                      startMonument: sampleMonuments.first,
                    ),
                  );
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

 void _showTripEndDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => WillPopScope(
      onWillPop: () async => false,
      child: BlocProvider.value(
        value: context.read<TripBloc>(),
        child: BlocConsumer<TripBloc, TripState>(
          listener: (context, state) {
            // Once the trip is ended and trip data is updated, we reload the screen

          },
          builder: (context, state) {
            return AlertDialog(
              title: const Text('End Trip'),
              content: state.isLoading
                  ? const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : TripDetailsForm(
                      onSubmit: (vehicleType, purpose, occupancy) {
                        final bloc = context.read<TripBloc>();

                        // Update trip details and end trip
                        bloc
                          ..add(UpdateTripDetails(
                            vehicleType: vehicleType,
                            purpose: purpose,
                            occupancy: occupancy,
                          ))
                          ..add(EndTrip(
                            endMonument: sampleMonuments.last, // TODO: Detect nearest
                          ));
                           Navigator.of(dialogContext).pop();
                      },
                      
                    ),
              actions: [
                if (!state.isLoading)
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}


}