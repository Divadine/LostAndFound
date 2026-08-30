import 'dart:async';

import 'package:flutter/material.dart';

import 'package:lost_and_found/services/calender_provider.dart';
import 'package:lost_and_found/shared_widgets/app_button.dart';
import 'package:lost_and_found/shared_widgets/app_icon_widget.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_dialog.dart';
import 'package:lost_and_found/utils/app_images.dart';

class DateFilterState {
  final String? selectedRange;
  final DateTimeRange? customRange;

  const DateFilterState({
    this.selectedRange,
    this.customRange,
  });

  DateFilterState copyWith({
    String? selectedRange,
    DateTimeRange? customRange,
    bool clearCustomRange = false,
  }) {
    return DateFilterState(
      selectedRange: selectedRange ?? this.selectedRange,
      customRange: clearCustomRange
          ? null
          : (customRange ?? this.customRange),
    );
  }

  String? get apiDateFilter {
    switch (selectedRange) {
      case 'Today':
        return 'today';

      case 'Last 7 Days':
        return 'last_7_days';

      case 'Last 30 Days':
        return 'last_30_days';

      case 'Last 3 Months':
        return 'last_3_months';

      case 'Last Year':
        return 'last_year';

      case 'Custom Range':
        return 'custom';

      default:
        return null;
    }
  }
}

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  // ============================================================
  // FILTER OPTIONS
  // ============================================================

  final List<String> _ranges = [
    'Today',
    'Last 7 Days',
    'Last 30 Days',
    'Last 3 Months',
    'Last Year',
    'Custom Range',
  ];

  // ============================================================
  // FILTER STATE
  // ============================================================

  DateFilterState _filterState = const DateFilterState();

  final StreamController<DateFilterState>
  _filterStreamController =
  StreamController<DateFilterState>.broadcast();

  // ============================================================
  // EMIT STATE
  // ============================================================

  void _emit(DateFilterState state) {
    _filterState = state;

    if (!_filterStreamController.isClosed) {
      _filterStreamController.add(state);
    }
  }

  // ============================================================
  // FORMAT DATE
  //
  // API requires:
  //
  // 22/08/2026
  //
  // NOT:
  //
  // 2026-08-22
  // ============================================================

  String _formatApiDate(DateTime date) {
    final String day =
    date.day.toString().padLeft(2, '0');

    final String month =
    date.month.toString().padLeft(2, '0');

    final String year =
    date.year.toString();

    return '$day/$month/$year';
  }

  // ============================================================
  // PICK CUSTOM RANGE
  // ============================================================

  Future<void> _pickCustomRange() async {
    final DateTimeRange? range =
    await AppDialogue.showValuePopup<DateTimeRange>(
      context: context,
      contentPadding: EdgeInsets.zero,
      radius: 16,
      content: CustomDateRangePicker(
        initialRange: _filterState.customRange,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      ),
    );

    if (range == null) {
      return;
    }

    debugPrint(
      'CUSTOM DATE SELECTED: '
          '${_formatApiDate(range.start)} - '
          '${_formatApiDate(range.end)}',
    );

    _emit(
      DateFilterState(
        selectedRange: 'Custom Range',
        customRange: range,
      ),
    );
  }

  // ============================================================
  // SELECT PRESET
  // ============================================================

  void _selectPresetRange(String label) {
    _emit(
      DateFilterState(
        selectedRange: label,
        customRange: null,
      ),
    );
  }

  // ============================================================
  // BUILD RANGE CHIP
  // ============================================================

  Widget _buildRangeChip(
      String label,
      DateFilterState state,
      ) {
    final bool isSelected =
        state.selectedRange == label;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        if (label == 'Custom Range') {
          _pickCustomRange();
        } else {
          _selectPresetRange(label);
        }
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
          color: isSelected
              ? AppColors.idCardColor
              : AppColors.white,
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

  // ============================================================
  // APPLY FILTER
  // ============================================================

  void _applyFilter() {
    // ----------------------------------------------------------
    // NO FILTER SELECTED
    // ----------------------------------------------------------

    if (_filterState.selectedRange == null) {
      AppSnackBar.show(
        context: context,
        message: 'Please select a date range',
      );

      return;
    }

    // ----------------------------------------------------------
    // CUSTOM RANGE
    // ----------------------------------------------------------

    if (_filterState.selectedRange == 'Custom Range') {
      final DateTimeRange? customRange =
          _filterState.customRange;

      if (customRange == null) {
        AppSnackBar.show(
          context: context,
          message: 'Please select a custom date range',
        );

        return;
      }

      final String startDate =
      _formatApiDate(customRange.start);

      final String endDate =
      _formatApiDate(customRange.end);

      debugPrint('======================================');
      debugPrint('FILTER APPLIED');
      debugPrint('Range       : Custom Range');
      debugPrint('Date Filter : custom');
      debugPrint('Start Date  : $startDate');
      debugPrint('End Date    : $endDate');
      debugPrint('======================================');

      // --------------------------------------------------------
      // RETURN DATA TO POST LIST SCREEN
      // --------------------------------------------------------

      Navigator.of(context).pop({
        'range': 'Custom Range',

        // API:
        // date_filter=custom
        'dateFilter': 'custom',

        // API:
        // start_date=22/08/2026
        'startDate': startDate,

        // API:
        // end_date=28/08/2026
        'endDate': endDate,

        // Keep original DateTimeRange also
        'customRange': customRange,
      });

      return;
    }

    // ----------------------------------------------------------
    // PRESET FILTER
    // ----------------------------------------------------------

    final String? dateFilter =
        _filterState.apiDateFilter;

    debugPrint('======================================');
    debugPrint('FILTER APPLIED');
    debugPrint(
      'Range       : ${_filterState.selectedRange}',
    );
    debugPrint(
      'Date Filter : $dateFilter',
    );
    debugPrint('======================================');

    Navigator.of(context).pop({
      'range': _filterState.selectedRange,
      'dateFilter': dateFilter,

      // Preset filters don't need custom dates
      'startDate': null,
      'endDate': null,
      'customRange': null,
    });
  }

  // ============================================================
  // CLEAR FILTER
  // ============================================================

  void _clearFilter() {
    Navigator.of(context).pop('clear');
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _filterStreamController.close();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ======================================================
          // HEADER
          // ======================================================

          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [

              const AppText(
                text: 'Filter',
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),

              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: AppIconWidget(
                  assetPath: AssetImages.crossIcon,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ======================================================
          // DATE RANGE TITLE
          // ======================================================

          const AppText(
            text: 'Date Range',
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),

          const SizedBox(height: 10),

          // ======================================================
          // FILTER OPTIONS
          // ======================================================

          StreamBuilder<DateFilterState>(
            stream: _filterStreamController.stream,
            initialData: _filterState,
            builder: (
                BuildContext context,
                AsyncSnapshot<DateFilterState> snapshot,
                ) {
              final DateFilterState state =
                  snapshot.data ??
                      const DateFilterState();

              return Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  // ------------------------------------------------
                  // FILTER CHIPS
                  // ------------------------------------------------

                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics:
                    const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.6,
                    children: _ranges
                        .map(
                          (String label) =>
                          _buildRangeChip(
                            label,
                            state,
                          ),
                    )
                        .toList(),
                  ),

                  // ------------------------------------------------
                  // SELECTED CUSTOM RANGE
                  // ------------------------------------------------

                  if (state.selectedRange ==
                      'Custom Range' &&
                      state.customRange != null) ...[

                    const SizedBox(height: 12),

                    InkWell(
                      onTap: _pickCustomRange,
                      borderRadius:
                      BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding:
                        const EdgeInsets.all(12),
                        decoration:
                        BoxDecoration(
                          color:
                          AppColors.idCardColor,
                          borderRadius:
                          BorderRadius.circular(
                            10,
                          ),
                          border: Border.all(
                            color: AppColors
                                .primaryColor
                                .withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [

                            // --------------------------------------
                            // CALENDAR ICON / TEXT
                            // --------------------------------------

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                                children: [

                                  const AppText(
                                    text:
                                    'Selected Date Range',
                                    fontSize: 12,
                                    fontWeight:
                                    FontWeight.w500,
                                  ),

                                  const SizedBox(
                                    height: 4,
                                  ),

                                  AppText(
                                    text:
                                    '${_formatApiDate(state.customRange!.start)}'
                                        ' - '
                                        '${_formatApiDate(state.customRange!.end)}',
                                    fontSize: 14,
                                    fontWeight:
                                    FontWeight.w600,
                                    color: AppColors
                                        .primaryColor,
                                  ),
                                ],
                              ),
                            ),

                            // --------------------------------------
                            // CHANGE
                            // --------------------------------------

                            const AppText(
                              text: 'Change',
                              fontSize: 13,
                              fontWeight:
                              FontWeight.w600,
                              color:
                              AppColors.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // ======================================================
          // BUTTONS
          // ======================================================

          Row(
            children: [

              // --------------------------------------------------
              // CLEAR
              // --------------------------------------------------

              Expanded(
                child: AppButton(
                  title: 'Clear',
                  onTap: _clearFilter,
                  fontSize: 15,
                  textColor:
                  AppColors.primaryColor,
                  bgColor:
                  AppColors.idCardColor,
                  radius:
                  BorderRadius.circular(10),
                ),
              ),

              const SizedBox(width: 12),

              // --------------------------------------------------
              // APPLY
              // --------------------------------------------------

              Expanded(
                child: AppButton(
                  title: 'Apply Filter',
                  onTap: _applyFilter,
                  fontSize: 15,
                  textColor: AppColors.white,
                  bgColor:
                  AppColors.primaryColor,
                  radius:
                  BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}