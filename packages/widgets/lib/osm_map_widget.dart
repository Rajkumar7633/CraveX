import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';


/// Reusable OpenStreetMap widget using leaflet-like rendering.
/// No API keys are required.
class OsmMapWidget extends StatefulWidget {
  final List<Marker> markers;
  final List<Polyline> polylines;
  final LatLng? center;
  final double zoom;
  final bool interactive;

  const OsmMapWidget({
    super.key,
    this.markers = const [],
    this.polylines = const [],
    this.center,
    this.zoom = 13.0,
    this.interactive = true,
  });

  @override
  State<OsmMapWidget> createState() => _OsmMapWidgetState();
}

class _OsmMapWidgetState extends State<OsmMapWidget> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng _calculateCenter() {
    if (widget.center != null) return widget.center!;
    if (widget.markers.isEmpty) {
      // Default to Bangalore center
      return const LatLng(12.9716, 77.5946);
    }
    double totalLat = 0;
    double totalLng = 0;
    for (var marker in widget.markers) {
      totalLat += marker.point.latitude;
      totalLng += marker.point.longitude;
    }
    return LatLng(totalLat / widget.markers.length, totalLng / widget.markers.length);
  }

  @override
  Widget build(BuildContext context) {
    final computedCenter = _calculateCenter();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: computedCenter,
              initialZoom: widget.zoom,
              interactionOptions: InteractionOptions(
                flags: widget.interactive ? InteractiveFlag.all : InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.cravex',
              ),
              if (widget.polylines.isNotEmpty)
                PolylineLayer(
                  polylines: widget.polylines,
                ),
              if (widget.markers.isNotEmpty)
                MarkerLayer(
                  markers: widget.markers,
                ),
            ],
          ),
          if (widget.interactive)
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'zoom_in_${identityHashCode(this)}',
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    onPressed: () {
                      final currentZoom = _mapController.camera.zoom;
                      _mapController.move(_mapController.camera.center, currentZoom + 1);
                    },
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoom_out_${identityHashCode(this)}',
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    onPressed: () {
                      final currentZoom = _mapController.camera.zoom;
                      _mapController.move(_mapController.camera.center, currentZoom - 1);
                    },
                    child: const Icon(Icons.remove),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
