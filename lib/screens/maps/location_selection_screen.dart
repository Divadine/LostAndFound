import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
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
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/shared_widgets/map_pin_loader.dart';
import 'package:lost_and_found/shared_widgets/no_internet_widget.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_permission.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:lost_and_found/utils/app_utils.dart';
import 'package:permission_handler/permission_handler.dart';

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
  // CONNECTIVITY
  // ===========================================================================

  StreamSubscription<List<ConnectivityResult>>?
  _connectivitySub;

  bool _isOffline = false;

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

  bool _isLoadingInitialLocation = false;

  bool _isMapReady = false;

  bool _isInitializing = false;

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

    // Multi-location mode can restore its existing locations.
    // Single-location/Profile mode must start from the user's CURRENT GPS,
    // so an old saved/home location is not restored here.
    if (widget.mapScreenModel.selectedLocation != null &&
        !widget.mapScreenModel.needSingleLocation) {
      _selectedLocations = List<SelectedLocationModel>.from(
        widget.mapScreenModel.selectedLocation!,
      );
    }

    // -------------------------------------------------------------------------
    // LOAD CUSTOM MARKER
    // -------------------------------------------------------------------------

    _loadPinIcon();

    // -------------------------------------------------------------------------
    // LISTEN FOR CONNECTIVITY CHANGES
    // -------------------------------------------------------------------------

    _initConnectivityListener();

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

    _connectivitySub?.cancel();

    super.dispose();
  }

  // ===========================================================================
  // CONNECTIVITY HELPERS
  // ===========================================================================

  void _initConnectivityListener() {
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((results) {
      final offline =
          results.contains(ConnectivityResult.none) ||
              results.isEmpty;

      if (!mounted) return;

      // Only react on a change of state, and only show the toast
      // when we transition from online -> offline.
      if (offline && !_isOffline) {
        _showNoInternetToast();
      }

      final bool recovering = _isOffline && !offline;

      setState(() {
        _isOffline = offline;
      });

      // Recovery trigger: Immediately attempt to fetch location and map data
      if (recovering) {
        _initLocation(isRecovery: true);
      }
    });
  }

  Future<bool> _hasInternetConnection() async {
    // Fast check if possible, otherwise check actual connectivity
    if (_isOffline) return false;

    try {
      final result = await Connectivity().checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  void _showNoInternetToast() {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'No internet connection. Please check your network.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
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

  Future<void> _initLocation({bool isRecovery = false}) async {
    if (_isInitializing) return;

    _isInitializing = true;

    // Show loader: Full-screen if map not ready, otherwise overlay spinner
    if (mounted) {
      setState(() {
        _isLoadingInitialLocation = true;
      });
    }

    try {
      // Permission check - fast check first
      final status = await Permission.location.status;
      if (!status.isGranted) {
        if (!isRecovery) {
          final granted = await _appPermissions.requestLocationPermission(context);
          if (!granted) {
            _isInitializing = false;
            if (mounted) setState(() => _isLoadingInitialLocation = false);
            return;
          }
        } else {
          _isInitializing = false;
          if (mounted) setState(() => _isLoadingInitialLocation = false);
          return;
        }
      }

      final serviceOn = await _appPermissions.isLocationServiceEnabled();
      if (!serviceOn) {
        _isInitializing = false;
        if (mounted) setState(() => _isLoadingInitialLocation = false);
        return;
      }

      // Only multi-location mode restores locations passed by the caller.
      // Single-location/Profile mode MUST fetch the user's current GPS.
      final bool useExistingLocations =
          !widget.mapScreenModel.needSingleLocation &&
              _selectedLocations.isNotEmpty;

      if (useExistingLocations) {
        if (_mapController != null) {
          final selected = _selectedLocations.first;
          try {
            await _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(selected.latitude, selected.longitude),
                15,
              ),
            );
          } catch (e) {
            debugPrint('[Map] Initial camera error: $e');
          }
        }
        _isInitializing = false;
        if (mounted) {
          setState(() => _isLoadingInitialLocation = false);
        }
        return;
      }

      // IMPORTANT:
      // Do NOT use getLastKnownPosition here. It may be an old/home location.
      // Always fetch the user's actual CURRENT GPS for single-location mode.

      if (_isOffline) {
        _isInitializing = false;
        if (mounted) setState(() => _isLoadingInitialLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(const Duration(seconds: 4), onTimeout: () {
        throw TimeoutException('Location timeout');
      });

      if (position != null && mounted) {
        await _setPinFromLatLng(
          LatLng(position.latitude, position.longitude),
          moveCamera: true,
        );
      }
    } catch (e) {
      debugPrint('[LocationSelection] Init/Recovery error: $e');
      if (isRecovery && mounted && !_isOffline) {
        // Retry recovery after a short delay
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) _initLocation(isRecovery: true);
        });
      }
    } finally {
      _isInitializing = false;
      if (mounted) {
        setState(() {
          _isLoadingInitialLocation = false;
        });
      }
    }
  }

  // ===========================================================================
  // CURRENT LOCATION
  // ===========================================================================

  Future<void> _useCurrentLocation() async {
    if (!await _hasInternetConnection()) {
      _showNoInternetToast();
      return;
    }

    final granted =
    await _appPermissions.requestLocationPermission(
      context,
    );

    if (!granted) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );

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

    // Clear previous search text when starting a new location search.
   // _searchController.clear();
    _clearLocationSearch();

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
  // =================================  ==========================================

  void _clearLocationSearch() {
    _debounce?.cancel();

    _searchController.clear();

    if (!_suggestionsController.isClosed) {
      _suggestionsController.add([]);
    }

    if (mounted) {
      setState(() {
        _searchFocused = false;
      });
    }
  }
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
        if (!await _hasInternetConnection()) {
          _showNoInternetToast();

          if (!_suggestionsController.isClosed) {
            _suggestionsController.add([]);
          }

          return;
        }

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
    if (!await _hasInternetConnection()) {
      _showNoInternetToast();
      return;
    }

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
    if (!await _hasInternetConnection()) {
      _showNoInternetToast();
      return;
    }

    debugPrint(
      '[Map] Tapped: '
          '${latLng.latitude}, '
          '${latLng.longitude}',
    );

    _clearLocationSearch();

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

    if (!await _hasInternetConnection()) {
      _showNoInternetToast();

      setState(() {
        _loadingPoliceStations = false;
      });

      return;
    }

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
    // CHECK CONNECTIVITY BEFORE NETWORK CALLS
    //
    // Marker/pin stays visible on the map (already added above) even if we
    // are offline; we just can't resolve the address or nearby stations.
    // =========================================================================

    if (_isOffline) {
      if (!mounted || requestId != _locationRequestId) {
        return;
      }

      final offlineLocation = SelectedLocationModel(
        address: knownAddress ??
            'Dropped pin '
                '(${latLng.latitude.toStringAsFixed(5)}, '
                '${latLng.longitude.toStringAsFixed(5)})',
        latitude: latLng.latitude,
        longitude: latLng.longitude,
      );

      setState(() {
        _resolvingPin = false;

        if (!_addingNewLocation) {
          if (_selectedLocations.isEmpty) {
            _selectedLocations.add(offlineLocation);
          } else {
            _selectedLocations[0] = offlineLocation;
          }

          _pendingLocation = null;
        } else {
          final exists = _selectedLocations.any(
                (location) => _isSameLocation(location, offlineLocation),
          );
          if (!exists && _selectedLocations.length < kMaxLocations) {
            _selectedLocations.add(offlineLocation);
          }
          _pendingLocation = null;
          _addingNewLocation = false;
        }
      });

      return;
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
        // Add Another mode: Add to the list immediately but stay on screen.
        final exists = _selectedLocations.any(
              (location) => _isSameLocation(location, resolvedLocation),
        );
        if (!exists && _selectedLocations.length < kMaxLocations) {
          _selectedLocations.add(resolvedLocation);
        }
        _pendingLocation = null;
        _addingNewLocation = false;
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
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: AppColors.primaryColor,
      ),
      body: Stack(
        children: [
          // ===================================================================
          // MAP
          // ===================================================================

          GoogleMap(
            initialCameraPosition: _fallbackCamera,
            onMapCreated: (controller) async {
              _mapController = controller;
              if (mounted) {
                setState(() {
                  _isMapReady = true;
                });
              }

              // ===============================================================
              // Restore camera only for multi-location mode.
              // Single-location mode is positioned by CURRENT GPS in
              // _initLocation(), so an old saved/home location must not
              // override it here.
              // ===============================================================

              if (!widget.mapScreenModel.needSingleLocation &&
                  _selectedLocations.isNotEmpty) {
                final location = _selectedLocations.first;
                final target = LatLng(
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
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _buildMarkers(),
          ),

          // ===================================================================
          // INITIAL / OFFLINE LOADER
          // ===================================================================

          if (!_isMapReady || _isOffline)
            Container(
              color: AppColors.white,
              child: _isOffline
                  ? const NoInternetWidget()
                  : const Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_isLoadingInitialLocation)
            Center(
              child: IgnorePointer(
                child: _isOffline
                    ? const NoInternetWidget(size: 50)
                    : const CircularProgressIndicator(),
              ),
            ),

          // ===================================================================
          // OFFLINE BANNER
          // ===================================================================

          // if (_isOffline)
          //   Positioned(
          //     top: MediaQuery.of(context).padding.top,
          //     left: 0,
          //     right: 0,
          //     child: _buildOfflineBanner(),
          //   ),

          // ===================================================================
          // SEARCH BAR
          // ===================================================================

          Positioned(
            top:
            MediaQuery.of(context)
                .padding
                .top +
                (_isOffline ? 40 : 0) +
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
                  (_isOffline ? 40 : 0) +
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
                  (_isOffline ? 40 : 0) +
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
  // OFFLINE BANNER
  // ===========================================================================

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      color: Colors.redAccent,
      padding: const EdgeInsets.symmetric(
        vertical: 6,
        horizontal: 12,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            size: 14,
            color: Colors.white,
          ),
          SizedBox(width: 6),
          Text(
            'No internet connection',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
            InfoWindow(
              title:
              'Selected location',
              snippet: pending.address,
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
          height: 45,
          width: 45,
          icon: AssetImages.iosBackArrow,
          onTap: () {
            context.pop();
          },
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 45),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AppTextField(
              textController: _searchController,
              onChange: _onSearchChanged,
              onTap: () {
                setState(() {
                  _searchFocused = true;
                });
              },
              hintText: 'Search location',
              onSubmit: (v) {},
              borderColor: Colors.transparent,
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12.0),
                child: AppIconWidget(
                  assetPath: AssetImages.search,
                  color: Colors.grey,
                  size: 18,
                ),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? GestureDetector(
                onTap: () {
                  _searchController.clear();
                  if (!_suggestionsController.isClosed) {
                    _suggestionsController.add([]);
                  }
                  setState(() {});
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: AppIconWidget(
                    assetPath: AssetImages.close,
                    color: Colors.grey,
                    size: 18,
                  ),
                ),
              )
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 10),
        buildIconContainer(
          context,
          height: 45,
          width: 45,
          icon: AssetImages.currentLocation,
          onTap: _useCurrentLocation,
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

      child: Row(
        mainAxisSize:
        MainAxisSize.min,

        children: [
          SizedBox(
            height: 16,

            width: 16,

            child: _isOffline
                ? const NoInternetWidget(size: 16, showText: false)
                : const CircularProgressIndicator(
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
                Center(
                  child: AppButton(
                    width: AppUtils.isTab ? 300 : 200,
                    onTap:
                    _confirm,

                    title:
                    'Confirm location',
                  ),
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
    return AppContainer(
      height:55,
      // margin:
      // const EdgeInsets.only(
      //   bottom: 10,
      // ),
      //
      // padding:
      // const EdgeInsets.symmetric(
      //   horizontal: 12,
      //   vertical: 10,
      // ),

      // decoration:
      // BoxDecoration(
      //   color:
      //   const Color(
      //     0xFFF5F6FA,
      //   ),
      //
      //   borderRadius:
      //   BorderRadius.circular(
      //     12,
      //   ),
      // ),

      widget:
       Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment:
        CrossAxisAlignment
            .center,

        children: [
          // ===================================================================
          // LOADING / MAP ICON
          // ===================================================================

          if (isLoading)
            Padding(
              padding:
              const EdgeInsets.only(
                top: 2,
              ),

              child: SizedBox(
                height: 16,

                width: 16,

                child: _isOffline
                    ? const NoInternetWidget(size: 16, showText: false)
                    : const CircularProgressIndicator(
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
      ).padHorizontal(),
    ).pad();
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

    return const SizedBox.shrink();
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
  final bool isNearby;

  MapScreenModel({
    required this.needSingleLocation,
    this.selectedLocation,
    this.showPoliceStations = false,
    this.isNearby = false,
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
          5,
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