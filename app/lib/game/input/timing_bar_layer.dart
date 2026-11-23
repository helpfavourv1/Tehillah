import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:tehillah/core/input/timing_bar_strategy.dart';
import 'package:tehillah/game/geometry/pitch_projection.dart';
import 'package:tehillah/game/input/zone_grid.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/tokens.dart';

/// The second input scheme. First tap one of six zones on the goal, then a bar
/// sweeps back and forth and a tap anywhere stops it: where it stops sets the
/// power and how true the shot is. The bar is a measuring instrument and always
/// runs left to right, in any reading direction.
class TimingBarLayer extends StatefulWidget {
  const TimingBarLayer({
    required this.strategy,
    required this.projection,
    required this.zoneLabel,
    required this.stopLabel,
    super.key,
    this.enabled = true,
  });

  final TimingBarStrategy strategy;
  final PitchProjection projection;
  final String Function(int column, int row) zoneLabel;

  /// Shown above the bar and read by screen readers ("Tap to stop").
  final String stopLabel;

  final bool enabled;

  @override
  State<TimingBarLayer> createState() => _TimingBarLayerState();
}

class _TimingBarLayerState extends State<TimingBarLayer> with SingleTickerProviderStateMixin {
  Ticker? _ticker;

  bool get _running => widget.strategy.phase == TimingPhase.running;

  void _select(int column, int row) {
    if (!widget.enabled || _running) {
      return;
    }
    widget.strategy.selectZone(column, row);
    _ticker?.dispose();
    _ticker = createTicker((Duration elapsed) {
      widget.strategy.tick(elapsed.inMilliseconds);
      if (mounted) {
        setState(() {});
      }
    })
      ..start();
    setState(() {});
  }

  void _stop() {
    if (!_running) {
      return;
    }
    _stopTicker();
    widget.strategy.stop();
    setState(() {});
  }

  void _stopTicker() {
    _ticker?.dispose();
    _ticker = null;
  }

  @override
  void didUpdateWidget(TimingBarLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _running) {
      _stopTicker();
      widget.strategy.reset();
    }
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return const SizedBox.shrink();
    }
    final AppThemeData theme = AppTheme.of(context);
    final TimingBarStrategy s = widget.strategy;
    final ({int column, int row})? chosen = _running ? (column: s.column, row: s.row) : null;
    final double bottom = MediaQuery.paddingOf(context).bottom + Sp.lg;
    return Stack(
      children: <Widget>[
        ZoneGrid(
          projection: widget.projection,
          zoneLabel: widget.zoneLabel,
          selected: chosen,
          onSelect: _running ? null : _select,
        ),
        if (_running) ...<Widget>[
          Positioned.fill(
            child: Semantics(
              button: true,
              label: widget.stopLabel,
              onTap: _stop,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _stop,
                child: const SizedBox.expand(),
              ),
            ),
          ),
          PositionedDirectional(
            start: Sp.lg,
            end: Sp.lg,
            bottom: bottom,
            child: IgnorePointer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(widget.stopLabel, textAlign: TextAlign.center, style: theme.text.callout),
                  const SizedBox(height: Sp.sm),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: _Bar(position: s.position, palette: theme.palette),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.position, required this.palette});

  final double position;
  final AppPalette palette;

  static const double height = Sp.lg;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) {
          final double w = box.maxWidth;
          const double thumb = Sp.sm;
          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.bgSecondary,
                    borderRadius: BorderRadius.circular(Radii.pill(height)),
                    border: Border.all(color: palette.borderSubtle, width: Metrics.hairline),
                  ),
                ),
              ),
              Positioned(
                left: w * TimingBarStrategy.sweetSpot,
                top: 0,
                bottom: 0,
                right: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.accent.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(Radii.pill(height)),
                  ),
                ),
              ),
              Positioned(
                left: (w - thumb) * position,
                top: -Sp.xs,
                bottom: -Sp.xs,
                width: thumb,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.accent,
                    borderRadius: BorderRadius.circular(Radii.pill(thumb)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
