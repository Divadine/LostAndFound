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

  static const String _fetchingAddressText = 'Fetching address...';

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
  BitmapDescriptor? _policePinIcon;

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
  PoliceStationModel? _selectedPoliceStation;

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

    // Multi-location mode can restore its existing locations.
    // Single-location/Profile mode must start from the user's CURRENT GPS,
    // so an old saved/home location is not restored here.
    if (widget.mapScreenModel.selectedLocation != null &&
        !widget.mapScreenModel.needSingleLocation) {
      _selectedLocations = List<SelectedLocationModel>.from(
        widget.mapScreenModel.selectedLocation!,
      );
    }

    _loadPinIcon();

    _initConnectivityListener();

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

      if (offline && !_isOffline) {
        _showNoInternetToast();
      }

      final bool recovering = _isOffline && !offline;

      setState(() {
        _isOffline = offline;
      });

      if (recovering) {
        _initLocation(isRecovery: true);
      }
    });
  }

  Future<bool> _hasInternetConnection() async {
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
  // CUSTOM MARKERS
  // ===========================================================================

  Future<void> _loadPinIcon() async {
    try {
      final icon = await MapPinIconLoader.load(
        _pinAssetPath,
        size: 110,
      );

      BitmapDescriptor? policeIcon;
      try {
        policeIcon = await MapPinIconLoader.load(
          AssetImages.nearByMap,
          size: 70,
        );
      } catch (e) {
        debugPrint('[PolicePin] Failed to load custom police marker: $e');
      }

      if (!mounted) return;

      setState(() {
        _pinIcon = icon;
        _policePinIcon = policeIcon;
      });

      debugPrint(
        '[MapPin] Custom markers loaded successfully',
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

    if (mounted) {
      setState(() {
        _isLoadingInitialLocation = true;
      });
    }

    try {
      final status = await Permission.location.status;
      if (!status.isGranted) {
        if (!isRecovery) {
          if (!mounted) return;
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

      if (_isOffline) {
        _isInitializing = false;
        if (mounted) setState(() => _isLoadingInitialLocation = false);
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          ),
        ).timeout(const Duration(seconds: 5), onTimeout: () {
          if (position != null) return position;
          throw TimeoutException('Location timeout');
        });
      } catch (e) {
        debugPrint('[LocationSelection] Get position error: $e');
      }

      if (position != null && mounted) {
        await _setPinFromLatLng(
          LatLng(position.latitude, position.longitude),
          moveCamera: true,
        );
      }
    } catch (e) {
      debugPrint('[LocationSelection] Init/Recovery error: $e');
      if (isRecovery && mounted && !_isOffline) {
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

    if (!mounted) return;
    final granted = await _appPermissions.requestLocationPermission(
      context,
    );

    if (!granted) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
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
  // ===========================================================================

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
      '[LocationSearch] Selected: ${suggestion.description}',
    );

    _searchController.text = suggestion.description;

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
      '[Map] Tapped: ${latLng.latitude}, ${latLng.longitude}',
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
    required int requestId,
  }) async {
    if (!mounted) return;

    if (!await _hasInternetConnection()) {
      _showNoInternetToast();

      if (requestId == _locationRequestId) {
        setState(() {
          _loadingPoliceStations = false;
        });
      }
      return;
    }

    if (requestId == _locationRequestId) {
      setState(() {
        _loadingPoliceStations = true;
        _policeStations = [];
      });
    }

    try {
      final response =
      await authController.getNearbyPoliceStations(
        latitude: latitude,
        longitude: longitude,
        radiusKm: _policeSearchRadiusKm,
      );

      if (!mounted || requestId != _locationRequestId) return;

      if (!response.isSuccess ||
          response.data == null) {
        setState(() {
          _policeStations = [];
          _loadingPoliceStations = false;
        });
        return;
      }

      setState(() {
        _policeStations = response.data!;
        _loadingPoliceStations = false;
      });

      debugPrint(
        '[PoliceStations] Found: ${_policeStations.length}',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '[PoliceStations] ERROR: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted || requestId != _locationRequestId) return;

      setState(() {
        _policeStations = [];
        _loadingPoliceStations = false;
      });
    }
  }

  // ===========================================================================
  // SELECT POLICE STATION
  // ===========================================================================

  void _selectPoliceStation(PoliceStationModel station) {
    if (!mounted) return;

    ++_locationRequestId;

    final stationLocation = SelectedLocationModel(
      address: station.address,
      latitude: station.latitude,
      longitude: station.longitude,
      name: station.name,
    );

    setState(() {
      _selectedPoliceStation = station;
      _resolvingPin = false;

      if (_selectedLocations.isEmpty) {
        _selectedLocations.add(stationLocation);
      } else {
        _selectedLocations[0] = stationLocation;
      }
      _pendingLocation = null;
    });

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(station.latitude, station.longitude),
          15,
        ),
      );
    }
  }

  // ===========================================================================
  // SET PIN
  // ===========================================================================

  Future<void> _setPinFromLatLng(
      LatLng latLng, {
        required bool moveCamera,
        String? knownAddress,
      }) async {
    if (!mounted) return;

    final int requestId = ++_locationRequestId;
    _selectedPoliceStation = null;

    final String temporaryAddress = knownAddress ?? _fetchingAddressText;

    final immediateLocation = SelectedLocationModel(
      address: temporaryAddress,
      latitude: latLng.latitude,
      longitude: latLng.longitude,
    );

    if (!_addingNewLocation) {
      setState(() {
        _resolvingPin = true;

        if (_selectedLocations.isEmpty) {
          _selectedLocations.add(immediateLocation);
        } else {
          _selectedLocations[0] = immediateLocation;
        }

        _pendingLocation = null;
      });
    } else {
      setState(() {
        _resolvingPin = true;
        _pendingLocation = immediateLocation;
      });
    }

    if (moveCamera && _mapController != null) {
      try {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 15),
        );
      } catch (e) {
        debugPrint('[Map] Camera animation error: $e');
      }
    }

    if (_isOffline) {
      if (!mounted || requestId != _locationRequestId) return;

      final offlineLocation = SelectedLocationModel(
        address: knownAddress ??
            'Dropped pin (${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)})',
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

    if (widget.mapScreenModel.showPoliceStations) {
      _loadNearbyPoliceStations(
        latitude: latLng.latitude,
        longitude: latLng.longitude,
        requestId: requestId,
      );
    }

    String address = temporaryAddress;
    String? pincode;

    if (widget.mapScreenModel.fetchPincode) {
      try {
        final geocodeResult = await PlacesService.reverseGeocodeWithPincode(
          latLng.latitude,
          latLng.longitude,
        );
        address = knownAddress ??
            geocodeResult?.address ??
            'Dropped pin (${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)})';
        pincode = geocodeResult?.pincode;
      } catch (e) {
        debugPrint('[Location] Reverse geocode error: $e');
        address = knownAddress ??
            'Dropped pin (${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)})';
      }
    } else if (knownAddress == null) {
      try {
        address = await PlacesService.reverseGeocode(
          latLng.latitude,
          latLng.longitude,
        ) ??
            'Dropped pin (${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)})';
      } catch (e) {
        debugPrint('[Location] Reverse geocode error: $e');
        address = 'Dropped pin (${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)})';
      }
    }

    if (!mounted || requestId != _locationRequestId) return;

    final resolvedLocation = SelectedLocationModel(
      address: address,
      latitude: latLng.latitude,
      longitude: latLng.longitude,
      pincode: pincode,
    );

    setState(() {
      _resolvingPin = false;

      if (!_addingNewLocation) {
        if (_selectedLocations.isEmpty) {
          _selectedLocations.add(resolvedLocation);
        } else {
          _selectedLocations[0] = resolvedLocation;
        }
        _pendingLocation = null;
      } else {
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
      _selectedLocations.add(
        pending,
      );

      _pendingLocation = null;
      _addingNewLocation = false;
    });
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
    if (_selectedLocations.isEmpty) return;

    // Safety: never return the placeholder address / while still resolving
    if (_resolvingPin) return;
    if (_selectedLocations.any((l) => l.address == _fetchingAddressText)) {
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
          GoogleMap(
            initialCameraPosition: _fallbackCamera,
            onMapCreated: (controller) async {
              _mapController = controller;
              if (mounted) {
                setState(() {
                  _isMapReady = true;
                });
              }

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

          Positioned(
            top:
            MediaQuery.of(context)
                .padding
                .top +
                (_isOffline ? 40 : 0) +
                12,
            left: 16,
            right: 16,
            child: _buildSearchBar(),
          ),

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
              child: _buildSuggestionsDropdown(),
            ),

          if (widget.mapScreenModel.showPoliceStations &&
              _loadingPoliceStations)
            Positioned(
              top:
              MediaQuery.of(context)
                  .padding
                  .top +
                  (_isOffline ? 40 : 0) +
                  70,
              right: 16,
              child: _buildPoliceLoadingIndicator(),
            ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomSheet(
              canAddMore,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MARKERS
  // ===========================================================================

  Set<Marker> _buildMarkers() {
    final Set<Marker> markers = <Marker>{};

    if (widget.mapScreenModel.showPoliceStations) {
      for (int i = 0; i < _policeStations.length; i++) {
        final station = _policeStations[i];

        final isSelected = _selectedPoliceStation?.id == station.id ||
            (_selectedPoliceStation?.latitude == station.latitude &&
                _selectedPoliceStation?.longitude == station.longitude);

        markers.add(
          Marker(
            markerId: MarkerId('police_station_${station.id}_$i'),
            position: LatLng(station.latitude, station.longitude),
            icon: _policePinIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue,
                ),
            anchor: const Offset(0.5, 1.0),
            zIndexInt: isSelected ? 2 : 1,
            alpha: isSelected ? 1.0 : 0.85,
            infoWindow: InfoWindow(
              title: station.name,
              snippet: station.address,
            ),
            onTap: () {
              _selectPoliceStation(station);
            },
          ),
        );
      }
    }

    for (int i = 0; i < _selectedLocations.length; i++) {
      final location = _selectedLocations[i];

      markers.add(
        Marker(
          markerId: MarkerId('selected_location_$i'),
          position: LatLng(
            location.latitude,
            location.longitude,
          ),
          icon: _pinIcon ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 1.0),
          zIndexInt: 3,
          infoWindow: InfoWindow(
            title: location.name ?? 'Selected location',
            snippet: location.address,
          ),
          consumeTapEvents: false,
        ),
      );
    }

    if (_pendingLocation != null) {
      final pending = _pendingLocation!;

      final alreadySelected = _selectedLocations.any(
            (location) => _isSameLocation(
          location,
          pending,
        ),
      );

      if (!alreadySelected) {
        markers.add(
          Marker(
            markerId: const MarkerId('pending_pin'),
            position: LatLng(
              pending.latitude,
              pending.longitude,
            ),
            icon: _pinIcon ?? BitmapDescriptor.defaultMarker,
            anchor: const Offset(0.5, 1.0),
            zIndexInt: 3,
            infoWindow: InfoWindow(
              title: pending.name ?? 'Selected location',
              snippet: pending.address,
            ),
            consumeTapEvents: false,
          ),
        );
      }
    }

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
                  color: Colors.black.withAlpha(13),
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
    return StreamBuilder<List<LocationSuggestionModel>>(
      stream: _suggestionsController.stream,
      builder: (context, snapshot) {
        final suggestions = snapshot.data ?? [];

        if (suggestions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          constraints: const BoxConstraints(
            maxHeight: 280,
          ),
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
            padding: const EdgeInsets.symmetric(
              vertical: 6,
            ),
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
            ),
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];

              return Material(
                color: AppColors.white,
                child: ListTile(
                  dense: true,
                  leading: AppIconWidget(
                    assetPath: AssetImages.mapIcon,
                  ).pad(),
                  title: AppText(
                    text: suggestion.description,
                    fontSize: 14,
                  ),
                  onTap: () {
                    _onSuggestionTap(suggestion);
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
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(width: 8),
          const Text(
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
    final hasPendingPreview = _pendingLocation != null &&
        !_selectedLocations.any(
              (e) =>
          e.latitude == _pendingLocation!.latitude &&
              e.longitude == _pendingLocation!.longitude,
        );

    // Confirm button is disabled until the address is resolved
    final bool isFetchingAddress =
    _selectedLocations.any((l) => l.address == _fetchingAddressText);

    final bool canConfirm =
        _selectedLocations.isNotEmpty && !isFetchingAddress && !_resolvingPin;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              text: widget.mapScreenModel.showPoliceStations &&
                  _selectedPoliceStation != null
                  ? 'Selected Police Station'
                  : 'Selected location',
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),

            const SizedBox(height: 8),

            if (_selectedLocations.isEmpty && !hasPendingPreview)
              AppText(
                text: 'Search or tap on the map to drop a pin.',
                fontSize: 13,
                color: AppColors.grey,
              ),

            ..._selectedLocations.map(
                  (loc) => _buildLocationCard(
                loc,
                isLoading: loc.address == _fetchingAddressText,
                isPending: false,
              ),
            ),

            if (hasPendingPreview)
              _buildLocationCard(
                _pendingLocation!,
                isLoading: _resolvingPin,
                isPending: true,
              ),

            if (widget.mapScreenModel.showPoliceStations &&
                !_loadingPoliceStations &&
                _policeStations.isEmpty) ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.fieldGrey.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const AppText(
                  text: 'No police stations found nearby',
                  fontSize: 12,
                  color: AppColors.grey,
                ),
              ),
            ],

            if (canAddMore &&
                !widget.mapScreenModel.needSingleLocation) ...[
              const SizedBox(height: 8),
              _buildAddAnotherButton(),
            ],

            if ((_selectedLocations.isNotEmpty ||
                _pendingLocation != null) &&
                !widget.mapScreenModel.needSingleLocation) ...[
              const SizedBox(height: 12),
              _buildHintBanner(),
            ],

            const SizedBox(height: 16),

            Opacity(
              opacity: canConfirm ? 1 : 0.5,
              child: IgnorePointer(
                ignoring: !canConfirm,
                child: Center(
                  child: AppButton(
                    width: AppUtils.isTab ? 300 : 200,
                    onTap: _confirm,
                    title: 'Confirm location',
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
    final bool hasName = location.name != null && location.name!.isNotEmpty;

    return AppContainer(
      widget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildIconContainer(
                context,
                size: 15,
                icon: AssetImages.mapIcon,
                height: 28,
                width: 28,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: isLoading
                    ? const Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasName) ...[
                      AppText(
                        text: location.name!,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        maxLine: 1,
                        textOverflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                    ],
                    AppText(
                      text: location.address,
                      fontSize: 12,
                      maxLine: 2,
                      textOverflow: TextOverflow.ellipsis,
                      color: hasName ? AppColors.grey : Colors.black87,
                    ),
                  ],
                ),
              ),

              if (!isLoading)
                GestureDetector(
                  onTap: () {
                    if (isPending) {
                      _clearPendingPreview();
                    } else {
                      _removeLocation(location);
                    }
                  },
                  child: AppIconWidget(
                    assetPath: AssetImages.delete,
                    color: AppColors.black,
                    size: 20,
                  ).pad(),
                ),
            ],
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
        title: 'Add Another Location',
        onTap: () {
          if (_selectedLocations.length >= kMaxLocations) {
            return;
          }
          _startAddingAnotherLocation();
        },
        bgColor: AppColors.white,
        textColor: AppColors.primaryColor,
        fontSize: 14,
        prefixIcon: AssetImages.add,
        border: Border.all(
          color: AppColors.primaryColor,
        ),
        radius: const BorderRadius.all(
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            size: 18,
            color: AppColors.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppText(
              text:
              'You can add up to $kMaxLocations locations. We\'ll search around all selected locations.',
              fontSize: 12,
              color: AppColors.grey,
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
  final bool fetchPincode;

  MapScreenModel({
    required this.needSingleLocation,
    this.selectedLocation,
    this.showPoliceStations = false,
    this.isNearby = false,
    this.fetchPincode = false,
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
      height: height ?? 40,
      width: width ?? 40,
      decoration: ShapeDecoration(
        color: bgColor ?? AppColors.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
          side: BorderSide(
            color: borderColor ?? Colors.transparent,
          ),
        ),
      ),
      child: Center(
        child: AppIconWidget(
          size: size ?? 20,
          assetPath: icon ?? AssetImages.backArrow,
          color: iconColor ?? AppColors.white,
          fit: BoxFit.contain,
        ),
      ).pad(
        padSize ?? 2,
      ),
    ),
  );
}
// import 'dart:async';
//
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
//
// import 'package:lost_and_found/api_providers/api_client.dart';
// import 'package:lost_and_found/controllers/auth_controllers.dart';
// import 'package:lost_and_found/models/handover/location_suggestion.dart';
// import 'package:lost_and_found/models/handover/police_station.dart';
// import 'package:lost_and_found/repository/Auth_repository.dart';
// import 'package:lost_and_found/services/place_service.dart';
// import 'package:lost_and_found/models/posts_model/selected_location_model.dart';
// import 'package:lost_and_found/shared_widgets/app_button.dart';
// import 'package:lost_and_found/shared_widgets/app_container.dart';
// import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
// import 'package:lost_and_found/shared_widgets/app_text.dart';
// import 'package:lost_and_found/shared_widgets/app_text_field.dart';
// import 'package:lost_and_found/shared_widgets/map_pin_loader.dart';
// import 'package:lost_and_found/shared_widgets/no_internet_widget.dart';
// import 'package:lost_and_found/utils/app_colors.dart';
// import 'package:lost_and_found/utils/app_images.dart';
// import 'package:lost_and_found/utils/app_permission.dart';
// import 'package:lost_and_found/utils/app_ui_helper.dart';
// import 'package:lost_and_found/utils/app_utils.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class LocationSelectionScreen extends StatefulWidget {
//   final MapScreenModel mapScreenModel;
//
//   const LocationSelectionScreen({
//     super.key,
//     required this.mapScreenModel,
//   });
//
//   @override
//   State<LocationSelectionScreen> createState() =>
//       _LocationSelectionScreenState();
// }
//
// class _LocationSelectionScreenState
//     extends State<LocationSelectionScreen> {
//   // ===========================================================================
//   // CONTROLLER
//   // ===========================================================================
//
//   final authController = AuthControllers(
//     authRepository: AuthRepository(
//       apiClient: ApiClient(),
//     ),
//   );
//
//   // ===========================================================================
//   // CONSTANTS
//   // ===========================================================================
//
//   static const int kMaxLocations = 3;
//
//   static const double _policeSearchRadiusKm = 15;
//
//   static const CameraPosition _fallbackCamera = CameraPosition(
//     target: LatLng(
//       11.0168,
//       76.9558,
//     ),
//     zoom: 11,
//   );
//
//   static const String _pinAssetPath =
//       'assets/images/map_pin.svg';
//
//   // ===========================================================================
//   // SERVICES
//   // ===========================================================================
//
//   final AppPermissions _appPermissions =
//   AppPermissions();
//
//   // ===========================================================================
//   // CONNECTIVITY
//   // ===========================================================================
//
//   StreamSubscription<List<ConnectivityResult>>?
//   _connectivitySub;
//
//   bool _isOffline = false;
//
//   // ===========================================================================
//   // SEARCH
//   // ===========================================================================
//
//   final TextEditingController _searchController =
//   TextEditingController();
//
//   final StreamController<List<LocationSuggestionModel>>
//   _suggestionsController =
//   StreamController<List<LocationSuggestionModel>>.broadcast();
//
//   Timer? _debounce;
//
//   bool _searchFocused = false;
//
//   // ===========================================================================
//   // MAP
//   // ===========================================================================
//
//   GoogleMapController? _mapController;
//
//   BitmapDescriptor? _pinIcon;
//   BitmapDescriptor? _policePinIcon;
//
//   bool _resolvingPin = false;
//
//   bool _addingNewLocation = false;
//
//   bool _isLoadingInitialLocation = false;
//
//   bool _isMapReady = false;
//
//   bool _isInitializing = false;
//
//   // ===========================================================================
//   // LOCATION
//   // ===========================================================================
//
//   SelectedLocationModel? _pendingLocation;
//
//   List<SelectedLocationModel> _selectedLocations =
//   [];
//
//   // ===========================================================================
//   // POLICE STATIONS
//   // ===========================================================================
//
//   List<PoliceStationModel> _policeStations = [];
//   PoliceStationModel? _selectedPoliceStation;
//
//   bool _loadingPoliceStations = false;
//
//   // ===========================================================================
//   // ASYNC SELECTION CONTROL
//   //
//   // Every time the user selects a new location, this number changes.
//   // If an old reverse-geocoding request finishes later, it will not overwrite
//   // the newer selected location.
//   // ===========================================================================
//
//   int _locationRequestId = 0;
//
//   // ===========================================================================
//   // INIT
//   // ===========================================================================
//
//   @override
//   void initState() {
//     super.initState();
//
//     // -------------------------------------------------------------------------
//     // RESTORE PREVIOUS LOCATIONS
//     // -------------------------------------------------------------------------
//
//     // Multi-location mode can restore its existing locations.
//     // Single-location/Profile mode must start from the user's CURRENT GPS,
//     // so an old saved/home location is not restored here.
//     if (widget.mapScreenModel.selectedLocation != null &&
//         !widget.mapScreenModel.needSingleLocation) {
//       _selectedLocations = List<SelectedLocationModel>.from(
//         widget.mapScreenModel.selectedLocation!,
//       );
//     }
//
//     // -------------------------------------------------------------------------
//     // LOAD CUSTOM MARKER
//     // -------------------------------------------------------------------------
//
//     _loadPinIcon();
//
//     // -------------------------------------------------------------------------
//     // LISTEN FOR CONNECTIVITY CHANGES
//     // -------------------------------------------------------------------------
//
//     _initConnectivityListener();
//
//     // -------------------------------------------------------------------------
//     // INITIALIZE LOCATION
//     // -------------------------------------------------------------------------
//
//     _initLocation();
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//
//     _suggestionsController.close();
//
//     _debounce?.cancel();
//
//     _connectivitySub?.cancel();
//
//     super.dispose();
//   }
//
//   // ===========================================================================
//   // CONNECTIVITY HELPERS
//   // ===========================================================================
//
//   void _initConnectivityListener() {
//     _connectivitySub = Connectivity()
//         .onConnectivityChanged
//         .listen((results) {
//       final offline =
//           results.contains(ConnectivityResult.none) ||
//               results.isEmpty;
//
//       if (!mounted) return;
//
//       if (offline && !_isOffline) {
//         _showNoInternetToast();
//       }
//
//       final bool recovering = _isOffline && !offline;
//
//       setState(() {
//         _isOffline = offline;
//       });
//
//       if (recovering) {
//         _initLocation(isRecovery: true);
//       }
//     });
//   }
//
//   Future<bool> _hasInternetConnection() async {
//     if (_isOffline) return false;
//
//     try {
//       final result = await Connectivity().checkConnectivity();
//       return !result.contains(ConnectivityResult.none);
//     } catch (_) {
//       return false;
//     }
//   }
//
//   void _showNoInternetToast() {
//     if (!mounted) return;
//
//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(
//         const SnackBar(
//           content: Text(
//             'No internet connection. Please check your network.',
//           ),
//           duration: Duration(seconds: 2),
//         ),
//       );
//   }
//
//   // ===========================================================================
//   // CUSTOM MARKERS
//   // ===========================================================================
//
//   Future<void> _loadPinIcon() async {
//     try {
//       final icon = await MapPinIconLoader.load(
//         _pinAssetPath,
//         size: 110,
//       );
//
//       BitmapDescriptor? policeIcon;
//       try {
//         policeIcon = await MapPinIconLoader.load(
//           AssetImages.nearByMap,
//           size: 70,
//         );
//       } catch (e) {
//         debugPrint('[PolicePin] Failed to load custom police marker: $e');
//       }
//
//       if (!mounted) return;
//
//       setState(() {
//         _pinIcon = icon;
//         _policePinIcon = policeIcon;
//       });
//
//       debugPrint(
//         '[MapPin] Custom markers loaded successfully',
//       );
//     } catch (e) {
//       debugPrint(
//         '[MapPin] Failed to load custom marker: $e',
//       );
//     }
//   }
//
//   // ===========================================================================
//   // INITIAL LOCATION
//   // ===========================================================================
//
//   Future<void> _initLocation({bool isRecovery = false}) async {
//     if (_isInitializing) return;
//
//     _isInitializing = true;
//
//     if (mounted) {
//       setState(() {
//         _isLoadingInitialLocation = true;
//       });
//     }
//
//     try {
//       final status = await Permission.location.status;
//       if (!status.isGranted) {
//         if (!isRecovery) {
//           if (!mounted) return;
//           final granted = await _appPermissions.requestLocationPermission(context);
//           if (!granted) {
//             _isInitializing = false;
//             if (mounted) setState(() => _isLoadingInitialLocation = false);
//             return;
//           }
//         } else {
//           _isInitializing = false;
//           if (mounted) setState(() => _isLoadingInitialLocation = false);
//           return;
//         }
//       }
//
//       final serviceOn = await _appPermissions.isLocationServiceEnabled();
//       if (!serviceOn) {
//         _isInitializing = false;
//         if (mounted) setState(() => _isLoadingInitialLocation = false);
//         return;
//       }
//
//       final bool useExistingLocations =
//           !widget.mapScreenModel.needSingleLocation &&
//               _selectedLocations.isNotEmpty;
//
//       if (useExistingLocations) {
//         if (_mapController != null) {
//           final selected = _selectedLocations.first;
//           try {
//             await _mapController!.animateCamera(
//               CameraUpdate.newLatLngZoom(
//                 LatLng(selected.latitude, selected.longitude),
//                 15,
//               ),
//             );
//           } catch (e) {
//             debugPrint('[Map] Initial camera error: $e');
//           }
//         }
//         _isInitializing = false;
//         if (mounted) {
//           setState(() => _isLoadingInitialLocation = false);
//         }
//         return;
//       }
//
//       if (_isOffline) {
//         _isInitializing = false;
//         if (mounted) setState(() => _isLoadingInitialLocation = false);
//         return;
//       }
//
//       Position? position;
//       try {
//         position = await Geolocator.getLastKnownPosition();
//       } catch (_) {}
//
//       try {
//         position = await Geolocator.getCurrentPosition(
//           locationSettings: const LocationSettings(
//             accuracy: LocationAccuracy.medium,
//             timeLimit: Duration(seconds: 5),
//           ),
//         ).timeout(const Duration(seconds: 5), onTimeout: () {
//           if (position != null) return position;
//           throw TimeoutException('Location timeout');
//         });
//       } catch (e) {
//         debugPrint('[LocationSelection] Get position error: $e');
//       }
//
//       if (position != null && mounted) {
//         await _setPinFromLatLng(
//           LatLng(position.latitude, position.longitude),
//           moveCamera: true,
//         );
//       }
//     } catch (e) {
//       debugPrint('[LocationSelection] Init/Recovery error: $e');
//       if (isRecovery && mounted && !_isOffline) {
//         Future.delayed(const Duration(seconds: 3), () {
//           if (mounted) _initLocation(isRecovery: true);
//         });
//       }
//     } finally {
//       _isInitializing = false;
//       if (mounted) {
//         setState(() {
//           _isLoadingInitialLocation = false;
//         });
//       }
//     }
//   }
//
//   // ===========================================================================
//   // CURRENT LOCATION
//   // ===========================================================================
//
//   Future<void> _useCurrentLocation() async {
//     if (!await _hasInternetConnection()) {
//       _showNoInternetToast();
//       return;
//     }
//
//     if (!mounted) return;
//     final granted = await _appPermissions.requestLocationPermission(
//       context,
//     );
//
//     if (!granted) return;
//
//     try {
//       final position = await Geolocator.getCurrentPosition(
//         locationSettings: const LocationSettings(
//           accuracy: LocationAccuracy.medium,
//           timeLimit: Duration(seconds: 5),
//         ),
//       );
//
//       await _setPinFromLatLng(
//         LatLng(
//           position.latitude,
//           position.longitude,
//         ),
//         moveCamera: true,
//       );
//     } catch (e) {
//       debugPrint(
//         '[Location] Current location error: $e',
//       );
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Unable to fetch current location',
//             ),
//           ),
//         );
//       }
//     }
//   }
//
//   // ===========================================================================
//   // ADD ANOTHER LOCATION
//   // ===========================================================================
//
//   void _startAddingAnotherLocation() {
//     if (_selectedLocations.length >= kMaxLocations) {
//       return;
//     }
//
//     _clearLocationSearch();
//
//     setState(() {
//       _addingNewLocation = true;
//       _pendingLocation = null;
//     });
//
//     debugPrint(
//       '[Location] Started adding another location',
//     );
//   }
//
//   // ===========================================================================
//   // SEARCH
//   // ===========================================================================
//
//   void _clearLocationSearch() {
//     _debounce?.cancel();
//
//     _searchController.clear();
//
//     if (!_suggestionsController.isClosed) {
//       _suggestionsController.add([]);
//     }
//
//     if (mounted) {
//       setState(() {
//         _searchFocused = false;
//       });
//     }
//   }
//
//   void _onSearchChanged(String value) {
//     _debounce?.cancel();
//
//     if (value.trim().isEmpty) {
//       if (!_suggestionsController.isClosed) {
//         _suggestionsController.add([]);
//       }
//
//       return;
//     }
//
//     _debounce = Timer(
//       const Duration(
//         milliseconds: 400,
//       ),
//           () async {
//         if (!await _hasInternetConnection()) {
//           _showNoInternetToast();
//
//           if (!_suggestionsController.isClosed) {
//             _suggestionsController.add([]);
//           }
//
//           return;
//         }
//
//         try {
//           final query = value.trim();
//
//           debugPrint(
//             '[LocationSearch] Searching: $query',
//           );
//
//           final response =
//           await authController.searchLocation(
//             query: query,
//             limit: 5,
//           );
//
//           if (!mounted ||
//               _suggestionsController.isClosed) {
//             return;
//           }
//
//           if (!response.isSuccess ||
//               response.data == null) {
//             _suggestionsController.add([]);
//
//             return;
//           }
//
//           _suggestionsController.add(
//             response.data!,
//           );
//         } catch (e) {
//           debugPrint(
//             '[LocationSearch] ERROR: $e',
//           );
//
//           if (!_suggestionsController.isClosed) {
//             _suggestionsController.add([]);
//           }
//         }
//       },
//     );
//   }
//
//   // ===========================================================================
//   // SEARCH SUGGESTION TAP
//   // ===========================================================================
//
//   Future<void> _onSuggestionTap(
//       LocationSuggestionModel suggestion,
//       ) async {
//     if (!await _hasInternetConnection()) {
//       _showNoInternetToast();
//       return;
//     }
//
//     debugPrint(
//       '[LocationSearch] Selected: ${suggestion.description}',
//     );
//
//     _searchController.text = suggestion.description;
//
//     if (!_suggestionsController.isClosed) {
//       _suggestionsController.add([]);
//     }
//
//     FocusScope.of(context).unfocus();
//
//     if (mounted) {
//       setState(() {
//         _searchFocused = false;
//       });
//     }
//
//     await _setPinFromLatLng(
//       LatLng(
//         suggestion.latitude,
//         suggestion.longitude,
//       ),
//       moveCamera: true,
//       knownAddress: suggestion.description,
//     );
//   }
//
//   // ===========================================================================
//   // MAP TAP
//   // ===========================================================================
//
//   Future<void> _onMapTap(
//       LatLng latLng,
//       ) async {
//     if (!await _hasInternetConnection()) {
//       _showNoInternetToast();
//       return;
//     }
//
//     debugPrint(
//       '[Map] Tapped: ${latLng.latitude}, ${latLng.longitude}',
//     );
//
//     _clearLocationSearch();
//
//     await _setPinFromLatLng(
//       latLng,
//       moveCamera: false,
//     );
//   }
//
//   // ===========================================================================
//   // POLICE STATIONS
//   // ===========================================================================
//
//   Future<void> _loadNearbyPoliceStations({
//     required double latitude,
//     required double longitude,
//     required int requestId,
//   }) async {
//     if (!mounted) return;
//
//     if (!await _hasInternetConnection()) {
//       _showNoInternetToast();
//
//       if (requestId == _locationRequestId) {
//         setState(() {
//           _loadingPoliceStations = false;
//         });
//       }
//       return;
//     }
//
//     if (requestId == _locationRequestId) {
//       setState(() {
//         _loadingPoliceStations = true;
//         _policeStations = [];
//       });
//     }
//
//     try {
//       final response =
//       await authController.getNearbyPoliceStations(
//         latitude: latitude,
//         longitude: longitude,
//         radiusKm: _policeSearchRadiusKm,
//       );
//
//       if (!mounted || requestId != _locationRequestId) return;
//
//       if (!response.isSuccess ||
//           response.data == null) {
//         setState(() {
//           _policeStations = [];
//           _loadingPoliceStations = false;
//         });
//         return;
//       }
//
//       setState(() {
//         _policeStations = response.data!;
//         _loadingPoliceStations = false;
//       });
//
//       debugPrint(
//         '[PoliceStations] Found: ${_policeStations.length}',
//       );
//     } catch (e, stackTrace) {
//       debugPrint(
//         '[PoliceStations] ERROR: $e',
//       );
//
//       debugPrintStack(
//         stackTrace: stackTrace,
//       );
//
//       if (!mounted || requestId != _locationRequestId) return;
//
//       setState(() {
//         _policeStations = [];
//         _loadingPoliceStations = false;
//       });
//     }
//   }
//
//   // ===========================================================================
//   // SELECT POLICE STATION
//   // ===========================================================================
//
//   void _selectPoliceStation(PoliceStationModel station) {
//     if (!mounted) return;
//
//     ++_locationRequestId;
//
//     final stationLocation = SelectedLocationModel(
//       address: station.address,
//       latitude: station.latitude,
//       longitude: station.longitude,
//       name: station.name,
//     );
//
//     setState(() {
//       _selectedPoliceStation = station;
//       _resolvingPin = false;
//
//       if (_selectedLocations.isEmpty) {
//         _selectedLocations.add(stationLocation);
//       } else {
//         _selectedLocations[0] = stationLocation;
//       }
//       _pendingLocation = null;
//     });
//
//     if (_mapController != null) {
//       _mapController!.animateCamera(
//         CameraUpdate.newLatLngZoom(
//           LatLng(station.latitude, station.longitude),
//           15,
//         ),
//       );
//     }
//   }
//
//   // ===========================================================================
//   // SET PIN
//   // ===========================================================================
//
//   Future<void> _setPinFromLatLng(
//       LatLng latLng, {
//         required bool moveCamera,
//         String? knownAddress,
//       }) async {
//     if (!mounted) return;
//
//     final int requestId = ++_locationRequestId;
//     _selectedPoliceStation = null;
//
//     final String temporaryAddress = knownAddress ?? 'Fetching address...';
//
//     final immediateLocation = SelectedLocationModel(
//       address: temporaryAddress,
//       latitude: latLng.latitude,
//       longitude: latLng.longitude,
//     );
//
//     if (!_addingNewLocation) {
//       setState(() {
//         _resolvingPin = true;
//
//         if (_selectedLocations.isEmpty) {
//           _selectedLocations.add(immediateLocation);
//         } else {
//           _selectedLocations[0] = immediateLocation;
//         }
//
//         _pendingLocation = null;
//       });
//     } else {
//       setState(() {
//         _resolvingPin = true;
//         _pendingLocation = immediateLocation;
//       });
//     }
//
//     if (moveCamera && _mapController != null) {
//       try {
//         await _mapController!.animateCamera(
//           CameraUpdate.newLatLngZoom(latLng, 15),
//         );
//       } catch (e) {
//         debugPrint('[Map] Camera animation error: $e');
//       }
//     }
//
//     if (_isOffline) {
//       if (!mounted || requestId != _locationRequestId) return;
//
//       final offlineLocation = SelectedLocationModel(
//         address: knownAddress ??
//             'Dropped pin (${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)})',
//         latitude: latLng.latitude,
//         longitude: latLng.longitude,
//       );
//
//       setState(() {
//         _resolvingPin = false;
//
//         if (!_addingNewLocation) {
//           if (_selectedLocations.isEmpty) {
//             _selectedLocations.add(offlineLocation);
//           } else {
//             _selectedLocations[0] = offlineLocation;
//           }
//           _pendingLocation = null;
//         } else {
//           final exists = _selectedLocations.any(
//                 (location) => _isSameLocation(location, offlineLocation),
//           );
//           if (!exists && _selectedLocations.length < kMaxLocations) {
//             _selectedLocations.add(offlineLocation);
//           }
//           _pendingLocation = null;
//           _addingNewLocation = false;
//         }
//       });
//       return;
//     }
//
//     if (widget.mapScreenModel.showPoliceStations) {
//       _loadNearbyPoliceStations(
//         latitude: latLng.latitude,
//         longitude: latLng.longitude,
//         requestId: requestId,
//       );
//     }
//
//     String address = temporaryAddress;
//     String? pincode;
//
//     if (widget.mapScreenModel.fetchPincode) {
//       try {
//         final geocodeResult = await PlacesService.reverseGeocodeWithPincode(
//           latLng.latitude,
//           latLng.longitude,
//         );
//         address = knownAddress ??
//             geocodeResult?.address ??
//             'Dropped pin (${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)})';
//         pincode = geocodeResult?.pincode;
//       } catch (e) {
//         debugPrint('[Location] Reverse geocode error: $e');
//         address = knownAddress ??
//             'Dropped pin (${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)})';
//       }
//     } else if (knownAddress == null) {
//       try {
//         address = await PlacesService.reverseGeocode(
//           latLng.latitude,
//           latLng.longitude,
//         ) ??
//             'Dropped pin (${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)})';
//       } catch (e) {
//         debugPrint('[Location] Reverse geocode error: $e');
//         address = 'Dropped pin (${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)})';
//       }
//     }
//
//     if (!mounted || requestId != _locationRequestId) return;
//
//     final resolvedLocation = SelectedLocationModel(
//       address: address,
//       latitude: latLng.latitude,
//       longitude: latLng.longitude,
//       pincode: pincode,
//     );
//
//     setState(() {
//       _resolvingPin = false;
//
//       if (!_addingNewLocation) {
//         if (_selectedLocations.isEmpty) {
//           _selectedLocations.add(resolvedLocation);
//         } else {
//           _selectedLocations[0] = resolvedLocation;
//         }
//         _pendingLocation = null;
//       } else {
//         final exists = _selectedLocations.any(
//               (location) => _isSameLocation(location, resolvedLocation),
//         );
//         if (!exists && _selectedLocations.length < kMaxLocations) {
//           _selectedLocations.add(resolvedLocation);
//         }
//         _pendingLocation = null;
//         _addingNewLocation = false;
//       }
//     });
//   }
//
//   // ===========================================================================
//   // ADD PENDING LOCATION
//   // ===========================================================================
//
//   void _addPendingLocation() {
//     if (_pendingLocation == null ||
//         _resolvingPin) {
//       return;
//     }
//
//     if (_selectedLocations.length >=
//         kMaxLocations) {
//       return;
//     }
//
//     final pending =
//     _pendingLocation!;
//
//     final exists =
//     _selectedLocations.any(
//           (location) =>
//           _isSameLocation(
//             location,
//             pending,
//           ),
//     );
//
//     if (exists) {
//       return;
//     }
//
//     setState(() {
//       _selectedLocations.add(
//         pending,
//       );
//
//       _pendingLocation = null;
//       _addingNewLocation = false;
//     });
//   }
//
//   // ===========================================================================
//   // LOCATION COMPARISON
//   // ===========================================================================
//
//   bool _isSameLocation(
//       SelectedLocationModel first,
//       SelectedLocationModel second,
//       ) {
//     return first.latitude ==
//         second.latitude &&
//         first.longitude ==
//             second.longitude;
//   }
//
//   // ===========================================================================
//   // REMOVE LOCATION
//   // ===========================================================================
//
//   void _removeLocation(
//       SelectedLocationModel location,
//       ) {
//     setState(() {
//       _selectedLocations.remove(
//         location,
//       );
//     });
//   }
//
//   // ===========================================================================
//   // CLEAR PENDING PREVIEW
//   // ===========================================================================
//
//   void _clearPendingPreview() {
//     setState(() {
//       _pendingLocation = null;
//       _resolvingPin = false;
//     });
//   }
//
//   // ===========================================================================
//   // CONFIRM
//   // ===========================================================================
//
//   void _confirm() {
//     if (_selectedLocations.isEmpty) {
//       return;
//     }
//
//     if (widget.mapScreenModel.needSingleLocation) {
//       Navigator.pop(
//         context,
//         _selectedLocations.first,
//       );
//     } else {
//       Navigator.pop(
//         context,
//         _selectedLocations,
//       );
//     }
//   }
//
//   // ===========================================================================
//   // BUILD
//   // ===========================================================================
//
//   @override
//   Widget build(
//       BuildContext context,
//       ) {
//     final canAddMore =
//         _selectedLocations.length <
//             kMaxLocations;
//
//     return Scaffold(
//       resizeToAvoidBottomInset: false,
//       appBar: AppBar(
//         toolbarHeight: 0,
//         backgroundColor: AppColors.primaryColor,
//       ),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition: _fallbackCamera,
//             onMapCreated: (controller) async {
//               _mapController = controller;
//               if (mounted) {
//                 setState(() {
//                   _isMapReady = true;
//                 });
//               }
//
//               if (!widget.mapScreenModel.needSingleLocation &&
//                   _selectedLocations.isNotEmpty) {
//                 final location = _selectedLocations.first;
//                 final target = LatLng(
//                   location.latitude,
//                   location.longitude,
//                 );
//
//                 try {
//                   await controller.animateCamera(
//                     CameraUpdate.newLatLngZoom(
//                       target,
//                       15,
//                     ),
//                   );
//                 } catch (e) {
//                   debugPrint(
//                     '[Map] Initial camera error: $e',
//                   );
//                 }
//               }
//             },
//             onTap: _onMapTap,
//             myLocationButtonEnabled: false,
//             zoomControlsEnabled: false,
//             markers: _buildMarkers(),
//           ),
//
//           if (!_isMapReady || _isOffline)
//             Container(
//               color: AppColors.white,
//               child: _isOffline
//                   ? const NoInternetWidget()
//                   : const Center(
//                 child: CircularProgressIndicator(),
//               ),
//             )
//           else if (_isLoadingInitialLocation)
//             Center(
//               child: IgnorePointer(
//                 child: _isOffline
//                     ? const NoInternetWidget(size: 50)
//                     : const CircularProgressIndicator(),
//               ),
//             ),
//
//           Positioned(
//             top:
//             MediaQuery.of(context)
//                 .padding
//                 .top +
//                 (_isOffline ? 40 : 0) +
//                 12,
//             left: 16,
//             right: 16,
//             child: _buildSearchBar(),
//           ),
//
//           if (_searchFocused)
//             Positioned(
//               top:
//               MediaQuery.of(context)
//                   .padding
//                   .top +
//                   (_isOffline ? 40 : 0) +
//                   68,
//               left: 16,
//               right: 16,
//               child: _buildSuggestionsDropdown(),
//             ),
//
//           if (widget.mapScreenModel.showPoliceStations &&
//               _loadingPoliceStations)
//             Positioned(
//               top:
//               MediaQuery.of(context)
//                   .padding
//                   .top +
//                   (_isOffline ? 40 : 0) +
//                   70,
//               right: 16,
//               child: _buildPoliceLoadingIndicator(),
//             ),
//
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: 0,
//             child: _buildBottomSheet(
//               canAddMore,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ===========================================================================
//   // MARKERS
//   // ===========================================================================
//
//   Set<Marker> _buildMarkers() {
//     final Set<Marker> markers = <Marker>{};
//
//     if (widget.mapScreenModel.showPoliceStations) {
//       for (int i = 0; i < _policeStations.length; i++) {
//         final station = _policeStations[i];
//
//         final isSelected = _selectedPoliceStation?.id == station.id ||
//             (_selectedPoliceStation?.latitude == station.latitude &&
//                 _selectedPoliceStation?.longitude == station.longitude);
//
//         markers.add(
//           Marker(
//             markerId: MarkerId('police_station_${station.id}_$i'),
//             position: LatLng(station.latitude, station.longitude),
//             icon: _policePinIcon ??
//                 BitmapDescriptor.defaultMarkerWithHue(
//                   BitmapDescriptor.hueBlue,
//                 ),
//             anchor: const Offset(0.5, 1.0),
//             zIndexInt: isSelected ? 2 : 1,
//             alpha: isSelected ? 1.0 : 0.85,
//             infoWindow: InfoWindow(
//               title: station.name,
//               snippet: station.address,
//             ),
//             onTap: () {
//               _selectPoliceStation(station);
//             },
//           ),
//         );
//       }
//     }
//
//     for (int i = 0; i < _selectedLocations.length; i++) {
//       final location = _selectedLocations[i];
//
//       markers.add(
//         Marker(
//           markerId: MarkerId('selected_location_$i'),
//           position: LatLng(
//             location.latitude,
//             location.longitude,
//           ),
//           icon: _pinIcon ?? BitmapDescriptor.defaultMarker,
//           anchor: const Offset(0.5, 1.0),
//           zIndexInt: 3,
//           infoWindow: InfoWindow(
//             title: location.name ?? 'Selected location',
//             snippet: location.address,
//           ),
//           consumeTapEvents: false,
//         ),
//       );
//     }
//
//     if (_pendingLocation != null) {
//       final pending = _pendingLocation!;
//
//       final alreadySelected = _selectedLocations.any(
//             (location) => _isSameLocation(
//           location,
//           pending,
//         ),
//       );
//
//       if (!alreadySelected) {
//         markers.add(
//           Marker(
//             markerId: const MarkerId('pending_pin'),
//             position: LatLng(
//               pending.latitude,
//               pending.longitude,
//             ),
//             icon: _pinIcon ?? BitmapDescriptor.defaultMarker,
//             anchor: const Offset(0.5, 1.0),
//             zIndexInt: 3,
//             infoWindow: InfoWindow(
//               title: pending.name ?? 'Selected location',
//               snippet: pending.address,
//             ),
//             consumeTapEvents: false,
//           ),
//         );
//       }
//     }
//
//     return markers;
//   }
//
//   // ===========================================================================
//   // SEARCH BAR
//   // ===========================================================================
//
//   Widget _buildSearchBar() {
//     return Row(
//       children: [
//         buildIconContainer(
//           context,
//           height: 45,
//           width: 45,
//           icon: AssetImages.iosBackArrow,
//           onTap: () {
//             context.pop();
//           },
//         ),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Container(
//             constraints: const BoxConstraints(minHeight: 45),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(10),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withAlpha(13),
//                   blurRadius: 10,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: AppTextField(
//               textController: _searchController,
//               onChange: _onSearchChanged,
//               onTap: () {
//                 setState(() {
//                   _searchFocused = true;
//                 });
//               },
//               hintText: 'Search location',
//               onSubmit: (v) {},
//               borderColor: Colors.transparent,
//               prefixIcon: Padding(
//                 padding: const EdgeInsets.all(12.0),
//                 child: AppIconWidget(
//                   assetPath: AssetImages.search,
//                   color: Colors.grey,
//                   size: 18,
//                 ),
//               ),
//               suffixIcon: _searchController.text.isNotEmpty
//                   ? GestureDetector(
//                 onTap: () {
//                   _searchController.clear();
//                   if (!_suggestionsController.isClosed) {
//                     _suggestionsController.add([]);
//                   }
//                   setState(() {});
//                 },
//                 child: Padding(
//                   padding: const EdgeInsets.all(12.0),
//                   child: AppIconWidget(
//                     assetPath: AssetImages.close,
//                     color: Colors.grey,
//                     size: 18,
//                   ),
//                 ),
//               )
//                   : null,
//             ),
//           ),
//         ),
//         const SizedBox(width: 10),
//         buildIconContainer(
//           context,
//           height: 45,
//           width: 45,
//           icon: AssetImages.currentLocation,
//           onTap: _useCurrentLocation,
//         ),
//       ],
//     );
//   }
//
//   // ===========================================================================
//   // SEARCH SUGGESTIONS
//   // ===========================================================================
//
//   Widget _buildSuggestionsDropdown() {
//     return StreamBuilder<List<LocationSuggestionModel>>(
//       stream: _suggestionsController.stream,
//       builder: (context, snapshot) {
//         final suggestions = snapshot.data ?? [];
//
//         if (suggestions.isEmpty) {
//           return const SizedBox.shrink();
//         }
//
//         return Container(
//           constraints: const BoxConstraints(
//             maxHeight: 280,
//           ),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: const [
//               BoxShadow(
//                 color: Colors.black12,
//                 blurRadius: 10,
//                 offset: Offset(0, 4),
//               ),
//             ],
//           ),
//           child: ListView.separated(
//             shrinkWrap: true,
//             padding: const EdgeInsets.symmetric(
//               vertical: 6,
//             ),
//             itemCount: suggestions.length,
//             separatorBuilder: (_, __) => const Divider(
//               height: 1,
//             ),
//             itemBuilder: (context, index) {
//               final suggestion = suggestions[index];
//
//               return Material(
//                 color: AppColors.white,
//                 child: ListTile(
//                   dense: true,
//                   leading: AppIconWidget(
//                     assetPath: AssetImages.mapIcon,
//                   ).pad(),
//                   title: AppText(
//                     text: suggestion.description,
//                     fontSize: 14,
//                   ),
//                   onTap: () {
//                     _onSuggestionTap(suggestion);
//                   },
//                 ),
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
//
//   // ===========================================================================
//   // POLICE LOADING INDICATOR
//   // ===========================================================================
//
//   Widget _buildPoliceLoadingIndicator() {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 12,
//         vertical: 8,
//       ),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: const [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 8,
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           SizedBox(
//             height: 16,
//             width: 16,
//             child: _isOffline
//                 ? const NoInternetWidget(size: 16, showText: false)
//                 : const CircularProgressIndicator(
//               strokeWidth: 2,
//             ),
//           ),
//           const SizedBox(width: 8),
//           const Text(
//             'Finding police stations...',
//             style: TextStyle(
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ===========================================================================
//   // BOTTOM SHEET
//   // ===========================================================================
//
//   Widget _buildBottomSheet(
//       bool canAddMore,
//       ) {
//     final hasPendingPreview = _pendingLocation != null &&
//         !_selectedLocations.any(
//               (e) =>
//           e.latitude == _pendingLocation!.latitude &&
//               e.longitude == _pendingLocation!.longitude,
//         );
//
//     return Container(
//       padding: const EdgeInsets.fromLTRB(
//         16,
//         16,
//         16,
//         24,
//       ),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(
//           top: Radius.circular(20),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 12,
//             offset: Offset(0, -2),
//           ),
//         ],
//       ),
//       child: SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             AppText(
//               text: widget.mapScreenModel.showPoliceStations &&
//                       _selectedPoliceStation != null
//                   ? 'Selected Police Station'
//                   : 'Selected location',
//               fontWeight: FontWeight.w600,
//               fontSize: 15,
//             ),
//
//             const SizedBox(height: 8),
//
//             if (_selectedLocations.isEmpty && !hasPendingPreview)
//               AppText(
//                 text: 'Search or tap on the map to drop a pin.',
//                 fontSize: 13,
//                 color: AppColors.grey,
//               ),
//
//             ..._selectedLocations.map(
//                   (loc) => _buildLocationCard(
//                 loc,
//                 isLoading: false,
//                 isPending: false,
//               ),
//             ),
//
//             if (hasPendingPreview)
//               _buildLocationCard(
//                 _pendingLocation!,
//                 isLoading: _resolvingPin,
//                 isPending: true,
//               ),
//
//             if (widget.mapScreenModel.showPoliceStations &&
//                 !_loadingPoliceStations &&
//                 _policeStations.isEmpty) ...[
//               const SizedBox(height: 4),
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: AppColors.fieldGrey.withAlpha(50),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const AppText(
//                   text: 'No police stations found nearby',
//                   fontSize: 12,
//                   color: AppColors.grey,
//                 ),
//               ),
//             ],
//
//             if (canAddMore &&
//                 !widget.mapScreenModel.needSingleLocation) ...[
//               const SizedBox(height: 8),
//               _buildAddAnotherButton(),
//             ],
//
//             if ((_selectedLocations.isNotEmpty ||
//                 _pendingLocation != null) &&
//                 !widget.mapScreenModel.needSingleLocation) ...[
//               const SizedBox(height: 12),
//               _buildHintBanner(),
//             ],
//
//             const SizedBox(height: 16),
//
//             Opacity(
//               opacity: _selectedLocations.isEmpty ? 0.5 : 1,
//               child: IgnorePointer(
//                 ignoring: _selectedLocations.isEmpty,
//                 child: Center(
//                   child: AppButton(
//                     width: AppUtils.isTab ? 300 : 200,
//                     onTap: _confirm,
//                     title: 'Confirm location',
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ===========================================================================
//   // LOCATION CARD
//   // ===========================================================================
//
//   Widget _buildLocationCard(
//       SelectedLocationModel location, {
//         required bool isLoading,
//         bool isPending = false,
//       }) {
//     final bool hasName = location.name != null && location.name!.isNotEmpty;
//
//     return AppContainer(
//       widget: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SizedBox(height: 10),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               buildIconContainer(
//                 context,
//                 size: 15,
//                 icon: AssetImages.mapIcon,
//                 height: 28,
//                 width: 28,
//               ),
//
//               const SizedBox(width: 10),
//
//               Expanded(
//                 child: isLoading
//                     ? const SizedBox(
//                   height: 14,
//                   width: 14,
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 )
//                     : Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     if (hasName) ...[
//                       AppText(
//                         text: location.name!,
//                         fontSize: 13,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black87,
//                         maxLine: 1,
//                         textOverflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 2),
//                     ],
//                     AppText(
//                       text: location.address,
//                       fontSize: 12,
//                       maxLine: 2,
//                       textOverflow: TextOverflow.ellipsis,
//                       color: hasName ? AppColors.grey : Colors.black87,
//                     ),
//                   ],
//                 ),
//               ),
//
//               if (!isLoading)
//                 GestureDetector(
//                   onTap: () {
//                     if (isPending) {
//                       _clearPendingPreview();
//                     } else {
//                       _removeLocation(location);
//                     }
//                   },
//                   child: AppIconWidget(
//                     assetPath: AssetImages.delete,
//                     color: AppColors.black,
//                     size: 20,
//                   ).pad(),
//                 ),
//             ],
//           ),
//         ],
//       ).padHorizontal(),
//     ).pad();
//   }
//
//   // ===========================================================================
//   // ADD ANOTHER BUTTON
//   // ===========================================================================
//
//   Widget _buildAddAnotherButton() {
//     if (!_addingNewLocation) {
//       return AppButton(
//         title: 'Add Another Location',
//         onTap: () {
//           if (_selectedLocations.length >= kMaxLocations) {
//             return;
//           }
//           _startAddingAnotherLocation();
//         },
//         bgColor: AppColors.white,
//         textColor: AppColors.primaryColor,
//         fontSize: 14,
//         prefixIcon: AssetImages.add,
//         border: Border.all(
//           color: AppColors.primaryColor,
//         ),
//         radius: const BorderRadius.all(
//           Radius.circular(10),
//         ),
//         height: 40,
//       );
//     }
//
//     return const SizedBox.shrink();
//   }
//
//   // ===========================================================================
//   // HINT BANNER
//   // ===========================================================================
//
//   Widget _buildHintBanner() {
//     return Container(
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF0F3FF),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Icon(
//             Icons.lightbulb_outline,
//             size: 18,
//             color: AppColors.primaryColor,
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: AppText(
//               text:
//               'You can add up to $kMaxLocations locations. We\'ll search around all selected locations.',
//               fontSize: 12,
//               color: AppColors.grey,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // =============================================================================
// // MAP SCREEN MODEL
// // =============================================================================
//
// class MapScreenModel {
//   final bool needSingleLocation;
//
//   final List<SelectedLocationModel>?
//   selectedLocation;
//
//   final bool showPoliceStations;
//   final bool isNearby;
//   final bool fetchPincode;
//
//   MapScreenModel({
//     required this.needSingleLocation,
//     this.selectedLocation,
//     this.showPoliceStations = false,
//     this.isNearby = false,
//     this.fetchPincode = false,
//   });
// }
//
// // =============================================================================
// // ICON CONTAINER
// // =============================================================================
//
// Widget buildIconContainer(
//     BuildContext context, {
//       VoidCallback? onTap,
//       String? icon,
//       double? padSize,
//       Color? borderColor,
//       Color? bgColor,
//       Color? iconColor,
//       double? height,
//       double? width,
//       double? size,
//     }) {
//   return GestureDetector(
//     onTap: onTap,
//     child: Container(
//       height: height ?? 40,
//       width: width ?? 40,
//       decoration: ShapeDecoration(
//         color: bgColor ?? AppColors.primaryColor,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(5),
//           side: BorderSide(
//             color: borderColor ?? Colors.transparent,
//           ),
//         ),
//       ),
//       child: Center(
//         child: AppIconWidget(
//           size: size ?? 20,
//           assetPath: icon ?? AssetImages.backArrow,
//           color: iconColor ?? AppColors.white,
//           fit: BoxFit.contain,
//         ),
//       ).pad(
//         padSize ?? 2,
//       ),
//     ),
//   );
// }