import 'dart:io';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lost_and_found/models/selected_location_model.dart';
import 'package:lost_and_found/screens/authentication/register_screen.dart';
import 'package:lost_and_found/screens/maps/location_selection_screen.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_recorder.dart';
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
  const SecondStepperScreen({super.key});

  @override
  State<SecondStepperScreen> createState() => _SecondStepperScreenState();
}

class _SecondStepperScreenState extends State<SecondStepperScreen> {
  DateTime? selectedDate;

  bool isVideoPlaying = false;
  Duration videoDuration = Duration.zero;

  XFile? selectedVideo;
  List<SelectedLocationModel> loc = [];

  TextEditingController textController = TextEditingController();
  TextEditingController mapController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  final ImagePicker picker = ImagePicker();
  VideoPlayerController? _videoController;

  @override
  void dispose() {
    _videoController?.dispose();

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

    setState(() {});
  }

  String formatDuration(Duration duration) {
    String two(int n) => n.toString().padLeft(2, '0');

    return "${two(duration.inMinutes)}:${two(duration.inSeconds % 60)}";
  }

  void deleteVideo() {
    _videoController?.dispose();

    setState(() {
      selectedVideo = null;
      _videoController = null;
      isVideoPlaying = false;
    });
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
      dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      setState(() {});
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

              buildTextFieldWithHeading(
                title: 'Location',
                fieldWidget: loc.isEmpty
                    ? AppTextField(
                        readOnly: true,

                        onTap: () async {
                          final location = await context.pushNamed(
                            AppRoutes.mapScreen,
                            extra: MapScreenModel(
                              needSingleLocation: false,
                              selectedLocation: loc,
                            ),
                          );
                          loc = location as List<SelectedLocationModel>;
                          print(
                            "lllllllllllllllllllllllllllllllll${loc.map((e) => e.address)}",
                          );
                        },
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
                            itemCount: loc.length,
                            itemBuilder: (context, index) {
                              final locate = loc[index];
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
                                        setState(() {});
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
                              onTap: () async {
                                final location = await context.pushNamed(
                                  AppRoutes.mapScreen,
                                  extra: MapScreenModel(
                                    needSingleLocation: false,
                                    selectedLocation: loc,
                                  ),
                                );
                                loc = location as List<SelectedLocationModel>;
                                print(
                                  "lllllllllllllllllllllllllllllllll${loc.map((e) => e.address)}",
                                );
                              },
                            ),
                        ],
                      ),
              ),

              buildTextFieldWithHeading(
                title: 'Date',
                fieldWidget: AppTextField(
                  //readOnly: true,
                  hintText: 'Select Date',
                  readOnly: true,
                  textController: dateController,
                  onChange: (v) {},
                  onSubmit: (v) {},
                  suffixIcon: GestureDetector(
                    onTap: selectDate,
                    child: AppIconWidget(assetPath: AssetImages.calender).pad(),
                  ),
                ),
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
              Column(
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
                            onTap: pickVideos,
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
              ),

              AppButton(
                title: 'Review & Submit',
                onTap: () {
                  AppDialogue.showPopup(context: context, content: PostLive());
                },
                radius: BorderRadius.circular(10),
                fontSize: 14,
              ),
            ],
          ).pad(16),
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
                height: 180,
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
                  setState(() {
                    if (_videoController!.value.isPlaying) {
                      _videoController!.pause();
                      isVideoPlaying = false;
                    } else {
                      _videoController!.play();
                      isVideoPlaying = true;
                    }
                  });
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
