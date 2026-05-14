import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:apnea_project/services/firebase_service.dart';
import 'package:apnea_project/services/pdf_report_service.dart';

class ReportProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
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
      final profile = await _firebaseService.getUserProfile(uid);
      final stats = await _firebaseService.getPatientStats(uid);
      final measurements = await _firebaseService.getMeasurementRecords(uid: uid, limit: 100);
      final notes = await _firebaseService.getPatientNotes(uid);
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