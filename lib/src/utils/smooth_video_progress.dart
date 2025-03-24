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
    final isSeeking = useState(false);

    final tickerProvider = useSingleTickerProvider();
    final ticker = useMemoized(() {
      return Ticker((elapsed) {
        if (isSeeking.value) return;

        final now = DateTime.now();
        final elapsedSinceUpdate = now.difference(lastUpdateTime.value).inMilliseconds;

        // Predict real current position
        final predicted = lastActualPosition.value + Duration(milliseconds: elapsedSinceUpdate);

        // Clamp to avoid going beyond duration
        final target = duration.value != Duration.zero
            ? predicted > duration.value
                ? duration.value
                : predicted
            : predicted;

        // Smoothly move toward predicted
        final lerped = Duration(
          milliseconds: lerpDouble(
            animatedProgress.value.inMilliseconds.toDouble(),
            target.inMilliseconds.toDouble(),
            0.3, // Adjust smoothness factor here
          )!
              .round(),
        );

        animatedProgress.value = lerped;
      });
    });

    useEffect(() {
      ticker.start();
      return () => ticker.dispose();
    }, []);

    useEffect(() {
      void listener(BetterPlayerEvent event) {
        final value = videoPlayerController.value;

        if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
          if (value.duration != null && value.duration!.inMilliseconds > 0) {
            duration.value = value.duration!;
          }
        }

        if (event.betterPlayerEventType == BetterPlayerEventType.progress) {
          final newPos = value.position;

          final jump = (newPos - lastActualPosition.value).inMilliseconds.abs();
          if (jump > 1500) {
            // Likely a seek
            isSeeking.value = true;
            animatedProgress.value = newPos;

            Future.delayed(const Duration(milliseconds: 100), () {
              isSeeking.value = false;
            });
          }

          lastActualPosition.value = newPos;
          lastUpdateTime.value = DateTime.now();

          if (duration.value == Duration.zero && value.duration != null) {
            duration.value = value.duration!;
          }
        }
      }

      controller.addEventsListener(listener);
      return () => controller.removeEventsListener(listener);
    }, [controller]);

    return builder(
      context,
      animatedProgress.value,
      duration.value,
      child,
    );
  }
}
