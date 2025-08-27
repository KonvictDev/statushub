import 'dart:io';
import 'dart:typed_data' as typed;
import 'package:flutter/material.dart';
import 'package:statushub/constants/app_strings.dart';
import 'package:video_player/video_player.dart';
import '../../l10n/app_localizations.dart';
import '../action_buttons.dart';
import '../disclaimer_box.dart';
import '../drag_indicator.dart';

class VideoPreviewBottomSheet extends StatefulWidget {
  final File file;
  final typed.Uint8List? thumbnail;
  final ScrollController scrollController;
  final bool isSaved;

  const VideoPreviewBottomSheet({
    super.key,
    required this.file,
    this.thumbnail,
    required this.scrollController,
    required this.isSaved,
  });

  @override
  State<VideoPreviewBottomSheet> createState() => _VideoPreviewBottomSheetState();
}

class _VideoPreviewBottomSheetState extends State<VideoPreviewBottomSheet> {
  late VideoPlayerController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.file(widget.file)..setLooping(true);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: isDark ? Colors.black : Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            const DragIndicator(),
            const DisclaimerBox(),
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
            ActionButtons(
              file: widget.file,
              isSaved: widget.isSaved,
              isVideo: true,
              sheetContext: context,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}