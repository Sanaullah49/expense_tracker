import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ScreenshotService {
  static final GlobalKey _globalKey = GlobalKey();

  static GlobalKey get key => _globalKey;

  static Future<void> captureAndShare(
    BuildContext context,
    String fileName,
  ) async {
    try {
      RenderRepaintBoundary? boundary =
          _globalKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        await Future.delayed(const Duration(milliseconds: 20));
        boundary =
            _globalKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;
        if (boundary == null) return;
      }

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName.png');
        await file.writeAsBytes(pngBytes);

        await SharePlus.instance.share(ShareParams(files: [
          XFile(file.path),
        ], text: 'Shared via Expense Tracker'));
      }
    } catch (e) {
      debugPrint('Error sharing image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate image')),
        );
      }
    }
  }
}
