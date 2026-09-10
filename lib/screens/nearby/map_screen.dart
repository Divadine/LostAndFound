import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lost_and_found/models/posts_model/selected_location_model.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/shared_widgets/map_pin_loader.dart';
import 'package:lost_and_found/shared_widgets/no_internet_widget.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_utils.dart';
import 'package:lost_and_found/screens/maps/location_selection_screen.dart';

class MapScreen extends StatefulWidget {
  final MapScreenModel? model;
  const MapScreen({super.key, this.model});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  TextEditingController searchController = TextEditingController();
  LatLng? selectedLocation;
  String? selectedAddress;
  GoogleMapController? mapController;
  BitmapDescriptor? _pinIcon;
  LatLng? _tempCameraPosition;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isOffline = false;
  bool _isMapReady = false;
  bool _isFetchingAddress = false;
  Timer? _debounce;

  CameraPosition initialPosition = const CameraPosition(
      target: LatLng(11.040366232580462, 76.99749305902779), zoom: 12);

  @override
  void initState() {
    super.initState();
    if (widget.model?.selectedLocation?.isNotEmpty ?? false) {
      final loc = widget.model!.selectedLocation!.first;
      selectedLocation = LatLng(loc.latitude, loc.longitude);
      selectedAddress = loc.address;
      initialPosition = CameraPosition(target: selectedLocation!, zoom: 15);
      searchController.text = loc.address;
    } else {
      _determinePosition();
    }
    _loadPinIcon();
    _initConnectivityListener();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      // Try to get last known position first for faster response
      Position? position = await Geolocator.getLastKnownPosition();
      
      if (position != null) {
        LatLng lastLatLng = LatLng(position.latitude, position.longitude);
        if (mounted) {
          setState(() {
            selectedLocation = lastLatLng;
            initialPosition = CameraPosition(target: lastLatLng, zoom: 15);
          });
          if (mapController != null) {
            mapController!.animateCamera(CameraUpdate.newLatLngZoom(lastLatLng, 15));
          }
          _getAddressFromLatLng(lastLatLng);
        }
      }

      // Get current position with lower accuracy for speed
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      ).timeout(const Duration(seconds: 5), onTimeout: () {
        if (position != null) return position!;
        throw TimeoutException("Failed to get location");
      });

      LatLng currentLatLng = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          selectedLocation = currentLatLng;
          initialPosition = CameraPosition(target: currentLatLng, zoom: 15);
        });

        if (mapController != null) {
          mapController!
              .animateCamera(CameraUpdate.newLatLngZoom(currentLatLng, 15));
        }
        _getAddressFromLatLng(currentLatLng);
      }
    } catch (e) {
      debugPrint("Error getting current location: $e");
    }
  }

  Future<void> _loadPinIcon() async {
    try {
      final icon = await MapPinIconLoader.load(
        AssetImages.map_pin,
        size: 110,
      );

      if (!mounted) return;

      setState(() {
        _pinIcon = icon;
      });
    } catch (e) {
      debugPrint('[MapPin] Failed to load custom marker: $e');
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void _initConnectivityListener() async {
    // Check initial state
    final results = await Connectivity().checkConnectivity();
    _updateOfflineStatus(results);

    // Listen for changes
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      _updateOfflineStatus(results);
    });
  }

  void _updateOfflineStatus(List<ConnectivityResult> results) {
    final offline = results.contains(ConnectivityResult.none) || results.isEmpty;
    if (!mounted) return;
    setState(() {
      _isOffline = offline;
    });
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() {
      _isFetchingAddress = true;
    });
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          selectedAddress = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea} - ${place.postalCode}";
        });
      }
    } catch (e) {
      debugPrint("Error fetching address: $e");
      setState(() {
        selectedAddress = "Unknown location";
      });
    } finally {
      setState(() {
        _isFetchingAddress = false;
      });
    }
  }

  Future<void> searchedLocation(String loc) async{
    if (loc.trim().isEmpty) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        List<Location> locations = await locationFromAddress(loc);

        if(locations.isNotEmpty){
          final  location = locations.first;
          final searchLocation = LatLng(location.latitude, location.longitude);

          setState(() {
            selectedLocation = searchLocation;
          });

          _getAddressFromLatLng(searchLocation);

          mapController?.animateCamera(CameraUpdate.newLatLngZoom(searchLocation, 15));
        }
      } catch (e) {
        debugPrint("Error searching location: $e");
      }
    });
  }

  Widget _buildTopIconButton(
      {required String icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 45,
        width: 45,
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: AppIconWidget(
            assetPath: icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isNearbyMode = widget.model?.isNearby ?? false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: AppColors.primaryColor,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initialPosition,
            onMapCreated: (controller) {
              mapController = controller;
              setState(() {
                _isMapReady = true;
              });
              if (selectedLocation != null) {
                controller.animateCamera(
                    CameraUpdate.newLatLngZoom(selectedLocation!, 15));
              }
            },
            onTap: isNearbyMode
                ? (LatLng location) {
                    setState(() {
                      selectedLocation = location;
                    });
                    _getAddressFromLatLng(location);
                  }
                : null,
            onCameraMove: !isNearbyMode
                ? (CameraPosition position) {
                    _tempCameraPosition = position.target;
                  }
                : null,
            onCameraIdle: !isNearbyMode
                ? () {
                    if (_tempCameraPosition != null) {
                      setState(() {
                        selectedLocation = _tempCameraPosition;
                      });
                      _getAddressFromLatLng(selectedLocation!);
                    }
                  }
                : null,
            markers: !isNearbyMode || selectedLocation == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId('location'),
                      position: selectedLocation!,
                      icon: _pinIcon ?? BitmapDescriptor.defaultMarker,
                      anchor: const Offset(0.5, 1.0),
                    ),
                  },
          ),
          if (!isNearbyMode)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 35),
                child: AppIconWidget(
                  assetPath: AssetImages.map_pin,
                  size: 50,
                ),
              ),
            ),

          if (!_isMapReady || _isOffline)
            Container(
              color: Colors.white,
              child: _isOffline
                  ? const NoInternetWidget()
                  : const Center(
                      child: CircularProgressIndicator(),
                    ),
            ),

          if (selectedLocation != null)
            Positioned(
              bottom: 25,
              left: 20,
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
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
                              child: _isFetchingAddress
                                  ? const SizedBox(
                                      height: 2,
                                      child: LinearProgressIndicator(
                                        backgroundColor: Colors.transparent,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22326A)),
                                      ),
                                    )
                                  : AppText(
                                      text: selectedAddress ?? 'Fetching address...',
                                      fontSize: 14,
                                      color: Colors.black87,
                                      maxLine: 2,
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_isMapReady) ...[
                    const SizedBox(height: 15),
                    AppButton(
                      width: 200,
                      title: 'Confirm location',
                      height: 50,
                      radius: BorderRadius.circular(10),
                      bgColor: AppColors.primaryColor,
                      onTap: () {
                        if (selectedLocation != null) {
                          Navigator.pop(
                            context,
                            SelectedLocationModel(
                              address: selectedAddress ?? '',
                              latitude: selectedLocation!.latitude,
                              longitude: selectedLocation!.longitude,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),



          //top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _buildTopIconButton(
                  icon: AssetImages.iosBackArrow,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 45,
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
                    child: TextField(
                      inputFormatters: [NoLeadingSpaceFormatter()],
                      onChanged: (value) {
                        searchedLocation(value);
                      },
                      controller: searchController,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: AppIconWidget(
                            assetPath: AssetImages.search,
                            color: Colors.grey,
                            size: 18,
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        hintText: 'Search location',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                                onPressed: () {
                                  searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _buildTopIconButton(
                  icon: AssetImages.currentLocation,
                  onTap: _determinePosition,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}