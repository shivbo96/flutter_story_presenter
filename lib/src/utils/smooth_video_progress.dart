library smooth_video_progress;

import 'package:better_player/better_player.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:math';

/// A widget that provides a method of building widgets using an interpolated
/// position value for [BetterPlayerController].
class SmoothVideoProgress extends HookWidget {
  const SmoothVideoProgress({
    super.key,
    required this.controller,
    required this.builder,
    this.child,
  });

  /// The [BetterPlayerController] to track progress for.
  final BetterPlayerController controller;

  /// The builder function.
  final Widget Function(BuildContext context, Duration progress,
      Duration duration, Widget? child) builder;

  /// An optional child that will be passed to the [builder] function.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final videoPlayerController = controller.videoPlayerController;
    if (videoPlayerController == null) {
      return builder(context, Duration.zero, Duration.zero, child);
    }

    final position = useState(Duration.zero);
    final duration = useState(Duration.zero);
    final isInitialized = useState(false);

    useEffect(() {
      void listener(BetterPlayerEvent event) {
        final value = videoPlayerController.value;

        // 🔹 1. Capture duration when player is initialized
        if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
          isInitialized.value = true;
          if (value.duration != null && value.duration!.inMilliseconds > 0) {
            duration.value = value.duration!;
          }
        }

        // 🔹 2. Update progress on progress event
        if (event.betterPlayerEventType == BetterPlayerEventType.progress) {
          position.value = value.position;

          // 🔹 3. If duration is still zero, update it dynamically
          if (duration.value == Duration.zero && value.duration != null) {
            duration.value = value.duration!;
          }
        }
      }

      controller.addEventsListener(listener);

      return () {
        controller.removeEventsListener(listener);
      };
    }, [controller]);

    return TweenAnimationBuilder<Duration>(
      duration: const Duration(milliseconds: 100), // Smooth transition
      tween: Tween<Duration>(
        begin: position.value,
        end: position.value,
      ),
      builder: (context, animatedProgress, child) {
        return builder(
          context,
          animatedProgress,
          duration.value,
          child,
        );
      },
      child: child,
    );
  }
}
