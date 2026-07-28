import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPinIconLoader {
  MapPinIconLoader._();

  static Future<BitmapDescriptor?> load(String assetPath, {int size = 110}) async {
    try {
      final bytes = assetPath.endsWith('.svg')
          ? await _svgAssetToPngBytes(assetPath, size: size)
          : await _pngAssetToBytes(assetPath);
      return BitmapDescriptor.fromBytes(bytes);
    } catch (e) {
      return null;
    }
  }

  static Future<Uint8List> _svgAssetToPngBytes(String assetPath, {int size = 100}) async {
    final svgString = await rootBundle.loadString(assetPath);
    final pictureInfo = await vg.loadPicture(SvgStringLoader(svgString), null);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final scale = size / pictureInfo.size.width;
    canvas.scale(scale);
    canvas.drawPicture(pictureInfo.picture);

    final image = await recorder.endRecording().toImage(
      size,
      (pictureInfo.size.height * scale).round(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  static Future<Uint8List> _pngAssetToBytes(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List();
  }
}