import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FullScreenImageViewer extends StatelessWidget {
  final File? file;
  final String? networkUrl;

  const FullScreenImageViewer({
    super.key,
    this.file,
    this.networkUrl,
  });

  /// Helper to open the viewer from anywhere.
  static void open(BuildContext context, {File? file, String? networkUrl}) {
    if (file == null && (networkUrl == null || networkUrl.trim().isEmpty)) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(
          file: file,
          networkUrl: networkUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: size.width,
            maxHeight: size.height * 0.6,
          ),
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: file != null
                ? Image.file(
                    file!,
                    fit: BoxFit.contain,
                  )
                : CachedNetworkImage(
                    imageUrl: networkUrl ?? '',
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
