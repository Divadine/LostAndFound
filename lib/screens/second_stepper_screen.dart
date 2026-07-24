import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lost_and_found/screens/register_screen.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';


class SecondStepperScreen extends StatefulWidget {
  const SecondStepperScreen({super.key});

  @override
  State<SecondStepperScreen> createState() => _SecondStepperScreenState();
}

class _SecondStepperScreenState extends State<SecondStepperScreen> {

  DateTime? selectedDate;
  bool isRecording = false;
  String? audioPath;
  XFile? selectedVideo;

  TextEditingController textController = TextEditingController();
  TextEditingController mapController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  final AudioRecorder recorder = AudioRecorder();
  final ImagePicker picker = ImagePicker();
  VideoPlayerController? _videoController;





  Future<void> pickVideo() async {
    final XFile? video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 30),
    );

    if (video != null) {
      selectedVideo = video;

      setState(() {});
    }
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
        const SnackBar(
          content: Text("Video must be less than 15 MB"),
        ),
      );
      return;
    }

    selectedVideo = video;
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(file);
    await _videoController!.initialize();

    setState(() {});
  }

  Future<void> selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      setState(() {});
    }
  }

  Future<void> startRecordings() async {
    if (await recorder.hasPermission()) {
      await recorder.start(
        const RecordConfig(),
        path: '${DateTime.now().millisecondsSinceEpoch}.m4a',
      );

      setState(() {
        isRecording = true;
      });
    }
  }

  Future<void> startRecording() async {
    try {
      if (await recorder.hasPermission()) {
        await recorder.start(
          const RecordConfig(),
          path: '${DateTime.now().millisecondsSinceEpoch}.m4a',
        );

        setState(() {
          isRecording = true;
        });
      } else {
        debugPrint("Microphone permission denied");
      }
    } catch (e, s) {
      debugPrint("Recording error: $e");
      debugPrintStack(stackTrace: s);
    }
  }


  Future<void> stopRecording() async {
    audioPath = await recorder.stop();

    setState(() {
      isRecording = false;
    });

    print(audioPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(title: 'Post Lost Item',
        leadingSvg: AssetImages.backArrow,leadingIconColor: AppColors.primaryColor,
        onLeadingTap: () {
          AppRoutes.pop();
        },),
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
          fieldWidget: AppTextField(
            hintText: 'Chennai, Tamil Nadu, India',
            textController: mapController,
            onChange: (v) {},
            onSubmit: (v) {},
            suffixIcon: AppIconWidget(
              assetPath: AssetImages.locationMarker,
            ).pad(),
          ),
        ),

        buildTextFieldWithHeading(
          title: 'Date',
          fieldWidget: AppTextField(
            //readOnly: true,
            hintText: 'Select Date',
            textController: dateController,
            onChange: (v) {},
            onSubmit: (v) {},
            suffixIcon: 
                GestureDetector(onTap : selectDate, child: AppIconWidget(assetPath: AssetImages.calender).pad())),
          
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
            AppContainer(
              widget: Column(
                spacing: 10,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppText(
                    text: 'Tap the button to start recording',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: AppColors.grey,
                  ),
                  GestureDetector(
                        onTap:   () {
                        if (isRecording) {
                          stopRecording();
                        } else {
                          startRecording();
                        }
                      },
                      child: AppIconWidget(assetPath: AssetImages.mic)),
                ],
              ).pad(),
            ),
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
                  AppText(
                    text: 'Tap to choose a video',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: AppColors.grey,
                  ),

                  if (_videoController != null && _videoController!.value.isInitialized)
                    SizedBox(
                      height: 180,
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                    )
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
          onTap: () {},
          radius: BorderRadius.circular(10),
          fontSize: 14,

        ),
      ],
    ).pad(16),),
    ),
    );
  }
}
