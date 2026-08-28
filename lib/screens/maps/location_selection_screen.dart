import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/models/handover/location_suggestion.dart';
import 'package:lost_and_found/models/handover/police_station.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/services/place_service.dart';
import 'package:lost_and_found/models/posts_model/selected_location_model.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/shared_widgets/map_pin_loader.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_permission.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

class LocationSelectionScreen extends StatefulWidget {
  final MapScreenModel mapScreenModel;

  const LocationSelectionScreen({
    super.key,
    required this.mapScreenModel,
  });

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState
    extends State<LocationSelectionScreen> {
  // ===========================================================================
  // CONTROLLER
  // ===========================================================================

  final authController = AuthControllers(
    authRepository: AuthRepository(
      apiClient: ApiClient(),
    ),
  );

  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  static const int kMaxLocations = 3;

  static const double _policeSearchRadiusKm = 15;

  static const CameraPosition _fallbackCamera = CameraPosition(
    target: LatLng(
      11.0168,
      76.9558,
    ),
    zoom: 11,
  );

  static const String _pinAssetPath =
      'assets/images/map_pin.svg';

  // ===========================================================================
  // SERVICES
  // ===========================================================================

  final AppPermissions _appPermissions =
  AppPermissions();

  // ===========================================================================
  // SEARCH
  // ===========================================================================

  final TextEditingController _searchController =
  TextEditingController();

  final StreamController<List<LocationSuggestionModel>>
  _suggestionsController =
  StreamController<List<LocationSuggestionModel>>.broadcast();

  Timer? _debounce;

  bool _searchFocused = false;

  // ===========================================================================
  // MAP
  // ===========================================================================

  GoogleMapController? _mapController;

  BitmapDescriptor? _pinIcon;

  bool _resolvingPin = false;

  bool _addingNewLocation = false;

  // ===========================================================================
  // LOCATION
  // ===========================================================================

  SelectedLocationModel? _pendingLocation;

  List<SelectedLocationModel> _selectedLocations =
  [];

  // ===========================================================================
  // POLICE STATIONS
  // ===========================================================================

  List<PoliceStationModel> _policeStations = [];

  bool _loadingPoliceStations = false;

  // ===========================================================================
  // ASYNC SELECTION CONTROL
  //
  // Every time the user selects a new location, this number changes.
  // If an old reverse-geocoding request finishes later, it will not overwrite
  // the newer selected location.
  // ===========================================================================

  int _locationRequestId = 0;

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    // -------------------------------------------------------------------------
    // RESTORE PREVIOUS LOCATIONS
    // -------------------------------------------------------------------------

    if (widget.mapScreenModel.selectedLocation != null) {
      _selectedLocations = List<SelectedLocationModel>.from(
        widget.mapScreenModel.selectedLocation!,
      );
    }

    // -------------------------------------------------------------------------
    // LOAD CUSTOM MARKER
    // -------------------------------------------------------------------------

    _loadPinIcon();

    // -------------------------------------------------------------------------
    // INITIALIZE LOCATION
    // -------------------------------------------------------------------------

    _initLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();

    _suggestionsController.close();

    _debounce?.cancel();

    super.dispose();
  }

  // ===========================================================================
  // CUSTOM MARKER
  // ===========================================================================

  Future<void> _loadPinIcon() async {
    try {
      final icon = await MapPinIconLoader.load(
        _pinAssetPath,
        size: 110,
      );

      if (!mounted) return;

      setState(() {
        _pinIcon = icon;
      });

      debugPrint(
        '[MapPin] Custom marker loaded successfully',
      );
    } catch (e) {
      debugPrint(
        '[MapPin] Failed to load custom marker: $e',
      );
    }
  }

  // ===========================================================================
  // INITIAL LOCATION
  // ===========================================================================

  Future<void> _initLocation() async {
    final granted =
    await _appPermissions.requestLocationPermission(
      context,
    );

    if (!granted) return;

    final serviceOn =
    await _appPermissions.isLocationServiceEnabled();

    if (!serviceOn) return;

    try {
      // =======================================================================
      // VERY IMPORTANT
      //
      // If we already have a selected location, NEVER replace it with GPS.
      // =======================================================================

      if (_selectedLocations.isNotEmpty) {
        final selected =
            _selectedLocations.first;

        final selectedLatLng = LatLng(
          selected.latitude,
          selected.longitude,
        );

        // Map might not have been created yet.
        if (_mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              selectedLatLng,
              15,
            ),
          );
        }

        // Make sure marker remains visible.
        if (mounted) {
          setState(() {});
        }

        return;
      }

      // =======================================================================
      // NO PREVIOUS LOCATION
      //
      // Use current GPS location.
      // =======================================================================

      final position =
      await Geolocator.getCurrentPosition();

      if (!mounted) return;

      await _setPinFromLatLng(
        LatLng(
          position.latitude,
          position.longitude,
        ),
        moveCamera: true,
      );
    } catch (e) {
      debugPrint(
        '[Location] Initial location error: $e',
      );
    }
  }

  // ===========================================================================
  // CURRENT LOCATION
  // ===========================================================================

  Future<void> _useCurrentLocation() async {
    final granted =
    await _appPermissions.requestLocationPermission(
      context,
    );

    if (!granted) return;

    try {
      final position =
      await Geolocator.getCurrentPosition();

      await _setPinFromLatLng(
        LatLng(
          position.latitude,
          position.longitude,
        ),
        moveCamera: true,
      );
    } catch (e) {
      debugPrint(
        '[Location] Current location error: $e',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to fetch current location',
            ),
          ),
        );
      }
    }
  }

  // ===========================================================================
  // ADD ANOTHER LOCATION
  // ===========================================================================

  void _startAddingAnotherLocation() {
    if (_selectedLocations.length >= kMaxLocations) {
      return;
    }

    setState(() {
      _addingNewLocation = true;

      _pendingLocation = null;
    });

    debugPrint(
      '[Location] Started adding another location',
    );
  }

  // ===========================================================================
  // SEARCH
  // ===========================================================================

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      if (!_suggestionsController.isClosed) {
        _suggestionsController.add([]);
      }

      return;
    }

    _debounce = Timer(
      const Duration(
        milliseconds: 400,
      ),
          () async {
        try {
          final query = value.trim();

          debugPrint(
            '[LocationSearch] Searching: $query',
          );

          final response =
          await authController.searchLocation(
            query: query,
            limit: 5,
          );

          if (!mounted ||
              _suggestionsController.isClosed) {
            return;
          }

          if (!response.isSuccess ||
              response.data == null) {
            _suggestionsController.add([]);

            return;
          }

          _suggestionsController.add(
            response.data!,
          );
        } catch (e) {
          debugPrint(
            '[LocationSearch] ERROR: $e',
          );

          if (!_suggestionsController.isClosed) {
            _suggestionsController.add([]);
          }
        }
      },
    );
  }

  // ===========================================================================
  // SEARCH SUGGESTION TAP
  // ===========================================================================

  Future<void> _onSuggestionTap(
      LocationSuggestionModel suggestion,
      ) async {
    debugPrint(
      '[LocationSearch] Selected: '
          '${suggestion.description}',
    );

    debugPrint(
      '[LocationSearch] Lat: '
          '${suggestion.latitude}',
    );

    debugPrint(
      '[LocationSearch] Lng: '
          '${suggestion.longitude}',
    );

    _searchController.text =
        suggestion.description;

    if (!_suggestionsController.isClosed) {
      _suggestionsController.add([]);
    }

    FocusScope.of(context).unfocus();

    if (mounted) {
      setState(() {
        _searchFocused = false;
      });
    }

    await _setPinFromLatLng(
      LatLng(
        suggestion.latitude,
        suggestion.longitude,
      ),
      moveCamera: true,
      knownAddress: suggestion.description,
    );
  }

  // ===========================================================================
  // MAP TAP
  // ===========================================================================

  Future<void> _onMapTap(
      LatLng latLng,
      ) async {
    debugPrint(
      '[Map] Tapped: '
          '${latLng.latitude}, '
          '${latLng.longitude}',
    );

    await _setPinFromLatLng(
      latLng,
      moveCamera: false,
    );
  }

  // ===========================================================================
  // POLICE STATIONS
  // ===========================================================================

  Future<void> _loadNearbyPoliceStations({
    required double latitude,
    required double longitude,
  }) async {
    if (!mounted) return;

    setState(() {
      _loadingPoliceStations = true;

      _policeStations = [];
    });

    try {
      final response =
      await authController.getNearbyPoliceStations(
        latitude: latitude,
        longitude: longitude,
        radiusKm: _policeSearchRadiusKm,
      );

      if (!mounted) return;

      if (!response.isSuccess ||
          response.data == null) {
        setState(() {
          _policeStations = [];

          _loadingPoliceStations = false;
        });

        return;
      }

      setState(() {
        _policeStations =
        response.data!;

        _loadingPoliceStations = false;
      });

      debugPrint(
        '[PoliceStations] Found: '
            '${_policeStations.length}',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '[PoliceStations] ERROR: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        _policeStations = [];

        _loadingPoliceStations = false;
      });
    }
  }

  // ===========================================================================
  // SET PIN
  //
  // THIS IS THE MAIN FIX.
  //
  // For normal location selection:
  //
  //     selected coordinate -> _selectedLocations
  //
  // The marker therefore stays alive even while reverse-geocoding is running.
  //
  // For "Add Another":
  //
  //     selected coordinate -> _pendingLocation
  //
  // until the user confirms it.
  // ===========================================================================

  Future<void> _setPinFromLatLng(
      LatLng latLng, {
        required bool moveCamera,
        String? knownAddress,
      }) async {
    if (!mounted) return;

    // =========================================================================
    // Generate unique request ID.
    //
    // This protects against old async reverse-geocoding responses.
    // =========================================================================

    final int requestId =
    ++_locationRequestId;

    final String temporaryAddress =
        knownAddress ??
            'Fetching address...';

    final immediateLocation =
    SelectedLocationModel(
      address: temporaryAddress,
      latitude: latLng.latitude,
      longitude: latLng.longitude,
    );

    // =========================================================================
    // IMMEDIATELY SHOW MARKER
    //
    // This is the critical part.
    //
    // Do NOT wait for reverse geocoding before putting the coordinate into
    // _selectedLocations.
    // =========================================================================

    if (!_addingNewLocation) {
      setState(() {
        _resolvingPin = true;

        if (_selectedLocations.isEmpty) {
          _selectedLocations.add(
            immediateLocation,
          );
        } else {
          // For normal/single-location selection, replace the first location.
          _selectedLocations[0] =
              immediateLocation;
        }

        // There is no need for pending location in normal mode.
        _pendingLocation = null;
      });
    } else {
      setState(() {
        _resolvingPin = true;

        _pendingLocation =
            immediateLocation;
      });
    }

    debugPrint(
      '[Marker] IMMEDIATELY added at '
          '${latLng.latitude}, ${latLng.longitude}',
    );

    // =========================================================================
    // MOVE CAMERA
    // =========================================================================

    if (moveCamera && _mapController != null) {
      try {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            latLng,
            15,
          ),
        );
      } catch (e) {
        debugPrint(
          '[Map] Camera animation error: $e',
        );
      }
    }

    // =========================================================================
    // POLICE STATIONS
    // =========================================================================

    if (widget.mapScreenModel.showPoliceStations) {
      await _loadNearbyPoliceStations(
        latitude: latLng.latitude,
        longitude: latLng.longitude,
      );
    }

    // =========================================================================
    // REVERSE GEOCODE
    // =========================================================================

    String address = temporaryAddress;

    if (knownAddress == null) {
      try {
        address =
            await PlacesService.reverseGeocode(
              latLng.latitude,
              latLng.longitude,
            ) ??
                'Dropped pin '
                    '(${latLng.latitude.toStringAsFixed(5)}, '
                    '${latLng.longitude.toStringAsFixed(5)})';
      } catch (e) {
        debugPrint(
          '[Location] Reverse geocode error: $e',
        );

        address =
        'Dropped pin '
            '(${latLng.latitude.toStringAsFixed(5)}, '
            '${latLng.longitude.toStringAsFixed(5)})';
      }
    }

    // =========================================================================
    // IGNORE OLD REQUEST
    //
    // Example:
    //
    // User selects A
    // User quickly selects B
    // A's reverse geocode finishes after B
    //
    // We don't allow A to overwrite B.
    // =========================================================================

    if (!mounted ||
        requestId != _locationRequestId) {
      return;
    }

    final resolvedLocation =
    SelectedLocationModel(
      address: address,
      latitude: latLng.latitude,
      longitude: latLng.longitude,
    );

    // =========================================================================
    // UPDATE ADDRESS WITHOUT REMOVING MARKER
    // =========================================================================

    setState(() {
      _resolvingPin = false;

      if (!_addingNewLocation) {
        if (_selectedLocations.isEmpty) {
          // Safety fallback.
          _selectedLocations.add(
            resolvedLocation,
          );
        } else {
          // IMPORTANT:
          // Update the existing selected location.
          // The marker remains because _buildMarkers() uses this list.
          _selectedLocations[0] =
              resolvedLocation;
        }

        // Keep this null in normal mode.
        _pendingLocation = null;
      } else {
        // Add Another mode.
        _pendingLocation =
            resolvedLocation;
      }
    });

    debugPrint(
      '[Marker] PERMANENT marker at '
          '${resolvedLocation.latitude}, '
          '${resolvedLocation.longitude}',
    );
  }

  // ===========================================================================
  // ADD PENDING LOCATION
  // ===========================================================================

  void _addPendingLocation() {
    if (_pendingLocation == null ||
        _resolvingPin) {
      return;
    }

    if (_selectedLocations.length >=
        kMaxLocations) {
      return;
    }

    final pending =
    _pendingLocation!;

    final exists =
    _selectedLocations.any(
          (location) =>
          _isSameLocation(
            location,
            pending,
          ),
    );

    if (exists) {
      return;
    }

    setState(() {
      // Move pending location into permanent list.
      _selectedLocations.add(
        pending,
      );

      _pendingLocation = null;

      _addingNewLocation = false;
    });

    debugPrint(
      '[Marker] Added permanent location: '
          '${pending.latitude}, ${pending.longitude}',
    );
  }

  // ===========================================================================
  // LOCATION COMPARISON
  // ===========================================================================

  bool _isSameLocation(
      SelectedLocationModel first,
      SelectedLocationModel second,
      ) {
    return first.latitude ==
        second.latitude &&
        first.longitude ==
            second.longitude;
  }

  // ===========================================================================
  // REMOVE LOCATION
  // ===========================================================================

  void _removeLocation(
      SelectedLocationModel location,
      ) {
    setState(() {
      _selectedLocations.remove(
        location,
      );
    });

    debugPrint(
      '[Marker] Removed selected location',
    );
  }

  // ===========================================================================
  // CLEAR PENDING PREVIEW
  // ===========================================================================

  void _clearPendingPreview() {
    setState(() {
      _pendingLocation = null;

      _resolvingPin = false;
    });
  }

  // ===========================================================================
  // CONFIRM
  // ===========================================================================

  void _confirm() {
    if (_selectedLocations.isEmpty) {
      return;
    }

    if (widget.mapScreenModel.needSingleLocation) {
      Navigator.pop(
        context,
        _selectedLocations.first,
      );
    } else {
      Navigator.pop(
        context,
        _selectedLocations,
      );
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final canAddMore =
        _selectedLocations.length <
            kMaxLocations;

    return Scaffold(
      resizeToAvoidBottomInset: false,

      body: Stack(
        children: [
          // ===================================================================
          // MAP
          // ===================================================================

          GoogleMap(
            initialCameraPosition:
            _fallbackCamera,

            onMapCreated:
                (controller) async {
              _mapController =
                  controller;

              // ===============================================================
              // Restore camera to existing selected location.
              // ===============================================================

              if (_selectedLocations.isNotEmpty) {
                final location =
                    _selectedLocations.first;

                final target =
                LatLng(
                  location.latitude,
                  location.longitude,
                );

                try {
                  await controller.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      target,
                      15,
                    ),
                  );
                } catch (e) {
                  debugPrint(
                    '[Map] Initial camera error: $e',
                  );
                }
              }
            },

            onTap: _onMapTap,

            myLocationButtonEnabled:
            false,

            zoomControlsEnabled:
            false,

            // =================================================================
            // IMPORTANT:
            //
            // Every rebuild gets markers from _selectedLocations.
            //
            // So changing address/loading state does NOT remove the marker.
            // =================================================================

            markers:
            _buildMarkers(),
          ),

          // ===================================================================
          // SEARCH BAR
          // ===================================================================

          Positioned(
            top:
            MediaQuery.of(context)
                .padding
                .top +
                12,

            left: 16,

            right: 16,

            child:
            _buildSearchBar(),
          ),

          // ===================================================================
          // SEARCH DROPDOWN
          // ===================================================================

          if (_searchFocused)
            Positioned(
              top:
              MediaQuery.of(context)
                  .padding
                  .top +
                  68,

              left: 16,

              right: 16,

              child:
              _buildSuggestionsDropdown(),
            ),

          // ===================================================================
          // POLICE LOADING
          // ===================================================================

          if (widget
              .mapScreenModel
              .showPoliceStations &&
              _loadingPoliceStations)
            Positioned(
              top:
              MediaQuery.of(context)
                  .padding
                  .top +
                  70,

              right: 16,

              child:
              _buildPoliceLoadingIndicator(),
            ),

          // ===================================================================
          // BOTTOM SHEET
          // ===================================================================

          Positioned(
            left: 0,

            right: 0,

            bottom: 0,

            child:
            _buildBottomSheet(
              canAddMore,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MARKERS
  //
  // THIS FUNCTION IS NOW THE SINGLE SOURCE OF TRUTH FOR LOCATION MARKERS.
  // ===========================================================================

  Set<Marker> _buildMarkers() {
    final Set<Marker> markers =
    <Marker>{};

    // =========================================================================
    // POLICE STATION MARKERS
    // =========================================================================

    if (widget.mapScreenModel.showPoliceStations) {
      for (int i = 0;
      i < _policeStations.length;
      i++) {
        final station =
        _policeStations[i];

        markers.add(
          Marker(
            markerId: MarkerId(
              'police_station_$i',
            ),

            position: LatLng(
              station.latitude,
              station.longitude,
            ),

            icon:
            BitmapDescriptor
                .defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),

            infoWindow:
            InfoWindow(
              title:
              station.name,
              snippet:
              station.address,
            ),
          ),
        );
      }
    }

    // =========================================================================
    // PERMANENT SELECTED LOCATION MARKERS
    //
    // NEVER REMOVE THIS BASED ON _resolvingPin.
    //
    // Even while address is being fetched, the marker must remain.
    // =========================================================================

    for (int i = 0;
    i < _selectedLocations.length;
    i++) {
      final location =
      _selectedLocations[i];

      markers.add(
        Marker(
          markerId: MarkerId(
            'selected_location_$i',
          ),

          position: LatLng(
            location.latitude,
            location.longitude,
          ),

          // ===================================================================
          // CUSTOM SVG MARKER
          // ===================================================================

          icon:
          _pinIcon ??
              BitmapDescriptor
                  .defaultMarker,

          // ===================================================================
          // IMPORTANT
          //
          // The coordinate represents the bottom-center of your pin image.
          // ===================================================================

          anchor:
          const Offset(
            0.5,
            1.0,
          ),

          infoWindow:
          InfoWindow(
            title:
            'Selected location',
            snippet:
            location.address,
          ),

          // Allows marker tap.
          consumeTapEvents: false,
        ),
      );
    }

    // =========================================================================
    // PENDING LOCATION
    //
    // Only used for "Add Another Location".
    // =========================================================================

    if (_pendingLocation != null) {
      final pending =
      _pendingLocation!;

      final alreadySelected =
      _selectedLocations.any(
            (location) =>
            _isSameLocation(
              location,
              pending,
            ),
      );

      if (!alreadySelected) {
        markers.add(
          Marker(
            markerId:
            const MarkerId(
              'pending_pin',
            ),

            position: LatLng(
              pending.latitude,
              pending.longitude,
            ),

            icon:
            _pinIcon ??
                BitmapDescriptor
                    .defaultMarker,

            anchor:
            const Offset(
              0.5,
              1.0,
            ),

            infoWindow:
            const InfoWindow(
              title:
              'Selected location',
            ),

            consumeTapEvents:
            false,
          ),
        );
      }
    }

    debugPrint(
      '[Markers] Total markers: ${markers.length}',
    );

    debugPrint(
      '[Markers] Selected locations: '
          '${_selectedLocations.length}',
    );

    debugPrint(
      '[Markers] Pending: '
          '${_pendingLocation != null}',
    );

    return markers;
  }

  // ===========================================================================
  // SEARCH BAR
  // ===========================================================================

  Widget _buildSearchBar() {
    return Row(
      children: [
        buildIconContainer(
          context,

          icon:
          AssetImages
              .iosBackArrow,

          onTap: () {
            context.pop();
          },
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child: AppTextField(
            textController:
            _searchController,

            onChange:
            _onSearchChanged,

            onTap: () {
              setState(() {
                _searchFocused =
                true;
              });
            },

            hintText:
            'Search location',

            onSubmit: (v) {},

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
                _searchController
                    .clear();

                if (!_suggestionsController
                    .isClosed) {
                  _suggestionsController
                      .add([]);
                }

                setState(() {});
              },

              child:
              AppIconWidget(
                assetPath:
                AssetImages
                    .close,
              ).pad(3),
            )
                : null,
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        buildIconContainer(
          context,

          icon:
          AssetImages
              .currentLocation,

          onTap:
          _useCurrentLocation,
        ),
      ],
    );
  }

  // ===========================================================================
  // SEARCH SUGGESTIONS
  // ===========================================================================

  Widget _buildSuggestionsDropdown() {
    return StreamBuilder<
        List<LocationSuggestionModel>>(
      stream:
      _suggestionsController.stream,

      builder:
          (context, snapshot) {
        final suggestions =
            snapshot.data ?? [];

        if (suggestions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          constraints:
          const BoxConstraints(
            maxHeight: 280,
          ),

          decoration:
          BoxDecoration(
            color: Colors.white,

            borderRadius:
            BorderRadius.circular(
              16,
            ),

            boxShadow:
            const [
              BoxShadow(
                color:
                Colors.black12,
                blurRadius: 10,
                offset:
                Offset(0, 4),
              ),
            ],
          ),

          child:
          ListView.separated(
            shrinkWrap: true,

            padding:
            const EdgeInsets.symmetric(
              vertical: 6,
            ),

            itemCount:
            suggestions.length,

            separatorBuilder:
                (_, __) =>
            const Divider(
              height: 1,
            ),

            itemBuilder:
                (context, index) {
              final suggestion =
              suggestions[index];

              return Material(
                color:
                AppColors.white,

                child:
                ListTile(
                  dense: true,

                  leading:
                  AppIconWidget(
                    assetPath:
                    AssetImages
                        .mapIcon,
                  ).pad(),

                  title:
                  AppText(
                    text:
                    suggestion
                        .description,
                    fontSize: 14,
                  ),

                  onTap: () {
                    _onSuggestionTap(
                      suggestion,
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ===========================================================================
  // POLICE LOADING INDICATOR
  // ===========================================================================

  Widget _buildPoliceLoadingIndicator() {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),

      decoration:
      BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(
          20,
        ),

        boxShadow:
        const [
          BoxShadow(
            color:
            Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),

      child: const Row(
        mainAxisSize:
        MainAxisSize.min,

        children: [
          SizedBox(
            height: 16,

            width: 16,

            child:
            CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),

          SizedBox(
            width: 8,
          ),

          Text(
            'Finding police stations...',

            style: TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BOTTOM SHEET
  // ===========================================================================

  Widget _buildBottomSheet(
      bool canAddMore,
      ) {
    final hasPendingPreview =
        _pendingLocation != null &&
            !_selectedLocations.any(
                  (e) =>
              e.latitude ==
                  _pendingLocation!
                      .latitude &&
                  e.longitude ==
                      _pendingLocation!
                          .longitude,
            );

    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        24,
      ),

      decoration:
      const BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(
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

      child: SafeArea(
        child: Column(
          mainAxisSize:
          MainAxisSize.min,

          crossAxisAlignment:
          CrossAxisAlignment
              .start,

          children: [
            AppText(
              text:
              'Selected location',

              fontWeight:
              FontWeight.w600,

              fontSize: 15,
            ),

            const SizedBox(
              height: 8,
            ),

            // =================================================================
            // EMPTY
            // =================================================================

            if (_selectedLocations
                .isEmpty &&
                !hasPendingPreview)
              AppText(
                text:
                'Search or tap on the map to drop a pin.',

                fontSize: 13,

                color:
                AppColors.grey,
              ),

            // =================================================================
            // SELECTED LOCATIONS
            // =================================================================

            ..._selectedLocations.map(
                  (loc) =>
                  _buildLocationCard(
                    loc,

                    isLoading:
                    false,

                    isPending:
                    false,
                  ),
            ),

            // =================================================================
            // PENDING
            // =================================================================

            if (hasPendingPreview)
              _buildLocationCard(
                _pendingLocation!,

                isLoading:
                _resolvingPin,

                isPending:
                true,
              ),

            // =================================================================
            // ADD ANOTHER
            // =================================================================

            if (canAddMore &&
                !widget
                    .mapScreenModel
                    .needSingleLocation) ...[
              const SizedBox(
                height: 8,
              ),

              _buildAddAnotherButton(),
            ],

            // =================================================================
            // HINT
            // =================================================================

            if ((_selectedLocations
                .isNotEmpty ||
                _pendingLocation !=
                    null) &&
                !widget
                    .mapScreenModel
                    .needSingleLocation) ...[
              const SizedBox(
                height: 12,
              ),

              _buildHintBanner(),
            ],

            const SizedBox(
              height: 16,
            ),

            // =================================================================
            // CONFIRM
            // =================================================================

            Opacity(
              opacity:
              _selectedLocations
                  .isEmpty
                  ? 0.5
                  : 1,

              child:
              IgnorePointer(
                ignoring:
                _selectedLocations
                    .isEmpty,

                child:
                AppButton(
                  onTap:
                  _confirm,

                  title:
                  'Confirm location',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // LOCATION CARD
  // ===========================================================================

  Widget _buildLocationCard(
      SelectedLocationModel location, {
        required bool isLoading,
        bool isPending = false,
      }) {
    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),

      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),

      decoration:
      BoxDecoration(
        color:
        const Color(
          0xFFF5F6FA,
        ),

        borderRadius:
        BorderRadius.circular(
          12,
        ),
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,

        children: [
          // ===================================================================
          // LOADING / MAP ICON
          // ===================================================================

          if (isLoading)
            const Padding(
              padding:
              EdgeInsets.only(
                top: 2,
              ),

              child: SizedBox(
                height: 16,

                width: 16,

                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            )
          else
            buildIconContainer(
              context,

              size: 15,

              icon:
              AssetImages
                  .mapIcon,

              height: 28,

              width: 28,
            ),

          const SizedBox(
            width: 10,
          ),

          // ===================================================================
          // ADDRESS
          // ===================================================================

          Expanded(
            child: isLoading
                ? AppText(
              text:
              'Fetching address...',

              fontSize:
              13,

              color:
              AppColors
                  .grey,
            )
                : AppText(
              text:
              location.address,

              fontSize:
              13,

              color:
              Colors.black87,
            ),
          ),

          // ===================================================================
          // DELETE
          // ===================================================================

          if (!isLoading)
            GestureDetector(
              onTap: () {
                if (isPending) {
                  _clearPendingPreview();
                } else {
                  _removeLocation(
                    location,
                  );
                }
              },

              child:
              AppIconWidget(
                assetPath:
                AssetImages
                    .delete,

                color:
                AppColors.black,

                size: 20,
              ).pad(),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ADD ANOTHER BUTTON
  // ===========================================================================

  Widget _buildAddAnotherButton() {
    if (!_addingNewLocation) {
      return AppButton(
        title:
        'Add Another Location',

        onTap: () {
          if (_selectedLocations
              .length >=
              kMaxLocations) {
            return;
          }

          _startAddingAnotherLocation();
        },

        bgColor:
        AppColors.white,

        textColor:
        AppColors.primaryColor,

        fontSize: 14,

        prefixIcon:
        AssetImages.add,

        border:
        Border.all(
          color:
          AppColors.primaryColor,
        ),

        radius:
        const BorderRadius.all(
          Radius.circular(10),
        ),

        height: 40,
      );
    }

    final enabled =
        !_resolvingPin &&
            _pendingLocation !=
                null;

    return AppButton(
      title:
      'Confirm Added Location',

      onTap: () {
        if (enabled) {
          _addPendingLocation();
        }
      },

      bgColor:
      AppColors.white,

      textColor:
      AppColors.primaryColor,

      fontSize: 14,

      prefixIcon:
      AssetImages.tickmark,

      size: 20,

      border:
      Border.all(
        color:
        AppColors.primaryColor,
      ),

      radius:
      const BorderRadius.all(
        Radius.circular(10),
      ),

      height: 40,
    );
  }

  // ===========================================================================
  // HINT BANNER
  // ===========================================================================

  Widget _buildHintBanner() {
    return Container(
      padding:
      const EdgeInsets.all(
        10,
      ),

      decoration:
      BoxDecoration(
        color:
        const Color(
          0xFFF0F3FF,
        ),

        borderRadius:
        BorderRadius.circular(
          10,
        ),
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,

        children: [
          const Icon(
            Icons.lightbulb_outline,

            size: 18,

            color:
            AppColors
                .primaryColor,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: AppText(
              text:
              'You can add up to $kMaxLocations locations. We\'ll search around all selected locations.',

              fontSize: 12,

              color:
              AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// MAP SCREEN MODEL
// =============================================================================

class MapScreenModel {
  final bool needSingleLocation;

  final List<SelectedLocationModel>?
  selectedLocation;

  final bool showPoliceStations;

  MapScreenModel({
    required this.needSingleLocation,
    this.selectedLocation,
    this.showPoliceStations = false,
  });
}

// =============================================================================
// ICON CONTAINER
// =============================================================================

Widget buildIconContainer(
    BuildContext context, {
      VoidCallback? onTap,
      String? icon,
      double? padSize,
      Color? borderColor,
      Color? bgColor,
      Color? iconColor,
      double? height,
      double? width,
      double? size,
    }) {
  return GestureDetector(
    onTap: onTap,

    child: Container(
      height:
      height ?? 40,

      width:
      width ?? 40,

      decoration:
      ShapeDecoration(
        color:
        bgColor ??
            AppColors
                .primaryColor,

        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(
            10,
          ),

          side:
          BorderSide(
            color:
            borderColor ??
                Colors
                    .transparent,
          ),
        ),
      ),

      child: Center(
        child:
        AppIconWidget(
          size:
          size ?? 20,

          assetPath:
          icon ??
              AssetImages
                  .backArrow,

          color:
          iconColor ??
              AppColors
                  .white,

          fit:
          BoxFit.contain,
        ),
      ).pad(
        padSize ?? 2,
      ),
    ),
  );
}