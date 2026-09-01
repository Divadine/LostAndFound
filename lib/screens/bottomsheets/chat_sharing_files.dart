import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';

import 'package:lost_and_found/screens/chat/chat_firebaase_functions.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';

class ChatSharingFiles extends StatefulWidget {
  final String roomId;
  final String currentUserId;

  const ChatSharingFiles({
    super.key,
    required this.roomId,
    required this.currentUserId,
  });

  @override
  State<ChatSharingFiles> createState() =>
      _ChatSharingFilesState();
}

class _ChatSharingFilesState extends State<ChatSharingFiles> {
  final ImagePicker _imagePicker = ImagePicker();

  final AuthControllers authController = AuthControllers(
    authRepository: AuthRepository(
      apiClient: ApiClient(),
    ),
  );

  bool _loading = false;
  String _loadingText = '';

  // ============================================================
  // CAMERA
  // ============================================================

  Future<void> _openCamera() async {
    if (_loading) return;
    try {
      setState(() {
        _loading = true;
        _loadingText = 'Opening camera...';
      });

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (pickedFile == null) {
        _stopLoading();
        return;
      }

      final File imageFile = File(pickedFile.path);

      if (!await imageFile.exists()) {
        throw Exception('Camera image was not found.');
      }

      if (!mounted) return;

      setState(() {
        _loadingText = 'Uploading photo...';
      });

      // ========================================================
      // UPLOAD VIA createImage API
      // ========================================================

      final uploadResponse = await authController.createImage(
        images: [imageFile],
      );

      if (!uploadResponse.isSuccess ||
          uploadResponse.data == null ||
          uploadResponse.data!.isEmpty) {
        throw Exception(
          uploadResponse.message ?? 'Image upload failed',
        );
      }

      final imageUrl = uploadResponse.data!.first.imgPath;

      if (imageUrl.trim().isEmpty) {
        throw Exception('Server did not return an image URL');
      }

      if (!mounted) return;

      setState(() {
        _loadingText = 'Sending photo...';
      });

      // ========================================================
      // SAVE URL TO FIRESTORE
      // ========================================================

      await ChatService.sendImageMessageWithUrl(
        roomId: widget.roomId,
        senderId: widget.currentUserId,
        imageUrl: imageUrl.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      _showSuccess('Photo sent');
    } catch (e) {
      _stopLoading();

      if (!mounted) return;

      _showError('Unable to open camera or send photo.\n$e');
    }
  }

  // ============================================================
  // GALLERY
  // ============================================================

  Future<void> _attachPhoto() async {
    if (_loading) return;

    try {
      setState(() {
        _loading = true;
        _loadingText = 'Opening gallery...';
      });

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (pickedFile == null) {
        _stopLoading();
        return;
      }

      final File imageFile = File(pickedFile.path);

      if (!await imageFile.exists()) {
        throw Exception('Selected image was not found.');
      }

      if (!mounted) return;

      setState(() {
        _loadingText = 'Uploading photo...';
      });

      // ========================================================
      // UPLOAD VIA createImage API
      // ========================================================

      final uploadResponse = await authController.createImage(
        images: [imageFile],
      );

      if (!uploadResponse.isSuccess ||
          uploadResponse.data == null ||
          uploadResponse.data!.isEmpty) {
        throw Exception(
          uploadResponse.message ?? 'Image upload failed',
        );
      }

      final imageUrl = uploadResponse.data!.first.imgPath;

      if (imageUrl.trim().isEmpty) {
        throw Exception('Server did not return an image URL');
      }

      if (!mounted) return;

      setState(() {
        _loadingText = 'Sending photo...';
      });

      // ========================================================
      // SAVE URL TO FIRESTORE
      // ========================================================

      await ChatService.sendImageMessageWithUrl(
        roomId: widget.roomId,
        senderId: widget.currentUserId,
        imageUrl: imageUrl.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      _showSuccess('Photo sent');
    } catch (e) {
      _stopLoading();

      if (!mounted) return;

      _showError('Unable to attach photo or send it.\n$e');
    }
  }

  // ============================================================
  // SHARE LOCATION
  // ============================================================

  Future<void> _shareLocation() async {
    if (_loading) return;

    try {
      setState(() {
        _loading = true;
        _loadingText = 'Getting your location...';
      });

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _stopLoading();

        if (!mounted) return;

        await DeviceLocationAccess();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _stopLoading();

        if (!mounted) return;

        _showError('Location permission was denied.');

        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _stopLoading();

        if (!mounted) return;

        await AppLocationAccess();
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _stopLoading();

      if (!mounted) return;

      Navigator.of(context).pop();

      final bool? sent = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => LocationConfirmationScreen(
            roomId: widget.roomId,
            currentUserId: widget.currentUserId,
            position: position,
          ),
        ),
      );

      if (sent == true && mounted) {
        _showSuccess('Location shared');
      }
    } catch (e) {
      _stopLoading();

      if (!mounted) return;

      _showError('Unable to get your location.\n$e');
    }
  }

  // ============================================================
  // SHARE ADDRESS
  // ============================================================

  Future<void> _shareAddress() async {
    if (_loading) return;

    try {
      setState(() {
        _loading = true;
        _loadingText = 'Getting your address...';
      });

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _stopLoading();

        if (!mounted) return;

        await DeviceLocationAccess();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _stopLoading();

        if (!mounted) return;

        _showError('Location permission was denied.');

        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _stopLoading();

        if (!mounted) return;

        await AppLocationAccess();
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _stopLoading();

      if (!mounted) return;

      Navigator.of(context).pop();

      final bool? sent = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => LocationConfirmationScreen(
            roomId: widget.roomId,
            currentUserId: widget.currentUserId,
            position: position,
            addressOnly: true,
          ),
        ),
      );

      if (sent == true && mounted) {
        _showSuccess('Address shared');
      }
    } catch (e) {
      _stopLoading();

      if (!mounted) return;

      _showError('Unable to get your address.\n$e');
    }
  }

  // ============================================================
  // LOADING
  // ============================================================

  void _stopLoading() {
    if (!mounted) return;

    setState(() {
      _loading = false;
      _loadingText = '';
    });
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  // ============================================================
  // LOCATION SERVICE DIALOG
  // ============================================================

  Future<void> _showLocationServiceDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Location is disabled',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Please turn on your device location service and try again.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await Geolocator.openLocationSettings();
              },
              child: const Text('Settings'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // PERMISSION SETTINGS
  // ============================================================

  Future<void> _showPermissionSettingsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Location permission required',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Location permission was permanently denied. Please enable it from app settings.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await Geolocator.openAppSettings();
              },
              child: const Text('Settings'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6D6D6),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildOption(
                      title: 'Camera',
                      onTap: _openCamera,
                    ),
                    _buildDivider(),

                    _buildOption(
                      title: 'Attach Photo',
                      onTap: _attachPhoto,
                    ),
                    _buildDivider(),

                    _buildOption(
                      title: 'Share Location',
                      onTap: _shareLocation,
                    ),
                    _buildDivider(),

                    _buildOption(
                      title: 'Share Address',
                      onTap: _shareAddress,
                      isLast: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _loading
                        ? null
                        : () {
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      height: 54,
                      alignment: Alignment.center,
                      child: Text(
                        'Cancel',
                        style: const TextStyle(
                          color: AppColors.red,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (_loading) ...[
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Flexible(
                      child: Text(
                        _loadingText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 0.6,
      indent: 0,
      endIndent: 0,
      color: Color(0x29808080),
    );
  }

  Widget _buildOption({
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: _loading ? null : onTap,
        splashColor: AppColors.primaryColor.withAlpha(15),
        highlightColor: AppColors.primaryColor.withAlpha(8),
        child: Container(
          width: double.infinity,
          height: 56,
          alignment: Alignment.center,
          color: Colors.white,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

// =================================================================
// LOCATION CONFIRMATION SCREEN
// =================================================================

class LocationConfirmationScreen extends StatefulWidget {
  final String roomId;
  final String currentUserId;
  final Position position;

  /// If true, this screen is being used
  /// specifically for sharing the address.
  final bool addressOnly;

  const LocationConfirmationScreen({
    super.key,
    required this.roomId,
    required this.currentUserId,
    required this.position,
    this.addressOnly = false,
  });

  @override
  State<LocationConfirmationScreen> createState() =>
      _LocationConfirmationScreenState();
}

class _LocationConfirmationScreenState
    extends State<LocationConfirmationScreen> {
  GoogleMapController? _mapController;

  bool _sendCurrentLocation = false;
  bool _sending = false;

  String _address = 'Fetching address...';

  late final LatLng _currentLatLng;

  @override
  void initState() {
    super.initState();

    _currentLatLng = LatLng(
      widget.position.latitude,
      widget.position.longitude,
    );

    _getAddress();
  }

  // ============================================================
  // GET ADDRESS
  // ============================================================

  Future<void> _getAddress() async {
    try {
      final placemarks = await placemarkFromCoordinates(
        widget.position.latitude,
        widget.position.longitude,
      );

      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final address = _formatPlacemark(placemarks.first);

        setState(() {
          _address = address.isNotEmpty ? address : 'Current location';
        });
      } else {
        setState(() {
          _address = 'Current location';
        });
      }
    } catch (e) {
      debugPrint('[LOCATION] ADDRESS ERROR: $e');

      if (!mounted) return;

      setState(() {
        _address = 'Current location';
      });
    }
  }

  // ============================================================
  // FORMAT ADDRESS
  // ============================================================

  String _formatPlacemark(Placemark place) {
    final List<String> parts = [];

    void add(String? value) {
      if (value == null) return;

      final clean = value.trim();

      if (clean.isEmpty) return;

      if (!parts.contains(clean)) {
        parts.add(clean);
      }
    }

    add(place.name);
    add(place.street);
    add(place.subLocality);
    add(place.locality);
    add(place.subAdministrativeArea);
    add(place.administrativeArea);
    add(place.postalCode);
    add(place.country);

    return parts.join(', ');
  }

  // ============================================================
  // SEND LOCATION
  // ============================================================

  Future<void> _sendLocation() async {
    if (!_sendCurrentLocation) {
      _showMessage(
        'Please select "Send your current location" first.',
      );
      return;
    }

    if (_sending) return;

    try {
      setState(() {
        _sending = true;
      });

      await ChatService.sendLocationMessage(
        roomId: widget.roomId,
        senderId: widget.currentUserId,
        latitude: widget.position.latitude,
        longitude: widget.position.longitude,
        address: _address,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _sending = false;
      });

      _showMessage('Unable to share location.\n$e');
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // MAP CREATED
  // ============================================================

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          icon: AppIconWidget(
            assetPath: AssetImages.backArrow,
            size: 20,
            color: AppColors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.addressOnly ? 'Share Address' : 'Share Location',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLatLng,
                zoom: 17,
              ),

              onMapCreated: _onMapCreated,

              myLocationEnabled: true,

              myLocationButtonEnabled: true,

              zoomControlsEnabled: false,

              mapToolbarEnabled: false,

              compassEnabled: true,

              markers: {
                Marker(
                  markerId: const MarkerId('current_location'),
                  position: _currentLatLng,
                  infoWindow: const InfoWindow(
                    title: 'Your current location',
                  ),
                ),
              },
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM PANEL
  // ============================================================

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              text: widget.addressOnly ? 'Nearby Place' : 'Nearby Place',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),

            const SizedBox(height: 8),

            Text(
              _address,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 12),

            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _sending
                  ? null
                  : () async {
                setState(() {
                  _sendCurrentLocation = true;
                });

                await _sendLocation();
              },
              child: Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: _sendCurrentLocation ? true : null,
                    activeColor: AppColors.primaryColor,
                    onChanged: _sending
                        ? null
                        : (value) async {
                      if (value == true) {
                        setState(() {
                          _sendCurrentLocation = true;
                        });

                        await _sendLocation();
                      }
                    },
                  ),

                  const SizedBox(width: 2),

                  Expanded(
                    child: Text(
                      widget.addressOnly
                          ? 'Send this address'
                          : 'Send your current location',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  if (_sending)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),

                  const SizedBox(width: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}