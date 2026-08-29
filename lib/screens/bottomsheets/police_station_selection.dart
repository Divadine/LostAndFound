import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lost_and_found/models/posts_model/selected_location_model.dart';
import 'package:lost_and_found/screens/bottomsheets/police_proof_submission.dart';
import 'package:lost_and_found/screens/maps/location_selection_screen.dart';
import 'package:lost_and_found/screens/permissions/location_permission.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

import '../post/first_stepper_screen.dart';

class PoliceStationHandOver extends StatefulWidget {
  final int postId;
  final int userId;
  final String phoneNumber;
  final int? enquiryId;
  final int? receiverId;
  final int? receiverPostId;
  final int handoverType; // owner=1 / police=2 / others=3 — see HandoverType

  const PoliceStationHandOver({
    super.key,
    required this.postId,
    required this.userId,
    required this.phoneNumber,
    this.enquiryId,
    this.receiverId,
    this.receiverPostId,
    required this.handoverType,
  });

  @override
  State<PoliceStationHandOver> createState() => _PoliceStationHandOverState();
}

class _PoliceStationHandOverState extends State<PoliceStationHandOver> {
  final TextEditingController mapTextController = TextEditingController();
  final TextEditingController textController = TextEditingController();

  final AppLocationPermission _appPermissions = AppLocationPermission();
  String? latitude;
  String? longitude;

  Future<void> _openMapForAddress() async {
    final granted = await _appPermissions.requestLocationPermission(context);
    if (!granted) return;

    if (!mounted) return;
    final singleLocation = await context.pushNamed(
      AppRoutes.mapScreen,
      extra: MapScreenModel(needSingleLocation: true),
    );

    if (singleLocation != null) {
      final location = singleLocation as SelectedLocationModel;
      setState(() {
        textController.text = location.address;
        latitude = location.latitude?.toString();
        longitude = location.longitude?.toString();
        // if (mapTextController.text.isEmpty) {
        //   mapTextController.text = location.address;
        // }
      });
    }
  }

  @override
  void dispose() {
    mapTextController.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppText(
          text: 'Hand Over to Police Station',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        AppText(
          text: 'Please Provide the Police Station information',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        buildTextFieldWithHeading(
          title: 'Police Station Location',
          fieldWidget: AppTextField(
            hintText: 'Enter Police station name or location',
            textController: mapTextController,
            onChange: (v) {},
            onSubmit: (v) {},
          ),
        ),

        Align(
          alignment: AlignmentGeometry.centerLeft,
          child: AppText(
            text: 'Example : T. Nagar Police station, Chennai',
            fontWeight: FontWeight.w300,
            fontSize: 10,
            color: AppColors.black.withAlpha(100),
          ),
        ),

        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              text: 'Police station location Pin',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ).pad(1),
            SizedBox(height: 7),

            GestureDetector(
              onTap: _openMapForAddress,
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.fieldGrey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AppIconWidget(
                        assetPath: AssetImages.map,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Center(
                      child: AppTextField(
                        onTap: _openMapForAddress,
                        hintText: '',
                        textController: TextEditingController(
                          text: "Pin Location on Map",
                        ),
                        textBackgroundColor: AppColors.primaryColor,
                        onChange: (e) {},
                        suffixIcon: AppIconWidget(
                          assetPath: AssetImages.iosForward,
                        ).pad(12),
                        readOnly: true,
                        onSubmit: (e) {},
                        prefixIcon: AppIconWidget(
                          assetPath: AssetImages.map_marker,
                          size: 20,
                        ).pad(12),
                      ).padHorizontal(15),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        buildTextFieldWithHeading(
          title: 'Full Address',
          fieldWidget: AppTextField(
            hintText: 'Enter Police station name or location',
            textController: textController,
            readOnly: true,
            onTap: _openMapForAddress,
            onChange: (v) {},
            onSubmit: (v) {},
          ),
        ),

        AppButton(
          title: 'Submit',
          onTap: () {
            if (textController.text.trim().isEmpty) {
              AppDialogue.showPopup(
                context: context,
                content: const AppText(
                  text: 'Please pick the police station location on the map',
                ),
              );
              return;
            }

            AppRoutes.pop();
            AppUiHelper.showBottomSheet(
              showHandle: false,
              context: context,
              child: PoliceHandoverProofDocuments(
                postId: widget.postId,
                userId: widget.userId,
                phoneNumber: widget.phoneNumber,
                enquiryId: widget.enquiryId,
                receiverId: widget.receiverId,
                receiverPostId: widget.receiverPostId,
                handoverType: widget.handoverType,
                stationName: mapTextController.text.trim(),
                stationAddress: textController.text.trim(),
                latitude: latitude,
                longitude: longitude,
              ),
            );
          },
          fontSize: 14,
          bgColor: AppColors.primaryColor,
          radius: BorderRadius.circular(7),
        ),
      ],
    );
  }
}