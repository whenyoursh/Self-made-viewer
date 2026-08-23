import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/viewer_settings.dart';

/// Renders image bytes with margin cropping applied and customizable alignment (for 0-gap dual page)
class CroppedImageWidget extends StatefulWidget {
  final Uint8List imageBytes;
  final MarginCrop marginCrop;
  final Alignment alignment;

  const CroppedImageWidget({
    super.key,
    required this.imageBytes,
    required this.marginCrop,
    this.alignment = Alignment.center,
  });

  @override
  State<CroppedImageWidget> createState() => _CroppedImageWidgetState();
}

class _CroppedImageWidgetState extends State<CroppedImageWidget> {
  ui.Image? _decodedImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void didUpdateWidget(covariant CroppedImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageBytes != widget.imageBytes) {
      _decodeImage();
    }
  }

  Future<void> _decodeImage() async {
    setState(() => _isLoading = true);
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _decodedImage = frame.image;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      );
    }

    if (_decodedImage == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image, color: Colors.white38, size: 48),
            SizedBox(height: 8),
            Text('이미지를 불러올 수 없습니다.', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _CroppedImagePainter(
            image: _decodedImage!,
            crop: widget.marginCrop,
            alignment: widget.alignment,
          ),
        );
      },
    );
  }
}

class _CroppedImagePainter extends CustomPainter {
  final ui.Image image;
  final MarginCrop crop;
  final Alignment alignment;

  _CroppedImagePainter({
    required this.image,
    required this.crop,
    required this.alignment,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();

    // Source rectangle inside the image after margin removal
    final srcLeft = imgW * crop.left.clamp(0.0, 0.4);
    final srcTop = imgH * crop.top.clamp(0.0, 0.4);
    final srcRight = imgW * (1.0 - crop.right.clamp(0.0, 0.4));
    final srcBottom = imgH * (1.0 - crop.bottom.clamp(0.0, 0.4));

    final srcWidth = (srcRight - srcLeft).clamp(1.0, imgW);
    final srcHeight = (srcBottom - srcTop).clamp(1.0, imgH);

    final srcRect = Rect.fromLTWH(srcLeft, srcTop, srcWidth, srcHeight);

    // Calculate destination rectangle to fit within canvas while maintaining aspect ratio
    final double srcAspect = srcWidth / srcHeight;
    final double dstAspect = size.width / size.height;

    double dstWidth, dstHeight;
    if (dstAspect > srcAspect) {
      dstHeight = size.height;
      dstWidth = dstHeight * srcAspect;
    } else {
      dstWidth = size.width;
      dstHeight = dstWidth / srcAspect;
    }

    // Horizontal alignment calculation:
    // centerRight -> Flush against right edge (for left page of book)
    // centerLeft  -> Flush against left edge (for right page of book)
    // center      -> Centered
    double dstLeft;
    if (alignment == Alignment.centerRight) {
      dstLeft = size.width - dstWidth;
    } else if (alignment == Alignment.centerLeft) {
      dstLeft = 0.0;
    } else {
      dstLeft = (size.width - dstWidth) / 2.0;
    }

    final dstTop = (size.height - dstHeight) / 2.0;
    final dstRect = Rect.fromLTWH(dstLeft, dstTop, dstWidth, dstHeight);

    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..isAntiAlias = true;

    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(covariant _CroppedImagePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.crop != crop ||
        oldDelegate.alignment != alignment;
  }
}
