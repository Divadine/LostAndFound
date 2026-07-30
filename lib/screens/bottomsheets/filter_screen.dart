import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lost_and_found/providers/calender_provider.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';
import 'package:lost_and_found/utils/app_routes.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  String? _selectedRange;
  DateTimeRange? _customRange;

  final List<String> _ranges = [
    'Today',
    'Last 7 Days',
    'Last 30 Days',
    'Last 3 Months',
    'Last Year',
    'Custom Range',
  ];

  Future<void> _pickCustomRange() async {
    final range = await AppDialogue.showValuePopup<DateTimeRange>(
      context: context,
      contentPadding: EdgeInsets.zero,
      radius: 16,
      content: CustomDateRangePicker(
        initialRange: _customRange,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      ),
    );

    if (range != null) {
      setState(() {
        _customRange = range;
        _selectedRange = 'Custom Range';
      });
    }
  }

  Widget _buildRangeChip(String label) {
    final bool isSelected = _selectedRange == label;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        if (label == 'Custom Range') {
          _pickCustomRange();
        } else {
          setState(() {
            _selectedRange = label;
            _customRange = null;
          });
        }
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
          color: isSelected ? AppColors.idCardColor : AppColors.white,
        ),
        child: AppText(
          text: label,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.black,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 2,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                text: 'Filter',
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              InkWell(
                onTap: () => AppRoutes.pop(),
                child: AppIconWidget(assetPath: AssetImages.crossIcon),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const AppText(
            text: 'Date Range',
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          const SizedBox(height: 10),

          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.6,
            children: _ranges.map(_buildRangeChip).toList(),
          ),

          if (_selectedRange == 'Custom Range') ...[
            const SizedBox(height: 10),
            CustomDateRangePicker(),
          ],

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: AppButton(
                  title: 'Clear',
                  onTap: () {
                    AppRoutes.pop();
                  },
                  fontSize: 15,
                  textColor: AppColors.primaryColor,
                  bgColor: AppColors.idCardColor,
                  radius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  title: 'Apply Filter',
                  onTap: () {

                    if (_selectedRange == null) return;
                    AppRoutes.pop({'range': _selectedRange,'customRange': _customRange,});
                    setState(() {

                    });
                  },
                  fontSize: 15,
                  textColor: AppColors.white,
                  bgColor: AppColors.primaryColor,
                  radius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
