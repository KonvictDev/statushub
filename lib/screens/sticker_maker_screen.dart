
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterbackgroundremover/backgroundremover.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whatsapp_stickers_handler/model/sticker_pack_exception.dart';
import 'package:whatsapp_stickers_handler/whatsapp_stickers_handler.dart';
import 'package:whatsapp_stickers_handler/model/sticker_pack.dart';
import 'package:whatsapp_stickers_handler/service/sticker_pack_util.dart';

class StickerMakerScreen extends StatefulWidget {
  const StickerMakerScreen({super.key});

  @override
  State<StickerMakerScreen> createState() => _StickerMakerScreenState();
}

class _StickerMakerScreenState extends State<StickerMakerScreen> {
  // --- UI state ---
  File? _selectedImage;
  String _stickerText = "Your Text";
  Color _textColor = Colors.white;
  double _textSize = 24.0;
  Color _borderColor = Colors.black;
  double _borderWidth = 2.0;
  Color _textBgColor = Colors.black.withOpacity(0.5);
  bool _showTextBg = false;
  bool _isProcessing = false;
  File? _processedSticker;
  File? _originalImage;        // Keep original for restoring
  List<Offset> _strokes = [];  // Painted points
  double _brushSize = 30.0;

  final TextEditingController _textController = TextEditingController();
  final TextEditingController _packNameController = TextEditingController();
  final TextEditingController _authorNameController = TextEditingController();

  Offset _textPosition = const Offset(0, 0);

  // --- WA handler & persistence keys ---
  final _handler = WhatsappStickersHandler();
  static const _kPackIdKey = 'wa_pack_identifier';
  static const _kPackNameKey = 'wa_pack_name';
  static const _kPackPublisherKey = 'wa_pack_publisher';
  static const _kPackDirKey = 'wa_pack_dir';

  // -------------------- Image pick --------------------
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _originalImage = File(pickedFile.path);
        _selectedImage = File(pickedFile.path);
        _processedSticker = null;
        _strokes.clear();
        _textPosition = const Offset(0, 0); // reset position
      });
    }
  }

// -------------------- Background removal --------------------
  Future<void> _removeBackgroundButton() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image first")),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Correct usage: positional File argument
      final Uint8List result = await FlutterBackgroundRemover.removeBackground(_selectedImage!);

      // Save processed image temporarily
      final docs = await getTemporaryDirectory();
      final outPath = "${docs.path}/removed_${DateTime.now().millisecondsSinceEpoch}.png";
      final file = File(outPath);
      await file.writeAsBytes(result);

      setState(() {
        _processedSticker = file;
        _selectedImage = file; // update preview
        _strokes.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Background removed successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error removing background: $e")),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }

  }
  // -------------------- Text & color pickers --------------------
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
                _stickerText = _textController.text.isNotEmpty
                    ? _textController.text
                    : "Your Text";
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
        title: Text(isBackground
            ? 'Pick Text Background Color'
            : (isTextColorOrBg ? 'Pick Text Color' : 'Pick Border Color')),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: isBackground
                ? _textBgColor
                : (isTextColorOrBg ? _textColor : _borderColor),
            onColorChanged: (color) {
              setState(() {
                if (isBackground) {
                  _textBgColor = color;
                } else if (isTextColorOrBg) {
                  _textColor = color;
                } else {
                  _borderColor = color;
                }
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

  void _toggleTextTheme() {
    setState(() {
      _showTextBg = !_showTextBg;
    });
  }

  // -------------------- Sticker Pack --------------------
  void _showStickerPackDialog() async {
    final prefs = await SharedPreferences.getInstance();
    _packNameController.text = prefs.getString(_kPackNameKey) ?? "My Sticker Pack";
    _authorNameController.text =
        prefs.getString(_kPackPublisherKey) ?? "Sticker Maker App";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sticker Pack Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _packNameController,
              decoration: const InputDecoration(
                  labelText: "Pack Name", hintText: "Enter sticker pack name"),
              maxLength: 128,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _authorNameController,
              decoration: const InputDecoration(
                  labelText: "Author Name", hintText: "Enter author name"),
              maxLength: 128,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _createOrUpdateWhatsAppStickerPack();
            },
            child: const Text('Create/Update Pack'),
          ),
        ],
      ),
    );
  }

  Future<void> _createOrUpdateWhatsAppStickerPack() async {
    if (_processedSticker == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Sticker not processed')));
      return;
    }

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

    final packName = _packNameController.text.trim().isEmpty
        ? "My Sticker Pack"
        : _packNameController.text.trim();
    final publisher = _authorNameController.text.trim().isEmpty
        ? "Sticker Maker App"
        : _authorNameController.text.trim();

    await prefs.setString(_kPackNameKey, packName);
    await prefs.setString(_kPackPublisherKey, publisher);

    final util = StickerPackUtil();
    final newStickerPath =
        '$stickerDir/sticker_${DateTime.now().millisecondsSinceEpoch}.webp';
    await util.createStickerFromImage(_processedSticker!.path, newStickerPath);

    final stickers = await _listWebpFiles(stickerDir);
    if (stickers.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No stickers found')));
      return;
    }

    if (stickers.length < 3) {
      while (stickers.length < 3) {
        final duplicatePath = '$stickerDir/duplicate_${stickers.length}.webp';
        await File(stickers.first).copy(duplicatePath);
        stickers.add(duplicatePath);
      }
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
      ..showSnackBar(const SnackBar(content: Text("Processing pack...")));

    try {
      final installed = await _handler.isStickerPackInstalled(identifier);

      if (installed) {
        await _handler.updateStickerPack(pack);
        messenger.showSnackBar(
          const SnackBar(content: Text("Sticker Pack updated in WhatsApp!")),
        );
      } else {
        await _handler.addStickerPack(pack);
        messenger.showSnackBar(
          const SnackBar(content: Text("Sticker Pack added to WhatsApp!")),
        );
      }
    } on StickerPackException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Failed: ${e.message}")));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Unexpected error: $e")));
    } finally {
      messenger.hideCurrentSnackBar();
    }
  }

  Future<List<String>> _listWebpFiles(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return [];
    final files = await dir
        .list(recursive: false)
        .where((e) => e is File && e.path.toLowerCase().endsWith('.webp'))
        .cast<File>()
        .toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    return files.map((f) => f.path).toList();
  }

  // -------------------- Render PNG for sticker --------------------
  Future<File> _createStickerImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(512, 512);

    final backgroundPaint = Paint()..color = Colors.transparent;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    final srcImage = await _loadImage(_selectedImage!);
    final imageRatio = srcImage.width / srcImage.height;
    final canvasRatio = size.width / size.height;

    Rect destRect;
    if (imageRatio > canvasRatio) {
      final height = size.width / imageRatio;
      destRect = Rect.fromLTWH(0, (size.height - height) / 2, size.width, height);
    } else {
      final width = size.height * imageRatio;
      destRect = Rect.fromLTWH((size.width - width) / 2, 0, width, size.height);
    }

    paintImage(canvas: canvas, rect: destRect, image: srcImage, fit: BoxFit.contain);

    if (_borderWidth > 0) {
      final borderPaint = Paint()
        ..color = _borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _borderWidth;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);
    }

    if (_stickerText.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: _stickerText,
          style: TextStyle(
            color: _textColor,
            fontSize: _textSize,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: const Offset(1.0, 1.0),
                blurRadius: 3.0,
                color: Colors.black.withOpacity(0.8),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width - 32);

      final dx = _textPosition.dx;
      final dy = _textPosition.dy;

      if (_showTextBg) {
        final bgPaint = Paint()..color = _textBgColor;
        final padding = 8.0;
        final rect = Rect.fromLTWH(
          dx - padding,
          dy - padding,
          textPainter.width + padding * 2,
          textPainter.height + padding * 2,
        );
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
        canvas.drawRRect(rrect, bgPaint);
      }

      textPainter.paint(canvas, Offset(dx, dy));
    }

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
  }

  @override
  void dispose() {
    _textController.dispose();
    _packNameController.dispose();
    _authorNameController.dispose();
    super.dispose();
  }

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sticker Maker'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Preview
              Expanded(
                flex: 3,
                child: Container(
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
                      final startX =
                          (constraints.maxWidth - _textSize * _stickerText.length / 2) / 2;
                      final startY = constraints.maxHeight - _textSize - 20;

                      if (_textPosition == const Offset(0, 0)) {
                        _textPosition = Offset(startX, startY);
                      }

                      return Stack(
                        children: [
                          Center(
                            child: Image.file(_selectedImage!, fit: BoxFit.contain),
                          ),
                          Positioned(
                            left: _textPosition.dx,
                            top: _textPosition.dy,
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                setState(() {
                                  _textPosition += details.delta;
                                });
                              },
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(onPressed: _pickImage, child: const Text('Pick Image')),
                            ElevatedButton(onPressed: _showTextDialog, child: const Text('Edit Text')),
                            // ElevatedButton(
                            //     onPressed: () => _showColorPicker(true), child: const Text('Text Color')),
                            ElevatedButton(onPressed: _removeBackgroundButton, child: const Text('Remove BG')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(onPressed: _toggleTextTheme, child: Text(_showTextBg ? 'Remove Theme' : 'Text Theme')),
                            if (_showTextBg)
                              ElevatedButton(
                                  onPressed: () => _showColorPicker(false, isBackground: true),
                                  child: const Text('BG Color')),
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
          // Sticky bottom send button
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
                onPressed: _isProcessing
                    ? null
                    : () async {
                  if (_selectedImage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select an image first')));
                    return;
                  }
                  setState(() => _isProcessing = true);
                  try {
                    if (_processedSticker == null) {
                      _processedSticker = await _createStickerImage();
                    }
                    await _createOrUpdateWhatsAppStickerPack();
                  } catch (e) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                  } finally {
                    setState(() => _isProcessing = false);
                  }
                },
              ),
            ),
          ),
          if (_isProcessing) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class RestorePainter extends CustomPainter {
  final ui.Image removedImage;
  final ui.Image originalImage;
  final List<Offset> strokes;
  final double brushSize;

  RestorePainter(this.removedImage, this.originalImage, this.strokes, this.brushSize);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw removed background version
    paintImage(canvas: canvas, rect: Offset.zero & size, image: removedImage, fit: BoxFit.contain);

    // Reveal original where strokes exist
    final paint = Paint();
    for (var point in strokes) {
      canvas.saveLayer(Offset.zero & size, Paint());
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: point, radius: brushSize)));
      paintImage(canvas: canvas, rect: Offset.zero & size, image: originalImage, fit: BoxFit.contain);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(RestorePainter old) =>
      old.strokes != strokes || old.brushSize != brushSize;
}

