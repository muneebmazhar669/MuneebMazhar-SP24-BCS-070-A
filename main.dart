import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

// ═══════════════════════════════════════════════════════════════
// GRADE TABLE  —  COMSATS official
// ═══════════════════════════════════════════════════════════════
class GradeInfo {
  final String letter;
  final double points;
  const GradeInfo(this.letter, this.points);
}

GradeInfo pctToGrade(double pct) {
  if (pct >= 85) return const GradeInfo('A',  4.00);
  if (pct >= 80) return const GradeInfo('A-', 3.67);
  if (pct >= 75) return const GradeInfo('B+', 3.33);
  if (pct >= 71) return const GradeInfo('B',  3.00);
  if (pct >= 68) return const GradeInfo('B-', 2.67);
  if (pct >= 64) return const GradeInfo('C+', 2.33);
  if (pct >= 61) return const GradeInfo('C',  2.00);
  if (pct >= 58) return const GradeInfo('C-', 1.67);
  if (pct >= 54) return const GradeInfo('D+', 1.33);
  if (pct >= 50) return const GradeInfo('D',  1.00);
  return           const GradeInfo('F',  0.00);
}

String gpaStatus(double gpa)      => gpa >= 2.00 ? 'Pass' : 'Fail';
Color  gpaStatusColor(double gpa) => gpa >= 2.00
    ? const Color(0xFF2E7D32)
    : const Color(0xFFC62828);

// ═══════════════════════════════════════════════════════════════
// MARK ENTRY
// ═══════════════════════════════════════════════════════════════
class MarkEntry {
  double? obtained;
  double? total;

  /// null  → total blank → skip component entirely
  /// 0–100 → calculated (obtained defaults to 0 if blank)
  double? get pct {
    if (total == null || total! <= 0) return null;
    return ((obtained ?? 0.0) / total!) * 100.0;
  }
}

// ═══════════════════════════════════════════════════════════════
// STABLE  ID  GENERATOR
// ═══════════════════════════════════════════════════════════════
class _IdGen {
  static int _n = 0;
  static int next() => ++_n;
}

// ═══════════════════════════════════════════════════════════════
// COURSE  MODEL
// Controllers live here so they are NEVER destroyed on rebuild.
// ═══════════════════════════════════════════════════════════════
class CourseData {
  /// Stable id — used as ValueKey so Flutter never recreates the
  /// card widget (and never loses field values) on list rebuild.
  final int id = _IdGen.next();

  String name        = '';
  int    creditHours = 3;
  bool   hasLab      = false;
  int    labCount    = 4;

  // ── Mark entries (pure data) ──
  final List<MarkEntry> assignments = List.generate(4, (_) => MarkEntry());
  final List<MarkEntry> quizzes     = List.generate(4, (_) => MarkEntry());
  final MarkEntry       mid         = MarkEntry();
  final MarkEntry       finalE      = MarkEntry();

  List<MarkEntry> labAssignments    = List.generate(4, (_) => MarkEntry());
  final MarkEntry labMid            = MarkEntry();
  final MarkEntry labFinal          = MarkEntry();

  // ── Controllers (owned by the model, not by widget State) ──
  final nameCtrl = TextEditingController();

  final List<List<TextEditingController>> aC =
  List.generate(4, (_) => [TextEditingController(), TextEditingController()]);
  final List<List<TextEditingController>> qC =
  List.generate(4, (_) => [TextEditingController(), TextEditingController()]);
  final List<TextEditingController> mC =
  [TextEditingController(), TextEditingController()];
  final List<TextEditingController> fC =
  [TextEditingController(), TextEditingController()];
  final List<List<TextEditingController>> laC =
  List.generate(4, (_) => [TextEditingController(), TextEditingController()]);
  final List<TextEditingController> lmC =
  [TextEditingController(), TextEditingController()];
  final List<TextEditingController> lfC =
  [TextEditingController(), TextEditingController()];

  /// Call when the course is removed from the list.
  void dispose() {
    nameCtrl.dispose();
    for (final p in aC)  { p[0].dispose(); p[1].dispose(); }
    for (final p in qC)  { p[0].dispose(); p[1].dispose(); }
    mC[0].dispose();  mC[1].dispose();
    fC[0].dispose();  fC[1].dispose();
    for (final p in laC) { p[0].dispose(); p[1].dispose(); }
    lmC[0].dispose(); lmC[1].dispose();
    lfC[0].dispose(); lfC[1].dispose();
  }

  // ── GPA calculation ──────────────────────────────────────────
  static double? _avg(List<MarkEntry> list) {
    final vals = list.map((e) => e.pct).whereType<double>().toList();
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  double? get theoryPct {
    final a = _avg(assignments);
    final q = _avg(quizzes);
    final m = mid.pct;
    final f = finalE.pct;
    if (a == null && q == null && m == null && f == null) return null;
    double num = 0, den = 0;
    if (a != null) { num += a * 12.5; den += 12.5; }
    if (q != null) { num += q * 12.5; den += 12.5; }
    if (m != null) { num += m * 25.0; den += 25.0; }
    if (f != null) { num += f * 50.0; den += 50.0; }
    return num / den;
  }

  double? get labPct {
    final la = _avg(labAssignments.sublist(0, labCount));
    final lm = labMid.pct;
    final lf = labFinal.pct;
    if (la == null && lm == null && lf == null) return null;
    double num = 0, den = 0;
    if (la != null) { num += la * 12.5; den += 12.5; }
    if (lm != null) { num += lm * 25.0; den += 25.0; }
    if (lf != null) { num += lf * 50.0; den += 50.0; }
    return num / den;
  }

  double? get mergedPct {
    final t = theoryPct;
    if (!hasLab) return t;
    final l = labPct;
    if (t == null && l == null) return null;
    if (t != null && l != null) return t * 0.75 + l * 0.25;
    return t ?? l;
  }

  double? get subjectGPA   => mergedPct != null ? pctToGrade(mergedPct!).points : null;
  String? get gradeLetter  => mergedPct != null ? pctToGrade(mergedPct!).letter : null;
  double  get gpaPoints    => (subjectGPA ?? 0.0) * creditHours;
  bool    get isValid      => name.trim().isNotEmpty;
}

// ═══════════════════════════════════════════════════════════════
// APP  ROOT
// ═══════════════════════════════════════════════════════════════
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'COMSATS CGPA Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          isDense: true,
        ),
      ),
      home: const CGPAHomePage(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HOME  PAGE
// ═══════════════════════════════════════════════════════════════
class CGPAHomePage extends StatefulWidget {
  const CGPAHomePage({super.key});

  @override
  State<CGPAHomePage> createState() => _CGPAHomePageState();
}

class _CGPAHomePageState extends State<CGPAHomePage> {
  final List<CourseData> _courses = [];

  double get _semGPA {
    double pts = 0, creds = 0;
    for (final c in _courses) {
      if (c.isValid && c.subjectGPA != null) {
        pts   += c.gpaPoints;
        creds += c.creditHours;
      }
    }
    return creds > 0 ? pts / creds : 0;
  }

  double get _totalCredits =>
      _courses.where((c) => c.isValid).fold(0.0, (s, c) => s + c.creditHours);

  int get _doneCourses =>
      _courses.where((c) => c.isValid && c.subjectGPA != null).length;

  void _add() => setState(() => _courses.add(CourseData()));

  void _remove(int i) {
    // Dispose controllers before removing
    _courses[i].dispose();
    setState(() => _courses.removeAt(i));
  }

  void _showCGPAResult() {
    final ready = _courses.where((c) => c.isValid && c.subjectGPA != null).toList();
    if (ready.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one course with marks to calculate CGPA.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    double pts = 0, creds = 0;
    for (final c in ready) { pts += c.gpaPoints; creds += c.creditHours; }
    showDialog(
      context: context,
      builder: (_) => _CGPADialog(
        courses: ready, cgpa: creds > 0 ? pts / creds : 0,
        totalCreds: creds, totalPts: pts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 3,
        title: const Text('COMSATS CGPA Calculator',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          TextButton.icon(
            onPressed: _showCGPAResult,
            icon: const Icon(Icons.calculate_outlined, color: Colors.white, size: 20),
            label: const Text('CGPA',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
      body: Column(
        children: [
          _Banner(semGPA: _semGPA, credits: _totalCredits,
              done: _doneCourses, total: _courses.length),
          Expanded(
            child: _courses.isEmpty
                ? _EmptyState(onAdd: _add)
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 110),
              itemCount: _courses.length,
              itemBuilder: (_, i) => CourseCard(
                // ← stable id key: card is NEVER recreated on rebuild
                key: ValueKey(_courses[i].id),
                index: i,
                course: _courses[i],
                onChanged: () => setState(() {}),
                onDelete: () => _remove(i),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [


          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: _add,
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Add Course'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'calc',
            onPressed: _showCGPAResult,
            backgroundColor: const Color(0xFF283593),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Calculate CGPA',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CGPA  RESULT  DIALOG
// ═══════════════════════════════════════════════════════════════
class _CGPADialog extends StatelessWidget {
  final List<CourseData> courses;
  final double cgpa, totalCreds, totalPts;

  const _CGPADialog({
    required this.courses, required this.cgpa,
    required this.totalCreds, required this.totalPts,
  });

  Color get _cgpaColor {
    if (cgpa >= 3.67) return const Color(0xFF2E7D32);
    if (cgpa >= 3.00) return const Color(0xFF1565C0);
    if (cgpa >= 2.33) return const Color(0xFFE65100);
    return const Color(0xFFC62828);
  }

  String get _status      => cgpa >= 2.00 ? 'Pass' : 'Fail';
  Color  get _statusColor => cgpa >= 2.00 ? const Color(0xFF2E7D32) : const Color(0xFFC62828);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(children: [
              const Text('CGPA Result',
                  style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 1)),
              const SizedBox(height: 6),
              Text(cgpa.toStringAsFixed(2),
                  style: TextStyle(
                    color: cgpa >= 3.00
                        ? Colors.greenAccent.shade200
                        : cgpa >= 2.00
                        ? Colors.orangeAccent.shade100
                        : Colors.redAccent.shade100,
                    fontSize: 52, fontWeight: FontWeight.bold, letterSpacing: 2,
                  )),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor.withOpacity(0.5), width: 1.5),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(cgpa >= 2.00 ? Icons.check_circle_outline : Icons.cancel_outlined,
                      color: _statusColor, size: 16),
                  const SizedBox(width: 5),
                  Text(_status,
                      style: TextStyle(color: _statusColor,
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ]),
              ),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _DStat(label: 'Total Credits',
                    value: totalCreds == totalCreds.roundToDouble()
                        ? totalCreds.toInt().toString() : totalCreds.toStringAsFixed(1)),
                _DStat(label: 'Total Points', value: totalPts.toStringAsFixed(2)),
                _DStat(label: 'Courses',      value: '${courses.length}'),
              ]),
            ]),
          ),

          // Breakdown table
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Course Breakdown',
                      style: TextStyle(fontWeight: FontWeight.w700,
                          fontSize: 13, letterSpacing: 0.3)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(children: [
                      Expanded(flex: 4,
                          child: Text('Course', style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 11))),
                      _TH('CH'), _TH('Grade'), _TH('GPA'), _TH('Points'),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  ...courses.map((c) => Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(children: [
                      Expanded(flex: 4,
                          child: Text(c.name,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis)),
                      _TD('${c.creditHours}'),
                      _TD(c.gradeLetter ?? '—'),
                      _TD(c.subjectGPA!.toStringAsFixed(2), color: gpaStatusColor(c.subjectGPA!)),
                      _TD(c.gpaPoints.toStringAsFixed(2)),
                    ]),
                  )),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      const Expanded(flex: 4,
                          child: Text('Total / CGPA',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      _TD(totalCreds == totalCreds.roundToDouble()
                          ? totalCreds.toInt().toString() : totalCreds.toStringAsFixed(1),
                          bold: true),
                      const _TD(''),
                      _TD(cgpa.toStringAsFixed(2), color: _cgpaColor, bold: true),
                      _TD(totalPts.toStringAsFixed(2), bold: true),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Close button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Close',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DStat extends StatelessWidget {
  final String label, value;
  const _DStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
  ]);
}

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Expanded(
      child: Text(text, textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)));
}

class _TD extends StatelessWidget {
  final String text;
  final Color? color;
  final bool bold;
  const _TD(this.text, {super.key, this.color, this.bold = false});
  @override
  Widget build(BuildContext context) => Expanded(
      child: Text(text, textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: color,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal)));
}

// ═══════════════════════════════════════════════════════════════
// SUMMARY  BANNER
// ═══════════════════════════════════════════════════════════════
class _Banner extends StatelessWidget {
  final double semGPA, credits;
  final int done, total;

  const _Banner({required this.semGPA, required this.credits,
    required this.done, required this.total});

  Color get _accent {
    if (semGPA >= 3.67) return Colors.greenAccent.shade200;
    if (semGPA >= 3.00) return Colors.lightBlueAccent.shade100;
    if (semGPA >= 2.33) return Colors.orangeAccent.shade100;
    return Colors.redAccent.shade100;
  }

  @override
  Widget build(BuildContext context) {
    final hasData = done > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text(hasData ? semGPA.toStringAsFixed(2) : '—',
              style: TextStyle(color: hasData ? _accent : Colors.white38,
                  fontSize: 36, fontWeight: FontWeight.bold)),
          const Text('Semester GPA',
              style: TextStyle(color: Colors.white60, fontSize: 11)),
        ]),
        Container(width: 1, height: 48, color: Colors.white.withOpacity(0.18)),
        _BStat(label: 'Credits',
            value: credits == credits.roundToDouble()
                ? credits.toInt().toString() : credits.toStringAsFixed(1)),
        _BStat(label: 'Courses', value: '$done / $total'),
      ]),
    );
  }
}

class _BStat extends StatelessWidget {
  final String label, value;
  const _BStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
  ]);
}

// ═══════════════════════════════════════════════════════════════
// EMPTY  STATE
// ═══════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.school_outlined, size: 68, color: Colors.grey.shade400),
      const SizedBox(height: 14),
      Text('No courses yet',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
      const SizedBox(height: 6),
      Text('Tap "Add Course" to begin',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      const SizedBox(height: 22),
      ElevatedButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add First Course'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════
// COURSE  CARD
// ─────────────────────────────────────────────────────────────
// Controllers are owned by CourseData (the model), not by this
// widget's State.  The State only holds the _expanded flag.
// Because we key on course.id (stable int), Flutter never throws
// away this widget on list rebuild → data is always preserved.
// ═══════════════════════════════════════════════════════════════
class CourseCard extends StatefulWidget {
  final int index;
  final CourseData course;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const CourseCard({
    super.key,
    required this.index,
    required this.course,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  // Only UI state lives here — controllers are in widget.course
  bool _expanded = true;

  void _refresh() { setState(() {}); widget.onChanged(); }

  void _parse(List<TextEditingController> ctrl, MarkEntry entry) {
    final ob  = double.tryParse(ctrl[0].text.trim());
    final tot = double.tryParse(ctrl[1].text.trim());
    if (ob != null && tot != null && ob > tot) {
      entry.obtained = tot;
      ctrl[0].text   = _f(tot);
    } else {
      entry.obtained = ob;
    }
    entry.total = tot;
    _refresh();
  }

  String _f(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final c   = widget.course;
    final gpa = c.subjectGPA;
    final statusColor = gpa != null ? gpaStatusColor(gpa) : Colors.grey.shade400;
    final statusLabel = gpa != null ? gpaStatus(gpa) : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(children: [

        _Header(
          index:       widget.index,
          name:        c.name.trim().isEmpty ? 'Course ${widget.index + 1}' : c.name,
          hasName:     c.name.trim().isNotEmpty,
          gpa:         gpa,
          statusLabel: statusLabel,
          statusColor: statusColor,
          expanded:    _expanded,
          onToggle:    () => setState(() => _expanded = !_expanded),
          onDelete:    widget.onDelete,
        ),

        if (_expanded) Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Course name + credit hours
              Row(children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: c.nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                        labelText: 'Course Name *', hintText: 'e.g. Data Structures'),
                    onChanged: (v) { c.name = v; _refresh(); },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    value: c.creditHours,
                    decoration: const InputDecoration(labelText: 'Credit Hrs'),
                    items: [1, 2, 3, 4]
                        .map((h) => DropdownMenuItem(value: h, child: Text('$h')))
                        .toList(),
                    onChanged: (v) { c.creditHours = v!; _refresh(); },
                  ),
                ),
              ]),

              const SizedBox(height: 16),
              _div('Theory'),
              const _ColHdr(),

              _Sec(label: 'Assignments', icon: Icons.assignment_outlined),
              const SizedBox(height: 4),
              ...List.generate(4, (i) => _Row(
                label: 'Assignment ${i + 1}',
                ob: c.aC[i][0], tot: c.aC[i][1],
                onChange: () => _parse(c.aC[i], c.assignments[i]),
              )),

              const SizedBox(height: 10),
              _Sec(label: 'Quizzes', icon: Icons.quiz_outlined),
              const SizedBox(height: 4),
              ...List.generate(4, (i) => _Row(
                label: 'Quiz ${i + 1}',
                ob: c.qC[i][0], tot: c.qC[i][1],
                onChange: () => _parse(c.qC[i], c.quizzes[i]),
              )),

              const SizedBox(height: 10),
              _Sec(label: 'Mid Exam', icon: Icons.edit_document),
              const SizedBox(height: 4),
              _Row(label: 'Mid', ob: c.mC[0], tot: c.mC[1],
                  onChange: () => _parse(c.mC, c.mid)),

              const SizedBox(height: 10),
              _Sec(label: 'Final Exam', icon: Icons.description_outlined),
              const SizedBox(height: 4),
              _Row(label: 'Final', ob: c.fC[0], tot: c.fC[1],
                  onChange: () => _parse(c.fC, c.finalE)),

              const SizedBox(height: 16),
              _LabSwitch(hasLab: c.hasLab,
                  onChange: (v) { c.hasLab = v; _refresh(); }),

              if (c.hasLab) ...[
                const SizedBox(height: 14),
                _div('Lab  (25 % of final grade)'),

                Row(children: [
                  const Text('Lab Assignments:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  ToggleButtons(
                    isSelected: [c.labCount == 2, c.labCount == 4],
                    onPressed: (i) {
                      c.labCount = i == 0 ? 2 : 4;
                      c.labAssignments = List.generate(4, (_) => MarkEntry());
                      for (final p in c.laC) { p[0].clear(); p[1].clear(); }
                      _refresh();
                    },
                    borderRadius: BorderRadius.circular(8),
                    selectedColor: Colors.white,
                    fillColor: const Color(0xFF1A237E),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 30),
                    children: const [
                      Text('×2', style: TextStyle(fontSize: 13)),
                      Text('×4', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ]),

                const SizedBox(height: 8),
                const _ColHdr(),

                _Sec(label: 'Lab Assignments', icon: Icons.assignment_outlined),
                const SizedBox(height: 4),
                ...List.generate(c.labCount, (i) => _Row(
                  label: 'Lab Assignment ${i + 1}',
                  ob: c.laC[i][0], tot: c.laC[i][1],
                  onChange: () => _parse(c.laC[i], c.labAssignments[i]),
                )),

                const SizedBox(height: 10),
                _Sec(label: 'Lab Mid Exam', icon: Icons.science_outlined),
                const SizedBox(height: 4),
                _Row(label: 'Lab Mid', ob: c.lmC[0], tot: c.lmC[1],
                    onChange: () => _parse(c.lmC, c.labMid)),

                const SizedBox(height: 10),
                _Sec(label: 'Lab Final Exam', icon: Icons.science),
                const SizedBox(height: 4),
                _Row(label: 'Lab Final', ob: c.lfC[0], tot: c.lfC[1],
                    onChange: () => _parse(c.lfC, c.labFinal)),
              ],

              const SizedBox(height: 16),
              _GPABar(gpa: gpa, statusLabel: statusLabel, statusColor: statusColor),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _div(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
          color: Colors.indigo.shade700, letterSpacing: 0.4)),
      const SizedBox(width: 8),
      Expanded(child: Divider(color: Colors.indigo.shade100, thickness: 1)),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════
// CARD  HEADER
// ═══════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final int index;
  final String name;
  final bool hasName;
  final double? gpa;
  final String? statusLabel;
  final Color statusColor;
  final bool expanded;
  final VoidCallback onToggle, onDelete;

  const _Header({
    required this.index, required this.name, required this.hasName,
    required this.gpa, required this.statusLabel, required this.statusColor,
    required this.expanded, required this.onToggle, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.vertical(
      top: const Radius.circular(14),
      bottom: expanded ? Radius.zero : const Radius.circular(14),
    );
    return InkWell(
      onTap: onToggle,
      borderRadius: r,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
            color: const Color(0xFF1A237E).withOpacity(0.06), borderRadius: r),
        child: Row(children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: const Color(0xFF1A237E),
            child: Text('${index + 1}', style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                    color: hasName ? Colors.black87 : Colors.grey),
                overflow: TextOverflow.ellipsis),
          ),
          if (gpa != null && hasName && statusLabel != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.45), width: 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 7, height: 7,
                    decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text('GPA: ${gpa!.toStringAsFixed(2)}',
                    style: TextStyle(color: statusColor,
                        fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 5),
                Container(width: 1, height: 12, color: statusColor.withOpacity(0.4)),
                const SizedBox(width: 5),
                Text(statusLabel!, style: TextStyle(color: statusColor,
                    fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: onDelete, visualDensity: VisualDensity.compact,
          ),
          Icon(expanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey, size: 20),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GPA  BAR
// ═══════════════════════════════════════════════════════════════
class _GPABar extends StatelessWidget {
  final double? gpa;
  final String? statusLabel;
  final Color statusColor;

  const _GPABar({required this.gpa, required this.statusLabel, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final hasData = gpa != null && statusLabel != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withOpacity(0.25)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        Column(children: [
          Text(hasData ? gpa!.toStringAsFixed(2) : '—',
              style: TextStyle(color: statusColor, fontSize: 34,
                  fontWeight: FontWeight.bold, letterSpacing: 1)),
          Text('Subject GPA',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ]),
        Container(width: 1, height: 48, color: statusColor.withOpacity(0.25)),
        Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.45), width: 1.5),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(hasData && gpa! >= 2.00
                  ? Icons.check_circle_outline : Icons.cancel_outlined,
                  color: statusColor, size: 16),
              const SizedBox(width: 5),
              Text(hasData ? statusLabel! : '—',
                  style: TextStyle(color: statusColor,
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
          ),
          const SizedBox(height: 4),
          Text(hasData
              ? (gpa! >= 2.00 ? 'Min. GPA met (≥ 2.00)' : 'Below minimum GPA')
              : '',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        ]),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SMALL  REUSABLE  WIDGETS
// ═══════════════════════════════════════════════════════════════
class _ColHdr extends StatelessWidget {
  const _ColHdr();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      const SizedBox(width: 130),
      Expanded(child: Text('Obtained', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500,
              fontWeight: FontWeight.w600))),
      const SizedBox(width: 24),
      Expanded(child: Text('Total', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500,
              fontWeight: FontWeight.w600))),
    ]),
  );
}

class _Row extends StatelessWidget {
  final String label;
  final TextEditingController ob, tot;
  final VoidCallback onChange;

  const _Row({required this.label, required this.ob,
    required this.tot, required this.onChange});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      SizedBox(width: 130,
          child: Text(label, style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis)),
      Expanded(child: _Num(ctrl: ob,  hint: 'Obtained', onChange: onChange)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text('/', style: TextStyle(fontSize: 20,
            color: Colors.grey.shade400, fontWeight: FontWeight.w300)),
      ),
      Expanded(child: _Num(ctrl: tot, hint: 'Total', onChange: onChange)),
    ]),
  );
}

class _Num extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final VoidCallback onChange;

  const _Num({required this.ctrl, required this.hint, required this.onChange});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
    style: const TextStyle(fontSize: 13),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      isDense: true,
    ),
    onChanged: (_) => onChange(),
  );
}

class _Sec extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Sec({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15, color: Colors.indigo.shade400),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
  ]);
}

class _LabSwitch extends StatelessWidget {
  final bool hasLab;
  final ValueChanged<bool> onChange;
  const _LabSwitch({required this.hasLab, required this.onChange});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: hasLab ? Colors.indigo.shade50 : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
          color: hasLab ? Colors.indigo.shade200 : Colors.grey.shade300),
    ),
    child: SwitchListTile(
      title: const Text('Has Lab',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(
        hasLab ? 'Lab contributes 25 % to the final grade'
            : 'Toggle to add lab components',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      value: hasLab,
      activeColor: const Color(0xFF1A237E),
      onChanged: onChange,
      secondary: Icon(Icons.science_outlined,
          color: hasLab ? const Color(0xFF1A237E) : Colors.grey),
      dense: true,
    ),
  );
}