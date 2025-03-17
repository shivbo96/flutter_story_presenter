import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_story_presenter/flutter_story_presenter.dart';

/// A widget that displays a video story view, supporting different video sources
/// (network, file, asset) and optional thumbnail and error widgets.
class VideoStoryView extends StatefulWidget {
  /// The story item containing video data and configuration.
  final StoryItem storyItem;

  /// Callback function to notify when the video is loaded.
  final Function(BetterPlayerController)? onVideoLoad;

  /// In case of single video story
  final bool? looping;

  /// Creates a [VideoStoryView] widget.
  const VideoStoryView({required this.storyItem, this.onVideoLoad, this.looping, super.key});

  @override
  State<VideoStoryView> createState() => _VideoStoryViewState();
}

class _VideoStoryViewState extends State<VideoStoryView> {
  late BetterPlayerController _betterPlayerController;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeBetterPlayer();
  }

  /// Initializes the Better Player controller based on the source of the video.
  Future<void> _initializeBetterPlayer() async {
    try {
      final storyItem = widget.storyItem;
      BetterPlayerDataSource dataSource;

      if (storyItem.storyItemSource.isNetwork) {
        dataSource = BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          storyItem.url!,
          placeholder: storyItem.videoConfig?.placeholder,
          cacheConfiguration: BetterPlayerCacheConfiguration(
            useCache: storyItem.videoConfig?.cacheVideo ?? false,
          ),
        );
      } else if (storyItem.storyItemSource.isFile) {
        dataSource = BetterPlayerDataSource(
          BetterPlayerDataSourceType.file,
          storyItem.url!,
        );
      } else {
        dataSource = BetterPlayerDataSource(
          BetterPlayerDataSourceType.memory,
          storyItem.url!,
        );
      }

      _betterPlayerController = BetterPlayerController(
        BetterPlayerConfiguration(
          aspectRatio: storyItem.videoConfig?.aspectRatio ?? 9 / 16,
          autoPlay: true,
          looping: widget.looping ?? false,
          showPlaceholderUntilPlay: true,
          allowedScreenSleep: false,
          placeholder: storyItem.videoConfig?.placeholder,
          fit: storyItem.videoConfig?.fit ?? BoxFit.cover,
          controlsConfiguration: BetterPlayerControlsConfiguration(
              showControls: false, loadingWidget: widget.storyItem.videoConfig?.loadingWidget),
        ),
        betterPlayerDataSource: dataSource,
      );

      widget.onVideoLoad?.call(_betterPlayerController);
    } catch (e) {
      setState(() {
        hasError = true;
      });
      debugPrint('Error initializing BetterPlayer: $e');
    }
  }

  @override
  void dispose() {
    _betterPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: (widget.storyItem.videoConfig?.fit == BoxFit.cover) ? Alignment.topCenter : Alignment.center,
      fit: (widget.storyItem.videoConfig?.fit == BoxFit.cover) ? StackFit.expand : StackFit.loose,
      children: [
        // if (widget.storyItem.videoConfig?.loadingWidget != null) ...{
        //   widget.storyItem.videoConfig!.loadingWidget!,
        // } else if (widget.storyItem.thumbnail != null) ...{
        //   widget.storyItem.thumbnail!,
        // },
        // if (widget.storyItem.errorWidget != null && hasError) ...{
        //   widget.storyItem.errorWidget!,
        // },
        BetterPlayer(controller: _betterPlayerController),
      ],
    );
  }
}
