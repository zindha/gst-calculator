import 'dart:convert';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/money.dart';
import '../../core/utils/rate_formatter.dart';
import '../../features/history/data/models/history_entry.dart';

/// Utility to export data as CSV files and share them.
class CsvExport {
  CsvExport._();

  /// CSV-safe quoting: wraps [value] in double quotes if it contains
  /// commas, newlines, or double-quotes.
  static String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Builds a CSV row from a list of strings.
  static String _row(List<String> cells) => '${cells.map(_escape).join(',')}\n';

  // ── Calculation History Export ──────────────────────────────────────

  /// Headers for calculation history CSV.
  static const _historyHeaders = [
    'Date',
    'Time',
    'Amount',
    'GST Rate %',
    'Tax Type',
    'Transaction Type',
    'Base Amount',
    'CGST',
    'SGST',
    'IGST',
    'Total Amount',
  ];

  /// Generates CSV content from a list of [HistoryEntry].
  static String buildHistoryCsv(List<HistoryEntry> entries) {
    final buf = StringBuffer();
    buf.write(_row(_historyHeaders));

    for (final e in entries) {
      final dt = DateTime.fromMillisecondsSinceEpoch(e.timestamp);
      // Export the same reconciled values shown on screen so the CSV rows
      // sum exactly (CGST + SGST + IGST == Total).
      final b = Money.reconcile(
        base: e.baseAmount,
        cgst: e.cgst,
        sgst: e.sgst,
        igst: e.igst,
        total: e.totalAmount,
        isIntraState: e.isIntraState,
      );
      buf.write(
        _row([
          DateFormatter.date(dt),
          DateFormatter.time(dt),
          e.amountText,
          formatRate(e.rate),
          e.isInclusive ? 'Inclusive' : 'Exclusive',
          e.isIntraState ? 'Intra-State' : 'Inter-State',
          b.base.toStringAsFixed(2),
          b.cgst.toStringAsFixed(2),
          b.sgst.toStringAsFixed(2),
          b.igst.toStringAsFixed(2),
          b.total.toStringAsFixed(2),
        ]),
      );
    }
    return buf.toString();
  }

  /// Encodes [csv] as UTF-8 bytes for in-memory sharing via [XFile.fromData].
  static Uint8List _csvBytes(String csv) =>
      Uint8List.fromList(utf8.encode(csv));

  /// Shares calculation history CSV as an in-memory [XFile] (works on
  /// Android — no temp-file write).
  ///
  /// The filename is passed via [ShareParams.fileNameOverrides] because
  /// cross_file's IO [XFile.fromData] ignores its `name` parameter; the
  /// override is honored on every platform.
  static Future<void> shareHistoryCsv(List<HistoryEntry> entries) async {
    final csv = buildHistoryCsv(entries);
    final filename =
        'gst_calculations_${DateTime.now().millisecondsSinceEpoch}.csv';
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(_csvBytes(csv), mimeType: 'text/csv')],
        fileNameOverrides: [filename],
        subject: 'GST Calculation History',
      ),
    );
  }
}
