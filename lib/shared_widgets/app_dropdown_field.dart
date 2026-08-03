import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';


class AppDropdownField<T> extends StatefulWidget {

  final T? value;

  final String hintText;

  final List<T> items;

  final String Function(T) itemLabel;

  final Function(T?) onChanged;


  final Color? backgroundColor;

  final Color? borderColor;

  final Color? selectedItemColor;

  final Color? selectedItemTextColor;


  const AppDropdownField({

    super.key,

    required this.value,

    required this.hintText,

    required this.items,

    required this.itemLabel,

    required this.onChanged,


    this.backgroundColor,

    this.borderColor,

    this.selectedItemColor,

    this.selectedItemTextColor,

  });


  @override
  State<AppDropdownField<T>> createState() =>
      _AppDropdownFieldState<T>();

}





class _AppDropdownFieldState<T>
    extends State<AppDropdownField<T>> {


  late TextEditingController controller;

  late FocusNode focusNode;



  bool isOpen = false;



  @override
  void initState() {

    super.initState();


    focusNode = FocusNode();


    controller = TextEditingController(

      text: widget.value == null
          ? ""
          : widget.itemLabel(widget.value as T),

    );


  }




  @override
  void didUpdateWidget(
      covariant AppDropdownField<T> oldWidget) {

    super.didUpdateWidget(oldWidget);


    if(oldWidget.value != widget.value){

      controller.text =
      widget.value == null
          ? ""
          : widget.itemLabel(widget.value as T);

    }

  }

  @override
  void dispose() {

    focusNode.dispose();

    controller.dispose();

    super.dispose();

  }

  @override
  Widget build(BuildContext context) {


    return LayoutBuilder(

      builder: (context,constraints){
        return DropdownMenu<T>(
          width: constraints.maxWidth,
          controller: controller,
          focusNode: focusNode,
          requestFocusOnTap: false,
          initialSelection: widget.value,
          trailingIcon:AppIconWidget(assetPath: AssetImages.dropDown),
          selectedTrailingIcon: AppIconWidget(assetPath: AssetImages.dropUp),
          hintText: widget.hintText,
          textStyle: TextStyle(
            fontSize: 16,
            color: AppColors.black

          ),
          inputDecorationTheme:
          InputDecorationTheme(
            filled: true,
            fillColor:
                Colors.white,
            hintStyle: const TextStyle(
              color:AppColors.black,
              fontSize: 16,
            ),
            contentPadding:
            const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(10),
              borderSide: BorderSide(color:
                    AppColors.fieldGrey,
                width: 1,
              ),
            ),
            focusedBorder:
            OutlineInputBorder(borderRadius:
              BorderRadius.circular(10),
              borderSide: BorderSide(color:
                AppColors.fieldGrey ,
                width: 1,
              ),
            ),
          ),
          menuStyle: MenuStyle(
            backgroundColor:
            WidgetStateProperty.all(
              AppColors.white
            ),
            elevation:
            WidgetStateProperty.all(2),
            shape:
            WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(10),
              ),
            ),
            fixedSize:
            WidgetStateProperty.all(
              Size(
                constraints.maxWidth,
                220,
              ),
            ),
          ),
          dropdownMenuEntries:
          widget.items.map((item){
            bool selected =
                item == widget.value;
            return DropdownMenuEntry<T>(
              value: item,
              label:
              widget.itemLabel(item),
              style:
              ButtonStyle(
                padding:
                WidgetStateProperty.all(
                  const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                ),
                backgroundColor:
                WidgetStateProperty.resolveWith(
                      (states){
                    if(selected){

                      return AppColors.idCardColor;

                    }
                    return Colors.white;
                  },
                ),
                foregroundColor:
                WidgetStateProperty.resolveWith(
                      (states){
                    if(selected){
                      return AppColors.black ;
                    }
                    return Colors.black;
                  },
                ),
                textStyle:
                WidgetStateProperty.all(
                  const TextStyle(
                    fontSize:16,
                  ),
                ),
              ),
            );
          }).toList(),

          onSelected: (value){
            focusNode.unfocus();
            widget.onChanged(value);
          },

        );

      },

    );

  }

}