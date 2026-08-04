import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lost_and_found/shared_widgets/app_text.dart';
import 'package:lost_and_found/utils/app_colors.dart';
import 'package:lost_and_found/utils/app_routes.dart';

/// Fully custom date-range picker, built with plain Row/Column/Stack —
/// no dependency on Flutter's built-in showDateRangePicker.
///
/// Usage:
/// ```dart
/// final range = await showModalBottomSheet<DateTimeRange>(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
///   builder: (_) => CustomDateRangePicker(initialRange: _customRange),
/// );
/// if (range != null) setState(() => _customRange = range);
/// ```
class CustomDateRangePicker extends StatefulWidget {
  final DateTimeRange? initialRange;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const CustomDateRangePicker({
    super.key,
    this.initialRange,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<CustomDateRangePicker> {
  late DateTime _visibleMonth;
  DateTime? _start;
  DateTime? _end;

  String? _selectedRange;
  DateTimeRange? _customRange;
  static const double _rowHeight = 44;

  @override
  void initState() {
    super.initState();
    _start = widget.initialRange?.start;
    _end = widget.initialRange?.end;
    _visibleMonth = _start ?? DateTime.now();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
    });
  }

  void _onDayTap(DateTime day) {
    setState(() {
      if (_start == null || (_start != null && _end != null)) {
        _start = day;
        _end = null;
      } else if (day.isBefore(_start!)) {
        _start = day;
      } else if (_isSameDay(day, _start!)) {

      } else {
        _end = day;
      }
    });
  }


  List<List<DateTime?>> _buildWeeks() {
    final firstDayOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingBlanks = firstDayOfMonth.weekday % 7; // Sun = 0

    final cells = <DateTime?>[
      for (int i = 0; i < leadingBlanks; i++) null,
      for (int d = 1; d <= daysInMonth; d++)
        DateTime(_visibleMonth.year, _visibleMonth.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    final weeks = <List<DateTime?>>[];
    for (int i = 0; i < cells.length; i += 7) {
      weeks.add(cells.sublist(i, i + 7));
    }
    return weeks;
  }

  Widget _buildHeader() {
    final headerDate = _end ?? _start;
    final headerText = headerDate != null
        ? DateFormat('EEE, MMM d').format(headerDate)
        : 'Select range';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select date',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            headerText,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('MMMM yyyy').format(_visibleMonth),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeMonth(-1),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayLabels() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
            .map((d) => Expanded(
          child: Center(
            child: Text(
              d,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        ))
            .toList(),
      ),
    );
  }

  Widget _buildWeekRow(List<DateTime?> week) {
    int? leftIdx, rightIdx;

    if (_start != null) {
      for (int i = 0; i < 7; i++) {
        final day = week[i];
        if (day == null) continue;
        final inRange = _end != null
            ? !day.isBefore(_start!) && !day.isAfter(_end!)
            : _isSameDay(day, _start!);
        if (inRange) {
          leftIdx ??= i;
          rightIdx = i;
        }
      }
    }

    return SizedBox(
      height: _rowHeight,
      child: Stack(
        children: [
          // Background band for the in-range stretch of this week.
          if (leftIdx != null && rightIdx != null && leftIdx != rightIdx)
            Positioned.fill(
              child: Row(
                children: List.generate(7, (i) {
                  final highlighted = i >= leftIdx! && i <= rightIdx!;
                  return Expanded(
                    child:
                    Container(
                      decoration: BoxDecoration(
                        color: highlighted ? AppColors.customRange : Colors.transparent,
                        borderRadius: BorderRadius.only(
                          topLeft: (i == leftIdx) ? const Radius.circular(17) : Radius.zero,
                          bottomLeft: (i == leftIdx) ? const Radius.circular(17) : Radius.zero,
                          topRight: (i == rightIdx) ? const Radius.circular(17) : Radius.zero,
                          bottomRight: (i == rightIdx) ? const Radius.circular(17) : Radius.zero,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          // Day numbers / selected circles on top.
          Row(
            children: List.generate(7, (i) => Expanded(child: _buildDayCell(week[i]))),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime? day) {
    if (day == null) return const SizedBox.shrink();

    final isStart = _start != null && _isSameDay(day, _start!);
    final isEnd = _end != null && _isSameDay(day, _end!);
    final isEndpoint = isStart || isEnd;

    final firstDate = widget.firstDate;
    final lastDate = widget.lastDate;
    final disabled = (firstDate != null && day.isBefore(firstDate)) ||
        (lastDate != null && day.isAfter(lastDate));

    return InkWell(
      onTap: disabled ? null : () => _onDayTap(day),
      child: Center(
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isEndpoint ? AppColors.primaryColor : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 13,
              color: disabled
                  ? Colors.grey.shade400
                  : isEndpoint
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const AppText( text: 'Cancel',color: AppColors.black,fontSize: 16,fontWeight: FontWeight.w400,),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed:(){
              _start == null
                  ? null
                  : () {
                final range = DateTimeRange(
                  start: _start!,
                  end: _end ?? _start!,
                );
                if (_selectedRange == null) return;
                AppRoutes.pop(range);

              };
            },

            child: const AppText( text: 'Ok',color: AppColors.black,fontSize: 16,fontWeight: FontWeight.w400,),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weeks = _buildWeeks();

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(height: 1),
            _buildMonthNav(),
            const SizedBox(height: 4),
            _buildWeekdayLabels(),
            // Non-scrollable grid: only the current month, single page.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                children: weeks.map(_buildWeekRow).toList(),
              ),
            ),
            const SizedBox(height: 4),
            _buildActions(),
          ],
        ),
      ),
    );
  }
}