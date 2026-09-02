import 'package:flutter/material.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_images.dart';


class AppDropdownField<T> extends StatefulWidget {

  final T? value;

  final String hintText;

  final List<T> items;

  final String Function(T) itemLabel;

  //final Function(T?) onChanged;
  final void Function(T?)? onChanged;
  final Color? backgroundColor;

  final Color? borderColor;

  final Color? selectedItemColor;

  final Color? selectedItemTextColor;

  final double? menuHeight;


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

    this.menuHeight,

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
        return Material(
          borderRadius: BorderRadius.circular(6),
          child: DropdownMenu<T>(
            width: constraints.maxWidth,
            menuHeight: widget.menuHeight,
            controller: controller,
            focusNode: focusNode,
            requestFocusOnTap: false,
            enableSearch: false,
            enableFilter: false,
            initialSelection: widget.value,
            trailingIcon:AppIconWidget(assetPath: AssetImages.dropDown),
            selectedTrailingIcon: AppIconWidget(assetPath: AssetImages.dropUp),
            hintText: widget.hintText,
            textStyle: appTextStyle(
              fontSize: 16,
              color: AppColors.black

            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              isDense: true,

              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 0,
              ),


              hintStyle: appTextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: widget.borderColor ??
                      AppColors.fieldGrey.withAlpha(20),
                ),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: widget.borderColor ??
                      AppColors.fieldGrey.withAlpha(20),
                ),
              ),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            menuStyle: MenuStyle(
              elevation: WidgetStateProperty.all(2),
              backgroundColor: WidgetStateProperty.all(Colors.white),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
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
                    appTextStyle(
                      fontSize:16,
                    ),
                  ),
                ),
              );
            }).toList(),

            onSelected: (value){
              focusNode.unfocus();
              //widget.onChanged(value);
              widget.onChanged?.call(value);
            },

          ),
        );

      },

    );

  }

}