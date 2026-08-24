import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/viewer_settings.dart';

/// Renders decoded image with margin cropping applied and zero flicker
class CroppedImageWidget extends StatefulWidget {
  final ui.Image? initialImage;
  final Future<ui.Image>? imageFuture;
  final Uint8List? fallbackBytes;
  final MarginCrop marginCrop;
  final Alignment alignment;

  const CroppedImageWidget({
    super.key,
    this.initialImage,
    this.imageFuture,
    this.fallbackBytes,
    required this.marginCrop,
    this.alignment = Alignment.center,
  });

  @override
  State<CroppedImageWidget> createState() => _CroppedImageWidgetState();
}

class _CroppedImageWidgetState extends State<CroppedImageWidget> {
  ui.Image? _currentImage;

  @override
  void initState() {
    super.initState();
    _currentImage = widget.initialImage;
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant CroppedImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImage != null && widget.initialImage != _currentImage) {
      _currentImage = widget.initialImage;
    } else if (widget.imageFuture != oldWidget.imageFuture ||
        widget.fallbackBytes != oldWidget.fallbackBytes) {
      _resolveImage();
    }
  }

  Future<void> _resolveImage() async {
    if (widget.initialImage != null) {
      if (mounted) setState(() => _currentImage = widget.initialImage);
      return;
    }

    if (widget.imageFuture != null) {
      try {
        final img = await widget.imageFuture!;
        if (mounted) {
          setState(() => _currentImage = img);
        }
      } catch (e) {
        debugPrint('Failed to resolve image future: $e');
      }
      return;
    }

    if (widget.fallbackBytes != null) {
      try {
        final codec = await ui.instantiateImageCodec(widget.fallbackBytes!);
        final frame = await codec.getNextFrame();
        if (mounted) {
          setState(() => _currentImage = frame.image);
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentImage == null) {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.blueAccent,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _CroppedImagePainter(
            image: _currentImage!,
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
