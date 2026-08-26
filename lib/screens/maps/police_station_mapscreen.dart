import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/models/handover/police_station.dart';
import 'package:lost_and_found/models/posts_model/selected_location_model.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/shared_widgets/map_pin_loader.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_permission.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_urls.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:url_launcher/url_launcher.dart';

import 'location_selection_screen.dart';

class PoliceStationMapScreen extends StatefulWidget {
  const PoliceStationMapScreen({super.key});

  @override
  State<PoliceStationMapScreen> createState() =>
      _PoliceStationMapScreenState();
}

class _PoliceStationMapScreenState extends State<PoliceStationMapScreen> {
  static const String _pinAssetPath =
      'assets/images/nearByMap.svg';

  static const CameraPosition _fallbackCamera =
  CameraPosition(
    target: LatLng(11.0168, 76.9558),
    zoom: 11,
  );

  final AppPermissions _appPermissions =
  AppPermissions();

  late final AuthControllers _authController;

  GoogleMapController? _mapController;

  final TextEditingController _searchController =
  TextEditingController();

  BitmapDescriptor? _pinIcon;

  Position? _currentPosition;

  LatLng? _referencePosition;

  List<PoliceStationModel> _stations = [];

  PoliceStationModel? _selectedStation;

  bool _loading = true;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _authController = AuthControllers(
      authRepository: AuthRepository(
        apiClient: ApiClient(),
      ),
    );

    _loadPinIcon();
    _init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ============================================================
  // CUSTOM MARKER
  // ============================================================

  Future<void> _loadPinIcon() async {
    try {
      final icon = await MapPinIconLoader.load(
        _pinAssetPath,
        size: 70,
      );

      if (!mounted) return;

      setState(() {
        _pinIcon = icon;
      });
    } catch (e) {
      debugPrint(
        '[PoliceStation] Marker icon error: $e',
      );
    }
  }

  // ============================================================
  // INITIAL LOCATION
  // ============================================================

  Future<void> _init() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    final granted =
    await _appPermissions
        .requestLocationPermission(context);

    if (!granted) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage =
        'Location permission is required to find nearby police stations.';
      });

      return;
    }

    final serviceOn =
    await _appPermissions
        .isLocationServiceEnabled();

    if (!serviceOn) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage =
        'Please enable location services and try again.';
      });

      return;
    }

    try {
      final position =
      await Geolocator.getCurrentPosition();

      _currentPosition = position;

      await getPoliceStations(
        position.latitude,
        position.longitude,
        position: position,
      );
    } catch (e) {
      debugPrint(
        '[PoliceStation] Current location error: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage =
        'Unable to get your current location.';
      });
    }
  }

  // ============================================================
  // GET NEARBY POLICE STATIONS
  //
  // IMPORTANT:
  // This method is used for BOTH:
  //
  // 1. Current location
  // 2. Searched location
  //
  // So searched Mumbai -> nearby Mumbai police stations.
  // ============================================================

  Future<void> getPoliceStations(
      double lat,
      double lng, {
        Position? position,
      }) async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _errorMessage = null;

      // Clear old station/card immediately.
      _stations = [];
      _selectedStation = null;

      // IMPORTANT:
      // Search location becomes the new reference point.
      _referencePosition = LatLng(lat, lng);
    });

    try {
      debugPrint(
        '===========================================',
      );

      debugPrint(
        '[PoliceStation] SEARCH/REFERENCE LOCATION',
      );

      debugPrint(
        '[PoliceStation] latitude = $lat',
      );

      debugPrint(
        '[PoliceStation] longitude = $lng',
      );

      debugPrint(
        '[PoliceStation] radius = 15 km',
      );

      final response =
      await _authController
          .getNearbyPoliceStations(
        latitude: lat,
        longitude: lng,
        radiusKm: 15,
      );

      debugPrint(
        '[PoliceStation] status = ${response.status}',
      );

      debugPrint(
        '[PoliceStation] message = ${response.message}',
      );

      debugPrint(
        '[PoliceStation] station count = '
            '${response.data?.length}',
      );

      debugPrint(
        '===========================================',
      );

      if (!mounted) return;

      if (!response.isSuccess ||
          response.data == null) {
        setState(() {
          _loading = false;
          _stations = [];
          _selectedStation = null;

          _errorMessage =
          response.message.isNotEmpty
              ? response.message
              : 'Unable to fetch nearby police stations.';
        });

        // Keep searched/current location visible.
        _moveCameraToReference();

        return;
      }

      final stations = response.data!;

      setState(() {
        if (position != null) {
          _currentPosition = position;
        }

        _referencePosition =
            LatLng(lat, lng);

        _stations = stations;

        // IMPORTANT:
        // Show a card after search too.
        _selectedStation =
        stations.isNotEmpty
            ? stations.first
            : null;

        _loading = false;

        _errorMessage = null;
      });

      // Give GoogleMap a frame to update markers
      // before moving camera.
      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        if (mounted) {
          _moveCameraToFitAll();
        }
      });
    } catch (e) {
      debugPrint(
        '[PoliceStation] API error: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
        _stations = [];
        _selectedStation = null;

        _errorMessage =
        'Unable to fetch nearby police stations. '
            'Please try again.';
      });

      _moveCameraToReference();
    }
  }

  // ============================================================
  // MOVE TO REFERENCE LOCATION
  // ============================================================

  void _moveCameraToReference() {
    if (_mapController == null ||
        _referencePosition == null) {
      return;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        _referencePosition!,
        13,
      ),
    );
  }

  // ============================================================
  // FIT REFERENCE + POLICE STATIONS
  // ============================================================

  void _moveCameraToFitAll() {
    if (_mapController == null ||
        _referencePosition == null) {
      return;
    }

    final points = <LatLng>[
      _referencePosition!,
      ..._stations.map(
            (station) => LatLng(
          station.latitude,
          station.longitude,
        ),
      ),
    ];

    if (points.isEmpty) {
      return;
    }

    if (points.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          points.first,
          14,
        ),
      );

      return;
    }

    double minLat =
        points.first.latitude;

    double maxLat =
        points.first.latitude;

    double minLng =
        points.first.longitude;

    double maxLng =
        points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) {
        minLat = point.latitude;
      }

      if (point.latitude > maxLat) {
        maxLat = point.latitude;
      }

      if (point.longitude < minLng) {
        minLng = point.longitude;
      }

      if (point.longitude > maxLng) {
        maxLng = point.longitude;
      }
    }

    // Prevent zero-size bounds.
    if ((maxLat - minLat).abs() < 0.001) {
      maxLat += 0.01;
      minLat -= 0.01;
    }

    if ((maxLng - minLng).abs() < 0.001) {
      maxLng += 0.01;
      minLng -= 0.01;
    }

    try {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              minLat,
              minLng,
            ),
            northeast: LatLng(
              maxLat,
              maxLng,
            ),
          ),
          70,
        ),
      );
    } catch (e) {
      debugPrint(
        '[PoliceStation] Camera bounds error: $e',
      );
    }
  }

  // ============================================================
  // SELECT POLICE STATION
  // ============================================================

  void _selectStation(
      PoliceStationModel station,
      ) {
    setState(() {
      _selectedStation = station;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(
          station.latitude,
          station.longitude,
        ),
        15,
      ),
    );
  }

  // ============================================================
  // SEARCH LOCATION
  // ============================================================

  Future<void> _searchLocation() async {
    final result = await context.pushNamed(
      AppRoutes.mapScreen,
      extra: MapScreenModel(
        needSingleLocation: true,
      ),
    );

    if (!mounted) return;

    SelectedLocationModel? selected;

    if (result is SelectedLocationModel) {
      selected = result;
    } else if (result
    is List<SelectedLocationModel>) {
      if (result.isNotEmpty) {
        selected = result.first;
      }
    }

    if (selected == null) {
      return;
    }

    debugPrint(
      '[PoliceStation] Selected search location:',
    );

    debugPrint(
      '[PoliceStation] address=${selected.address}',
    );

    debugPrint(
      '[PoliceStation] lat=${selected.latitude}',
    );

    debugPrint(
      '[PoliceStation] lng=${selected.longitude}',
    );

    // Update search field.
    setState(() {
      _searchController.text =
          selected!.address;
    });

    // ==========================================================
    // THIS IS THE IMPORTANT PART
    //
    // The searched location is passed to the SAME API.
    //
    // Example:
    //
    // Search Mumbai
    //      ↓
    // Mumbai latitude/longitude
    //      ↓
    // nearbyPoliceStations
    //      ↓
    // Mumbai police stations
    //      ↓
    // markers + card
    // ==========================================================

    await getPoliceStations(
      selected.latitude,
      selected.longitude,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,

      body: Stack(
        children: [
          // ======================================================
          // GOOGLE MAP
          // ======================================================

          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition:
              _fallbackCamera,

              onMapCreated:
                  (controller) {
                _mapController =
                    controller;

                if (_stations.isNotEmpty) {
                  _moveCameraToFitAll();
                } else {
                  _moveCameraToReference();
                }
              },

              myLocationEnabled: true,

              myLocationButtonEnabled:
              false,

              zoomControlsEnabled: false,

              compassEnabled: false,

              markers: _buildMarkers(),
            ),
          ),

          // ======================================================
          // SEARCH BAR
          // ======================================================

          Positioned(
            top:
            MediaQuery.of(context)
                .padding
                .top +
                12,

            left: 16,

            right: 16,

            child: _buildSearchBar(),
          ),

          // ======================================================
          // LOADING
          // ======================================================

          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black12,
                child: Center(
                  child:
                  CircularProgressIndicator(
                    color:
                    AppColors
                        .primaryColor,
                  ),
                ),
              ),
            ),

          // ======================================================
          // BOTTOM CARD
          // ======================================================

          if (!_loading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,

              child:
              _buildBottomSheet(),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return AppTextField(
      textController:
      _searchController,

      readOnly: true,

      onChange: (_) {},

      onTap: _searchLocation,

      hintText: 'Search location',

      onSubmit: (_) {},

      borderColor:
      Colors.transparent,

      prefixIcon:
      AppIconWidget(
        assetPath:
        AssetImages.search,
      ).pad(12),

      suffixIcon:
      _searchController
          .text
          .isNotEmpty
          ? GestureDetector(
        onTap: () {
          setState(() {
            _searchController
                .clear();
          });

          // Go back to current location.
          _init();
        },

        child:
        AppIconWidget(
          assetPath:
          AssetImages
              .close,
        ).pad(3),
      )
          : null,
    );
  }

  // ============================================================
  // MARKERS
  // ============================================================

  Set<Marker> _buildMarkers() {
    final icon =
        _pinIcon ??
            BitmapDescriptor
                .defaultMarker;

    return _stations.map(
          (station) {
        final isSelected =
            _selectedStation?.id ==
                station.id;

        return Marker(
          markerId: MarkerId(
            'police_${station.id}',
          ),

          position: LatLng(
            station.latitude,
            station.longitude,
          ),

          icon: icon,

          anchor:
          const Offset(
            0.5,
            1.0,
          ),

          alpha:
          isSelected
              ? 1.0
              : 0.85,

          infoWindow:
          InfoWindow(
            title:
            station.name,
            snippet:
            station.address,
          ),

          onTap: () {
            _selectStation(
              station,
            );
          },
        );
      },
    ).toSet();
  }

  // ============================================================
  // BOTTOM SHEET
  // ============================================================

  Widget _buildBottomSheet() {
    final height =
        MediaQuery.of(context)
            .size
            .height;

    // Keep the card compact but give enough room
    // for image + address + buttons.
    final maxHeight =
        height * 0.34;

    return SafeArea(
      top: false,

      child: Container(
        constraints:
        BoxConstraints(
          maxHeight:
          maxHeight,
        ),

        padding:
        const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12,
        ),

        decoration:
        const BoxDecoration(
          color:
          AppColors.white,

          borderRadius:
          BorderRadius.vertical(
            top:
            Radius.circular(
              20,
            ),
          ),

          boxShadow: [
            BoxShadow(
              color:
              Colors.black12,
              blurRadius: 12,
              offset:
              Offset(0, -2),
            ),
          ],
        ),

        child:
        _buildBottomContent(),
      ),
    );
  }

  // ============================================================
  // BOTTOM CONTENT
  // ============================================================

  Widget _buildBottomContent() {
    if (_errorMessage != null) {
      return SizedBox(
        width: double.infinity,

        child: Padding(
          padding:
          const EdgeInsets.all(
            12,
          ),

          child: AppText(
            text:
            _errorMessage!,
            fontSize: 13,
            color:
            AppColors.grey,
          ),
        ),
      );
    }

    if (_stations.isEmpty) {
      return SizedBox(
        width: double.infinity,

        child: Padding(
          padding:
          const EdgeInsets.all(
            12,
          ),

          child: AppText(
            text:
            'No police stations found nearby.',
            fontSize: 13,
            color:
            AppColors.grey,
          ),
        ),
      );
    }

    final station =
        _selectedStation ??
            _stations.first;

    // IMPORTANT:
    // Flexible prevents the Column from overflowing.
    return Flexible(
      child:
      SingleChildScrollView(
        physics:
        const ClampingScrollPhysics(),

        child:
        _buildStationCard(
          station,
        ),
      ),
    );
  }

  // ============================================================
  // POLICE STATION CARD
  // ============================================================

  Widget _buildStationCard(
      PoliceStationModel station,
      ) {
    final distance =
        station.distanceKm;

    return GestureDetector(
      onTap: () {
        _selectStation(
          station,
        );
      },

      child: Column(
        mainAxisSize:
        MainAxisSize.min,

        crossAxisAlignment:
        CrossAxisAlignment
            .stretch,

        children: [
          // ======================================================
          // STATION DETAILS
          // ======================================================

          Row(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,

            children: [
              // SMALL IMAGE
              SizedBox(
                width: 58,
                height: 58,

                child:
                ClipRRect(
                  borderRadius:
                  BorderRadius
                      .circular(
                    8,
                  ),

                  child:
                  AppCachedNetworkImage(
                    imageUrl:
                    station.imageUrl ??
                        '',
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,

                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

                  children: [
                    Row(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                      children: [
                        Expanded(
                          child:
                          AppText(
                            text:
                            station.name,
                            fontSize:
                            14,
                            fontWeight:
                            FontWeight
                                .w600,
                            color:
                            AppColors
                                .black,
                            maxLine:
                            2,
                            textOverflow:
                            TextOverflow
                                .ellipsis,
                          ),
                        ),

                        const SizedBox(
                          width: 6,
                        ),

                        // DISTANCE
                        Container(
                          constraints:
                          const BoxConstraints(
                            minWidth:
                            55,
                            maxWidth:
                            70,
                          ),

                          height: 28,

                          alignment:
                          Alignment
                              .center,

                          decoration:
                          BoxDecoration(
                            color:
                            AppColors
                                .idCardColor,

                            borderRadius:
                            BorderRadius
                                .circular(
                              7,
                            ),

                            border:
                            Border.all(
                              color:
                              AppColors
                                  .primaryColor,
                            ),
                          ),

                          child:
                          AppText(
                            text:
                            distance >=
                                1
                                ? '${distance.toStringAsFixed(1)} km'
                                : '${(distance * 1000).toStringAsFixed(0)} m',

                            fontSize:
                            10,

                            fontWeight:
                            FontWeight
                                .w500,

                            color:
                            AppColors
                                .primaryColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    if (station
                        .address
                        .isNotEmpty)
                      AppText(
                        text:
                        station
                            .address,

                        fontSize:
                        11,

                        fontWeight:
                        FontWeight
                            .w400,

                        color:
                        AppColors
                            .black,

                        maxLine:
                        2,


                        textOverflow:
                        TextOverflow
                            .ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          // ======================================================
          // CALL + DIRECTION
          // ======================================================

          Row(
            children: [
              Expanded(
                child:
                SizedBox(
                  height: 38,

                  child:
                  AppButton(
                    title:
                    'Call',

                    onTap:
                        () async {
                      final phone =
                      station
                          .phoneNumber
                          .trim();

                      if (phone
                          .isEmpty) {
                        if (!mounted) {
                          return;
                        }

                        ScaffoldMessenger
                            .of(
                          context,
                        ).showSnackBar(
                          const SnackBar(
                            content:
                            Text(
                              'Phone number not available',
                            ),
                          ),
                        );

                        return;
                      }

                      final uri =
                      Uri(
                        scheme:
                        'tel',
                        path:
                        phone,
                      );

                      try {
                        await launchUrl(
                          uri,
                        );
                      } catch (e) {
                        debugPrint(
                          'Could not call: $e',
                        );
                      }
                    },

                    border:
                    Border.all(
                      color:
                      AppColors
                          .primaryColor,
                    ),

                    bgColor:
                    AppColors
                        .white,

                    fontSize:
                    13,

                    height:
                    38,

                    textColor:
                    AppColors
                        .primaryColor,

                    radius:
                    const BorderRadius
                        .all(
                      Radius.circular(
                        10,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child:
                SizedBox(
                  height: 38,

                  child:
                  AppButton(
                    title:
                    'Direction',

                    onTap:
                        () async {
                      final lat =
                          station
                              .latitude;

                      final lng =
                          station
                              .longitude;

                      if (lat == 0 ||
                          lng == 0) {
                        return;
                      }

                      final url =
                      Uri.parse(
                        '${AppUrls.googleMap}$lat,$lng',
                      );

                      try {
                        await launchUrl(
                          url,
                          mode:
                          LaunchMode
                              .externalApplication,
                        );
                      } catch (e) {
                        debugPrint(
                          'Could not open maps: $e',
                        );
                      }
                    },

                    border:
                    Border.all(
                      color:
                      AppColors
                          .primaryColor,
                    ),

                    fontSize:
                    13,

                    height:
                    38,

                    radius:
                    const BorderRadius
                        .all(
                      Radius.circular(
                        10,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}