import 'dart:async';
import 'dart:io';
import 'package:audio_waveforms/audio_waveforms.dart';
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
import 'package:lost_and_found/shared_widgets/app_recorder.dart';
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

class SecondStepperScreen extends StatefulWidget {
  final int postId;
  final String? prefillDescription;
  const SecondStepperScreen({super.key, required this.postId, this.prefillDescription});

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

  bool isVideoPlaying = false;
  Duration videoDuration = Duration.zero;

  bool isSubmitting = false;
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

  @override
  void initState() {
    super.initState();
    locationController.add(loc);
    _recorderService.deleteRecording();
    if (widget.prefillDescription != null && widget.prefillDescription!.isNotEmpty) {
      descriptionController.text = widget.prefillDescription!;
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    locationController.close();
    _recorderService.dispose();
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

    videoDuration = _videoController!.value.duration;

    videoStreamController.add(null);
    //setState(() {});
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
    //setState(() {});
  }

  String formatDuration(Duration duration) {
    String two(int n) => n.toString().padLeft(2, '0');

    return "${two(duration.inMinutes)}:${two(duration.inSeconds % 60)}";
  }

  void deleteVideo() {

    _videoController?.dispose();
    _videoController = null;
    selectedVideo = null;
    isVideoPlaying = false;

    videoStreamController.add(null);
    // setState(() {
    //   selectedVideo = null;
    //   //_videoController = null;
    //   isVideoPlaying = false;
    // });
  }

  Future<void> selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
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
      selectedDate = DateTime(picked.year, picked.month, picked.day);
      selectedDate = picked;
      dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      dateStreamController.add(picked);
      //setState(() {});
    }
    print('picked date is ^^^^^^^^^^^^^^^^^^^^^^^^^   $picked');
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

  Future<void> _onSubmit() async {
    if (loc.isEmpty) {
      AppDialogue.showPopup(context: context, content: AppText(text: 'Please add a location'));
      return;
    }
    if (selectedDate == null) {
      AppDialogue.showPopup(context: context, content: AppText(text: 'Please select a date'));
      return;
    }
    if (descriptionController.text.trim().isEmpty) {
      AppDialogue.showPopup(context: context, content: AppText(text: 'Please enter a description'));
      return;
    }

    setState(() => isSubmitting = true);

    int? audioId;
    int? videoId;
    print("Audio path => ${_recorderService.audioPath}");

    if (_recorderService.isRecorded || _recorderService.audioPath != null) {
      final audioResponse = await  authController.createAudio(audio: File(_recorderService.audioPath!));
      if (!mounted) return;
      if (!audioResponse.isSuccess || audioResponse.data == null) {
        setState(() => isSubmitting = false);
        final msg = audioResponse.currentState == CurrentState.noInternet
            ? 'No internet connection. Please check your network.'
            : (audioResponse.message.isNotEmpty ? audioResponse.message : 'Failed to upload audio');
        AppDialogue.showPopup(context: context, content: AppText(text: msg));
        return;
      }
      audioId = audioResponse.data!.id;
    }
    // Step A: upload video if selected
    if (selectedVideo != null) {
      final videoResponse = await authController.createVideo(video: File(selectedVideo!.path));
      if (!mounted) return;
      if (!videoResponse.isSuccess || videoResponse.data == null) {
        setState(() => isSubmitting = false);
        final msg = videoResponse.currentState == CurrentState.noInternet
            ? 'No internet connection. Please check your network.'
            : (videoResponse.message.isNotEmpty ? videoResponse.message : 'Failed to upload video');
        AppDialogue.showPopup(context: context, content: AppText(text: msg));
        return;
      }
      videoId = videoResponse.data!.id;
    }

    // Step C: complete the post
    final firstLocation = loc.first;
    final coordinates = loc
        .map((l) => {
      'latitude': l.latitude.toString(),
      'longitude': l.longitude.toString(),
    })
        .toList();

    print('COORDINATES BEING SENT: @@@@@@@@@@@@@@@@@@@@@@@@@ ->$coordinates');

    print('=================== STEP 2 SUBMIT DEBUG ===================');
    print('postId: ${widget.postId}');
    print('---- LOCATIONS ----');
    for (int i = 0; i < loc.length; i++) {
      print('  [$i] address: ${loc[i].address}');
      print('  [$i] latitude: ${loc[i].latitude}');
      print('  [$i] longitude: ${loc[i].longitude}');
    }
    print('coordinates payload: $coordinates');
    print('location field value: ${textController.text.trim().isNotEmpty ? textController.text.trim() : firstLocation.address}');
    print('address field value: ${firstLocation.address}');
    print('---- DATE ----');
    print('selectedDate: $selectedDate');
    print('---- DESCRIPTION ----');
    print('description: ${descriptionController.text.trim()}');
    print('---- AUDIO ----');
    print('recorder state: ${_recorderService.state}');
    print('recorder audioPath: ${_recorderService.audioPath}');
    print('recorder isRecorded: ${_recorderService.isRecorded}');
    print('uploaded audioId: $audioId');
    print('---- VIDEO ----');
    print('selectedVideo path: ${selectedVideo?.path}');
    print('uploaded videoId: $videoId');
    print('=============================================================');
    final completeResponse = await authController.completePostStep2(
      postId: widget.postId,
      location: textController.text.trim().isNotEmpty ? textController.text.trim() : firstLocation.address,
      address: firstLocation.address,
      coordinates: coordinates,
      postDate: selectedDate!,
      description: descriptionController.text.trim(),
      audioId: audioId,
      videoId: videoId,
    );

    print('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%$completeResponse');

    if (!mounted) return;
    setState(() => isSubmitting = false);

    if (completeResponse.isSuccess) {
      AppDialogue.showPopup(context: context, content: PostLive());
      //AppRoutes.pushNamed(AppRoutes.bottomScreen);
    } else {
      final msg = completeResponse.currentState == CurrentState.noInternet
          ? 'No internet connection. Please check your network.'
          : (completeResponse.message.isNotEmpty ? completeResponse.message : 'Failed to complete post');
      AppDialogue.showPopup(context: context, content: AppText(text: msg));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: 'Post Lost Item',
        leadingSvg: AssetImages.backArrow,
        leadingIconColor: AppColors.primaryColor,
        onLeadingTap: () {
          AppRoutes.pop();
        },
      ),
      //AppBar(toolbarHeight: 0, backgroundColor: AppColors.primaryColor),
      body: SafeArea(
        child: Column(
          children: [
            const AppStepIndicator(currentStep: 2, totalSteps: 2),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  spacing: 10,
  
                  children: [
                  buildTextFieldWithHeading(
                    title: 'Where did you lose it ?',
                    fieldWidget: AppTextField(
                      hintText: 'Chennai, Tamil Nadu, India',
                      textController: textController,
                      onChange: (v) {},
                      onSubmit: (v) {},
                    ),
                  ),

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
                                          spacing: 7,
                                          children: [
                                            buildIconContainer(
                                              context,
                                              icon: AssetImages.mapIcon,
                                              size: 15,
                                              height: 30,
                                              width: 30,
                                            ),
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

                  StreamBuilder(
                    stream: dateStreamController.stream,
                    builder: (context, asyncSnapshot) {
                      //final dateData = asyncSnapshot.data;
                      return GestureDetector(
                        onTap: selectDate,
                        child: buildTextFieldWithHeading(
                          title: 'Date',
                          fieldWidget: GestureDetector(
                            onTap: selectDate,
                            child: AppTextField(
                              //readOnly: true,
                              hintText: 'Select Date',
                              readOnly: true,
                              textController: dateController,
                              onChange: (v) {},
                              onSubmit: (v) {},
                              suffixIcon: GestureDetector(
                                  onTap:selectDate,
                                  child: AppIconWidget(assetPath: AssetImages.calender).pad()
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  ),

                  buildTextFieldWithHeading(
                    title: 'Description',
                    fieldWidget: AppTextField(
                      hintText: 'write Description here',
                      textController: descriptionController,
                      onChange: (v) {},
                      onSubmit: (v) {},
                      maxLines: 5,
                    ),
                  ),
                  SizedBox(height: 10),
                  Column(
                    spacing: 10,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        text: 'Voice Description',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),

                      AppRecorder(),

                    ],
                  ),

                  SizedBox(height: 10),

                  StreamBuilder(
                    stream: videoStreamController.stream,
                    builder: (context, asyncSnapshot) {
                      return Column(
                        spacing: 10,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            text: 'Add a short video of your item or place',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          AppContainer(
                            widget: Column(
                              spacing: 10,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (selectedVideo == null)
                                  AppText(
                                    text: 'Tap to choose a video',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12,
                                    color: AppColors.grey,
                                  ),


                                if (_videoController != null &&
                                    _videoController!.value.isInitialized)
                                  buildVideoPreview()
                                else
                                  GestureDetector(
                                    onTap: pickVideo,
                                    child: AppIconWidget(assetPath: AssetImages.video),
                                  ),
                              ],
                            ).pad(),
                          ),

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

                  AppButton(
                    title: 'Review & Submit',
                    onTap:   isSubmitting ? () {} : _onSubmit,
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
    );
  }

  Widget buildVideoPreview() {
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
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              ),

              // Play button
              GestureDetector(
                onTap: () {
                  
                    if (_videoController!.value.isPlaying) {
                      _videoController!.pause();
                      isVideoPlaying = false;
                    } else {
                      _videoController!.play();
                      isVideoPlaying = true;
                    }
                videoStreamController.add(null);
                },

                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white.withOpacity(0.8),
                  child: Icon(
                    isVideoPlaying ? Icons.pause : Icons.play_arrow,
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
                    text: formatDuration(videoDuration),
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
  }
}
