import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:social_api_client/social_api_client.dart';

/// Full-bleed photo or looping video for reels.
class PostMediaView extends StatefulWidget {
  const PostMediaView({
    required this.media,
    required this.isActive,
    super.key,
  });

  final PostMedia media;
  final bool isActive;

  @override
  State<PostMediaView> createState() => _PostMediaViewState();
}

class _PostMediaViewState extends State<PostMediaView> {
  Player? _player;
  VideoController? _videoController;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<int?>? _widthSubscription;
  var _initializing = false;
  var _initFailed = false;
  var _initGeneration = 0;

  @override
  void initState() {
    super.initState();
    _scheduleInitVideo();
  }

  @override
  void didUpdateWidget(PostMediaView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.media.isVideo) return;

    if (oldWidget.media.url != widget.media.url) {
      _disposeVideo();
      _scheduleInitVideo();
      return;
    }

    if (!oldWidget.isActive && widget.isActive) {
      _initFailed = false;
      if (_player == null) {
        _scheduleInitVideo();
      } else {
        _syncPlayback();
      }
      return;
    }

    if (oldWidget.isActive && !widget.isActive) {
      _syncPlayback();
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  void _scheduleInitVideo() {
    if (!widget.media.isVideo || !widget.isActive) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.isActive || _player != null || _initializing) {
        return;
      }
      unawaited(
        _initVideo().catchError((_) {
          // Errors are handled inside [_initVideo].
        }),
      );
    });
  }

  Future<void> _initVideo() async {
    if (!mounted || !widget.isActive) return;

    final generation = ++_initGeneration;
    final player = Player();
    final videoController = VideoController(player);

    setState(() {
      _initializing = true;
      _initFailed = false;
      _player = player;
      _videoController = videoController;
    });

    _errorSubscription = player.stream.error.listen((_) {
      if (mounted && generation == _initGeneration) {
        setState(() => _initFailed = true);
      }
    });

    _widthSubscription = player.stream.width.listen((width) {
      if (!mounted || generation != _initGeneration) return;
      if ((width ?? 0) > 0 && widget.isActive && !player.state.playing) {
        unawaited(player.play().catchError((_) {}));
      }
    });

    // Video must be mounted with layout before opening media.
    await Future<void>.delayed(Duration.zero);
    if (!mounted || generation != _initGeneration) {
      await _safeDisposePlayer(player);
      return;
    }

    try {
      await player.setPlaylistMode(PlaylistMode.single);
      await player.open(
        Media(widget.media.url),
        play: widget.isActive,
      );

      if (!mounted || generation != _initGeneration) {
        await _safeDisposePlayer(player);
        return;
      }

      setState(() => _initializing = false);
      _syncPlayback();
    } on Object {
      await _safeDisposePlayer(player);
      if (mounted && generation == _initGeneration) {
        setState(() {
          _initializing = false;
          _initFailed = true;
          _player = null;
          _videoController = null;
        });
      }
    }
  }

  void _syncPlayback() {
    final player = _player;
    if (player == null) return;
    unawaited(
      (widget.isActive ? player.play() : player.pause()).catchError((_) {}),
    );
  }

  void _disposeVideo() {
    _initGeneration++;
    _initializing = false;
    _initFailed = false;

    unawaited(_errorSubscription?.cancel());
    _errorSubscription = null;
    unawaited(_widthSubscription?.cancel());
    _widthSubscription = null;

    final player = _player;
    _player = null;
    _videoController = null;
    if (player != null) {
      unawaited(_safeDisposePlayer(player));
    }
  }

  Future<void> _safeDisposePlayer(Player player) async {
    try {
      await player.dispose();
    } on Object {
      // Player may already be torn down during navigation.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media.isVideo) {
      if (_initFailed) {
        return _VideoUnavailable(onRetry: () {
          _disposeVideo();
          _scheduleInitVideo();
        });
      }

      final videoController = _videoController;
      if (videoController == null) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final height = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.sizeOf(context).height;

          return Stack(
            fit: StackFit.expand,
            children: [
              Video(
                controller: videoController,
                width: width,
                height: height,
                fit: BoxFit.cover,
                controls: (state) => const SizedBox.shrink(),
              ),
              if (_initializing)
                const ColoredBox(
                  color: Colors.black45,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          );
        },
      );
    }

    return Image.network(
      widget.media.url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: Colors.grey.shade900,
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.white54,
            size: 48,
          ),
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      },
    );
  }
}

class _VideoUnavailable extends StatelessWidget {
  const _VideoUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.grey.shade900,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_outlined,
              color: Colors.white54,
              size: 48,
            ),
            const SizedBox(height: 12),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
