import 'dart:ui';
import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SmoothVideoProgress extends HookWidget {
  const SmoothVideoProgress({
    super.key,
    required this.controller,
    required this.builder,
    this.child,
  });

  final BetterPlayerController controller;

  final Widget Function(
      BuildContext context,
      Duration progress,
      Duration duration,
      Widget? child,
      ) builder;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final videoPlayerController = controller.videoPlayerController;
    if (videoPlayerController == null) {
      return builder(context, Duration.zero, Duration.zero, child);
    }

    final duration = useState(Duration.zero);
    final lastActualPosition = useState(Duration.zero);
    final lastUpdateTime = useState(DateTime.now());
    final animatedProgress = useState(Duration.zero);

    final isPlaying = useState(false);
    final isInitialized = useState(false);
    final isSeeking = useState(false);
    final hasSnappedToStart = useState(false);

    final ticker = useMemoized(() {
      return Ticker((elapsed) {
        // Only animate if initialized AND playing AND not seeking
        if (!isInitialized.value || !isPlaying.value || isSeeking.value) return;

        final now = DateTime.now();
        final elapsedSinceUpdate = now.difference(lastUpdateTime.value).inMilliseconds;

        final predicted = lastActualPosition.value + Duration(milliseconds: elapsedSinceUpdate);

        final target = duration.value != Duration.zero
            ? (predicted > duration.value ? duration.value : predicted)
            : predicted;

        final lerped = Duration(
          milliseconds: lerpDouble(
            animatedProgress.value.inMilliseconds.toDouble(),
            target.inMilliseconds.toDouble(),
            hasSnappedToStart.value ? 0.3 : 1.0,
          )!
              .round(),
        );

        animatedProgress.value = lerped;
        hasSnappedToStart.value = true;
      });
    }, []);

    useEffect(() {
      ticker.start();
      return () => ticker.dispose();
    }, []);

    useEffect(() {
      void playerListener() {
        final value = videoPlayerController.value;

        if (value.initialized) {
          isInitialized.value = true;
          if (value.duration != null) {
            duration.value = value.duration!;
          }
        }

        isPlaying.value = value.isPlaying;

        final newPos = value.position;
        final jump = (newPos - lastActualPosition.value).inMilliseconds.abs();

        if (jump > 1500) {
          isSeeking.value = true;
          animatedProgress.value = newPos;
          hasSnappedToStart.value = true;

          Future.delayed(const Duration(milliseconds: 100), () {
            isSeeking.value = false;
          });
        }

        lastActualPosition.value = newPos;
        lastUpdateTime.value = DateTime.now();
      }

      videoPlayerController.addListener(playerListener);
      return () => videoPlayerController.removeListener(playerListener);
    }, [videoPlayerController]);

    return builder(
      context,
      animatedProgress.value,
      duration.value,
      child,
    );
  }
}
