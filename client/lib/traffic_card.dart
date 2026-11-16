import 'dart:async';
import 'dart:ui' show FontFeature, ImageFilter;

import 'package:flutter/material.dart';

import 'store.dart' show fmtBytes, fmtDuration;

const int _kPoints = 60;
const int _kWindowMs = 3000;

class TrafficSample {
  final bool on;
  final int down, up, downTotal, upTotal, seconds;
  final int directDown, directUp;
  final double? quotaFraction;
  final String quotaText;
  const TrafficSample({
    this.on = false,
    this.down = 0,
    this.up = 0,
    this.downTotal = 0,
    this.upTotal = 0,
    this.seconds = 0,
    this.directDown = 0,
    this.directUp = 0,
    this.quotaFraction,
    this.quotaText = '',
  });
}

class _Skin {
  final bool neon, fa;
  final Color down, up, time, bg1, bg2, tile;
  const _Skin({
    required this.neon,
    required this.fa,
    required this.down,
    required this.up,
    required this.time,
    required this.bg1,
    required this.bg2,
    required this.tile,
  });

  static const normal = _Skin(
    neon: false,
    fa: true,
    down: Color(0xFF4FB6FF),
    up: Color(0xFF3BF0A0),
    time: Color(0xFFFFD166),
    bg1: Color(0xFF123A7A),
    bg2: Color(0xFF0A1B3D),
    tile: Color(0xFF0A1B3D),
  );

  static const neonSkin = _Skin(
    neon: true,
    fa: false,
    down: Color(0xFF5CE1FF),
    up: Color(0xFFD16BFF),
    time: Color(0xFFFFB86B),
    bg1: Color(0xFF2A0F55),
    bg2: Color(0xFF070A1F),
    tile: Color(0xFF05040F),
  );

  String get tDown => fa ? 'دانلود' : 'DOWNLOAD';
  String get tUp => fa ? 'آپلود' : 'UPLOAD';
  String get tOnline => fa ? 'متصل' : 'ONLINE';
  String get tOffline => fa ? 'قطع' : 'OFFLINE';
  String get tTime => fa ? 'مدت اتصال' : 'SESSION';
  String get tPeak => fa ? 'اوج سرعت' : 'PEAK';
  String get tAvg => fa ? 'میانگین' : 'AVERAGE';
  String get tTotal => fa ? 'مجموع مصرف' : 'TOTAL USED';
  String get tDirect => fa ? 'مستقیم' : 'DIRECT';
}

class TrafficCard extends StatefulWidget {
  const TrafficCard({super.key, required this.reader, this.title = 'وضعیت اتصال', this.neon = false});

  final TrafficSample Function() reader;
  final String title;
  final bool neon;

  @override
  State<TrafficCard> createState() => _TrafficCardState();
}

class _Snap {
  final int ms, down, up;
  const _Snap(this.ms, this.down, this.up);
}

class _TrafficCardState extends State<TrafficCard> {
  final List<double> _dl = [];
  final List<double> _ul = [];
  final List<_Snap> _snaps = [];
  final Stopwatch _clock = Stopwatch()..start();
  Timer? _timer;
  TrafficSample _s = const TrafficSample();
  double _down = 0, _up = 0, _peakDown = 0, _peakUp = 0;

  _Skin get _skin => widget.neon ? _Skin.neonSkin : _Skin.normal;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reset() {
    _dl.clear();
    _ul.clear();
    _snaps.clear();
    _down = 0;
    _up = 0;
    _peakDown = 0;
    _peakUp = 0;
  }

  double _rate(int a, int b, double reported, bool totalsLive) {
    if (!totalsLive || _snaps.length < 2) return reported;
    final first = _snaps.first;
    final last = _snaps.last;
    final dt = (last.ms - first.ms) / 1000.0;
    if (dt < 0.4) return reported;
    final dd = (a - b).toDouble();
    return dd <= 0 ? 0 : dd / dt;
  }

  void _tick() {
    TrafficSample s;
    try {
      s = widget.reader();
    } catch (_) {
      s = const TrafficSample();
    }
    if (!s.on) {
      if (_dl.isNotEmpty || _down != 0 || _up != 0) _reset();
      if (mounted) setState(() => _s = s);
      return;
    }
    final now = _clock.elapsedMilliseconds;
    if (_snaps.isNotEmpty && (s.downTotal < _snaps.last.down || s.upTotal < _snaps.last.up)) {
      _reset();
    }
    _snaps.add(_Snap(now, s.downTotal, s.upTotal));
    while (_snaps.length > 2 && now - _snaps[1].ms >= _kWindowMs) {
      _snaps.removeAt(0);
    }
    final live = s.downTotal > 0 || s.upTotal > 0;
    final rd = _rate(s.downTotal, _snaps.first.down, s.down.toDouble(), live);
    final ru = _rate(s.upTotal, _snaps.first.up, s.up.toDouble(), live);
    _down = _down == 0 ? rd : _down * 0.35 + rd * 0.65;
    _up = _up == 0 ? ru : _up * 0.35 + ru * 0.65;
    if (rd == 0 && _down < 64) _down = 0;
    if (ru == 0 && _up < 64) _up = 0;
    if (_down > _peakDown) _peakDown = _down;
    if (_up > _peakUp) _peakUp = _up;
    _dl.add(_down);
    _ul.add(_up);
    if (_dl.length > _kPoints) _dl.removeAt(0);
    if (_ul.length > _kPoints) _ul.removeAt(0);
    if (mounted) setState(() => _s = s);
  }

  (String, String) _split(num v) {
    final t = fmtBytes(v).split(' ');
    return (t.first, t.length > 1 ? t[1] : 'B');
  }

  BoxDecoration _frost(double r, {double hi = 0.17, double lo = 0.05, double border = 0.22, Color? tint}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(r),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(Colors.white, tint ?? Colors.white, tint == null ? 0 : 0.35)!.withOpacity(hi),
          Colors.white.withOpacity(lo),
        ],
      ),
      border: Border.all(color: Colors.white.withOpacity(border), width: 1),
    );
  }

  Widget _speedTile(IconData icon, Color c, String label, double v) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: _frost(18, tint: c, hi: 0.2, lo: 0.04, border: 0.24),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c.withOpacity(0.55), c.withOpacity(0.12)]),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              boxShadow: [BoxShadow(color: c.withOpacity(0.35), blurRadius: 12)],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(label, style: TextStyle(color: Colors.white.withOpacity(0.62), fontSize: 10, letterSpacing: _skin.neon ? 1.8 : 0.4, fontWeight: FontWeight.w700)),
              const SizedBox(height: 1),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: v),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (_, val, __) {
                  final p = _split(val);
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, mainAxisSize: MainAxisSize.min, children: [
                      Text(p.$1, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
                      const SizedBox(width: 3),
                      Text('${p.$2}/s', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  );
                },
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _stat(IconData icon, Color c, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: _frost(14, hi: 0.1, lo: 0.03, border: 0.14),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: c.withOpacity(0.95), size: 13),
            const SizedBox(width: 4),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9.5, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 3),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700))),
        ]),
      ),
    );
  }

  Widget _ratioBar() {
    final k = _skin;
    final d = _s.downTotal.toDouble();
    final u = _s.upTotal.toDouble();
    final sum = d + u;
    final fd = sum <= 0 ? 0.5 : d / sum;
    return Container(
      height: 7,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Row(children: [
          Expanded(flex: (fd * 1000).round().clamp(1, 999), child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [k.down.withOpacity(0.55), k.down])))),
          const SizedBox(width: 2),
          Expanded(flex: ((1 - fd) * 1000).round().clamp(1, 999), child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [k.up, k.up.withOpacity(0.55)])))),
        ]),
      ),
    );
  }

  Widget _quota() {
    final k = _skin;
    final f = _s.quotaFraction;
    if (f == null && _s.quotaText.isEmpty) return const SizedBox.shrink();
    final danger = f != null && f > 0.9;
    final c = danger ? Colors.redAccent : k.time;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.data_usage_rounded, color: c, size: 14),
            const SizedBox(width: 5),
            Expanded(child: Text(_s.quotaText, style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600))),
          ]),
          if (f != null) ...[
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: f.clamp(0.0, 1.0), minHeight: 6, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation<Color>(c)),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _orb(Color c, double size, double op) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [c.withOpacity(op), c.withOpacity(0)])),
      );

  @override
  Widget build(BuildContext context) {
    final k = _skin;
    final s = _s;
    final on = s.on;
    final accent = on ? k.up : Colors.white54;
    final avg = s.seconds > 0 ? (s.downTotal + s.upTotal) / s.seconds : 0.0;
    final peak = _peakDown > _peakUp ? _peakDown : _peakUp;
    const r = 26.0;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(1.2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white.withOpacity(0.55), k.down.withOpacity(0.18), Colors.white.withOpacity(0.06), k.up.withOpacity(0.35)],
          ),
          boxShadow: [
            BoxShadow(color: k.down.withOpacity(0.22), blurRadius: 30, spreadRadius: -4, offset: const Offset(-6, 8)),
            BoxShadow(color: k.up.withOpacity(0.18), blurRadius: 30, spreadRadius: -4, offset: const Offset(6, 10)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r - 1.2),
          child: Stack(children: [
            Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [k.bg1, k.bg2])))),
            Positioned(left: -60, top: -50, child: _orb(k.down, 230, 0.55)),
            Positioned(right: -70, bottom: -60, child: _orb(k.up, 250, 0.45)),
            Positioned(right: 30, top: -40, child: _orb(k.time, 130, 0.25)),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.04)]),
                  ),
                ),
              ),
            ),
            Positioned(top: 0, left: 18, right: 18, child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white.withOpacity(0), Colors.white.withOpacity(0.7), Colors.white.withOpacity(0)])))),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [k.time.withOpacity(0.5), k.time.withOpacity(0.1)]),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.timer_rounded, color: Colors.white, size: 21),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(k.tTime, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10.5, letterSpacing: k.neon ? 2.5 : 0.4, fontWeight: FontWeight.w700)),
                      Text(
                        fmtDuration(on ? s.seconds : 0),
                        style: const TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w800, letterSpacing: 2.2, fontFeatures: [FontFeature.tabularFigures()]),
                      ),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: _frost(20, tint: accent, hi: 0.2, lo: 0.06, border: 0.26),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: accent, shape: BoxShape.circle, boxShadow: on ? [BoxShadow(color: accent, blurRadius: 8)] : null)),
                      const SizedBox(width: 6),
                      Text(on ? k.tOnline : k.tOffline, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11.5, letterSpacing: 1)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  _speedTile(Icons.south_rounded, k.down, k.tDown, _down),
                  const SizedBox(width: 10),
                  _speedTile(Icons.north_rounded, k.up, k.tUp, _up),
                ]),
                const SizedBox(height: 12),
                Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.14)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: RepaintBoundary(child: CustomPaint(painter: _ChartPainter(List.of(_dl), List.of(_ul), down: k.down, up: k.up, neon: false))),
                  ),
                ),
                const SizedBox(height: 11),
                _ratioBar(),
                const SizedBox(height: 11),
                Row(children: [
                  _stat(Icons.download_done_rounded, k.down, k.tDown, fmtBytes(s.downTotal)),
                  const SizedBox(width: 6),
                  _stat(Icons.upload_rounded, k.up, k.tUp, fmtBytes(s.upTotal)),
                  const SizedBox(width: 6),
                  _stat(Icons.speed_rounded, k.time, k.tPeak, '${fmtBytes(peak)}/s'),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  _stat(Icons.functions_rounded, k.down, k.tTotal, fmtBytes(s.downTotal + s.upTotal)),
                  const SizedBox(width: 6),
                  _stat(Icons.av_timer_rounded, k.up, k.tAvg, '${fmtBytes(avg)}/s'),
                  if (s.directDown + s.directUp > 0) ...[
                    const SizedBox(width: 6),
                    _stat(Icons.alt_route_rounded, k.time, k.tDirect, fmtBytes(s.directDown + s.directUp)),
                  ],
                ]),
                _quota(),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.dl, this.ul, {required this.down, required this.up, this.neon = false});
  final List<double> dl, ul;
  final Color down, up;
  final bool neon;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    var raw = 1024.0;
    for (final v in dl) {
      if (v > raw) raw = v;
    }
    for (final v in ul) {
      if (v > raw) raw = v;
    }
    final peak = raw * 1.15;
    _series(canvas, size, ul, peak, up);
    _series(canvas, size, dl, peak, down);
    final tp = TextPainter(
      text: TextSpan(text: '${fmtBytes(raw)}/s', style: const TextStyle(color: Colors.white38, fontSize: 9.5, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, const Offset(6, 4));
  }

  void _series(Canvas canvas, Size size, List<double> v, double peak, Color c) {
    if (v.length < 2) return;
    final pts = <Offset>[
      for (var i = 0; i < v.length; i++)
        Offset(
          size.width * (i + (_kPoints - v.length)) / (_kPoints - 1),
          size.height - 6 - (v[i] / peak) * (size.height - 20),
        ),
    ];
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[i == 0 ? 0 : i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = pts[i + 2 < pts.length ? i + 2 : i + 1];
      final c1 = Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
      final c2 = Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);
      line.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    final fill = Path.from(line)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.withOpacity(0.38), c.withOpacity(0.02)],
        ).createShader(Offset.zero & size),
    );
    if (neon) {
      canvas.drawPath(
        line,
        Paint()
          ..color = c.withOpacity(0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = neon ? Color.lerp(c, Colors.white, 0.35)! : c
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(pts.last, 6, Paint()..color = c.withOpacity(0.28));
    canvas.drawCircle(pts.last, 3.2, Paint()..color = c);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => true;
}
