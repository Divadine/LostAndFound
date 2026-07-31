import 'package:flutter/material.dart';
import 'package:lost_and_found/screens/bottomsheets/chat_sharing_files.dart';
import 'package:lost_and_found/screens/bottomsheets/report_chat.dart';
import 'package:lost_and_found/screens/maps/location_selection_screen.dart';
import 'package:lost_and_found/shared_widgets/app_bar.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_cached_widget.dart';
import 'package:lost_and_found/shared_widgets/app_container.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/shared_widgets/app_text_field.dart';
import 'package:lost_and_found/shared_widgets/item_card.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';
import 'package:lost_and_found/utils/app_ui_helper.dart';

class IndividualChatScreen extends StatefulWidget {
  const IndividualChatScreen({super.key});

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  TextEditingController textController = TextEditingController();

  int? selectedChatIndex;

  final List<Map<String, dynamic>> chats = [
    {
      "message":
          "Hi Arun, I think this watch might be mine. Could you please confirm a few details ? ",
      "isMe": true,
      "time": "10:00 AM",
      "isDeleted": false,
    },
    {
      "message": "Hello ",
      "isMe": false,
      "time": "10:01 AM",
      "isDeleted": false,
    },
    {
      "message": "I found your Fossil Watch post.",
      "isMe": true,
      "time": "10:02 AM",
      "isDeleted": false,
    },
    {
      "message": "Really? Where did you find it?",
      "isMe": false,
      "time": "10:03 AM",
      "isDeleted": false,
    },
    {
      "message": "Near Gandhipuram Bus Stand, Coimbatore.",
      "isMe": true,
      "time": "10:04 AM",
      "isDeleted": false,
    },
    {
      "message": "Can you share a photo?",
      "isMe": false,
      "time": "10:05 AM",
      "isDeleted": false,
    },
    {
      "message": "Sure. I'll send it now.",
      "isMe": true,
      "time": "10:06 AM",
      "isDeleted": false,
    },
    {
      "message": "Thank you ",
      "isMe": false,
      "time": "10:07 AM",
      "isDeleted": false,
    },
    {
      "message": "No problem!",
      "isMe": true,
      "time": "10:08 AM",
      "isDeleted": false,
    },
  ];

  void _deleteMessage(int index, {required bool forEveryone}) {
    setState(() {
      if (forEveryone) {
        chats[index]['isDeleted'] = true;
      } else {
        chats.removeAt(index);
      }
      selectedChatIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.white,
      appBar: AppBar(toolbarHeight: 0, backgroundColor: AppColors.primaryColor),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            spacing: 10,
            children: [
              //name + active status
              selectedChatIndex != null
                  ? _buildSelectionTopRow()
                  : Row(
                      spacing: 20,

                      children: [
                        GestureDetector(
                          onTap: () {
                            AppRoutes.pop();
                          },
                          child: AppIconWidget(
                            assetPath: AssetImages.backArrow,
                          ),
                        ),

                        // SizedBox(width: 12,),
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 18,

                              child: ClipOval(
                                child: AppCachedNetworkImage(
                                  imageUrl:
                                      'https://img.magnific.com/free-photo/handsome-bearded-guy-posing-against-white-wall_273609-20597.jpg?semt=ais_test_b&w=740&q=80',
                                  height: 36,
                                  width: 36,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),

                            Positioned(
                              bottom: 0,
                              right: -5,
                              child: Container(
                                //color: AppColors.white,
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.fieldGrey.withAlpha(70),
                                ),
                                child: AppIconWidget(
                                  assetPath: AssetImages.statusIcon,
                                  size: 15,
                                ),
                              ),
                            ),
                          ],
                        ),

                        Expanded(
                          child: AppText(
                            text: 'Dinesh',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: .zero,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.grey),
                          ),
                          child: PopupMenuButton(
                            padding: EdgeInsets.zero,
                            //elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            color: AppColors.white,
                            icon: AppIconWidget(
                              assetPath: AssetImages.more,
                              size: 20,
                              color: AppColors.black,
                            ),
                            offset: const Offset(0, 40),
                            onSelected: (value) {
                              switch (value) {
                                case "clear":
                                  break;

                                case "block":
                                  AppUiHelper.showBottomSheet(
                                    showHandle: false,
                                    context: context,
                                    child: const BlockChat(),
                                    showCloseIcon: false,
                                    color: AppColors.primaryColor,
                                    iconColor: AppColors.white,
                                  );
                                  break;

                                case "report":
                                  AppUiHelper.showBottomSheet(
                                    context: context,
                                    child: const ReportChat(),
                                    showCloseIcon: true,
                                    color: AppColors.primaryColor,
                                    iconColor: AppColors.white,
                                  );
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: "clear",
                                height: 36,
                                child: Text("Clear Chat"),
                              ),
                              const PopupMenuItem(
                                value: "block",
                                height: 36,
                                child: Text("Block"),
                              ),
                              const PopupMenuItem(
                                value: "report",
                                height: 36,
                                child: Text("Report"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

              Divider(),

              //send request
              AppContainer(
                widget: Row(
                  spacing: 8,
                  children: [
                    AppIconWidget(assetPath: AssetImages.mobileIcon),
                    AppText(
                      text: '+919876543210',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                    ),
                    const Spacer(),
                    AppButton(
                      height: 20,
                      title: 'Send Request',
                      onTap: () {
                        AppUiHelper.showBottomSheet(
                          context: context,
                          child: ReportChat(),
                          showCloseIcon: true,
                          color: AppColors.primaryColor,
                          iconColor: AppColors.white,
                        );
                      },
                      fontSize: 10,
                      border: Border.all(color: AppColors.primaryColor),
                      textColor: AppColors.primaryColor,
                      width: 80,
                      bgColor: AppColors.white,
                      radius: BorderRadius.circular(15),
                    ),
                  ],
                ).pad(8),
              ).padHorizontal(50),

              //ItemCard
              ItemCard(
                imageWidth: 170,
                isFromEnquiry: true,
                imgUrl:
                    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTweFjIvljtnBPBG3-QrPhjYAWLr_1vmJzWbHM58T7TUw&s=10',

                title: 'Fossil Watch',
                location: 'Coimbatore, TamilNadu',
                date: '20 May 2026',
                postId: '',
                onTap: () {},

                showPostId: false,
              ),

              //alert card
              AppContainer(
                bgColor: AppColors.idCardColor,
                widget: Row(
                  spacing: 8,
                  children: [
                    AppIconWidget(assetPath: AssetImages.shieldBorder),
                    AppText(
                      text:
                          'Stay safe! Keep Conversations in the app.\n Never Share personal info.',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      maxLine: 2,
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: () {
                        AppRoutes.pop();
                      },
                      child: AppIconWidget(
                        assetPath: AssetImages.crossIcon,
                        size: 15,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ).padRight(),
              ),

              Center(child: AppText(text: 'Today')),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final isDeleted = chat['isDeleted'] == true;
                    final isSelected = selectedChatIndex == index;

                    return GestureDetector(
                      onLongPress: () {
                        if (isDeleted) return;
                        setState(() => selectedChatIndex = index);
                      },
                      child: Container(
                        width: double.infinity,
                        color: isSelected
                            ? AppColors.chatDelete
                            : Colors.transparent,
                        child: Align(
                          alignment: chat['isMe']
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: chat['isMe']
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,

                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 5,
                                  horizontal: 10,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDeleted
                                      ? AppColors.fieldGrey.withAlpha(255)
                                      : chat['isMe']
                                      ? AppColors.chatByMe
                                      : AppColors.chatByOther,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(16),
                                  ),
                                ),
                                child: AppText(
                                  text: isDeleted
                                      ? "This message was deleted"
                                      : chat['message'],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              AppText(
                                text: chat['time'],
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          child: Row(
            spacing: 8,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              buildIconContainer(
                onTap: () {
                  AppUiHelper.showBottomSheet(
                    context: context,
                    child: ChatSharingFiles(),
                  );
                },
                height: 50,
                width: 50,
                context,
                icon: AssetImages.add,
                bgColor: AppColors.white,
                iconColor: AppColors.black,
                borderColor: AppColors.fieldGrey,
              ),

              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: AppTextField(
                    hintText: 'Write your message..',
                    textController: textController,
                    onChange: (v) {},
                    onSubmit: (v) {},
                  ),
                ),
              ),

              buildIconContainer(
                height: 50,
                width: 50,
                context,
                icon: AssetImages.send,
                bgColor: AppColors.primaryColor,
                iconColor: AppColors.white,
              ),
            ],
          ).pad(),
        ),
      ),
    );
  }

  Widget _buildSelectionTopRow() {
    final chat = chats[selectedChatIndex!];
    final isMe = chat['isMe'] as bool;

    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => selectedChatIndex = null),
          child: AppIconWidget(assetPath: AssetImages.backArrow),
        ),
        const Spacer(),
        if (isMe) ...[
          GestureDetector(
            onTap: () {
              setState(() => selectedChatIndex = null);
            },
            child: AppIconWidget(
              assetPath: AssetImages.chatEditPencilIcon,
              size: 22,
            ),
          ),
          const SizedBox(width: 20),
        ],
        PopupMenuButton<String>(
          offset: Offset(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: AppColors.white,
          icon: AppIconWidget(assetPath: AssetImages.delete, size: 22),
          onSelected: (value) {
            if (value == 'me') {
              _deleteMessage(selectedChatIndex!, forEveryone: false);
            } else if (value == 'everyone') {
              _deleteMessage(selectedChatIndex!, forEveryone: true);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'me',
              child: AppText(
                text: 'Delete for me',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const PopupMenuItem(
              value: 'everyone',
              child: AppText(
                text: 'Delete for everyone',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
