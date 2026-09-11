import 'dart:async';
import 'dart:io';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/enums/current_state.dart';
import 'package:lost_and_found/models/posts_model/selected_location_model.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/screens/authentication/register_screen.dart';
import 'package:lost_and_found/screens/maps/location_selection_screen.dart';
import 'package:lost_and_found/screens/permissions/location_permission.dart';
import 'package:lost_and_found/services/app_recorder_service.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/no_internet_widget.dart';
import 'package:lost_and_found/utils/app_utils.dart';
import 'first_stepper_screen.dart';
import 'reording_screen.dart';
import 'package:lost_and_found/shared_widgets/app_step_indicator.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lost_and_found/utils/app_preferences.dart';



class SecondStepperScreen extends StatefulWidget {
  final int postType;
  final int categoryId;
  final int subcategoryId;
  final String itemName;
  final List<File> selectedImages;

  final String? prefillDescription;

  // Forwarded from FirstStepperScreen so the Preview screen (step 3) can
  // show the item-type/color/dynamic-field summary without re-fetching.
  final String itemTypeLabel;
  final String itemTypeValue;
  final String color;
  final List<Map<String, String>> fieldValues;
  final File? mainImage;

  // Persistence data
  final String? initialTextLocation;
  final List<SelectedLocationModel>? initialLocations;
  final DateTime? initialDate;
  final XFile? initialVideo;
  final bool isResuming;

  const SecondStepperScreen({
    super.key,
    required this.postType,
    required this.categoryId,
    required this.subcategoryId,
    required this.itemName,
    required this.selectedImages,
    this.prefillDescription,
    this.itemTypeLabel = 'Item Type',
    this.itemTypeValue = '',
    this.color = '',
    this.fieldValues = const [],
    this.mainImage,
    this.initialTextLocation,
    this.initialLocations,
    this.initialDate,
    this.initialVideo,
    this.isResuming = false,
  });

  @override
  State<SecondStepperScreen> createState() => _SecondStepperScreenState();
}

class _SecondStepperScreenState extends State<SecondStepperScreen> {

  final authController = AuthControllers(
    authRepository: AuthRepository(
      apiClient: ApiClient(),
    ),
  );
  DateTime? selectedDate;

  XFile? selectedVideo;
  List<SelectedLocationModel> loc = [];
  StreamController<List<SelectedLocationModel>> locationController = StreamController.broadcast();
  StreamController<DateTime?> dateStreamController =  StreamController.broadcast();
  StreamController<void> videoStreamController =  StreamController.broadcast();


  TextEditingController textController = TextEditingController();
  TextEditingController mapController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  final ImagePicker picker = ImagePicker();
  VideoPlayerController? _videoController;
  final AppRecorderService _recorderService = AppRecorderService.instance;

  final AppLocationPermission _appPermissions = AppLocationPermission();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();

    _initConnectivityListener();

    // Use post frame callback to avoid notifyListeners() or stream events
    // triggering rebuilds during the navigation transition/build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        locationController.add(loc);

        // Only delete recording if this is the very first time entering Step 2.
        if (!widget.isResuming) {
          _recorderService.deleteRecording();
        }
      } catch (e) {
        debugPrint('Error in SecondStepperScreen post-frame: $e');
      }
    });

    if (widget.prefillDescription != null && widget.prefillDescription!.isNotEmpty) {
      descriptionController.text = widget.prefillDescription!;
    }

    // Prefill with existing data if returning to this screen
    if (widget.initialTextLocation != null) {
      textController.text = widget.initialTextLocation!;
    }
    if (widget.initialLocations != null) {
      loc = List<SelectedLocationModel>.from(widget.initialLocations!);
    }
    if (widget.initialDate != null) {
      selectedDate = widget.initialDate;
      dateController.text = DateFormat('dd/MM/yyyy').format(selectedDate!);
    }
    if (widget.initialVideo != null) {
      selectedVideo = widget.initialVideo;
      _initInitialVideo(File(selectedVideo!.path));
    }
  }

  void _initConnectivityListener() async {
    final results = await Connectivity().checkConnectivity();
    _updateOfflineStatus(results);
    _connectivitySub = Connectivity().onConnectivityChanged.listen(_updateOfflineStatus);
  }

  void _updateOfflineStatus(List<ConnectivityResult> results) {
    final offline = results.contains(ConnectivityResult.none) || results.isEmpty;
    if (!mounted) return;
    setState(() {
      _isOffline = offline;
    });
  }

  Future<void> _initInitialVideo(File file) async {
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(file);
    await _videoController!.initialize();
    if (mounted) {
      videoStreamController.add(null);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _videoController?.dispose();
    locationController.close();
    dateStreamController.close();
    videoStreamController.close();
    textController.dispose();
    mapController.dispose();
    dateController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickVideos() async {
    final XFile? video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 30),
    );

    if (video == null) return;

    final file = File(video.path);

    final sizeInMB = await file.length() / (1024 * 1024);

    if (sizeInMB > 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Video must be less than 15 MB")),
      );
      return;
    }

    selectedVideo = video;

    _videoController?.dispose();

    _videoController = VideoPlayerController.file(file);

    await _videoController!.initialize();

    videoStreamController.add(null);
    setState(() {});
  }

  Future<void> pickVideo() async {
    final XFile? video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 30),
    );

    if (video == null) return;

    final file = File(video.path);

    final sizeInMB = await file.length() / (1024 * 1024);

    if (sizeInMB > 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Video must be less than 15 MB")),
      );
      return;
    }

    selectedVideo = video;
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(file);
    await _videoController!.initialize();

    videoStreamController.add(file);
    setState(() {});
  }

  String formatDuration(Duration duration) {
    if (duration.isNegative) duration = Duration.zero;
    String two(int n) => n.toString().padLeft(2, '0');

    return "${two(duration.inMinutes)}:${two(duration.inSeconds % 60)}";
  }

  void deleteVideo() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    selectedVideo = null;

    videoStreamController.add(null);
    setState(() {});
  }

  Future<void> _handleMicPermission() async {
    final status = await Permission.microphone.status;

    if (status.isGranted) {
      await _recorderService.startRecording();
      return;
    }

    final hasAskedBefore = AppPreferences.getAskedMicPermission();

    if (!hasAskedBefore) {
      // First record tap
      final result = await Permission.microphone.request();
      await AppPreferences.setAskedMicPermission(true);
      if (result.isGranted) {
        await _recorderService.startRecording();
      }
    } else {
      // Second record tap after denial
      if (mounted) {
        await AppDialogue.showPopup(
          context: context,
          content: const AppMicAccess(),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate != null && selectedDate!.isBefore(now)
          ? selectedDate!
          : now,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
              surface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.black),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedDate = picked;
      dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      dateStreamController.add(picked);
    }
    debugPrint('picked date is: $picked');
  }


  Future<void> _openMapForLocations() async {
    final granted = await _appPermissions.requestLocationPermission(context);
    if (!granted) return;

    if (!mounted) return;
    final result = await context.pushNamed(
      AppRoutes.mapScreen,
      extra: MapScreenModel(
        needSingleLocation: false,
        selectedLocation: List<SelectedLocationModel>.from(loc),
      ),
    );

    if (result != null) {
      loc = result as List<SelectedLocationModel>;
      locationController.add(loc);


      // setState(() {
      //   loc = result as List<SelectedLocationModel>;
      // });
    }
  }


  Future<void> _goToPreview() async {
    if (_isOffline) {
      AppSnackBar.show(context: context, message: 'No internet connection', icon: Icons.wifi_off);
      return;
    }
    if (loc.isEmpty) {
      AppSnackBar.show(context: context, message: 'Please add a location');
      return;
    }
    if (selectedDate == null) {
      AppSnackBar.show(context: context, message: 'Please select a date');
      return;
    }
    if (descriptionController.text.trim().isEmpty) {
      AppSnackBar.show(context: context, message: 'Please enter a description');
      return;
    }

    AppRoutes.pushNamed(
      AppRoutes.previewScreen,
      arguments: {
        'postType': widget.postType,
        'categoryId': widget.categoryId,
        'subcategoryId': widget.subcategoryId,
        'itemName': widget.itemName,
        'selectedImages': widget.selectedImages,
        'mainImage': widget.mainImage,
        'itemTypeLabel': widget.itemTypeLabel,
        'itemTypeValue': widget.itemTypeValue,
        'color': widget.color,
        'fieldValues': widget.fieldValues,
        'locations': List<SelectedLocationModel>.from(loc),
        'locationText': textController.text.trim(),
        'postDate': selectedDate!,
        'description': descriptionController.text.trim(),
        'audioPath': (_recorderService.isRecorded || _recorderService.audioPath != null)
            ? _recorderService.audioPath
            : null,
        'videoFile': selectedVideo != null ? File(selectedVideo!.path) : null,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        AppRoutes.pop({
          'textLocation': textController.text.trim(),
          'locations': List<SelectedLocationModel>.from(loc),
          'selectedDate': selectedDate,
          'description': descriptionController.text.trim(),
          'selectedVideo': selectedVideo,
        });
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: CustomAppBar(
          title: widget.postType == 0 ? 'Post Lost Item' : 'Post Found Item',
          leadingSvg: AssetImages.backArrow,
          leadingIconColor: AppColors.primaryColor,
          onLeadingTap: () {
            AppRoutes.pop({
              'textLocation': textController.text.trim(),
              'locations': List<SelectedLocationModel>.from(loc),
              'selectedDate': selectedDate,
              'description': descriptionController.text.trim(),
              'selectedVideo': selectedVideo,
            });
          },
        ),
        //AppBar(toolbarHeight: 0, backgroundColor: AppColors.primaryColor),
        body: SafeArea(
          child: Column(
            children: [
              const AppStepIndicator(currentStep: 2, totalSteps: 2),
              Expanded(
                child: _isOffline
                    ? const NoInternetWidget()
                    : SingleChildScrollView(
                  child: Column(
                    children: [
                      buildTextFieldWithHeading(
                        title: widget.postType == 0 ? 'Where did you lose it ?' : 'Where did you find it ?',
                        fieldWidget: AppTextField(
                          hintText: 'Chennai, Tamil Nadu, India',
                          textController: textController,
                          onChange: (v) {},
                          onSubmit: (v) {},
                        ),
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder(
                          stream: locationController.stream,
                          initialData: loc,
                          builder: (context, asyncSnapshot) {
                            final locData = asyncSnapshot.data ?? [];
                            return buildTextFieldWithHeading(
                              title: 'Location',
                              fieldWidget: loc.isEmpty
                                  ? AppTextField(
                                readOnly: true,

                                onTap: _openMapForLocations,
                                hintText: 'Chennai, Tamil Nadu, India',
                                textController: mapController,
                                onChange: (v) {},
                                onSubmit: (v) {},
                                suffixIcon: AppIconWidget(
                                  assetPath: AssetImages.locationMarker,
                                ).pad(),
                              )
                                  : Column(
                                children: [
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: locData.length,
                                    itemBuilder: (context, index) {
                                      final locate = locData[index];
                                      return AppContainer(
                                        widget: Row(
                                          children: [
                                            buildIconContainer(
                                              context,
                                              icon: AssetImages.mapIcon,
                                              size: 15,
                                              height: 30,
                                              width: 30,
                                            ),
                                            const SizedBox(width: 7),
                                            Flexible(
                                              child: AppText(
                                                text: locate.address,
                                                maxLine: 2,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                                color: AppColors.black,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                loc.remove(locate);
                                                locationController.add(loc);
                                                //setState(() {});
                                              },
                                              child: AppIconWidget(
                                                assetPath: AssetImages.delete,

                                                color: AppColors.black,
                                              ).pad(),
                                            ),
                                          ],
                                        ).pad(),
                                      ).padBottom();
                                    },
                                  ),

                                  if (loc.length < 3)
                                    AppButton(
                                      prefixIcon: AssetImages.add,
                                      bgColor: Colors.transparent,
                                      border: Border.all(color: AppColors.primaryColor),
                                      title: 'Add Another Location (UP TO 3)',
                                      textColor: AppColors.primaryColor,
                                      radius: BorderRadius.circular(10),
                                      fontSize: 12,
                                      onTap: _openMapForLocations,
                                    ),
                                ],
                              ),
                            );
                          }
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder(
                          stream: dateStreamController.stream,
                          initialData: selectedDate,
                          builder: (context, asyncSnapshot) {
                            return buildTextFieldWithHeading(
                              title: 'Date',
                              fieldWidget: AppTextField(
                                hintText: 'Select Date',
                                readOnly: true,
                                textController: dateController,
                                onTap: _selectDate,
                                onChange: (v) {},
                                onSubmit: (v) {},
                                suffixIcon: GestureDetector(
                                    onTap: _selectDate,
                                    child: AppIconWidget(assetPath: AssetImages.calender).pad()
                                ),
                              ),
                            );
                          }
                      ),
                      const SizedBox(height: 10),
                      buildTextFieldWithHeading(
                        title: 'Description',
                        fieldWidget: AppTextField(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12,vertical: 10) ,
                          hintText: 'write Description here',
                          textController: descriptionController,
                          onChange: (v) {},
                          onSubmit: (v) {},
                          maxLines: 5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            text: 'Voice Description',
                            fontSize: 14,
                            fontWeight: AppUtils.isTab ? FontWeight.w400 : FontWeight.w500,
                          ),
                          const SizedBox(height: 10),
                          AppRecorder(
                            service: _recorderService,
                            onRecordTap: _handleMicPermission,
                          )

                        ],
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder(
                          stream: videoStreamController.stream,
                          initialData: null,
                          builder: (context, asyncSnapshot) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  text: 'Add a short video of your item or place',
                                  fontSize: 14,
                                  fontWeight: AppUtils.isTab ? FontWeight.w400 : FontWeight.w500,
                                ),
                                const SizedBox(height: 10),


                                (_videoController != null &&
                                    _videoController!.value.isInitialized)
                                    ? buildVideoPreview()
                                    : AppContainer(

                                  widget: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      AppText(
                                        text: 'Tap to choose a video',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 12,
                                        color: AppColors.grey,
                                      ),
                                      const SizedBox(height: 10),
                                      GestureDetector(
                                        onTap: pickVideo,
                                        child: AppIconWidget(assetPath: AssetImages.video),
                                      ),
                                    ],
                                  ).pad(),
                                ),

                                const SizedBox(height: 10),
                                AppText(
                                  text: 'Max 30 seconds & Max size 15 MB',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  color: AppColors.grey,
                                ),
                              ],
                            );
                          }
                      ),
                      const SizedBox(height: 10),
                      if (!_isOffline)
                        AppButton(
                          title: 'Review & Submit',
                          onTap: _goToPreview,
                          radius: BorderRadius.circular(10),
                          fontSize: 14,
                        ),
                    ],
                  ).pad(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildVideoPreview() {
    final controller = _videoController!;

    // FIX: ValueListenableBuilder listens to the controller's own value
    // (VideoPlayerController is a ValueNotifier<VideoPlayerValue>), so the
    // duration badge always reflects the controller's real, current state
    // instead of a value read once right after initialize() (which is why
    // it was showing 00:00 — the real duration often isn't known that
    // early). It also gives a live "position" every frame, so the badge
    // counts down while playing.
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final remaining = value.duration - value.position;
        final displayTime = value.duration == Duration.zero ? value.duration : remaining;

        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: value.size.width,
                        height: value.size.height,
                        child: VideoPlayer(controller),
                      ),
                    ),
                  ),

                  // Play button
                  GestureDetector(
                    onTap: () {
                      if (value.isPlaying) {
                        controller.pause();
                      } else {
                        if (value.position >= value.duration) {
                          controller.seekTo(Duration.zero);
                        }
                        controller.play();
                      }
                    },

                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withOpacity(0.8),
                      child: Icon(
                        value.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: AppColors.primaryColor,
                        size: 30,
                      ),
                    ),
                  ),

                  // Duration bottom right
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: AppText(
                        text: formatDuration(displayTime),
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: pickVideo,
                    child: AppContainer(
                      widget: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIconWidget(assetPath: AssetImages.refresh),

                          const SizedBox(width: 8),

                          AppText(text: "Replace Video", fontSize: 12),
                        ],
                      ).pad(),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: GestureDetector(
                    onTap: deleteVideo,
                    child: AppContainer(
                      widget: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIconWidget(assetPath: AssetImages.delete),

                          const SizedBox(width: 8),

                          AppText(text: "Delete", fontSize: 12),
                        ],
                      ).pad(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}