import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/time/vietnam_time.dart';
import '../../orders/data/models/booking_dto.dart';
import '../../orders/data/models/booking_enums.dart';

enum TicketExportResult { saved, shared, cancelled, unavailable }

class TicketDocument {
  const TicketDocument(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

class TicketDocumentBuilder {
  Future<TicketDocument> build(BookingDto booking) async {
    final used = booking.status == BookingStatus.used;
    if (!used &&
        (booking.status != BookingStatus.paid ||
            booking.qrCode?.trim().isNotEmpty != true)) {
      throw StateError('Đơn chưa có vé có thể lưu hoặc chia sẻ.');
    }
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Inter-Variable.ttf'),
    );
    final doc = pw.Document();
    final start = booking.showtimeStartSnapshot ?? booking.showtimeStart;
    final lines = <MapEntry<String, String>>[
      MapEntry('Mã đơn', booking.bookingCode),
      MapEntry(
        'Phim',
        booking.movieTitleSnapshot ?? booking.movieTitle ?? 'Phim',
      ),
      MapEntry('Rạp', booking.cinemaNameSnapshot ?? booking.cinemaName ?? '—'),
      MapEntry('Phòng', booking.roomNameSnapshot ?? booking.roomName ?? '—'),
      MapEntry(
        'Suất chiếu',
        start == null ? '—' : formatVietnamDateTime(start),
      ),
      MapEntry('Ghế', booking.seats.map((s) => s.seatLabel).join(', ')),
      for (final food in booking.foods)
        MapEntry(
          '${food.productName} × ${food.quantity}',
          food.lineTotal.format(),
        ),
      MapEntry('Tổng tiền', booking.totalAmount.format()),
      MapEntry('Trạng thái', used ? 'Đã sử dụng' : 'Đã thanh toán'),
    ];
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a5,
        theme: pw.ThemeData.withFont(base: font, bold: font),
        build: (_) => [
          pw.Text(
            used ? 'VÉ ĐÃ SỬ DỤNG' : 'VÉ XEM PHIM',
            style: const pw.TextStyle(fontSize: 22),
          ),
          pw.SizedBox(height: 16),
          if (!used)
            pw.Center(
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: booking.qrCode!,
                width: 160,
                height: 160,
              ),
            ),
          if (used) pw.Text('Vé đã được soát và không thể sử dụng lại.'),
          pw.SizedBox(height: 16),
          for (final line in lines)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: pw.Text(line.key)),
                  pw.Expanded(
                    child: pw.Text(line.value, textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
            ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Giờ hiển thị: Việt Nam (UTC+7).',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
    final code = booking.bookingCode.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return TicketDocument('ve_${code}_${booking.id}', await doc.save());
  }
}

abstract class TicketExportService {
  Future<TicketExportResult> save(TicketDocument document);
  Future<TicketExportResult> share(TicketDocument document, Rect origin);
}

class PlatformTicketExportService implements TicketExportService {
  @override
  Future<TicketExportResult> save(TicketDocument document) async {
    final location = await FileSaver.instance.saveAs(
      name: document.name,
      bytes: document.bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
    return location == null || location.isEmpty
        ? TicketExportResult.cancelled
        : TicketExportResult.saved;
  }

  @override
  Future<TicketExportResult> share(TicketDocument document, Rect origin) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(document.bytes, mimeType: 'application/pdf')],
        fileNameOverrides: ['${document.name}.pdf'],
        subject: 'Vé xem phim',
        sharePositionOrigin: origin,
      ),
    );
    return switch (result.status) {
      ShareResultStatus.success => TicketExportResult.shared,
      ShareResultStatus.dismissed => TicketExportResult.cancelled,
      _ => TicketExportResult.unavailable,
    };
  }
}

final ticketDocumentBuilderProvider = Provider(
  (ref) => TicketDocumentBuilder(),
);
final ticketExportServiceProvider = Provider<TicketExportService>(
  (ref) => PlatformTicketExportService(),
);
