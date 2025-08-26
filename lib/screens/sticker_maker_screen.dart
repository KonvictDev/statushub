import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterbackgroundremover/backgroundremover.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whatsapp_stickers_handler/model/sticker_pack_exception.dart';
import 'package:whatsapp_stickers_handler/whatsapp_stickers_handler.dart';
import 'package:whatsapp_stickers_handler/model/sticker_pack.dart';
import 'package:whatsapp_stickers_handler/service/sticker_pack_util.dart';

import 'image_editor_screen.dart';

class StickerMakerScreen extends StatefulWidget {
  const StickerMakerScreen({super.key});

  @override
  State<StickerMakerScreen> createState() => _StickerMakerScreenState();
}

class _StickerMakerScreenState extends State<StickerMakerScreen> {
  // UI state
  File? _selectedImage;
  String _stickerText = "Your Text";
  Color _textColor = Colors.white, _borderColor = Colors.black, _textBgColor = Colors.black;
  double _textSize = 24.0, _borderWidth = 2.0;
  bool _showTextBg = false, _isProcessing = false;
  Offset _textPosition = const Offset(0, 0);

  // Controller for InteractiveViewer
  late TransformationController _transformationController;

  // ✅ NEW: To store the on-screen size of the preview area
  Size _previewSize = Size.zero;

  final TextEditingController _textController = TextEditingController();
  final TextEditingController _packNameController = TextEditingController();
  final TextEditingController _authorNameController = TextEditingController();

  // WA handler & persistence keys
  final _handler = WhatsappStickersHandler();
  static const _kPackIdKey = 'wa_pack_identifier';
  static const _kPackNameKey = 'wa_pack_name';
  static const _kPackPublisherKey = 'wa_pack_publisher';
  static const _kPackDirKey = 'wa_pack_dir';

  // Image pick
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _textPosition = const Offset(0, 0);
        _transformationController.value = Matrix4.identity();
      });
    }
  }

  // Function to reset the image transformation
  void _resetImageTransform() {
    setState(() {
      _transformationController.value = Matrix4.identity();
    });
  }

  Future<void> _editImage() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image first")),
      );
      return;
    }

    final String? editedImagePath = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageEditorScreen(imageFile: _selectedImage!),
      ),
    );

    if (editedImagePath != null) {
      setState(() {
        _selectedImage = File(editedImagePath);
        _transformationController.value = Matrix4.identity();
      });
    }
  }

  // Text & color pickers
  void _showTextDialog() {
    _textController.text = _stickerText;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Text to Sticker'),
        content: TextField(
          controller: _textController,
          decoration: const InputDecoration(hintText: "Enter text here"),
          maxLength: 50,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() {
                _stickerText = _textController.text.isNotEmpty ? _textController.text : "Your Text";
              });
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(bool isTextColorOrBg, {bool isBackground = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isBackground ? 'Pick Text Background Color' : (isTextColorOrBg ? 'Pick Text Color' : 'Pick Border Color')),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: isBackground ? _textBgColor : (isTextColorOrBg ? _textColor : _borderColor),
            onColorChanged: (color) {
              setState(() {
                if (isBackground) _textBgColor = color;
                else if (isTextColorOrBg) _textColor = color;
                else _borderColor = color;
              });
            },
            showLabel: true,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
      ),
    );
  }

  void _toggleTextTheme() => setState(() => _showTextBg = !_showTextBg);

  // Sticker Pack Dialog
  void _showStickerPackDialog() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select an image first')));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    _packNameController.text = prefs.getString(_kPackNameKey) ?? "My Sticker Pack";
    _authorNameController.text = prefs.getString(_kPackPublisherKey) ?? "Sticker Maker App";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sticker Pack Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _packNameController,
              decoration: const InputDecoration(labelText: "Pack Name", hintText: "Enter sticker pack name"),
              maxLength: 128,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _authorNameController,
              decoration: const InputDecoration(labelText: "Author Name", hintText: "Enter author name"),
              maxLength: 128,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _processAndSendSticker();
            },
            child: const Text('Add Sticker to Pack'),
          ),
        ],
      ),
    );
  }

  // Main processing function
  Future<void> _processAndSendSticker() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image first')));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final File finalStickerPng = await _createStickerImage();
      await _addStickerToWhatsApp(finalStickerPng);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating sticker: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _addStickerToWhatsApp(File stickerPngFile) async {
    final prefs = await SharedPreferences.getInstance();
    String? identifier = prefs.getString(_kPackIdKey);
    final appDir = await getApplicationDocumentsDirectory();
    String? stickerDir = prefs.getString(_kPackDirKey);

    if (identifier == null || stickerDir == null) {
      identifier = "sticker_pack_${DateTime.now().millisecondsSinceEpoch}";
      stickerDir = "${appDir.path}/$identifier";
      await Directory(stickerDir).create(recursive: true);
      await prefs.setString(_kPackIdKey, identifier);
      await prefs.setString(_kPackDirKey, stickerDir);
    } else {
      await Directory(stickerDir).create(recursive: true);
    }

    final packName = _packNameController.text.trim().isEmpty ? "My Sticker Pack" : _packNameController.text.trim();
    final publisher = _authorNameController.text.trim().isEmpty ? "Sticker Maker App" : _authorNameController.text.trim();

    await prefs.setString(_kPackNameKey, packName);
    await prefs.setString(_kPackPublisherKey, publisher);

    final util = StickerPackUtil();
    final newStickerPath = '$stickerDir/sticker_${DateTime.now().millisecondsSinceEpoch}.webp';
    await util.createStickerFromImage(stickerPngFile.path, newStickerPath);

    final stickers = await _listWebpFiles(stickerDir);
    if (stickers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No stickers found in pack')));
      return;
    }

    while (stickers.length < 3) {
      final duplicatePath = '$stickerDir/duplicate_${stickers.length}.webp';
      await File(stickers.first).copy(duplicatePath);
      stickers.add(duplicatePath);
    }

    final trayPngPath = await util.saveWebpAsTrayImage(stickers.first);

    final pack = StickerPack(
      identifier: identifier,
      name: packName,
      publisher: publisher,
      trayImage: trayPngPath,
      stickers: stickers,
    );

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text("Sending to WhatsApp...")));

    try {
      final installed = await _handler.isStickerPackInstalled(identifier);

      if (installed) {
        _handler.updateStickerPack(pack);
      } else {
        _handler.addStickerPack(pack);
      }

      await Future.delayed(const Duration(seconds: 2));

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text("Sticker sent! Check WhatsApp.")));

    } on StickerPackException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text("Failed: ${e.message}")));
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text("An unexpected error occurred: $e")));
    }
  }

  Future<List<String>> _listWebpFiles(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return [];
    final files = await dir
        .list()
        .where((e) => e is File && e.path.toLowerCase().endsWith('.webp'))
        .map((e) => e.path)
        .toList();
    files.sort();
    return files;
  }
  Future<File> _createStickerImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(512, 512);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.transparent);

    // --- Image Drawing (No changes here) ---
    canvas.save();
    canvas.transform(_transformationController.value.storage);

    final srcImage = await _loadImage(_selectedImage!);
    final imageRatio = srcImage.width / srcImage.height;
    final canvasRatio = size.width / size.height;

    Rect destRect;
    if (imageRatio > canvasRatio) {
      final scaledHeight = size.width / imageRatio;
      destRect = Rect.fromLTWH(0, (size.height - scaledHeight) / 2, size.width, scaledHeight);
    } else {
      final scaledWidth = size.height * imageRatio;
      destRect = Rect.fromLTWH((size.width - scaledWidth) / 2, 0, scaledWidth, size.height);
    }
    paintImage(canvas: canvas, rect: destRect, image: srcImage, fit: BoxFit.contain);

    canvas.restore();

    // --- Border Drawing (No changes here) ---
    if (_borderWidth > 0) {
      final borderPaint = Paint()
        ..color = _borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _borderWidth;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);
    }

    // --- Text Drawing (All fixes are in this section) ---
    if (_stickerText.isNotEmpty) {
      if (_previewSize.width != 0 && _previewSize.height != 0) {
        // ⭐ FIX 1: Calculate a single UNIFORM scale factor
        final double scaleX = size.width / _previewSize.width;
        final double scaleY = size.height / _previewSize.height;
        final double uniformScale = scaleX < scaleY ? scaleX : scaleY;

        // ⭐ FIX 2: Calculate the centering offset
        final double scaledPreviewWidth = _previewSize.width * uniformScale;
        final double scaledPreviewHeight = _previewSize.height * uniformScale;
        final double offsetX = (size.width - scaledPreviewWidth) / 2.0;
        final double offsetY = (size.height - scaledPreviewHeight) / 2.0;

        final scaledTextStyle = TextStyle(
          color: _textColor,
          fontSize: _textSize * uniformScale, // Use uniform scale
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(1.0 * uniformScale, 1.0 * uniformScale),
              blurRadius: 3.0 * uniformScale,
              color: Colors.black.withOpacity(0.8),
            ),
          ],
        );

        final textPainter = TextPainter(
          text: TextSpan(
            text: _stickerText,
            style: scaledTextStyle,
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: size.width);

        // ⭐ FIX 3: Apply the scale AND the offset to the text position
        final dx = (_textPosition.dx * uniformScale) + offsetX;
        final dy = (_textPosition.dy * uniformScale) + offsetY;

        if (_showTextBg) {
          final bgPaint = Paint()..color = _textBgColor;
          final padding = 8.0 * uniformScale;
          final rect = Rect.fromLTWH(
            dx - padding,
            dy - padding,
            textPainter.width + padding * 2,
            textPainter.height + padding * 2,
          );
          final rrect = RRect.fromRectAndRadius(rect, Radius.circular(12 * uniformScale));
          canvas.drawRRect(rrect, bgPaint);
        }

        textPainter.paint(canvas, Offset(dx, dy));
      }
    }

    // --- Final image creation (No changes here) ---
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    final docs = await getTemporaryDirectory();
    final path = "${docs.path}/sticker_${DateTime.now().millisecondsSinceEpoch}.png";
    return File(path)..writeAsBytesSync(byteData!.buffer.asUint8List());
  }

  Future<ui.Image> _loadImage(File file) async {
    final data = await file.readAsBytes();
    return decodeImageFromList(data);
  }

  @override
  void initState() {
    super.initState();
    _textController.text = _stickerText;
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _textController.dispose();
    _packNameController.dispose();
    _authorNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sticker Maker'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editImage,
            tooltip: 'Edit Image (Crop, Remove BG)',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Preview
              Expanded(
                flex: 3,
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _selectedImage == null
                      ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No image selected'),
                      ],
                    ),
                  )
                      : LayoutBuilder(
                    builder: (context, constraints) {
                      // ✅ MODIFIED: Capture the preview size for later calculations
                      _previewSize = constraints.biggest;

                      if (_textPosition == const Offset(0, 0)) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            _textPosition = Offset(
                              (constraints.maxWidth / 2) - 50,
                              constraints.maxHeight - 60,
                            );
                          });
                        });
                      }

                      return Stack(
                        children: [
                          InteractiveViewer(
                            transformationController: _transformationController,
                            minScale: 0.5,
                            maxScale: 4.0,
                            boundaryMargin: const EdgeInsets.all(double.infinity),
                            child: Center(
                              child: Image.file(_selectedImage!, fit: BoxFit.contain),
                            ),
                          ),
                          Positioned(
                            left: _textPosition.dx,
                            top: _textPosition.dy,
                            child: GestureDetector(
                              onPanUpdate: (details) => setState(() => _textPosition += details.delta),
                              child: Container(
                                padding: _showTextBg ? const EdgeInsets.all(8.0) : EdgeInsets.zero,
                                decoration: _showTextBg
                                    ? BoxDecoration(
                                  color: _textBgColor,
                                  borderRadius: BorderRadius.circular(12),
                                )
                                    : null,
                                child: Text(
                                  _stickerText,
                                  style: TextStyle(
                                    color: _textColor,
                                    fontSize: _textSize,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        offset: const Offset(1.0, 1.0),
                                        blurRadius: 3.0,
                                        color: Colors.black.withOpacity(0.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              // Controls
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: [
                            ElevatedButton(onPressed: _pickImage, child: const Text('Pick Image')),
                            ElevatedButton(onPressed: _showTextDialog, child: const Text('Edit Text')),
                            ElevatedButton(onPressed: _resetImageTransform, child: const Text('Reset View')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(onPressed: _toggleTextTheme, child: Text(_showTextBg ? 'Remove Theme' : 'Text Theme')),
                            if (_showTextBg)
                              ElevatedButton(
                                  onPressed: () => _showColorPicker(false, isBackground: true), child: const Text('BG Color')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Text Size:'),
                            Expanded(
                              child: Slider(
                                value: _textSize,
                                min: 12,
                                max: 48,
                                divisions: 9,
                                label: _textSize.round().toString(),
                                onChanged: (v) => setState(() => _textSize = v),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('Border Width:'),
                            Expanded(
                              child: Slider(
                                value: _borderWidth,
                                min: 0,
                                max: 10,
                                divisions: 10,
                                label: _borderWidth.round().toString(),
                                onChanged: (v) => setState(() => _borderWidth = v),
                              ),
                            ),
                            ElevatedButton(onPressed: () => _showColorPicker(false), child: const Text('Border Color')),
                          ],
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.send),
                label: const Text('Send to WhatsApp', style: TextStyle(fontSize: 18)),
                onPressed: _isProcessing ? null : _showStickerPackDialog,
              ),
            ),
          ),
          if (_isProcessing) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}