import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lost_and_found/services/place_service.dart';
import 'package:lost_and_found/models/selected_location_model.dart';
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
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  static const int kMaxLocations = 3;
  static const CameraPosition _fallbackCamera = CameraPosition(
    target: LatLng(11.0168, 76.9558), // Coimbatore, matches the mock-up
    zoom: 11,
  );


  static const String _pinAssetPath = 'assets/images/map_pin.svg';

  final AppPermissions _appPermissions = AppPermissions();
  final TextEditingController _searchController = TextEditingController();
  final StreamController<List<PlaceSuggestion>> _suggestionsController =
  StreamController<List<PlaceSuggestion>>.broadcast();

  GoogleMapController? _mapController;
  Timer? _debounce;

  bool _searchFocused = false;
  bool _resolvingPin = false;
  bool _addingNewLocation = false;

  /// Custom marker icon, loaded once and reused for every pin drop.
  BitmapDescriptor? _pinIcon;

  SelectedLocationModel? _pendingLocation;

  final List<SelectedLocationModel> _selectedLocations = [];

  @override
  void initState() {
    super.initState();
    _loadPinIcon();
    _initLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _suggestionsController.close();
    _debounce?.cancel();
    super.dispose();
  }

  // ---------------- Custom marker icon ----------------

  Future<void> _loadPinIcon() async {
    final icon = await MapPinIconLoader.load(_pinAssetPath, size: 110);
    if (!mounted) return;
    setState(() => _pinIcon = icon);
  }

  // ---------------- Location bootstrap ----------------

  Future<void> _initLocation() async {
    final granted = await _appPermissions.requestLocationPermission(context);
    if (!granted) return;

    final serviceOn = await _appPermissions.isLocationServiceEnabled();
    if (!serviceOn) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      await _setPinFromLatLng(
        LatLng(position.latitude, position.longitude),
        moveCamera: true,
      );
    } catch (_) {
      // Fall back to default camera position silently.
    }
  }

  Future<void> _useCurrentLocation() async {
    final granted = await _appPermissions.requestLocationPermission(context);
    if (!granted) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      await _setPinFromLatLng(
        LatLng(position.latitude, position.longitude),
        moveCamera: true,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to fetch current location')),
        );
      }
    }
  }

  void _startAddingAnotherLocation() {
    setState(() {
      _addingNewLocation = true;
      _pendingLocation = null;
    });
  }

  // ---------------- Search ----------------

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      _suggestionsController.add([]);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await PlacesService.autocomplete(
        value,
        biasLat: _pendingLocation?.latitude,
        biasLng: _pendingLocation?.longitude,
      );
      if (!_suggestionsController.isClosed) {
        _suggestionsController.add(results);
      }
    });
  }

  Future<void> _onSuggestionTap(PlaceSuggestion suggestion) async {
    final details = await PlacesService.getPlaceDetails(suggestion.placeId);
    if (details == null) return;

    _searchController.text = details.formattedAddress;
    _suggestionsController.add([]);
    FocusScope.of(context).unfocus();
    setState(() => _searchFocused = false);

    await _setPinFromLatLng(
      LatLng(details.lat, details.lng),
      moveCamera: true,
      knownAddress: details.formattedAddress,
    );
  }

  // ---------------- Map ----------------

  Future<void> _onMapTap(LatLng latLng) async {
    await _setPinFromLatLng(latLng, moveCamera: false);
  }

  Future<void> _setPinFromLatLng(
      LatLng latLng, {
        required bool moveCamera,
        String? knownAddress,
      }) async {
    // Drop the pin and show a loading state immediately, so the tap feels
    // instant even while the address is still being fetched.
    setState(() {
      _resolvingPin = true;
      _pendingLocation = SelectedLocationModel(
        address: knownAddress ?? 'Fetching address...',
        latitude: latLng.latitude,
        longitude: latLng.longitude,
      );
    });

    if (moveCamera && _mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
    }

    final address =
        knownAddress ??
            await PlacesService.reverseGeocode(latLng.latitude, latLng.longitude) ??
            'Dropped pin (${latLng.latitude.toStringAsFixed(5)}, '
                '${latLng.longitude.toStringAsFixed(5)})';

    if (!mounted) return;

    final resolved = SelectedLocationModel(
      address: address,
      latitude: latLng.latitude,
      longitude: latLng.longitude,
    );

    setState(() {
      _resolvingPin = false;

      if (!_addingNewLocation) {
        if (_selectedLocations.isEmpty) {
          _selectedLocations.add(resolved);
        } else {
          _selectedLocations[0] = resolved;
        }
        _pendingLocation = null;
      } else {
        _pendingLocation = resolved;
      }
    });
  }

  // ---------------- Selected locations list ----------------

  void _addPendingLocation() {
    if (_pendingLocation == null || _resolvingPin) return;

    if (_selectedLocations.length >= kMaxLocations) return;

    final exists = _selectedLocations.any(
          (e) =>
      e.latitude == _pendingLocation!.latitude &&
          e.longitude == _pendingLocation!.longitude,
    );

    if (exists) return;

    setState(() {
      _selectedLocations.add(_pendingLocation!);

      // Clear preview after adding
      _pendingLocation = null;
      _addingNewLocation = false;
    });
  }

  void _removeLocation(SelectedLocationModel location) {
    setState(() => _selectedLocations.remove(location));
  }

  /// Clears a not-yet-confirmed pin preview (the ✕ tapped before the user
  /// hit "Add Another Location"). This is distinct from `_removeLocation`,
  /// which removes an already-confirmed entry from `_selectedLocations`.
  void _clearPendingPreview() {
    setState(() => _pendingLocation = null);
  }

  void _confirm() {
    if (_selectedLocations.isEmpty) return;
    Navigator.pop(context, _selectedLocations);
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final canAddMore = _selectedLocations.length < kMaxLocations;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ---- Map ----
          GoogleMap(
            initialCameraPosition: _fallbackCamera,
            onMapCreated: (c) => _mapController = c,
            onTap: _onMapTap,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: {
              if (_pendingLocation != null)
                Marker(
                  markerId: const MarkerId('pending_pin'),
                  position: LatLng(
                    _pendingLocation!.latitude,
                    _pendingLocation!.longitude,
                  ),
                  icon: _pinIcon ?? BitmapDescriptor.defaultMarker,
                  anchor: const Offset(0.5, 1.0),
                ),
            },
          ),

          // ---- Top search bar ----
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: _buildSearchBar(),
          ),

          // ---- Search suggestions dropdown ----
          if (_searchFocused)
            Positioned(
              top: MediaQuery.of(context).padding.top + 68,
              left: 16,
              right: 16,
              child: _buildSuggestionsDropdown(),
            ),

          // ---- Bottom sheet: selected locations + confirm ----
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomSheet(canAddMore),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
      return Row(
        children: [
          buildIconContainer(
            context,
            icon: AssetImages.iosBackArrow,
            onTap: () {
              context.pop();
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppTextField(
              textController: _searchController,
              onChange: _onSearchChanged,
              onTap: () => setState(() => _searchFocused = true),
              hintText: 'Search location',
              onSubmit: (v) {},
              borderColor: Colors.transparent,
              prefixIcon: AppIconWidget(assetPath: AssetImages.search).pad(12),
              suffixIcon: _searchController.text.isNotEmpty
                  ? GestureDetector(
                onTap: () {
                  _searchController.clear();
                  _suggestionsController.add([]);
                },
                child: AppIconWidget(assetPath: AssetImages.close).pad(3),
              )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          buildIconContainer(
            context,
            icon: AssetImages.currentLocation,
            onTap: _useCurrentLocation,
          ),
        ],
      );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: AppColors.primaryColor),
        ),
      ),
    );
  }

  Widget _buildSuggestionsDropdown() {
    return StreamBuilder<List<PlaceSuggestion>>(
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
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final s = suggestions[index];
              return Material(
                color: AppColors.white,
                child: ListTile(
                  dense: true,
                  leading: AppIconWidget(assetPath: AssetImages.mapIcon).pad(),
                  title: AppText(text: s.description, fontSize: 14),
                  onTap: () => _onSuggestionTap(s),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBottomSheet(bool canAddMore) {
    final hasPendingPreview =
        _pendingLocation != null &&
            !_selectedLocations.any(
                  (e) =>
              e.latitude == _pendingLocation!.latitude &&
                  e.longitude == _pendingLocation!.longitude,
            );

    return Container(
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
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              text: 'Selected location',
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            const SizedBox(height: 8),

            // Empty state
            if (_selectedLocations.isEmpty && !hasPendingPreview)
              AppText(
                text: 'Search or tap on the map to drop a pin.',
                fontSize: 13,
                color: AppColors.grey,
              ),

            // Selected (confirmed) location cards
            ..._selectedLocations.map(
                  (loc) =>
                  _buildLocationCard(loc, isLoading: false, isPending: false),
            ),

            // Preview card for a pin that's still being resolved / waiting
            // to be explicitly added via "Add Another Location".
            if (hasPendingPreview)
              _buildLocationCard(
                _pendingLocation!,
                isLoading: _resolvingPin,
                isPending: true,
              ),

            // Add another location
            if (canAddMore) ...[
              const SizedBox(height: 8),
              _buildAddAnotherButton(),
            ],

            // Hint banner
            if (_selectedLocations.isNotEmpty || _pendingLocation != null) ...[
              const SizedBox(height: 12),
              _buildHintBanner(),
            ],

            const SizedBox(height: 16),
            Opacity(
              opacity: _selectedLocations.isEmpty ? 0.5 : 1,
              child: IgnorePointer(
                ignoring: _selectedLocations.isEmpty,
                child: AppButton(onTap: _confirm, title: 'Confirm location'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(
      SelectedLocationModel location, {
        required bool isLoading,
        bool isPending = false,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
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
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  text: 'Fetching address...',
                  fontSize: 13,
                  color: AppColors.grey,
                ),
              ],
            )
                : AppText(
              text: location.address,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          if (!isLoading)
            GestureDetector(
              // A "pending" card isn't in `_selectedLocations` yet, so
              // removing it means clearing the preview, not calling
              // `_removeLocation` (which would silently do nothing).
              onTap: () =>
              isPending ? _clearPendingPreview() : _removeLocation(location),
              child: AppIconWidget(
                assetPath: AssetImages.delete,
                color: AppColors.black,
                size: 20,
              ).pad(),
            ),
        ],
      ),
    );
  }

  Widget _buildAddAnotherButton() {
    if (!_addingNewLocation) {
      return AppButton(
        title: "Add Another Location",
        onTap: () {
          if (_selectedLocations.length >= kMaxLocations) return;
          _startAddingAnotherLocation();
          return;
        },
        bgColor: AppColors.white,
        textColor: AppColors.primaryColor,
        fontSize: 14,
        prefixIcon: AssetImages.add,
        border: Border.all(color: AppColors.primaryColor),
        radius: BorderRadius.all(Radius.circular(10)),
        height: 40,
      );
    }

    // Already in add mode
    final enabled = !_resolvingPin && _pendingLocation != null;

    return AppButton(
      title: "Confirm Added Location",
      onTap: () {
        if (enabled) _addPendingLocation();
      },
      bgColor: AppColors.white,
      textColor: AppColors.primaryColor,
      fontSize: 14,
      prefixIcon: AssetImages.tickmark,
      size: 20,
      border: Border.all(color: AppColors.primaryColor),
      radius: BorderRadius.all(Radius.circular(10)),
      height: 40,
    );
  }

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
              'You can add up to $kMaxLocations locations. We\'ll search '
                  'around all selected locations.',
              fontSize: 12,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

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
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: borderColor ?? Colors.transparent),
        ),
      ),
      child: Center(
        child: AppIconWidget(
          size: size ?? 20,
          assetPath: icon ?? AssetImages.backArrow,
          color: iconColor ?? AppColors.white,
          fit: BoxFit.contain,
        ),
      ).pad(padSize ?? 2),
    ),
  );
}