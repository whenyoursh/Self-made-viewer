import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/comic_book.dart';

/// Utility to generate a realistic in-memory sample comic book for instant testing
class SampleComicGenerator {
  static Future<ComicBook> generateDemoComic() async {
    const int totalPages = 10;
    final pages = <ComicPageInfo>[];
    final Map<int, Uint8List> generatedBytes = {};

    for (int i = 1; i <= totalPages; i++) {
      final bytes = await _renderSamplePage(
        pageNumber: i,
        totalPages: totalPages,
      );
      generatedBytes[i - 1] = bytes;
      pages.add(ComicPageInfo(
        index: i - 1,
        name: 'page_${i.toString().padLeft(2, '0')}.png',
      ));
    }

    return _DemoComicBook(
      path: '[데모] 갤럭시 폴드 만화책 샘플',
      title: '[데모] 갤럭시 폴드 만화 샘플',
      format: ComicFormat.zip,
      pages: pages,
      coverBytes: generatedBytes[0],
      pageByteMap: generatedBytes,
    );
  }

  static Future<Uint8List> _renderSamplePage({
    required int pageNumber,
    required int totalPages,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 800, 1200));

    // Outer Margin Area (Light grey background to easily see margin cropping)
    final marginPaint = Paint()..color = const Color(0xFFE0E0E6);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 800, 1200), marginPaint);

    // Inner Comic Panel Area (White background with thick margin)
    // 50px top/bottom, 40px left/right margins
    const panelRect = Rect.fromLTWH(50, 50, 700, 1100);
    final pageBgPaint = Paint()..color = Colors.white;
    canvas.drawRect(panelRect, pageBgPaint);

    // Border around comic page
    final borderPaint = Paint()
      ..color = const Color(0xFF222222)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawRect(panelRect, borderPaint);

    // Margin Guide line (dotted visual cue)
    final guidePaint = Paint()
      ..color = Colors.redAccent.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(const Rect.fromLTWH(50, 50, 700, 1100), guidePaint);

    // Manga Panels Layout (2 Panels: Top & Bottom)
    final panel1 = const Rect.fromLTWH(80, 120, 640, 420);
    final panel2 = const Rect.fromLTWH(80, 580, 640, 450);

    final panelBorder = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final panelFill = Paint()..color = (pageNumber % 2 == 0) ? const Color(0xFFF5F7FA) : const Color(0xFFFAF5F5);

    canvas.drawRect(panel1, panelFill);
    canvas.drawRect(panel1, panelBorder);

    canvas.drawRect(panel2, panelFill);
    canvas.drawRect(panel2, panelBorder);

    // Draw Texts
    _drawText(
      canvas,
      text: 'FoldComic TEST MANGA',
      offset: const Offset(400, 80),
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Colors.blueAccent,
      align: TextAlign.center,
    );

    _drawText(
      canvas,
      text: 'PAGE $pageNumber / $totalPages',
      offset: const Offset(400, 260),
      fontSize: 48,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF1E1E2E),
      align: TextAlign.center,
    );

    _drawText(
      canvas,
      text: pageNumber % 2 == 1 ? '◀ 일본 만화 (우→좌 순서)' : '한국 / 서양 만화 (좌→우 순서) ▶',
      offset: const Offset(400, 360),
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.purple,
      align: TextAlign.center,
    );

    _drawText(
      canvas,
      text: '1장 보기 / 2장 보기 전환 및\n상단 자르기 아이콘(여백 제거)을 테스트해 보세요!',
      offset: const Offset(400, 750),
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF333333),
      align: TextAlign.center,
    );

    _drawText(
      canvas,
      text: '⚠️ 바깥쪽 회색 영역 = 여백 제거 테스트용 고정 여백',
      offset: const Offset(400, 1070),
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.redAccent,
      align: TextAlign.center,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(800, 1200);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static void _drawText(
    Canvas canvas, {
    required String text,
    required Offset offset,
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    TextAlign align = TextAlign.left,
  }) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: align,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: 700);

    final textOffset = Offset(
      offset.dx - (align == TextAlign.center ? textPainter.width / 2 : 0),
      offset.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, textOffset);
  }
}

class _DemoComicBook extends ComicBook {
  final Map<int, Uint8List> pageByteMap;

  _DemoComicBook({
    required super.path,
    required super.title,
    required super.format,
    required super.pages,
    super.coverBytes,
    required this.pageByteMap,
  });
}
