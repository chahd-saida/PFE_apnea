import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:apnea_project/services/user_service.dart';
import 'package:apnea_project/services/measurement_service.dart';
import 'package:apnea_project/services/stats_service.dart';
import 'package:apnea_project/services/note_service.dart';
import 'package:apnea_project/services/pdf_report_service.dart';

class ReportProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  final MeasurementService _measurementService = MeasurementService();
  final StatsService _statsService = StatsService();
  final NoteService _noteService = NoteService();
  final PdfReportService _pdfReportService = PdfReportService();

  bool _isProcessing = false;
  Uint8List? cachedPdfBytes;
  File? cachedPdfFile;

  bool get isProcessing => _isProcessing;

  Future<bool> generateReport({
    required String uid,
    required Map<String, dynamic> options,
  }) async {
    _isProcessing = true;
    notifyListeners();
    try {
      final profile = await _userService.getUserProfile(uid);
      final stats = await _statsService.getPatientStats(
        uid,
        getMeasurementRecords: _measurementService.getMeasurementRecords,
      );
      final measurements = await _measurementService.getMeasurementRecords(
        uid: uid,
        limit: 100,
      );
      final notes = await _noteService.getPatientNotes(uid);
      // ... construire ReportData et générer le PDF
      // cachedPdfBytes = await _pdfReportService.generatePdfReport(...)
      return true;
    } catch (_) {
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
