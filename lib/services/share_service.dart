import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  /// Share with explicit button context (PRIMARY METHOD)
  static Future<void> shareWithButtonContext({
    required GlobalKey screenshotKey,
    required BuildContext buttonContext,
    required String title,
    required String url,
  }) async {
    try {
      // Get position of share button first
      final box = buttonContext.findRenderObject() as RenderBox?;
      
      Rect sharePositionOrigin;
      if (box != null) {
        final position = box.localToGlobal(Offset.zero);
        sharePositionOrigin = Rect.fromLTWH(
          position.dx,
          position.dy,
          box.size.width,
          box.size.height,
        );
        debugPrint('📍 Share button position: $sharePositionOrigin');
      } else {
        // Fallback position
        sharePositionOrigin = const Rect.fromLTWH(200, 200, 100, 100);
        debugPrint('⚠️ Using fallback position');
      }

      // Capture screenshot
      RenderRepaintBoundary? boundary =
          screenshotKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint('❌ Could not find boundary, sharing text only');
        await _shareTextWithPosition(
          title: title,
          url: url,
          sharePositionOrigin: sharePositionOrigin,
        );
        return;
      }

      debugPrint('📸 Capturing screenshot...');
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      // No cropping - just convert to bytes directly
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrint('❌ Failed to convert image, sharing text only');
        await _shareTextWithPosition(
          title: title,
          url: url,
          sharePositionOrigin: sharePositionOrigin,
        );
        return;
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/newsify_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      debugPrint('✅ Screenshot saved, opening share sheet...');

      // Share the image
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '$title\n\n$url',
        subject: title,
        sharePositionOrigin: sharePositionOrigin,
      );

      debugPrint('✅ Share completed');

      // Cleanup after delay
      Future.delayed(const Duration(seconds: 2), () {
        try {
          if (file.existsSync()) file.deleteSync();
          debugPrint('🗑️ Cleaned up temp file');
        } catch (e) {
          debugPrint('⚠️ Could not delete temp file: $e');
        }
      });

    } catch (e) {
      debugPrint('❌ Error in shareWithButtonContext: $e');
      // Last resort: try without position
      try {
        await shareTextOnly(title: title, url: url, context: buttonContext);
      } catch (e2) {
        debugPrint('❌ Final fallback also failed: $e2');
      }
    }
  }

  /// Internal helper for text sharing with position
  static Future<void> _shareTextWithPosition({
    required String title,
    required String url,
    required Rect sharePositionOrigin,
  }) async {
    try {
      await Share.share(
        '$title\n\nRead more: $url',
        subject: title,
        sharePositionOrigin: sharePositionOrigin,
      );
      debugPrint('✅ Shared text with position');
    } catch (e) {
      debugPrint('❌ Error sharing text with position: $e');
    }
  }

  /// Shares text only (with context for positioning)
  static Future<void> shareTextOnly({
    required String title,
    required String url,
    BuildContext? context,
  }) async {
    try {
      Rect? sharePositionOrigin;
      
      if (Platform.isIOS && context != null) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final position = box.localToGlobal(Offset.zero);
          sharePositionOrigin = Rect.fromLTWH(
            position.dx,
            position.dy,
            box.size.width,
            box.size.height,
          );
        } else {
          sharePositionOrigin = const Rect.fromLTWH(200, 200, 100, 100);
        }
      }

      await Share.share(
        '$title\n\nRead more: $url',
        subject: title,
        sharePositionOrigin: sharePositionOrigin,
      );
      debugPrint('✅ Shared text only');
    } catch (e) {
      debugPrint('❌ Error sharing text: $e');
    }
  }

  /// Captures widget and shares (DEPRECATED - use shareWithButtonContext instead)
  static Future<void> captureAndShareWidget({
    required GlobalKey key,
    required String title,
    required String url,
    BuildContext? context,
  }) async {
    debugPrint('⚠️ captureAndShareWidget is deprecated, use shareWithButtonContext instead');
    
    if (context == null) {
      debugPrint('❌ Context is required for iOS sharing');
      return;
    }

    await shareWithButtonContext(
      screenshotKey: key,
      buttonContext: context,
      title: title,
      url: url,
    );
  }
}