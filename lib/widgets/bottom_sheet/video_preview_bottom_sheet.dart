import 'dart:io';
import 'dart:typed_data' as typed;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:social_sharing_plus/social_sharing_plus.dart';
import 'package:video_player/video_player.dart';

import '../../constants/app_strings.dart';
import '../action_buttons.dart';
import '../disclaimer_box.dart';
import '../drag_indicator.dart';

class VideoPreviewBottomSheet extends StatefulWidget {
  final File file;
  final typed.Uint8List? thumbnail;
  final ScrollController scrollController;
  final VoidCallback? onSave;
  final bool isSaved;

  const VideoPreviewBottomSheet({
    super.key,
    required this.file,
    this.thumbnail,
    required this.scrollController,
    this.onSave,
    required this.isSaved,
  });

  @override
  State<VideoPreviewBottomSheet> createState() => _VideoPreviewBottomSheetState();
}

class _VideoPreviewBottomSheetState extends State<VideoPreviewBottomSheet> {
  late VideoPlayerController _controller; // initialized in initState
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.file(widget.file)
      ..setLooping(true);

    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() {});
      _controller.play();
    } on Object catch (error) {
      if (!mounted) return;
      print('Video initialization error: $error');
      setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    if (!_controller.value.isInitialized) return;
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }


  Future<File?> _getShareableFile({required String prefix}) async {
    try {
      // 2. Get the original file's extension (e.g., '.jpg', '.mp4')
      final originalExtension = p.extension(widget.file.path);

      final tempDir = await getTemporaryDirectory();

      // 3. Use the original extension in the new file name
      final newFileName = "${prefix}_${DateTime.now().millisecondsSinceEpoch}$originalExtension";

      final newPath = "${tempDir.path}/$newFileName";

      return await widget.file.copy(newPath);
    } catch (e) {
      debugPrint("Error copying file for sharing: $e");
      return null;
    }
  }

  void _onShare() async {
    final shareableFile = await _getShareableFile(prefix: "Status_hub");
    if (shareableFile == null) return;

    await Share.shareXFiles(
      [XFile(shareableFile.path)],
      text: AppStrings.appShareDetails,
    );
  }

  void _onRepost(BuildContext context) async {
    final shareableFile = await _getShareableFile(prefix: "Status_hub_repost");
    if (shareableFile == null) return;

    try {
      await SocialSharingPlus.shareToSocialMedia(
        SocialPlatform.whatsapp,
        AppStrings.appShareDetails,
        media: shareableFile.path,
        isOpenBrowser: true,
      );
    } catch (e) {
      debugPrint("Error while reposting to WhatsApp: $e");
      // 💡 3. Add the context.mounted check for safety.
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to open WhatsApp")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            const DragIndicator(),
            const DisclaimerBox(),
            // --- Video view ---
            Expanded(
              child: Container(
                color: Colors.black,
                width: double.infinity,
                child: _hasError
                    ? const Center(
                  child: Icon(Icons.error, color: Colors.red, size: 56),
                )
                    : !_controller.value.isInitialized
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : GestureDetector(
                  onTap: _togglePlayback,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio > 0
                          ? _controller.value.aspectRatio
                          : 16 / 9,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoPlayer(_controller),
                          ValueListenableBuilder(
                            valueListenable: _controller,
                            builder: (context, VideoPlayerValue value, child) {
                              return AnimatedOpacity(
                                opacity: value.isPlaying ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 150),
                                child: child,
                              );
                            },
                            child: const Icon(
                              Icons.play_arrow,
                              size: 64,
                              color: Colors.white70,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: VideoProgressIndicator(
                              _controller,
                              allowScrubbing: true,
                              colors: const VideoProgressColors(
                                playedColor: Colors.greenAccent,
                                backgroundColor: Colors.white24,
                                bufferedColor: Colors.white38,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // --- Action Buttons ---
            ActionButtons(
              onShare: _onShare,
              onRepost: () => _onRepost(context),
              // ✨ CHANGED: Updated onSave logic
              onSave: widget.isSaved
                  ? null // If it's already saved, disable the button by passing null.
                  : (widget.onSave != null ? () async => widget.onSave!() : null), // Otherwise, use the original logic.
              sheetContext: context,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}