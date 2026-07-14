import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_state.dart';
import '../core/utils/date_formatter.dart';

class ExportService {
  static const PdfColor primaryColor = PdfColor.fromInt(0xff0f172a); // slate-900
  static const PdfColor secondaryColor = PdfColor.fromInt(0xff334155); // slate-700
  static const PdfColor accentColor = PdfColor.fromInt(0xff0ea5e9); // sky-500
  static const PdfColor greenColor = PdfColor.fromInt(0xff22c55e); 
  static const PdfColor redColor = PdfColor.fromInt(0xffef4444);
  static const PdfColor bgGray = PdfColor.fromInt(0xfff8fafc); // slate-50

  static Future<bool> exportAdherenceReport(AppState state) async {
    final profile = state.profile;
    if (profile == null) return false;

    // Doctor-ready reports are a Premium feature (research: top retention hook).
    // Returning false lets the call site present the paywall.
    if (!state.isPremium) return false;

    final userName = profile.name;
    final history = state.history;
    final meds = state.activeMeds;

    await _generateAndSharePdf(
      userName: userName,
      relation: 'Self',
      meds: meds,
      history: history,
    );

    return true;
  }

  static Future<bool> exportAdherenceReportForMember(
    AppState state,
    ManagedProfile member,
    List<Medicine> memberMeds,
    Map<String, List<DoseEntry>> memberHistory,
  ) async {
    final profile = state.profile;
    if (profile == null) return false;
    if (!state.isPremium) return false;

    await _generateAndSharePdf(
      userName: member.name,
      relation: member.relation,
      meds: memberMeds,
      history: memberHistory,
    );

    return true;
  }

  static Future<void> _generateAndSharePdf({
    required String userName,
    required String relation,
    required List<Medicine> meds,
    required Map<String, List<DoseEntry>> history,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);
    
    // Calculate adherence score
    int totalTaken = 0;
    int totalMissed = 0;
    
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      final doses = history[dateStr] ?? [];
      totalTaken += doses.where((d) => d.taken).length;
      totalMissed += doses.where((d) => !d.taken && !d.skipped).length;
    }
    
    final totalDoses = totalTaken + totalMissed;
    final double adherenceRate = totalDoses > 0 ? (totalTaken / totalDoses) * 100 : 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 20),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: bgGray, width: 2)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Medai',
                        style: pw.TextStyle(
                          color: primaryColor,
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Clinical Summary Report',
                        style: pw.TextStyle(color: accentColor, fontSize: 16),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Generated on',
                        style: pw.TextStyle(color: secondaryColor, fontSize: 10),
                      ),
                      pw.Text(
                        todayStr,
                        style: pw.TextStyle(
                          color: primaryColor,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // Patient Info & Summary Cards
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: bgGray,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('PATIENT', style: pw.TextStyle(color: secondaryColor, fontSize: 10)),
                        pw.SizedBox(height: 4),
                        pw.Text(userName, style: pw.TextStyle(color: primaryColor, fontSize: 20, fontWeight: pw.FontWeight.bold)),
                        if (relation != 'Self')
                          pw.Text('Relation: $relation', style: pw.TextStyle(color: secondaryColor, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: bgGray,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('30-DAY ADHERENCE', style: pw.TextStyle(color: secondaryColor, fontSize: 10)),
                        pw.SizedBox(height: 4),
                        pw.Text('${adherenceRate.toStringAsFixed(1)}%', 
                          style: pw.TextStyle(
                            color: adherenceRate >= 80 ? greenColor : redColor, 
                            fontSize: 20, 
                            fontWeight: pw.FontWeight.bold,
                          )
                        ),
                      ],
                    ),
                  ),
                ),
              ]
            ),
            
            pw.SizedBox(height: 30),

            // Active Medications Table
            pw.Text('Active Prescriptions & Regimens', style: pw.TextStyle(color: primaryColor, fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            if (meds.isEmpty)
              pw.Text('No active medications recorded.', style: pw.TextStyle(color: secondaryColor, fontStyle: pw.FontStyle.italic))
            else
              pw.TableHelper.fromTextArray(
                context: context,
                border: null,
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 12),
                headerDecoration: const pw.BoxDecoration(color: primaryColor),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                },
                cellStyle: pw.TextStyle(color: primaryColor, fontSize: 11),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: bgGray, width: 1)),
                ),
                data: <List<String>>[
                  <String>['Medication Name', 'Dosage', 'Schedule'],
                  ...meds.map((m) {
                    final scheds = m.schedule
                        .where((s) => s.enabled)
                        .map((s) => '${fmtTime(s.h, s.m)} (${s.label})')
                        .join(', ');
                    return [
                      m.name,
                      m.dose.isNotEmpty ? m.dose : 'As needed',
                      scheds.isNotEmpty ? scheds : 'No fixed schedule',
                    ];
                  }),
                ],
              ),
            
            pw.SizedBox(height: 30),

            // Recent Adherence Log
            pw.Text('Clinical Adherence Log (Last 7 Days)', style: pw.TextStyle(color: primaryColor, fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            _buildPremiumAdherenceLog(meds, history),

            // Footer
            pw.SizedBox(height: 50),
            pw.Container(
              padding: const pw.EdgeInsets.only(top: 10),
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: bgGray, width: 2)),
              ),
              child: pw.Text(
                'Disclaimer: This report is automatically generated by Medai based on user-entered data. It is intended to assist in personal health management and should not be used as a substitute for professional medical advice, diagnosis, or treatment.',
                style: pw.TextStyle(color: secondaryColor, fontSize: 8),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final sanitizedName = userName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final file = File('${output.path}/ClinicalReport_${sanitizedName}_$todayStr.pdf');
    await file.writeAsBytes(await pdf.save());

    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(file.path)], text: 'Medai Clinical Report - $userName');
  }

  static pw.Widget _buildPremiumAdherenceLog(
    List<Medicine> meds,
    Map<String, List<DoseEntry>> history,
  ) {
    List<List<dynamic>> rows = [
      ['Date', 'Medication', 'Scheduled Time', 'Status']
    ];

    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      final doses = history[dateStr] ?? [];

      for (var dose in doses) {
        final medName = meds.where((m) => m.id == dose.medId).firstOrNull?.name ?? 'Unknown Medicine';
        rows.add([
          dateStr,
          medName,
          dose.time,
          dose.taken ? 'Taken' : (dose.skipped ? 'Skipped' : 'Missed'),
        ]);
      }
    }

    if (rows.length == 1) {
      return pw.Text('No adherence data found for the last 7 days.', style: pw.TextStyle(color: secondaryColor, fontStyle: pw.FontStyle.italic));
    }

    return pw.TableHelper.fromTextArray(
      border: null,
      headerStyle: pw.TextStyle(color: primaryColor, fontWeight: pw.FontWeight.bold, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: bgGray),
      cellHeight: 25,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerLeft,
      },
      cellStyle: pw.TextStyle(color: primaryColor, fontSize: 10),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: bgGray, width: 0.5)),
      ),
      data: rows.map((r) {
        if (r[0] == 'Date') return r; // Header
        return r;
      }).toList(),
    );
  }
}
