import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lost_and_found/models/posts_model/selected_location_model.dart';
import 'package:lost_and_found/screens/maps/location_selection_screen.dart';
import 'package:lost_and_found/services/place_service.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/shared_widgets/map_pin_loader.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_permission.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:lost_and_found/utils/app_urls.dart';
import 'package:url_launcher/url_launcher.dart';

class PoliceStationMapScreen extends StatefulWidget {
  const PoliceStationMapScreen({super.key});

  @override
  State<PoliceStationMapScreen> createState() => _PoliceStationMapScreenState();
}

class _PoliceStationMapScreenState extends State<PoliceStationMapScreen> {
  static const String _pinAssetPath = 'assets/images/nearByMap.svg';
  static const CameraPosition _fallbackCamera = CameraPosition(
    target: LatLng(11.0168, 76.9558), // Coimbatore fallback
    zoom: 11,
  );

  final AppPermissions _appPermissions = AppPermissions();
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  BitmapDescriptor? _pinIcon;

  Position? _currentPosition;


  LatLng? _referencePosition;

  List<NearbyPlace> _stations = [];
  NearbyPlace? _selectedStation;

  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPinIcon();
    _init();
  }

  Future<void> _loadPinIcon() async {
    final icon = await MapPinIconLoader.load(_pinAssetPath, size: 100);
    if (!mounted) return;
    setState(() => _pinIcon = icon);
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final granted = await _appPermissions.requestLocationPermission(context);
    if (!granted) {
      setState(() {
        _loading = false;
        _errorMessage =
            'Location permission is required to find nearby police stations.';
      });
      return;
    }

    final serviceOn = await _appPermissions.isLocationServiceEnabled();
    if (!serviceOn) {
      setState(() {
        _loading = false;
        _errorMessage = 'Please enable location services and try again.';
      });
      return;
    }
    final position = await Geolocator.getCurrentPosition();

    getPoliceStations(
      position.latitude,
      position.longitude,
      position: position,
    );
  }

  Future<void> getPoliceStations(
    double lat,
    double lng, {
    Position? position,
  }) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final stations = await PlacesService.nearbySearch(
        lat: lat,
        lng: lng,
        type: 'police',
      );

      if (!mounted) return;

      setState(() {
        if (position != null) {
          _currentPosition = position;
        }

        _referencePosition = LatLng(lat, lng);

        _stations = _sortedByDistance(stations, _referencePosition!);

        _selectedStation = null;

        _loading = false;
        if (_stations.isEmpty) {
          _errorMessage = null;
        }
      });

      _moveCameraToFitAll();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage =
            'Unable to fetch nearby police stations. Please try again.';
      });
    }
  }

  List<NearbyPlace> _sortedByDistance(List<NearbyPlace> stations, LatLng from) {
    final withDistance = [...stations];
    withDistance.sort((a, b) {
      final da = Geolocator.distanceBetween(
        from.latitude,
        from.longitude,
        a.latitude,
        a.longitude,
      );
      final db = Geolocator.distanceBetween(
        from.latitude,
        from.longitude,
        b.latitude,
        b.longitude,
      );
      return da.compareTo(db);
    });
    return withDistance;
  }

  double? _distanceToStation(NearbyPlace station) {
    if (_referencePosition == null) return null;
    return Geolocator.distanceBetween(
      _referencePosition!.latitude,
      _referencePosition!.longitude,
      station.latitude,
      station.longitude,
    );
  }

  void _moveCameraToFitAll() {
    if (_mapController == null || _referencePosition == null) return;

    final points = <LatLng>[
      _referencePosition!,
      ..._stations.map((s) => LatLng(s.latitude, s.longitude)),
    ];

    if (points.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 14),
      );
      return;
    }

    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      minLat = p.latitude < minLat ? p.latitude : minLat;
      maxLat = p.latitude > maxLat ? p.latitude : maxLat;
      minLng = p.longitude < minLng ? p.longitude : minLng;
      maxLng = p.longitude > maxLng ? p.longitude : maxLng;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60,
      ),
    );
  }

  void _selectStation(NearbyPlace station) {
    setState(() => _selectedStation = station);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(station.latitude, station.longitude),
        15,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _referencePosition != null
                ? CameraPosition(target: _referencePosition!, zoom: 13)
                : _fallbackCamera,
            onMapCreated: (c) {
              _mapController = c;
              _moveCameraToFitAll();
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _buildMarkers(),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: _backButton(),
          ),

          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black12,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
          if (!_loading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomSheet(),
            ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final icon = _pinIcon ?? BitmapDescriptor.defaultMarker;
    return _stations.map((station) {
      final isSelected = _selectedStation?.placeId == station.placeId;
      return Marker(
        markerId: MarkerId(station.placeId),
        position: LatLng(station.latitude, station.longitude),
        icon: icon,
        anchor: const Offset(0.5, 1.0),
        alpha: isSelected ? 1.0 : 0.85,
        infoWindow: InfoWindow(title: station.name, snippet: station.vicinity),
        onTap: () => _selectStation(station),
      );
    }).toSet();
  }

  Widget _backButton() {
    return GestureDetector(
      onTap: () => context.pop(),
      child: AppTextField(
        textController: _searchController,
        readOnly: true,
        onChange: (v) {},
        onTap: () async {
          final result = await context.pushNamed(
            AppRoutes.mapScreen,
            extra: MapScreenModel(needSingleLocation: true),
          );

          if (result is List<SelectedLocationModel> && result.isNotEmpty) {
            final selected = result.first;
            _searchController.text = selected.address;

            getPoliceStations(selected.latitude, selected.longitude);
            _searchController.text = result.first.address;
          }
        },
        hintText: 'Search location',
        onSubmit: (v) {},
        borderColor: Colors.transparent,
        prefixIcon: AppIconWidget(assetPath: AssetImages.search).pad(12),
        suffixIcon: _searchController.text.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  _searchController.clear();
                },
                child: AppIconWidget(assetPath: AssetImages.close).pad(3),
              )
            : null,
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.2,
        maxHeight: MediaQuery.of(context).size.height * 0.27,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey,
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null)
              AppText(text: _errorMessage!, fontSize: 13, color: AppColors.grey)
            else if (!_loading && _stations.isEmpty)
              AppText(
                text: 'No police stations found nearby.',
                fontSize: 13,
                color: AppColors.grey,
              )
            else if (_stations.isNotEmpty)
              Flexible(
                child: _buildStationCard(_selectedStation ?? _stations.first),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationCard(NearbyPlace station) {
    final distance = _distanceToStation(station);

    return GestureDetector(
      onTap: () => _selectStation(station),
      child: Container(
        child: Column(
          spacing: 20,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCachedNetworkImage(imageUrl: station.icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: AppText(
                              text: station.name,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                          if (distance != null)
                            AppButton(
                              width: 60,
                              height: 30,
                              bgColor: AppColors.idCardColor,
                              border: Border.all(color: AppColors.primaryColor),
                              title: distance >= 1000
                                  ? '${(distance / 1000).toStringAsFixed(1)} km '
                                  : '${distance.toStringAsFixed(0)} m ',
                              fontSize: 12,
                              textColor: AppColors.primaryColor,
                              onTap: () {},
                            ),
                        ],
                      ),
                      SizedBox(height: 20),
                      if (station.vicinity.isNotEmpty)
                        AppText(
                          text: station.vicinity,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.black,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Flexible(
              child: Row(
                children: [
                  Flexible(
                    child: AppButton(
                      title: 'Call',
                      onTap: () {},
                      border: Border.all(color: AppColors.primaryColor),
                      bgColor: AppColors.white,
                      fontSize: 14,
                      height: 40,
                      textColor: AppColors.primaryColor,
                      radius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  SizedBox(width: 10),
                  Flexible(
                    child: AppButton(
                      title: 'Direction',
                      onTap: () async {
                        final lat = station.latitude;
                        final lng = station.longitude;

                        if (lat == 0 || lng == 0) return;

                        final url = Uri.parse("${AppUrls.googleMap}$lat,$lng");

                        try {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (e) {
                          debugPrint("Could not open maps: $e");
                        }
                      },
                      border: Border.all(color: AppColors.primaryColor),
                      fontSize: 14,
                      height: 40,
                      radius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ).pad(),
      ),
    );
  }
}
