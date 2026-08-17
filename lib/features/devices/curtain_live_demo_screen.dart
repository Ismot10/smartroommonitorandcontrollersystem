import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

enum _CurtainDemoMode { rain, bright }

class CurtainLiveDemoScreen extends StatefulWidget {
  const CurtainLiveDemoScreen({super.key});

  @override
  State<CurtainLiveDemoScreen> createState() => _CurtainLiveDemoScreenState();
}

class _CurtainLiveDemoScreenState extends State<CurtainLiveDemoScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _weatherController;
  _CurtainDemoMode _mode = _CurtainDemoMode.rain;
  bool _curtainClosed = false;
  int _sceneRevision = 0;

  bool get _isRaining => _mode == _CurtainDemoMode.rain;

  @override
  void initState() {
    super.initState();
    _weatherController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRainSequence());
  }

  @override
  void dispose() {
    _weatherController.dispose();
    super.dispose();
  }

  void _setMode(_CurtainDemoMode mode) {
    if (_mode == mode) return;
    _sceneRevision++;
    if (mode == _CurtainDemoMode.rain) {
      setState(() {
        _mode = mode;
        _curtainClosed = false;
      });
      _weatherController.repeat();
      _startRainSequence();
    } else {
      setState(() {
        _mode = mode;
        _curtainClosed = true;
      });
      _weatherController.stop();
      _weatherController.value = 0;
      _startBrightSequence();
    }
  }

  Future<void> _startRainSequence() async {
    final revision = ++_sceneRevision;
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted || revision != _sceneRevision || !_isRaining) return;
    setState(() => _curtainClosed = true);
  }

  Future<void> _startBrightSequence() async {
    final revision = ++_sceneRevision;
    _weatherController.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted || revision != _sceneRevision || _isRaining) return;
    setState(() => _curtainClosed = false);
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isRaining ? AppColors.accentBlue : AppColors.accentYellow;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.lightBackground,
              accent.withValues(alpha: 0.10),
              const Color(0xFFF7EFDF),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _RoundButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Curtain Live Demo',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const Text(
                            'Live curtain automation simulation',
                            style: TextStyle(
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 550),
                  curve: Curves.easeOutCubic,
                  height: 430,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: _isRaining
                          ? const [Color(0xFF486986), Color(0xFF91ABC1)]
                          : const [Color(0xFF70B7F2), Color(0xFFFFD77A)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.22),
                        blurRadius: 30,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: _isRaining
                              ? const SizedBox(key: ValueKey('storm'))
                              : _SunScene(
                                  key: const ValueKey('sun'),
                                  animation: _weatherController,
                                ),
                        ),
                      ),
                      if (_isRaining)
                        const Positioned(
                          top: 28,
                          left: 18,
                          right: 18,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Icon(
                                Icons.cloud_rounded,
                                color: Colors.white70,
                                size: 64,
                              ),
                              Icon(
                                Icons.cloud_rounded,
                                color: Colors.white54,
                                size: 78,
                              ),
                              Icon(
                                Icons.cloud_rounded,
                                color: Colors.white70,
                                size: 58,
                              ),
                            ],
                          ),
                        ),
                      const Positioned(
                        left: 30,
                        right: 30,
                        bottom: 52,
                        child: _WindowFrame(),
                      ),
                      if (_isRaining)
                        Positioned(
                          left: 36,
                          right: 36,
                          bottom: 59,
                          height: 256,
                          child: IgnorePointer(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: AnimatedBuilder(
                                animation: _weatherController,
                                builder: (_, __) => CustomPaint(
                                  painter: _RainPainter(
                                    progress: _weatherController.value,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        left: 30,
                        right: 30,
                        bottom: 52,
                        height: 270,
                        child: _AnimatedCurtains(closed: _curtainClosed),
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: 15,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: Text(
                            _isRaining
                                ? _curtainClosed
                                      ? 'Rain detected → Curtain closed'
                                      : 'Rain is falling → Curtain closing'
                                : _curtainClosed
                                ? 'Bright daylight detected → Sun rising'
                                : 'Sun is rising → Curtain opening',
                            key: ValueKey((_mode, _curtainClosed)),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<_CurtainDemoMode>(
                    segments: const [
                      ButtonSegment(
                        value: _CurtainDemoMode.rain,
                        icon: Icon(Icons.water_drop_rounded),
                        label: Text('Rain'),
                      ),
                      ButtonSegment(
                        value: _CurtainDemoMode.bright,
                        icon: Icon(Icons.wb_sunny_rounded),
                        label: Text('Bright light'),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (selection) =>
                        _setMode(selection.first),
                    style: ButtonStyle(
                      minimumSize: const WidgetStatePropertyAll(
                        Size.fromHeight(60),
                      ),
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 28, vertical: 19),
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.science_rounded, color: AppColors.primaryDark),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Demo mode is visual only. It does not write to '
                          'Firebase or move the physical curtain servo.',
                          style: TextStyle(
                            color: AppColors.lightTextSecondary,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedCurtains extends StatelessWidget {
  const _AnimatedCurtains({required this.closed});
  final bool closed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final closedWidth = constraints.maxWidth / 2;
        return Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _CurtainPanel(
                left: true,
                width: closed ? closedWidth : 55,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _CurtainPanel(
                left: false,
                width: closed ? closedWidth : 55,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CurtainPanel extends StatelessWidget {
  const _CurtainPanel({required this.left, required this.width});
  final bool left;
  final double width;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeInOutCubic,
      width: width,
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.horizontal(
          left: left ? const Radius.circular(18) : Radius.zero,
          right: left ? Radius.zero : const Radius.circular(18),
        ),
        gradient: LinearGradient(
          colors: const [Color(0xFF275E4C), Color(0xFF75B83B)],
          begin: left ? Alignment.centerLeft : Alignment.centerRight,
          end: left ? Alignment.centerRight : Alignment.centerLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
          ),
        ],
      ),
      child: CustomPaint(painter: _CurtainFoldPainter()),
    );
  }
}

class _WindowFrame extends StatelessWidget {
  const _WindowFrame();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 270,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(color: Colors.white, width: 7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Expanded(child: SizedBox()),
          VerticalDivider(color: Colors.white, thickness: 5, width: 5),
          Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}

class _SunScene extends StatelessWidget {
  const _SunScene({super.key, required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final rise = Curves.easeOutCubic.transform(animation.value);
        final pulse = 1 + math.sin(animation.value * math.pi) * 0.12;
        return Align(
          alignment: Alignment(0.58, 0.72 - (rise * 1.38)),
          child: Opacity(
            opacity: (0.35 + rise * 0.65).clamp(0.0, 1.0),
            child: Transform.scale(scale: pulse, child: child),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFE778).withValues(alpha: 0.48),
              blurRadius: 34,
              spreadRadius: 10,
            ),
          ],
        ),
        child: const Icon(
          Icons.wb_sunny_rounded,
          size: 88,
          color: Color(0xFFFFF1A8),
        ),
      ),
    );
  }
}

class _RainPainter extends CustomPainter {
  const _RainPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEAF8FF).withValues(alpha: 0.96)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    for (var index = 0; index < 64; index++) {
      final x = ((index * 37.0 + (index % 4) * 11) % size.width);
      final travel = size.height + 48;
      final start = ((index * 61.0 + progress * travel) % travel) - 28;
      canvas.drawLine(
        Offset(x, start),
        Offset(x, math.min(size.height + 12, start + 34)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _CurtainFoldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 2;
    for (var x = 12.0; x < size.width; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(width: 48, height: 48, child: Icon(icon)),
      ),
    );
  }
}
