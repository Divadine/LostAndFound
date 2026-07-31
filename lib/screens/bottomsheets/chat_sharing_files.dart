import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';

class ChatSharingFiles extends StatefulWidget {
  const ChatSharingFiles({super.key});

  @override
  State<ChatSharingFiles> createState() => _ChatSharingFilesState();
}

class _ChatSharingFilesState extends State<ChatSharingFiles> {
  @override
  Widget build(BuildContext context) {
    return AppContainer(
      widget: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 5,
        children: [
          AppText(text: 'Camera',fontWeight: FontWeight.w500,fontSize: 14,),
          Divider(),
          AppText(text: 'Attach Photo',fontWeight: FontWeight.w500,fontSize: 14,),
          Divider(),
          AppText(text: 'Share Location',fontWeight: FontWeight.w500,fontSize: 14,),
          Divider(),
          AppText(text: 'Share Address',fontWeight: FontWeight.w500,fontSize: 14,),
      
          SizedBox(height: 10,),
          AppButton(title: 'Cancel', onTap: (){},fontSize: 14,textColor: AppColors.red,bgColor: AppColors.white,)

        ],
      ),
    );
  }
}
