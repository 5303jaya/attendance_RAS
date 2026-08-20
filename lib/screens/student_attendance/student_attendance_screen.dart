import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'student_attendance_detail_screen.dart';

enum AttendanceStatus { present, absent, late }

enum AttendanceSession { morning, afternoon, evening }

class AttendanceHistoryEntry {
  final DateTime date;
  final AttendanceStatus status;
  final String reason;
  final AttendanceSession session;

  const AttendanceHistoryEntry({
    required this.date,
    required this.status,
    required this.reason,
    this.session = AttendanceSession.morning,
  });
}

class StudentRecord {
  final String name;
  final String rollNo;
  final String section;
  // TODO: point this at your real student photo (network URL or a local
  // asset path). Leave it null for students without a photo on file — the
  // avatar falls back to their initial automatically.
  final String? imageUrl;
  AttendanceStatus status;
  String reason;
  // False until staff taps one of Present/Late/Absent for this student.
  // While false, all three options show; once true, only the chosen one shows.
  bool marked;

  StudentRecord({
    required this.name,
    required this.rollNo,
    required this.section,
    this.imageUrl,
    this.status = AttendanceStatus.present,
    this.reason = '',
    this.marked = false,
  });

  StudentRecord copy() => StudentRecord(
        name: name,
        rollNo: rollNo,
        section: section,
        imageUrl: imageUrl,
        status: status,
        reason: reason,
        marked: marked,
      );
}

/// Shows a student's photo when one is set, falling back to a circular
/// initial (e.g. "A") if there's no imageUrl or the image fails to load —
/// so a bad/missing URL never leaves a blank or broken avatar on screen.
class StudentAvatar extends StatefulWidget {
  final String? imageUrl;
  final String initial;
  final double radius;

  const StudentAvatar({
    super.key,
    required this.imageUrl,
    required this.initial,
    this.radius = 28,
  });

  @override
  State<StudentAvatar> createState() => _StudentAvatarState();
}

class _StudentAvatarState extends State<StudentAvatar> {
  bool _failedToLoad = false;

  @override
  void didUpdateWidget(covariant StudentAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _failedToLoad = false; // give a new URL (e.g. different student) a fresh try
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imageUrl != null && widget.imageUrl!.isNotEmpty && !_failedToLoad;

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: AppColors.lavender,
      backgroundImage: hasImage ? NetworkImage(widget.imageUrl!) : null,
      onBackgroundImageError: hasImage
          ? (_, __) {
              if (mounted) setState(() => _failedToLoad = true);
            }
          : null,
      child: hasImage
          ? null
          : Text(
              widget.initial,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: widget.radius * 0.65,
                color: AppColors.primaryPurple,
              ),
            ),
    );
  }
}

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final List<StudentRecord> _templateStudents = [
    StudentRecord(
      name: 'Aarav Sharma',
      rollNo: '08',
      section: 'Class 8-A',
      imageUrl: 'https://i.pravatar.cc/150?img=51',
    ),
    StudentRecord(
      name: 'Maya Johnson',
      rollNo: '15',
      section: 'Class 8-A',
      imageUrl: 'https://i.pravatar.cc/150?img=47',
      status: AttendanceStatus.late,
      reason: 'Bus was delayed',
      marked: true,
    ),
    StudentRecord(
      name: 'Rohan Patel',
      rollNo: '21',
      section: 'Class 8-A',
      imageUrl: 'https://i.pravatar.cc/150?img=13',
      status: AttendanceStatus.absent,
      reason: 'Informed sick leave',
      marked: true,
    ),
    StudentRecord(
      name: 'Zara Ali',
      rollNo: '09',
      section: 'Class 8-A',
      imageUrl: 'https://i.pravatar.cc/150?img=32',
    ),
    StudentRecord(
      name: 'Ishaan Gupta',
      rollNo: '18',
      section: 'Class 8-A',
      imageUrl: 'https://i.pravatar.cc/150?img=60',
    ),
  ];

  // Attendance saved per calendar date AND per session (morning/afternoon/
  // evening), so switching either shows whatever was already entered instead
  // of a blank sheet.
  late final Map<DateTime, Map<AttendanceSession, List<StudentRecord>>> _attendanceByDate;

  DateTime _selectedDate = DateTime.now();
  late AttendanceSession _selectedSession;
  String _searchQuery = '';
  final Set<String> _expandedReasons = {}; // rollNo keys with reason panel open

  DateTime _dateKey(DateTime d) => DateTime(d.year, d.month, d.day);

  // Figures out which session "right now" falls into, so the screen opens
  // on the relevant one instead of always defaulting to Morning.
  AttendanceSession _sessionForTime(DateTime time) {
    if (time.hour < 12) return AttendanceSession.morning;
    if (time.hour < 17) return AttendanceSession.afternoon;
    return AttendanceSession.evening;
  }

  String _sessionLabel(AttendanceSession session) {
    switch (session) {
      case AttendanceSession.morning:
        return 'Morning';
      case AttendanceSession.afternoon:
        return 'Afternoon';
      case AttendanceSession.evening:
        return 'Evening';
    }
  }

  IconData _sessionIcon(AttendanceSession session) {
    switch (session) {
      case AttendanceSession.morning:
        return Icons.wb_sunny_rounded;
      case AttendanceSession.afternoon:
        return Icons.wb_cloudy_rounded;
      case AttendanceSession.evening:
        return Icons.nights_stay_rounded;
    }
  }

  // Morning -> Afternoon -> Evening -> null (nothing left today).
  AttendanceSession? _nextSession(AttendanceSession session) {
    const order = AttendanceSession.values;
    final i = order.indexOf(session);
    return i + 1 < order.length ? order[i + 1] : null;
  }

  // True once every student has been marked for the given date + session.
  bool _sessionCompleted(AttendanceSession session, [DateTime? date]) {
    final key = _dateKey(date ?? _selectedDate);
    final list = _attendanceByDate[key]?[session];
    if (list == null || list.isEmpty) return false;
    return list.every((s) => s.marked) && list.length == _templateStudents.length;
  }

  @override
  void initState() {
    super.initState();
    _selectedSession = _sessionForTime(DateTime.now());
    _attendanceByDate = {
      _dateKey(DateTime.now()): {
        AttendanceSession.morning: _templateStudents.map((s) => s.copy()).toList(),
      },
    };
  }

  List<StudentRecord> get _students {
    final dateKey = _dateKey(_selectedDate);
    final sessionsForDate = _attendanceByDate.putIfAbsent(dateKey, () => {});
    return sessionsForDate.putIfAbsent(
      _selectedSession,
      () => _templateStudents
          .map((s) => StudentRecord(name: s.name, rollNo: s.rollNo, section: s.section, imageUrl: s.imageUrl))
          .toList(),
    );
  }

  List<StudentRecord> get _filteredStudents {
    if (_searchQuery.trim().isEmpty) return _students;
    final q = _searchQuery.trim().toLowerCase();
    return _students
        .where((s) => s.name.toLowerCase().contains(q) || s.rollNo.toLowerCase().contains(q))
        .toList();
  }

  bool get _isToday => _dateKey(_selectedDate) == _dateKey(DateTime.now());

  int get _presentCount =>
      _students.where((s) => s.status == AttendanceStatus.present).length;
  int get _lateCount => _students.where((s) => s.status == AttendanceStatus.late).length;
  int get _absentCount => _students.where((s) => s.status == AttendanceStatus.absent).length;

  Color _statusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.green;
      case AttendanceStatus.late:
        return AppColors.amber;
      case AttendanceStatus.absent:
        return AppColors.red;
    }
  }

  String _statusLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.absent:
        return 'Absent';
    }
  }

  Future<void> _pickDate() async {
    final today = _dateKey(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      // Attendance can't be taken for a day that hasn't happened yet, so
      // today is the latest selectable date — anything after it shows
      // greyed out and isn't tappable.
      lastDate: today,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primaryPurple),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _searchQuery = '';
    });
  }

  // Reopens the picker so an already-marked student's status can be changed.
  Future<void> _changeStatus(StudentRecord student) async {
    final chosen = await showModalBottomSheet<AttendanceStatus>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _StatusPickerSheet(current: student.status),
    );
    if (chosen == null) return;
    await _selectStatus(student, chosen);
  }

  // Sets a student's status (used both by the initial Present/Late/Absent
  // buttons and by the reopened picker). Once set, `marked` flips to true so
  // the row collapses down to showing only the chosen status.
  Future<void> _selectStatus(StudentRecord student, AttendanceStatus status) async {
    if (status == AttendanceStatus.present) {
      setState(() {
        student.status = AttendanceStatus.present;
        student.reason = '';
        student.marked = true;
      });
      return;
    }

    // Late / Absent require a reason from staff.
    final reason = await _askReason(status, student.reason);
    if (reason == null) return; // user cancelled, keep previous status
    setState(() {
      student.status = status;
      student.reason = reason;
      student.marked = true;
    });
  }

  Future<String?> _askReason(AttendanceStatus status, String existing) async {
    final controller = TextEditingController(text: existing);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Reason for ${_statusLabel(status)}'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'e.g. Fever, family emergency, bus delay...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _statusColor(status)),
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save', style: TextStyle(color: AppColors.white)),
            ),
          ],
        );
      },
    );
  }

  void _openStudentDetail(StudentRecord student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentAttendanceDetailScreen(
          student: student,
          history: _historyFor(student.rollNo),
        ),
      ),
    );
  }

  // Pulls every past late/absent entry for this student across all dates
  // that have been marked, so the detail screen can show a date + reason log.
  List<AttendanceHistoryEntry> _historyFor(String rollNo) {
    final entries = <AttendanceHistoryEntry>[];
    _attendanceByDate.forEach((date, sessionsForDate) {
      sessionsForDate.forEach((session, list) {
        for (final record in list) {
          if (record.rollNo == rollNo &&
              record.marked &&
              record.status != AttendanceStatus.present) {
            entries.add(AttendanceHistoryEntry(
              date: date,
              status: record.status,
              reason: record.reason,
              session: session,
            ));
          }
        }
      });
    });
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  void _toggleReason(String rollNo) {
    setState(() {
      if (_expandedReasons.contains(rollNo)) {
        _expandedReasons.remove(rollNo);
      } else {
        _expandedReasons.add(rollNo);
      }
    });
  }

  // Only allow saving once every student for the day has a status chosen.
  void _handleSave() {
    final unmarked = _students.where((s) => !s.marked).toList();
    if (unmarked.isNotEmpty) {
      _showUnmarkedDialog(unmarked);
      return;
    }
    _showSuccessDialog();
  }

  void _showUnmarkedDialog(List<StudentRecord> unmarked) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.amber),
              SizedBox(width: 8),
              Text('Attendance incomplete'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please mark attendance for:'),
              const SizedBox(height: 10),
              ...unmarked.map(
                (s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    '\u2022 ${s.name} (Roll No: ${s.rollNo})',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkText),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: AppColors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      builder: (context) => const _SuccessDialog(),
    );
    
    final next = _nextSession(_selectedSession);
    if (next != null && mounted) {
      setState(() => _selectedSession = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    const String defaultStaffName = 'John Smith';
    final dateLabel =
        '${_selectedDate.day} ${_monthShort(_selectedDate.month)}${_isToday ? '' : ' ${_selectedDate.year}'}';

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.pageBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.deepPurple, AppColors.primaryPurple],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.10),
                      Colors.transparent,
                      AppColors.primaryPurple.withOpacity(0.18),
                    ],
                  ),
                ),
                child: const SizedBox(),
              ),
            ),
            Positioned(
              top: -60,
              right: -30,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withOpacity(0.10),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -40,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.lavender.withOpacity(0.18),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              defaultStaffName,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Student Attendance',
                              style: TextStyle(
                                color: Color(0xFFE9D5FF),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _pickDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded,
                                        color: AppColors.white, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      dateLabel,
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              label: 'Present',
                              value: '$_presentCount',
                              color: AppColors.green,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _statCard(
                              label: 'Late',
                              value: '$_lateCount',
                              color: AppColors.amber,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _statCard(
                              label: 'Absent',
                              value: '$_absentCount',
                              color: AppColors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Mark Attendance',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.darkText,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_students.length} students \u00b7 ${_sessionLabel(_selectedSession)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.mutedText,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.softPurple,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Class 8-A',
                                    style: TextStyle(
                                      color: AppColors.primaryPurple,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _sessionTabBar(),
                            const SizedBox(height: 14),
                            _AnimatedSearchField(
                              onChanged: (v) => setState(() => _searchQuery = v),
                            ),
                            const SizedBox(height: 14),
                            Expanded(
                              child: _filteredStudents.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No students match your search',
                                        style: TextStyle(color: AppColors.mutedText),
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: _filteredStudents.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final student = _filteredStudents[index];
                                        final statusColor = _statusColor(student.status);

                                        final isExpanded = _expandedReasons.contains(student.rollNo);
                                        final hasReason = student.reason.isNotEmpty;

                                        return Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8F7FF),
                                            borderRadius: BorderRadius.circular(18),
                                            border: Border.all(color: const Color(0xFFE5E7EB)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: InkWell(
                                                      borderRadius: BorderRadius.circular(14),
                                                      onTap: () => _openStudentDetail(student),
                                                      child: Row(
                                                        children: [
                                                          StudentAvatar(
                                                            imageUrl: student.imageUrl,
                                                            initial: student.name.substring(0, 1),
                                                            radius: 28,
                                                          ),
                                                          const SizedBox(width: 14),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  student.name,
                                                                  style: const TextStyle(
                                                                    fontSize: 16,
                                                                    fontWeight: FontWeight.w700,
                                                                    color: AppColors.darkText,
                                                                  ),
                                                                ),
                                                                const SizedBox(height: 4),
                                                                Text(
                                                                  'Roll No: ${student.rollNo}',
                                                                  style: const TextStyle(
                                                                    fontSize: 12,
                                                                    color: AppColors.mutedText,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Before a choice is made: show all three options.
                                                  // After: collapse down to just the chosen one.
                                                  if (_isToday && !student.marked)
                                                    _quickSelectButtons(student)
                                                  else
                                                    GestureDetector(
                                                      onTap: () => _changeStatus(student),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(
                                                            horizontal: 12, vertical: 10),
                                                        decoration: BoxDecoration(
                                                          color: statusColor.withOpacity(0.12),
                                                          borderRadius: BorderRadius.circular(12),
                                                          border: Border.all(
                                                              color: statusColor.withOpacity(0.4)),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              _statusLabel(student.status),
                                                              style: TextStyle(
                                                                color: statusColor,
                                                                fontWeight: FontWeight.w700,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Icon(
                                                              Icons.edit_rounded,
                                                              size: 13,
                                                              color: statusColor,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  // Down-chevron: only present when there's a
                                                  // reason to reveal, tap to expand/collapse it.
                                                  if (hasReason)
                                                    GestureDetector(
                                                      onTap: () => _toggleReason(student.rollNo),
                                                      child: Padding(
                                                        padding: const EdgeInsets.only(left: 4),
                                                        child: Icon(
                                                          isExpanded
                                                              ? Icons.keyboard_arrow_up_rounded
                                                              : Icons.keyboard_arrow_down_rounded,
                                                          color: statusColor,
                                                          size: 22,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              if (hasReason && isExpanded) ...[
                                                const SizedBox(height: 10),
                                                Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 12, vertical: 10),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withOpacity(0.08),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Icon(Icons.info_outline_rounded,
                                                          size: 15, color: statusColor),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          student.reason,
                                                          style: TextStyle(
                                                            fontSize: 12.5,
                                                            color: statusColor,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _handleSave,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryPurple,
                                  foregroundColor: AppColors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  _isToday ? 'Save Attendance' : 'Update Attendance',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthShort(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[month - 1];
  }

  Widget _statCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _sessionTabBar() {
    return Row(
      children: AttendanceSession.values.map((session) {
        final isSelected = session == _selectedSession;
        final isCompleted = _sessionCompleted(session, _selectedDate);
        final isLast = session == AttendanceSession.values.last;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSession = session;
                  _searchQuery = '';
                  _expandedReasons.clear();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryPurple : const Color(0xFFF3F1FB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryPurple : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _sessionIcon(session),
                          size: 16,
                          color: isSelected ? AppColors.white : AppColors.mutedText,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _sessionLabel(session),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? AppColors.white : AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                    if (isCompleted)
                      Positioned(
                        top: -10,
                        right: -10,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, size: 11, color: AppColors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // The initial Present / Late / Absent column shown for a student who
  // hasn't been marked yet. Tapping one locks it in and collapses the row
  // down to a single chip (handled in build() via student.marked).
  Widget _quickSelectButtons(StudentRecord student) {
    return Column(
      children: [
        _miniButton(
          label: 'Present',
          color: AppColors.green,
          onPressed: () => _selectStatus(student, AttendanceStatus.present),
        ),
        const SizedBox(height: 4),
        _miniButton(
          label: 'Late',
          color: AppColors.amber,
          onPressed: () => _selectStatus(student, AttendanceStatus.late),
        ),
        const SizedBox(height: 4),
        _miniButton(
          label: 'Absent',
          color: AppColors.red,
          onPressed: () => _selectStatus(student, AttendanceStatus.absent),
        ),
      ],
    );
  }

  Widget _miniButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 64,
      height: 22,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet used to pick a new status for a single student. Only three
/// compact options are shown; the row itself always displays just the one
/// currently-selected status as a chip (see build() above).
class _StatusPickerSheet extends StatelessWidget {
  final AttendanceStatus current;

  const _StatusPickerSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Text(
            'Mark as',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkText),
          ),
          const SizedBox(height: 16),
          _option(context, 'Present', AttendanceStatus.present, AppColors.green, Icons.check_circle_rounded),
          const SizedBox(height: 10),
          _option(context, 'Late', AttendanceStatus.late, AppColors.amber, Icons.schedule_rounded),
          const SizedBox(height: 10),
          _option(context, 'Absent', AttendanceStatus.absent, AppColors.red, Icons.cancel_rounded),
        ],
      ),
    );
  }

  Widget _option(
    BuildContext context,
    String label,
    AttendanceStatus status,
    Color color,
    IconData icon,
  ) {
    final selected = current == status;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.pop(context, status),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : const Color(0xFFF8F7FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 15),
            ),
            const Spacer(),
            if (selected) Icon(Icons.check_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Success popup shown after all students are marked and attendance is
/// saved. The checkmark bounces in with an elastic animation.
class _SuccessDialog extends StatefulWidget {
  const _SuccessDialog();

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: 260,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 46),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Attendance Saved!',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.darkText),
            ),
            const SizedBox(height: 6),
            const Text(
              'All students have been marked successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.mutedText),
            ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Done', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

/// Search field that animates on focus: the border lights up in purple, the
/// field lifts slightly with a soft shadow, and the search icon nudges in.
class _AnimatedSearchField extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const _AnimatedSearchField({required this.onChanged});

  @override
  State<_AnimatedSearchField> createState() => _AnimatedSearchFieldState();
}

class _AnimatedSearchFieldState extends State<_AnimatedSearchField>
    with SingleTickerProviderStateMixin {
  static const String _placeholder = 'Search by name or roll no.';

  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();
  late final AnimationController _typeController;
  bool _isFocused = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
    _textController.addListener(() {
      widget.onChanged(_textController.text);
      setState(() {}); // refresh whether the typed hint should be visible
    });
    _typeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _placeholder.length * 65),
    );
    _runTypewriterLoop();
  }

  // Types the placeholder out letter by letter, holds, then restarts —
  // purely decorative, only shown while the field itself is empty.
  Future<void> _runTypewriterLoop() async {
    while (!_isDisposed) {
      await _typeController.forward(from: 0);
      if (_isDisposed) return;
      await Future.delayed(const Duration(milliseconds: 1400));
      if (_isDisposed) return;
      _typeController.value = 0;
      await Future.delayed(const Duration(milliseconds: 350));
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _typeController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showTypedHint = _textController.text.isEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.primaryPurple.withOpacity(0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          TextField(
            controller: _textController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              // Real hint left blank; the typewriter text below takes its place.
              hintText: '',
              prefixIcon: AnimatedScale(
                scale: _isFocused ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: Icon(
                  Icons.search_rounded,
                  color: _isFocused ? AppColors.primaryPurple : AppColors.mutedText,
                ),
              ),
              filled: true,
              fillColor: _isFocused ? AppColors.white : const Color(0xFFF3F1FB),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
              ),
            ),
          ),
          if (showTypedHint)
            IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(left: 48),
                child: AnimatedBuilder(
                  animation: _typeController,
                  builder: (context, child) {
                    final charCount =
                        (_typeController.value * _placeholder.length).round();
                    final typed = _placeholder.substring(0, charCount);
                    return Text(
                      typed,
                      style: const TextStyle(color: AppColors.mutedText, fontSize: 14),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}