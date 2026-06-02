import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// One shared [Player] for the reels feed — avoids multiple textures in
/// [PageView] and swaps the active URL when the user scrolls.
class ReelVideoBackground extends StatefulWidget {
  const ReelVideoBackground({
    required this.videoUrl,
    required this.isActive,
    super.key,
  });

  /// `null` when the visible reel is a photo.
  final String? videoUrl;
  final bool isActive;

  @override
  State<ReelVideoBackground> createState() => _ReelVideoBackgroundState();
}

class _ReelVideoBackgroundState extends State<ReelVideoBackground> {
  late final Player _player;
  late final VideoController _controller;
  StreamSubscription<String>? _errorSubscription;
  var _loadGeneration = 0;
  var _hasError = false;
  String? _loadedUrl;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _errorSubscription = _player.stream.error.listen((error) {
      if (!mounted) return;
      debugPrint('ReelVideoBackground: $error');
      setState(() => _hasError = true);
    });
    unawaited(_syncVideo());
  }

  @override
  void didUpdateWidget(ReelVideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.videoUrl != oldWidget.videoUrl ||
        widget.isActive != oldWidget.isActive) {
      if (widget.videoUrl != oldWidget.videoUrl) {
        _hasError = false;
      }
      unawaited(_syncVideo());
    }
  }

  @override
  void dispose() {
    unawaited(_errorSubscription?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _syncVideo() async {
    final url = widget.videoUrl;
    if (url == null || !widget.isActive) {
      await _player.pause();
      return;
    }

    if (_loadedUrl == url && !_hasError) {
      if (!_player.state.playing) {
        await _player.play().catchError((_) {});
      }
      return;
    }

    final generation = ++_loadGeneration;
    if (mounted) {
      setState(() => _hasError = false);
    }

    try {
      await _player.setPlaylistMode(PlaylistMode.single);
      await _player.open(Media(url), play: widget.isActive);
      if (!mounted || generation != _loadGeneration) return;
      _loadedUrl = url;
    } on Object catch (error, stackTrace) {
      debugPrint('ReelVideoBackground open failed: $error\n$stackTrace');
      if (mounted && generation == _loadGeneration) {
        setState(() => _hasError = true);
      }
    }
  }

  void _retry() {
    _loadedUrl = null;
    _hasError = false;
    unawaited(_syncVideo());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoUrl == null) {
      return const ColoredBox(color: Colors.black);
    }

    final size = MediaQuery.sizeOf(context);

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Video(
            controller: _controller,
            width: size.width,
            height: size.height,
            fit: BoxFit.cover,
            controls: (state) => const SizedBox.shrink(),
          ),
          if (_hasError)
            Center(
              child: IconButton(
                tooltip: 'Retry video',
                icon:
                    const Icon(Icons.refresh, color: Colors.white70, size: 32),
                onPressed: _retry,
              ),
            ),
        ],
      ),
    );
  }
}
