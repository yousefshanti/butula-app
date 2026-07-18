import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/date_utils.dart';

const _green = PdfColor.fromInt(0xFF1A472A);
const _gold = PdfColor.fromInt(0xFFC9A84C);

/// Builds the commitment document as a formal, ornamental A4 PDF (RTL, Arabic).
Future<Uint8List> buildCommitmentPdf({
  required String text,
  required String name,
  required DateTime? createdAt,
  required DateTime? updatedAt,
  required bool isArabic,
}) async {
  final regular = await PdfGoogleFonts.amiriRegular();
  final bold = await PdfGoogleFonts.amiriBold();

  final doc = pw.Document();
  final created = createdAt == null ? '' : longDate(createdAt, isArabic: isArabic);
  final edited = (updatedAt != null &&
          createdAt != null &&
          updatedAt.difference(createdAt).inMinutes > 1)
      ? longDate(updatedAt, isArabic: isArabic)
      : null;

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _gold, width: 3),
          ),
          padding: const pw.EdgeInsets.all(6),
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _green, width: 1.5),
            ),
            padding: const pw.EdgeInsets.all(28),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Center(
                  child: pw.Text('🏆',
                      style: pw.TextStyle(font: regular, fontSize: 36)),
                ),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    isArabic ? 'وثيقة الالتزام' : 'Commitment Document',
                    style: pw.TextStyle(font: bold, fontSize: 26, color: _green),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Center(
                  child: pw.Container(width: 120, height: 2, color: _gold),
                ),
                pw.SizedBox(height: 24),
                pw.Expanded(
                  child: pw.Text(
                    text,
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(font: regular, fontSize: 15, lineSpacing: 6),
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Divider(color: _gold, thickness: 1),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(name,
                        style: pw.TextStyle(font: bold, fontSize: 14, color: _green)),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          isArabic ? 'حُرّرت في: $created' : 'Written: $created',
                          style: pw.TextStyle(font: regular, fontSize: 11),
                        ),
                        if (edited != null)
                          pw.Text(
                            isArabic ? 'آخر تعديل: $edited' : 'Edited: $edited',
                            style: pw.TextStyle(font: regular, fontSize: 10),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  return doc.save();
}

/// Opens the platform share sheet with the commitment PDF.
Future<void> shareCommitmentPdf(Uint8List bytes) =>
    Printing.sharePdf(bytes: bytes, filename: 'commitment.pdf');
