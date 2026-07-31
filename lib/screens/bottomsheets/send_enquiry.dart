import 'package:flutter/material.dart';
import 'package:lost_and_found/screens/authentication/register_screen.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';

class SendEnquiry extends StatefulWidget {
  const SendEnquiry({super.key});

  @override
  State<SendEnquiry> createState() => _SendEnquiryState();
}

class _SendEnquiryState extends State<SendEnquiry> {
  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(text: 'Send Enquiry',fontSize: 18,fontWeight: FontWeight.w600,color: AppColors.primaryColor,),
           InkWell(child: AppIconWidget(assetPath: AssetImages.crossIcon),onTap: (){AppRoutes.pop();},),
          ],
        ),
        buildTextFieldWithHeading(title: 'Name*', fieldWidget: AppTextField(hintText: '', textController: TextEditingController(), onChange: (v){}, onSubmit: (v){})),
        buildTextFieldWithHeading(title: 'Description', fieldWidget: AppTextField(hintText: '', textController: TextEditingController(), onChange: (v){}, onSubmit: (v){},maxLines: 5,)),
        
        AppButton(title: 'Send Enquiry', onTap: (){
          AppRoutes.pushNamed(AppRoutes.individualChatScreen);
        })

      ],
    );
  }
}
