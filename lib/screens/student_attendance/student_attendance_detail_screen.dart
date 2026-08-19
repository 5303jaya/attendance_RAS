import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_colors.dart';
import 'student_attendance_screen.dart';

class StudentAttendanceDetailScreen extends StatefulWidget {
  final StudentRecord student;
  final List<AttendanceHistoryEntry> history;

  const StudentAttendanceDetailScreen({
    super.key,
    required this.student,
    this.history = const [],
  });

  @override
  State<StudentAttendanceDetailScreen> createState() => _StudentAttendanceDetailScreenState();
}

class _StudentAttendanceDetailScreenState extends State<StudentAttendanceDetailScreen> {
  // TODO: swap this for the student's real month-by-month present percentage
  // once this screen is wired up to your backend. Values are 0-100.
  // Order matches the academic-year style range shown under the chart.
  static const List<String> _monthLabels = [
    'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr',
  ];
  static const List<double> _monthlyPresentPercent = [
    72, 80, 58, 65, 74, 88, 91, 84, 90, 95, 83,
  ];

  late int _selectedMonthIndex;

  @override
  void initState() {
    super.initState();
    // Default to the current calendar month if it falls within the Jun-Apr
    // range shown on the chart; otherwise just show the most recent month.
    _selectedMonthIndex = _currentMonthIndex;
  }

  String _monthShort(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[month - 1];
  }

  // Index of "right now" within _monthLabels. Anything after this hasn't
  // happened yet, so there's no real attendance data for it — the chart
  // stops drawing there and those months aren't selectable.
  int get _currentMonthIndex {
    final now = DateTime.now();
    final currentLabel = _monthShort(now.month);
    final match = _monthLabels.indexOf(currentLabel);
    return match != -1 ? match : _monthLabels.length - 1;
  }

  void _selectMonth(int index) {
    if (index > _currentMonthIndex) return; // future month — nothing to show yet
    setState(() => _selectedMonthIndex = index);
  }

  void _handleChartTap(Offset localPosition, double width) {
    final step = width / (_monthlyPresentPercent.length - 1);
    final index = (localPosition.dx / step).round().clamp(0, _monthlyPresentPercent.length - 1);
    _selectMonth(index);
  }

  @override
  Widget build(BuildContext context) {
    const double totalAverage = 0.83;
    const double present = 0.66;
    const double absent = 0.23;
    final student = widget.student;
    final history = widget.history;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Column(
          children: [
          Container(
              padding: EdgeInsets.fromLTRB(
                18,
                MediaQuery.of(context).padding.top + 14,
                18,
                34,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryPurple, Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_rounded, color: AppColors.white, size: 26),
                  ),
                  const Spacer(),
                  // Styled as a distinct rounded-square button rather than a
                  // bare icon glyph.
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.menu_rounded, color: AppColors.white, size: 20),
                  ),
                ],
              ),
            ),
          // Fixed card — sits between the header and the scroll area, and
          // no longer scrolls away with the rest of the content.
          Transform.translate(
            offset: const Offset(0, -34),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StudentAvatar(
                        imageUrl: student.imageUrl,
                        initial: student.name.substring(0, 1),
                        radius: 30,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: AppColors.darkText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              student.section,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _infoBlock('Email', '${student.name.split(' ').first.toLowerCase()}@school.com'),
                      ),
                      Container(width: 1, height: 32, color: const Color(0xFFE5E7EB)),
                      Expanded(
                        child: _infoBlock('Roll No', student.rollNo, alignEnd: true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryPurple,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Attendance Chart',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkText,
                                ),
                              ),
                              Text(
                                'Jun to Apr \u00b7 Present %',
                                style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.softPurple,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primaryPurple),
                            SizedBox(width: 6),
                            Text(
                              'Jun - Apr',
                              style: TextStyle(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primaryPurple),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (details) =>
                            _handleChartTap(details.localPosition, constraints.maxWidth),
                        onHorizontalDragUpdate: (details) =>
                            _handleChartTap(details.localPosition, constraints.maxWidth),
                        child: SizedBox(
                          height: 190,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _WaveChartPainter(
                              points: _monthlyPresentPercent,
                              maxValue: 100,
                              lineColor: AppColors.primaryPurple,
                              markerIndex: _selectedMonthIndex,
                              visibleCount: _currentMonthIndex + 1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_monthLabels.length, (i) {
                      final isSelected = i == _selectedMonthIndex;
                      final isFuture = i > _currentMonthIndex;
                      return GestureDetector(
                        onTap: isFuture ? null : () => _selectMonth(i),
                        child: Text(
                          _monthLabels[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isFuture
                                ? AppColors.mutedText.withOpacity(0.35)
                                : (isSelected ? AppColors.primaryPurple : AppColors.mutedText),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _percentRing('Total Average', totalAverage, AppColors.primaryPurple),
                      ),
                      Expanded(
                        child: _percentRing('Present', present, AppColors.green),
                      ),
                      Expanded(
                        child: _percentRing('Absent', absent, AppColors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _absenceDetailsSection(history),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _absenceDetailsSection(List<AttendanceHistoryEntry> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Absence Details',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.darkText),
          ),
        ),
        const SizedBox(height: 0),
        if (history.isEmpty)
          const _NoAbsenceEmptyState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = history[index];
              final color = entry.status == AttendanceStatus.absent
                  ? AppColors.red
                  : AppColors.amber;
              final label = entry.status == AttendanceStatus.absent ? 'Absent' : 'Late';

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F7FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${entry.date.day}',
                            style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 16),
                          ),
                          Text(
                            _monthShort(entry.date.month),
                            style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                label,
                                style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 13),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '\u00b7 ${entry.date.day} ${_monthShort(entry.date.month)} ${entry.date.year}',
                                style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.reason.isNotEmpty ? entry.reason : 'No reason provided',
                            style: const TextStyle(fontSize: 12.5, color: AppColors.darkText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _infoBlock(String label, String value, {bool alignEnd = false}) {
    return Padding(
      padding: EdgeInsets.only(left: alignEnd ? 16 : 0),
      child: Column(
        crossAxisAlignment: alignEnd ? CrossAxisAlignment.start : CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkText),
          ),
        ],
      ),
    );
  }

  Widget _percentRing(String label, double value, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 84,
          height: 84,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  backgroundColor: color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.mutedText, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Smooth filled wave chart, replicating the attendance curve shown in the
/// reference screens, with a marker + percentage tooltip at [markerIndex].
/// [markerIndex] is driven by the parent's tap/drag handling, so tapping any
/// point on the chart (or its month label) moves the tooltip there.
class _WaveChartPainter extends CustomPainter {
  final List<double> points;
  final double maxValue;
  final Color lineColor;
  final int markerIndex;
  // How many points (from the start) actually have real data. Anything from
  // this index onward is a future month — the line/fill simply stops there
  // instead of plotting invented numbers for days that haven't happened yet.
  final int visibleCount;

  _WaveChartPainter({
    required this.points,
    required this.maxValue,
    required this.lineColor,
    required this.markerIndex,
    int? visibleCount,
  }) : visibleCount = visibleCount ?? points.length;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final visible = visibleCount.clamp(1, points.length);

    final chartHeight = size.height - 24; // leave room for the tooltip bubble
    final stepX = size.width / (points.length - 1);

    // Months from here on have no attendance recorded yet, so they plot as
    // 0 — one continuous line across the whole range instead of stopping
    // or switching styles partway through.
    double valueFor(int i) => i < visible ? points[i] : 0;

    Offset offsetFor(int i) {
      final x = i * stepX;
      final y = 24 + chartHeight - (valueFor(i) / maxValue) * chartHeight;
      return Offset(x, y);
    }

    final path = Path()..moveTo(offsetFor(0).dx, offsetFor(0).dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = offsetFor(i);
      final p1 = offsetFor(i + 1);
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    path.lineTo(offsetFor(points.length - 1).dx, offsetFor(points.length - 1).dy);

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withOpacity(0.35), lineColor.withOpacity(0.02)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Gridlines
    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    for (int i = 0; i <= 2; i++) {
      final y = 24 + chartHeight * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Small dot markers on the flat (0) months so each one still reads as
    // its own point along the same purple line, not just an empty stretch.
    for (int i = visible; i < points.length; i++) {
      canvas.drawCircle(offsetFor(i), 2.5, Paint()..color = lineColor.withOpacity(0.6));
    }

    // Marker + tooltip (only ever sits on a visible/real data point)
    if (markerIndex >= 0 && markerIndex < visible) {
      final marker = offsetFor(markerIndex);
      canvas.drawCircle(marker, 6, Paint()..color = AppColors.white);
      canvas.drawCircle(
        marker,
        6,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

      final percentValue = ((points[markerIndex] / maxValue) * 100).round();
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$percentValue%',
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final bubbleWidth = textPainter.width + 20;
      const bubbleHeight = 26.0;
      var bubbleLeft = marker.dx - bubbleWidth / 2;
      bubbleLeft = bubbleLeft.clamp(0.0, size.width - bubbleWidth);
      final bubbleTop = (marker.dy - bubbleHeight - 12).clamp(0.0, size.height);

      final bubbleRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bubbleLeft, bubbleTop, bubbleWidth, bubbleHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(bubbleRect, Paint()..color = lineColor);
      textPainter.paint(
        canvas,
        Offset(bubbleLeft + 10, bubbleTop + (bubbleHeight - textPainter.height) / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.markerIndex != markerIndex ||
        oldDelegate.visibleCount != visibleCount;
  }
}

/// Friendly empty-state shown in "Absence Details" when a student has a
/// clean record. The illustration bounces in with an elastic scale, then
/// gently bobs up and down for a small celebratory touch. The artwork
/// itself already reads "No Absence · Perfect attendance!" so no separate
/// caption text is layered underneath it.
class _NoAbsenceEmptyState extends StatefulWidget {
  const _NoAbsenceEmptyState();

  @override
  State<_NoAbsenceEmptyState> createState() => _NoAbsenceEmptyStateState();
}

class _NoAbsenceEmptyStateState extends State<_NoAbsenceEmptyState>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entranceScale;
  late final AnimationController _floatController;
  late final Animation<double> _floatOffset;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _entranceScale = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.elasticOut,
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _floatOffset = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Semantics(
        label: 'No absence — perfect attendance record',
        child: AnimatedBuilder(
          animation: Listenable.merge([_entranceScale, _floatOffset]),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatOffset.value),
              child: ScaleTransition(scale: _entranceScale, child: child),
            );
          },
          child: SvgPicture.asset(
            'assets/illustrations/no_absence.svg',
            width: 260,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}