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
    final videoController = controller.videoPlayerController;
    if (videoController == null) {
      return builder(context, Duration.zero, Duration.zero, child);
    }

    final duration = useState(Duration.zero);
    final lastRealPosition = useState(Duration.zero);
    final lastRealTime = useState(DateTime.now());
    final animatedProgress = useState(Duration.zero);

    final isPlaying = useState(false);
    final isInitialized = useState(false);
    final isSeeking = useState(false);

    final ticker = useMemoized(() {
      return Ticker((_) {
        if (!isInitialized.value || !isPlaying.value || isSeeking.value) return;

        final now = DateTime.now();
        final elapsed = now.difference(lastRealTime.value);
        final predicted = lastRealPosition.value + elapsed;

        if (duration.value != Duration.zero &&
            predicted > duration.value) {
          animatedProgress.value = duration.value;
        } else {
          animatedProgress.value = predicted;
        }
      });
    }, []);

    useEffect(() {
      ticker.start();
      return () => ticker.dispose();
    }, []);

    useEffect(() {
      void listener() {
        final value = videoController.value;

        isPlaying.value = value.isPlaying;

        if (value.initialized) {
          isInitialized.value = true;
          if (value.duration != null) {
            duration.value = value.duration!;
          }
        }

        final currentPosition = value.position;
        final jump = (currentPosition - lastRealPosition.value).inMilliseconds.abs();

        if (jump > 1000) {
          // Big jump: user probably seeked
          isSeeking.value = true;
          animatedProgress.value = currentPosition;
          lastRealTime.value = DateTime.now();
          lastRealPosition.value = currentPosition;

          Future.delayed(const Duration(milliseconds: 120), () {
            isSeeking.value = false;
          });
        } else {
          lastRealTime.value = DateTime.now();
          lastRealPosition.value = currentPosition;
        }
      }

      videoController.addListener(listener);
      return () => videoController.removeListener(listener);
    }, [videoController]);

    return builder(
      context,
      animatedProgress.value,
      duration.value,
      child,
    );
  }
}
