import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/models/handover/location_suggestion.dart';
import 'package:lost_and_found/models/handover/police_station.dart';
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
import 'package:lost_and_found/utils/app_urls.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:url_launcher/url_launcher.dart';

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
  BitmapDescriptor? _searchPinIcon;

  Position? _currentPosition;

  LatLng? _referencePosition;

  List<PoliceStationModel> _stations = [];

  PoliceStationModel? _selectedStation;

  bool _loading = true;

  String? _errorMessage;

  Timer? _debounce;

  bool _isLocationConfirmed = true;
  String? _selectedAddress;
  bool _searchFocused = false;
  final StreamController<List<LocationSuggestionModel>> _suggestionsController =
      StreamController<List<LocationSuggestionModel>>.broadcast();

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
    _suggestionsController.close();
    _debounce?.cancel();
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

      final searchIcon = await MapPinIconLoader.load(
        AssetImages.map_pin,
        size: 110,
      );

      if (!mounted) return;

      setState(() {
        _pinIcon = icon;
        _searchPinIcon = searchIcon;
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
        _isLocationConfirmed = true;
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

  Future<void> _onSearchChanged(String value) async {
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      if (!_suggestionsController.isClosed) {
        _suggestionsController.add([]);
      }
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final response = await _authController.searchLocation(
          query: value.trim(),
          limit: 5,
        );

        if (!mounted || _suggestionsController.isClosed) return;

        if (response.isSuccess && response.data != null) {
          _suggestionsController.add(response.data!);
        } else {
          _suggestionsController.add([]);
        }
      } catch (e) {
        debugPrint("[PoliceStation] Search error: $e");
        if (!_suggestionsController.isClosed) {
          _suggestionsController.add([]);
        }
      }
    });
  }

  Future<void> _onSuggestionTap(LocationSuggestionModel suggestion) async {
    _searchController.text = suggestion.description;
    if (!_suggestionsController.isClosed) {
      _suggestionsController.add([]);
    }
    FocusScope.of(context).unfocus();

    setState(() {
      _searchFocused = false;
      _referencePosition = LatLng(suggestion.latitude, suggestion.longitude);
      _selectedAddress = suggestion.description;
      _isLocationConfirmed = false;
      _stations = [];
    });

    _moveCameraToReference();
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

              onTap: (_) {
                setState(() {
                  _searchFocused = false;
                });
              },

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
          // SEARCH SUGGESTIONS
          // ======================================================

          if (_searchFocused)
            Positioned(
              top:
              MediaQuery.of(context)
                  .padding
                  .top +
                  68,

              left: 16,

              right: 16,

              child: _buildSuggestionsDropdown(),
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

      readOnly: false,

      onChange: _onSearchChanged,

      onTap: () {
        setState(() {
          _searchFocused = true;
        });
      },

      hintText: 'Search location',

      onSubmit: (value) {
        _onSearchChanged(value);
      },

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
            if (!_suggestionsController.isClosed) {
              _suggestionsController.add([]);
            }
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

  Widget _buildSuggestionsDropdown() {
    return StreamBuilder<List<LocationSuggestionModel>>(
      stream: _suggestionsController.stream,
      builder: (context, snapshot) {
        final suggestions = snapshot.data ?? [];
        if (suggestions.isEmpty) return const SizedBox.shrink();

        return Container(
          constraints: const BoxConstraints(maxHeight: 280),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: suggestions.length + 1,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Material(
                  color: AppColors.white,
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.search, color: AppColors.primaryColor),
                    title: AppText(
                      text: _searchController.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    onTap: () async {
                      final query = _searchController.text;
                      if (query.isEmpty) return;
                      try {
                        final locations = await _authController.searchLocation(query: query, limit: 1);
                        if (locations.isSuccess && locations.data != null && locations.data!.isNotEmpty) {
                          _onSuggestionTap(locations.data!.first);
                        }
                      } catch (e) {
                        debugPrint("Error searching query: $e");
                      }
                    },
                  ),
                );
              }
              final suggestion = suggestions[index - 1];
              return Material(
                color: AppColors.white,
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined, color: AppColors.primaryColor),
                  title: AppText(
                    text: suggestion.description,
                    fontSize: 14,
                  ),
                  onTap: () => _onSuggestionTap(suggestion),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // MARKERS
  // ============================================================

  Set<Marker> _buildMarkers() {
    final Set<Marker> markers = {};

    if (_isLocationConfirmed) {
      final icon = _pinIcon ?? BitmapDescriptor.defaultMarker;
      markers.addAll(_stations.map((station) {
        final isSelected = _selectedStation?.id == station.id;
        return Marker(
          markerId: MarkerId('police_${station.id}'),
          position: LatLng(station.latitude, station.longitude),
          icon: icon,
          anchor: const Offset(0.5, 1.0),
          alpha: isSelected ? 1.0 : 0.85,
          infoWindow: InfoWindow(
            title: station.name,
            snippet: station.address,
          ),
          onTap: () => _selectStation(station),
        );
      }));
    }

    if (_referencePosition != null && !_isLocationConfirmed) {
      markers.add(
        Marker(
          markerId: const MarkerId('search_pinpoint'),
          position: _referencePosition!,
          icon: _searchPinIcon ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 1.0),
        ),
      );
    }

    return markers;
  }

  // ============================================================
  // BOTTOM SHEET
  // ============================================================

  Widget _buildBottomSheet() {
    if (!_isLocationConfirmed && _referencePosition != null) {
      return _buildConfirmLocationCard();
    }

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

  Widget _buildConfirmLocationCard() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              text: 'Selected location',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 45,
                  width: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22326A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: AppText(
                    text: _selectedAddress ?? 'Unknown location',
                    fontSize: 14,
                    color: Colors.black87,
                    maxLine: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppButton(
              title: 'Confirm location',
              height: 50,
              radius: BorderRadius.circular(10),
              bgColor: AppColors.primaryColor,
              onTap: () {
                if (_referencePosition != null) {
                  setState(() {
                    _isLocationConfirmed = true;
                  });
                  getPoliceStations(_referencePosition!.latitude, _referencePosition!.longitude);
                }
              },
            ),
          ],
        ),
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
    // SingleChildScrollView handles the content height within the parent's constraints.
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: _buildStationCard(
        station,
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