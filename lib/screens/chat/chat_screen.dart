import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final chats = [
    {
      "image":
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTweFjIvljtnBPBG3-QrPhjYAWLr_1vmJzWbHM58T7TUw&s=10',
      "name": "Dinesh",
      "message": "Hey, How are you",
      "time": "10:30 AM",
    },
    {
      "image":
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTweFjIvljtnBPBG3-QrPhjYAWLr_1vmJzWbHM58T7TUw&s=10',
      "name": "Kumar",
      "message": "Your item is found",
      "time": "Yesterday",
    },
  ];
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: AppColors.primaryColor,
        ),

        body: SafeArea(
          child: Column(
            spacing:15,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text: 'Enquires & Messages',
                fontWeight: FontWeight.w500,
                fontSize: 18,
              ).pad(),


              //tabBar options

              Container(
                height: 55,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.fieldGrey.withAlpha(1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.fieldGrey,
                  ),
                ),

                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,

                  indicator: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(5),
                  ),

                  dividerColor: Colors.transparent,

                  labelColor: AppColors.white,
                  unselectedLabelColor: AppColors.grey,

                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),

                  tabs: const [
                    Tab(
                      text: "My Leads",
                    ),
                    Tab(
                      text: "Enquiry",
                    ),
                  ],
                ),
              ),


              //chats

              Expanded(
                child: ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context,index){

                    final chat = chats[index];

                    return ChatTile(
                      imageUrl: chat["image"]!,
                      name: chat["name"]!,
                      lastMessage: chat["message"]!,
                      time: chat["time"]!,
                    );

                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }


}

Widget ChatTile({
required String imageUrl,
required String name,
required String lastMessage,
required String time,
})
{
  return  Row(
      crossAxisAlignment: CrossAxisAlignment.center,

      children: [

        Stack(
          children:[
            CircleAvatar(
              radius: 28,

              child: ClipOval(
                child: AppCachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 56,
                  width: 56,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              right: -4,
              child: Container(
                //color: AppColors.white,
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.fieldGrey.withAlpha(70),
                ),
                child: AppIconWidget(
                  assetPath: AssetImages.statusIcon,
                  size: 20,
                ),
              ),
            ),
          ]
        ),


        const SizedBox(width: 12),


        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              AppText(
                text: name,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),


              const SizedBox(height: 4),


              AppText(
                text: lastMessage,
                fontSize: 12,
                color: AppColors.grey,
                fontWeight: FontWeight.w400,

              ),


            ],
          ),
        ),


        const SizedBox(width: 10),


        Column(
          spacing: 10,
          children: [
            AppText(
              text: time,
              fontSize: 10,
              color: AppColors.grey,
              fontWeight: FontWeight.w400,
            ),

            CircleAvatar(
              radius: 10,
              backgroundColor: AppColors.lightBlue_2,

              child: AppText(text: '2',fontWeight: FontWeight.w600,fontSize: 10,color: AppColors.primaryColor,)
            ),
          ],
        ),

      ],

  ).pad();
}

