import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterbackgroundremover/backgroundremover.dart';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:statushub/constants/app_strings.dart';
import 'package:statushub/constants/app_colors.dart';

class ImageEditorScreen extends StatefulWidget {
  final File imageFile;

  const ImageEditorScreen({super.key, required this.imageFile});

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  late File _currentImage;
  File? _previousImage;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentImage = widget.imageFile;
  }

  void _undo() {
    if (_previousImage != null) {
      setState(() {
        _currentImage = _previousImage!;
        _previousImage = null;
      });
    }
  }

  Future<void> _cropImage() async {
    setState(() {
      _previousImage = _currentImage;
    });

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _currentImage.path,
      compressFormat: ImageCompressFormat.png,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: AppStrings.cropImage,
          toolbarColor: AppColors.deepPurple,
          toolbarWidgetColor: AppColors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: AppStrings.cropImage,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _currentImage = File(croppedFile.path);
      });
    } else {
      setState(() {
        _previousImage = null;
      });
    }
  }

  Future<void> _removeBackground() async {
    setState(() {
      _previousImage = _currentImage;
      _isProcessing = true;
    });

    try {
      final Uint8List result = await FlutterBackgroundRemover.removeBackground(_currentImage);
      final docs = await getTemporaryDirectory();
      final outPath = "${docs.path}/removed_${DateTime.now().millisecondsSinceEpoch}.png";
      final file = File(outPath);
      await file.writeAsBytes(result);

      setState(() {
        _currentImage = file;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.backgroundRemoved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${AppStrings.errorRemovingBg} $e")),
        );
      }
      setState(() {
        _previousImage = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.editImage),
        backgroundColor: AppColors.deepPurple,
        foregroundColor: AppColors.white,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _currentImage.path);
            },
            child: const Text(
              AppStrings.done,
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Image.file(_currentImage),
                  ),
                ),
              ),
              Container(
                color: AppColors.lightGrayBackground,
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                child: Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  spacing: 12.0,
                  runSpacing: 8.0,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _previousImage != null ? _undo : null,
                      icon: const Icon(Icons.undo),
                      label: const Text(AppStrings.undo),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _previousImage != null
                            ? AppColors.orangeAccent
                            : AppColors.gray,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _cropImage,
                      icon: const Icon(Icons.crop),
                      label: const Text(AppStrings.crop),
                    ),
                    ElevatedButton.icon(
                      onPressed: _removeBackground,
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text(AppStrings.removeBg),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isProcessing)
            Container(
              color: AppColors.overlayBlack,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
