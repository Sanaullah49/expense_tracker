import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class ProgressChartWidget extends StatefulWidget {
  final double percentage;
  final double size;
  final double strokeWidth;
  final Color? progressColor;
  final Color? backgroundColor;
  final Widget? centerWidget;
  final bool animate;
  final Duration animationDuration;

  const ProgressChartWidget({
    super.key,
    required this.percentage,
    this.size = 150,
    this.strokeWidth = 12,
    this.progressColor,
    this.backgroundColor,
    this.centerWidget,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<ProgressChartWidget> createState() => _ProgressChartWidgetState();
}

class _ProgressChartWidgetState extends State<ProgressChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _animation =
        Tween<double>(
          begin: 0,
          end: widget.percentage.clamp(0, 100) / 100,
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
        );

    if (widget.animate) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ProgressChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _animation =
          Tween<double>(
            begin: _animation.value,
            end: widget.percentage.clamp(0, 100) / 100,
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
          );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveProgressColor =
        widget.progressColor ??
        (widget.percentage > 80
            ? AppColors.error
            : widget.percentage > 60
            ? AppColors.warning
            : AppColors.success);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _ProgressChartPainter(
            percentage: widget.animate
                ? _animation.value
                : widget.percentage / 100,
            strokeWidth: widget.strokeWidth,
            progressColor: effectiveProgressColor,
            backgroundColor: widget.backgroundColor ?? Colors.grey.shade200,
          ),
          child: Container(
            width: widget.size,
            height: widget.size,
            alignment: Alignment.center,
            child:
                widget.centerWidget ??
                _buildDefaultCenter(effectiveProgressColor),
          ),
        );
      },
    );
  }

  Widget _buildDefaultCenter(Color progressColor) {
    final displayPercentage = widget.animate
        ? (_animation.value * 100).toInt()
        : widget.percentage.toInt();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$displayPercentage%',
          style: TextStyle(
            fontSize: widget.size * 0.2,
            fontWeight: FontWeight.bold,
            color: progressColor,
          ),
        ),
        if (widget.percentage > 100)
          Text(
            'Exceeded!',
            style: TextStyle(
              fontSize: widget.size * 0.08,
              color: AppColors.error,
            ),
          ),
      ],
    );
  }
}

class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder2(
      listenable: animation,
      builder: builder,
      child: child,
    );
  }
}

class AnimatedBuilder2 extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder2({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}

class _ProgressChartPainter extends CustomPainter {
  final double percentage;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;

  _ProgressChartPainter({
    required this.percentage,
    required this.strokeWidth,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * percentage.clamp(0, 1);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressChartPainter oldDelegate) {
    return percentage != oldDelegate.percentage ||
        progressColor != oldDelegate.progressColor;
  }
}

class MultiProgressChart extends StatelessWidget {
  final List<ProgressData> data;
  final double size;
  final double strokeWidth;

  const MultiProgressChart({
    super.key,
    required this.data,
    this.size = 200,
    this.strokeWidth = 8,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...data.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final adjustedSize = size - (index * strokeWidth * 3);

            return Center(
              child: ProgressChartWidget(
                percentage: item.percentage,
                size: adjustedSize,
                strokeWidth: strokeWidth,
                progressColor: item.color,
                centerWidget: index == 0 ? _buildCenterContent() : null,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCenterContent() {
    final totalPercentage =
        data.fold<double>(0, (sum, item) => sum + item.percentage) /
        data.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${totalPercentage.toInt()}%',
          style: TextStyle(fontSize: size * 0.15, fontWeight: FontWeight.bold),
        ),
        Text(
          'Average',
          style: TextStyle(fontSize: size * 0.06, color: Colors.grey),
        ),
      ],
    );
  }
}

class ProgressData {
  final String label;
  final double percentage;
  final Color color;

  ProgressData({
    required this.label,
    required this.percentage,
    required this.color,
  });
}
