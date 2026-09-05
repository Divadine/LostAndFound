import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

import 'package:lost_and_found/api_providers/api_client.dart';
import 'package:lost_and_found/controllers/auth_controllers.dart';
import 'package:lost_and_found/enums/current_state.dart';
import 'package:lost_and_found/models/posts_model/selected_location_model.dart';
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';
import 'package:lost_and_found/utils/app_preferences.dart';

class PreviewPostScreen extends StatefulWidget {
  final int postType;
  final int categoryId;
  final int subcategoryId;
  final String itemName;
  final List<File> selectedImages;
  final File? mainImage;
  final String itemTypeLabel;
  final String itemTypeValue;
  final String color;
  final List<Map<String, String>> fieldValues;
  final List<SelectedLocationModel> locations;
  final String locationText;
  final DateTime postDate;
  final String description;
  final String? audioPath;
  final File? videoFile;

  // These are for backward compatibility with the user's draft if needed, 
  // but we primarily use the fields above.
  final String? category;
  final String? subCategory;

  const PreviewPostScreen({
    super.key,
    required this.postType,
    required this.categoryId,
    required this.subcategoryId,
    required this.itemName,
    required this.selectedImages,
    this.mainImage,
    this.itemTypeLabel = 'Item Type',
    this.itemTypeValue = '',
    this.color = '',
    this.fieldValues = const [],
    required this.locations,
    required this.locationText,
    required this.postDate,
    required this.description,
    this.audioPath,
    this.videoFile,
    this.category,
    this.subCategory,
  });

  @override
  State<PreviewPostScreen> createState() => _PreviewPostScreenState();
}

class _PreviewPostScreenState extends State<PreviewPostScreen> {
  final authController = AuthControllers(
    authRepository: AuthRepository(apiClient: ApiClient()),
  );

  bool isSubmitting = false;

  // Audio Playback
  final PlayerController _waveController = PlayerController();
  bool _audioReady = false;
  bool _isAudioPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  // Video Playback
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    _setupAudio();
    _setupVideo();
  }

  Future<void> _setupAudio() async {
    if (widget.audioPath == null || widget.audioPath!.isEmpty) return;
    try {
      await _waveController.preparePlayer(
        path: widget.audioPath!,
        shouldExtractWaveform: true,
        noOfSamples: 100,
        volume: 1.0,
      );

      final durationMs = await _waveController.getDuration();
      if (!mounted) return;
      setState(() {
        _audioReady = true;
        _audioDuration = Duration(milliseconds: durationMs);
      });

      _waveController.onPlayerStateChanged.listen((state) {
        if (!mounted) return;
        setState(() => _isAudioPlaying = state == PlayerState.playing);
      });

      _waveController.onCurrentDurationChanged.listen((positionMs) {
        if (!mounted) return;
        setState(() => _audioPosition = Duration(milliseconds: positionMs));
      });

      _waveController.onCompletion.listen((_) {
        if (!mounted) return;
        setState(() {
          _isAudioPlaying = false;
          _audioPosition = Duration.zero;
        });
      });
    } catch (_) {}
  }

  Future<void> _setupVideo() async {
    if (widget.videoFile == null) return;
    _videoController = VideoPlayerController.file(widget.videoFile!);
    await _videoController!.initialize();
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _waveController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) => DateFormat('d MMM yyyy').format(date);

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }

  Future<void> _toggleAudio() async {
    if (!_audioReady) return;
    if (_isAudioPlaying) {
      await _waveController.pausePlayer();
    } else {
      await _waveController.startPlayer();
    }
  }

  Future<void> _onSubmit() async {
    if (widget.locations.isEmpty) {
      AppSnackBar.show(context: context, message: 'Please add a location');
      return;
    }

    setState(() => isSubmitting = true);

    // Step 1: upload Step 1 images
    final imageResponse = await authController.createImage(images: widget.selectedImages);
    if (!mounted) return;
    if (!imageResponse.isSuccess || imageResponse.data == null) {
      setState(() => isSubmitting = false);
      final msg = imageResponse.currentState == CurrentState.noInternet
          ? 'No internet connection. Please check your network.'
          : (imageResponse.message.isNotEmpty ? imageResponse.message : 'Failed to upload images');
      AppDialogue.showPopup(context: context, content: AppText(text: msg));
      return;
    }
    final imageIds = imageResponse.data!.map((e) => e.id).join(',');

    // Step 2: call createPostStep1
    final userId = await AppPreferences.getUserId();
    final postResponse = await authController.createPostStep1(
      userId: userId ?? 0,
      postType: widget.postType,
      categoryId: widget.categoryId,
      subcategoryId: widget.subcategoryId,
      itemName: widget.itemName,
      color: widget.color,
      postImages: imageIds,
      postValues: widget.fieldValues,
    );

    if (!mounted) return;
    if (!postResponse.isSuccess || postResponse.data == null) {
      setState(() => isSubmitting = false);
      final msg = postResponse.currentState == CurrentState.noInternet
          ? 'No internet connection. Please check your network.'
          : (postResponse.message.isNotEmpty ? postResponse.message : 'Failed to initiate post');
      AppSnackBar.show(context: context, message: msg);
      return;
    }

    final int postId = postResponse.data!.id;

    int? audioId;
    int? videoId;

    // Step 3: upload voice recording, if any
    if (widget.audioPath != null && widget.audioPath!.isNotEmpty) {
      final audioResponse = await authController.createAudio(audio: File(widget.audioPath!));
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

    // Step 4: upload video, if any
    if (widget.videoFile != null) {
      final videoResponse = await authController.createVideo(video: widget.videoFile!);
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

    // Step 5: complete the post
    final firstLocation = widget.locations.first;
    final coordinates = widget.locations
        .map((l) => {
      'latitude': l.latitude.toString(),
      'longitude': l.longitude.toString(),
    })
        .toList();

    final completeResponse = await authController.completePostStep2(
      postId: postId,
      location: widget.locationText.isNotEmpty ? widget.locationText : firstLocation.address,
      address: firstLocation.address,
      coordinates: coordinates,
      postDate: widget.postDate,
      description: widget.description,
      audioId: audioId,
      videoId: videoId,
    );

    if (!mounted) return;
    setState(() => isSubmitting = false);

    if (completeResponse.isSuccess) {
      AppDialogue.showPopup(context: context, content: PostLive());
    } else {
      final msg = completeResponse.currentState == CurrentState.noInternet
          ? 'No internet connection. Please check your network.'
          : (completeResponse.message.isNotEmpty ? completeResponse.message : 'Failed to complete post');
      AppSnackBar.show(context: context, message: msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentMaxWidth = screenWidth > 700 ? 640.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: widget.postType == 0 ? 'Lost Item Preview' : 'Found Item Preview',
              centerTitle: true,
              leadingSvg: AssetImages.backArrow,
              leadingIconColor: AppColors.primaryColor,
              onLeadingTap: () => AppRoutes.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFirstContainer(),
                        const SizedBox(height: 12),
                        _buildSecondContainer(),
                        const SizedBox(height: 12),
                      ],
                    ).pad(16),
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: AppButton(
                  title: isSubmitting ? 'Please wait...' : 'Submit',
                  onTap: isSubmitting ? () {} : _onSubmit,
                  radius: BorderRadius.circular(10),
                  fontSize: 14,
                ).pad(20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirstContainer() {
    final brandField = widget.fieldValues.firstWhere(
      (field) => field['field']?.trim().toLowerCase() == 'brand',
      orElse: () => <String, String>{},
    );
    final brand = brandField['value']?.trim() ?? '';

    final modelField = widget.fieldValues.firstWhere(
      (field) => field['field']?.trim().toLowerCase() == 'model',
      orElse: () => <String, String>{},
    );
    final model = modelField['value']?.trim() ?? '';

    String itemType = '';
    if (widget.itemTypeValue.trim().isNotEmpty) {
      itemType = widget.itemTypeValue.trim();
    } else if (widget.subCategory?.trim().isNotEmpty ?? false) {
      itemType = widget.subCategory!.trim();
    }

    final hasImage = widget.selectedImages.isNotEmpty;

    return AppContainer(
      widget: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: hasImage
                ? Image.file(
                    widget.selectedImages.first,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                  )
                : _buildImagePlaceholder(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (itemType.isNotEmpty) _buildInfoRow('Item Type', itemType),
                if (brand.isNotEmpty) _buildInfoRow('Brand', brand),
                if (model.isNotEmpty) _buildInfoRow('Model', model),
                if (widget.color.isNotEmpty) _buildInfoRow('Color', widget.color),
              ],
            ),
          ),
        ],
      ).pad(10),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: AppColors.grey.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined, size: 32, color: AppColors.primaryColor),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: AppText(text: title, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: AppText(text: value, fontSize: 13, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondContainer() {
    final dynamicFields = widget.fieldValues.where((field) {
      final name = field['field']?.trim().toLowerCase() ?? '';
      if (name == 'brand' || name == 'model' || name == 'color') return false;
      return (field['value']?.trim() ?? '').isNotEmpty;
    }).toList();

    final hasAudio = widget.audioPath != null && widget.audioPath!.trim().isNotEmpty;
    final hasVideo = widget.videoFile != null;
    final hasLocation = widget.locations.isNotEmpty;
    final hasLandmark = widget.locationText.trim().isNotEmpty;
    final hasDescription = widget.description.trim().isNotEmpty;

    return AppContainer(
      widget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasLandmark)
            _buildDividerLabeledBlock('Land Mark', widget.locationText.trim(), isFirst: true),
          
          for (int i = 0; i < dynamicFields.length; i++)
            _buildDividerLabeledBlock(
              dynamicFields[i]['field']?.trim() ?? '',
              dynamicFields[i]['value']?.trim() ?? '',
              isFirst: !hasLandmark && i == 0,
            ),

          if (hasLocation)
            _buildLocationsBlock(isFirst: !hasLandmark && dynamicFields.isEmpty),

          _buildDividerLabeledBlock(
            'Date',
            _formatDate(widget.postDate),
            isFirst: !hasLandmark && dynamicFields.isEmpty && !hasLocation,
          ),

          if (hasDescription)
            _buildDividerLabeledBlock('Description', widget.description.trim()),

          if (hasAudio) _buildAudioBlock(),
          if (hasVideo) _buildVideoBlock(),
        ],
      ).pad(12),
    );
  }

  Widget _buildDividerLabeledBlock(String title, String value, {bool isFirst = false}) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isFirst) ...[
          const SizedBox(height: 8),
          const Divider(color: AppColors.fieldGrey, thickness: 0.5, height: 1),
        ],
        const SizedBox(height: 8),
        AppText(
          text: title,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AppColors.primaryColor,
        ),
        const SizedBox(height: 4),
        AppText(text: value, fontWeight: FontWeight.w400, fontSize: 12),
      ],
    );
  }

  Widget _buildLocationsBlock({bool isFirst = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isFirst) ...[
          const SizedBox(height: 8),
          const Divider(color: AppColors.fieldGrey, thickness: 0.5, height: 1),
        ],
        const SizedBox(height: 8),
        const AppText(
          text: 'Location',
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AppColors.primaryColor,
        ),
        const SizedBox(height: 4),
        for (int i = 0; i < widget.locations.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == widget.locations.length - 1 ? 0 : 6),
            child: AppText(text: widget.locations[i].address, fontSize: 12, fontWeight: FontWeight.w400),
          ),
      ],
    );
  }

  Widget _buildAudioBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Divider(color: AppColors.fieldGrey, thickness: 0.5, height: 1),
        const SizedBox(height: 8),
        const AppText(
          text: 'Voice Description',
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AppColors.primaryColor,
        ),
        const SizedBox(height: 8),
        _buildWaveformPlayer(),
      ],
    );
  }

  Widget _buildWaveformPlayer() {
    if (!_audioReady) {
      return Container(
        height: 46,
        alignment: Alignment.centerLeft,
        child: const AppText(text: 'Loading recording...', fontSize: 12, color: AppColors.grey),
      );
    }
    return Row(
      children: [
        GestureDetector(
          onTap: _toggleAudio,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryColor,
            child: Icon(_isAudioPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: _buildWave()),
        const SizedBox(width: 10),
        AppText(text: _formatDuration(_audioDuration), fontSize: 12),
      ],
    );
  }

  static const List<double> _waveHeights = [
    2, 5, 8, 10, 14, 18, 20, 25, 20, 14, 10, 14, 18, 20, 25, 20, 14, 10, 15, 18, 20, 25, 20, 14, 10, 8, 5, 2,
  ];

  Widget _buildWave() {
    final totalMs = _audioDuration.inMilliseconds;
    final progress = totalMs > 0 ? (_audioPosition.inMilliseconds / totalMs).clamp(0.0, 1.0) : 0.0;
    final total = _waveHeights.length;
    final filledCount = (progress * total).floor();
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(total, (i) {
          final bool filled = i < filledCount;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 3,
            height: _waveHeights[i] + 6,
            decoration: BoxDecoration(
              color: filled ? AppColors.primaryColor : AppColors.grey,
              borderRadius: BorderRadius.circular(5),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildVideoBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Divider(color: AppColors.fieldGrey, thickness: 0.5, height: 1),
        const SizedBox(height: 8),
        const AppText(
          text: 'Video Description',
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AppColors.primaryColor,
        ),
        const SizedBox(height: 8),
        _buildLocalVideoPlayer(),
      ],
    );
  }

  Widget _buildLocalVideoPlayer() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(color: AppColors.fieldGrey, child: const Center(child: CircularProgressIndicator())),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                  _isVideoPlaying = false;
                } else {
                  _videoController!.play();
                  _isVideoPlaying = true;
                }
              });
            },
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white.withOpacity(0.8),
              child: Icon(_isVideoPlaying ? Icons.pause : Icons.play_arrow, color: AppColors.primaryColor, size: 30),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
              child: AppText(text: _formatDuration(_videoController!.value.duration), color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}