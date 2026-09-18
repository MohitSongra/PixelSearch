import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../models/photo.dart';

class OriginalPhoto extends StatefulWidget {
  const OriginalPhoto({super.key, required this.photo});
  final Photo photo;
  @override
  State<OriginalPhoto> createState() => _OriginalPhotoState();
}

class _OriginalPhotoState extends State<OriginalPhoto> {
  late final Future<File?> _file = widget.photo.source == PhotoSource.device
      ? AssetEntity.fromId(widget.photo.id).then((e) => e?.originFile)
      : Future.value(null);
  @override
  Widget build(BuildContext context) => FutureBuilder<File?>(
    future: _file,
    builder: (_, s) => s.data == null
        ? Image(image: widget.photo.image, fit: BoxFit.contain)
        : Image.file(
            s.data!,
            fit: BoxFit.contain,
            cacheWidth: 2048,
            errorBuilder: (_, _, _) =>
                Image(image: widget.photo.image, fit: BoxFit.contain),
          ),
  );
}
