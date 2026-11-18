import 'dart:io' show Platform;
import 'dart:math';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'nexora_logo.dart';
import 'store.dart';
import 'vpn_service.dart';

class AppBg extends StatelessWidget {
  final Widget child;
  const AppBg({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ValueListenableBuilder<bool>(valueListenable: Store.lite, builder: (context, lite, _) => Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const [Color(0xFF050D24), Color(0xFF040A1E), Color(0xFF03071A)]
              : [p.bg, p.bg],
        ),
      ),
      child: Stack(children: [
        if (dark && !lite && kFancy) const Positioned.fill(child: _Aurora()),
        if (dark && !lite)
          Positioned(
            top: -120,
            left: -80,
            right: -80,
            child: IgnorePointer(
              child: Container(
                height: 320,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [p.accent.withOpacity(0.16), Colors.transparent],
                    radius: 0.8,
                  ),
                ),
              ),
            ),
          ),
        child,
      ]),
    ));
  }
}

class Panel extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final EdgeInsets margin;
  final Color? tint;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.margin = const EdgeInsets.only(bottom: 12),
    this.tint,
  });

  @override
  State<Panel> createState() => _PanelState();
}

class _PanelState extends State<Panel> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fancy = kFancy && !Store.lite.value && dark;
    final r = BorderRadius.circular(18);
    final tint = widget.tint;
    final inner = widget.onTap == null
        ? Padding(padding: widget.padding, child: widget.child)
        : Material(
            color: Colors.transparent,
            borderRadius: r,
            child: InkWell(borderRadius: r, onTap: widget.onTap, child: Padding(padding: widget.padding, child: widget.child)),
          );
    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? [(tint ?? const Color(0xFF12275A)).withOpacity(fancy ? 0.42 : 0.55), (tint ?? const Color(0xFF0A1735)).withOpacity(fancy ? 0.58 : 0.70)]
              : [p.card, p.card],
        ),
        border: Border.all(color: (fancy && _hover ? p.accent2 : p.border).withOpacity(fancy && _hover ? 0.9 : (dark ? 0.55 : 0.8)), width: 1),
        boxShadow: fancy && _hover ? [BoxShadow(color: p.accent2.withOpacity(0.28), blurRadius: 20)] : null,
      ),
      child: fancy ? ClipRRect(borderRadius: r, child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: inner)) : inner,
    );
    if (!fancy) return box;
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(scale: _hover && widget.onTap != null ? 1.012 : 1.0, duration: const Duration(milliseconds: 150), curve: Curves.easeOut, child: box),
    );
  }
}

class Group extends StatelessWidget {
  final List<Widget> children;
  const Group({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(Divider(height: 1, thickness: 1, indent: 14, endIndent: 14, color: p.border.withOpacity(0.35)));
      }
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark ? [const Color(0xFF0E1D45).withOpacity(0.75), const Color(0xFF091330).withOpacity(0.85)] : [p.card, p.card],
        ),
        border: Border.all(color: p.border.withOpacity(0.5)),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Column(children: rows)),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(text, style: TextStyle(color: P.of(context).text, fontSize: 16, fontWeight: FontWeight.w800)),
        ),
      );
}

class Tile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool boxed;
  const Tile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.trailing,
    this.onTap,
    this.boxed = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final row = Directionality(
      textDirection: TextDirection.ltr,
      child: Row(children: [
        SizedBox(width: 38, child: Icon(icon, color: iconColor ?? p.accent2, size: 30)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: p.text, fontSize: 15, fontWeight: FontWeight.w700)),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(subtitle!, textDirection: TextDirection.rtl, style: TextStyle(color: p.sub, fontSize: 12)),
              ),
          ]),
        ),
        if (trailing != null) trailing!,
      ]),
    );
    final padded = Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13), child: row);
    final inner = InkWell(onTap: onTap, child: padded);
    if (boxed) {
      return Panel(onTap: onTap, margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13), child: row);
    }
    return Material(color: Colors.transparent, child: inner);
  }
}

class Chevron extends StatelessWidget {
  const Chevron({super.key});
  @override
  Widget build(BuildContext context) => Icon(Icons.chevron_right_rounded, color: P.of(context).text.withOpacity(0.9), size: 28);
}

class Toggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const Toggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 54,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: value ? p.accent : const Color(0xFF2A3350),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 120),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(width: 24, height: 24, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
        ),
      ),
    );
  }
}

class ShieldPainter extends CustomPainter {
  final Color a, b;
  ShieldPainter(this.a, this.b);

  Path _shield(Rect r) {
    final w = r.width, h = r.height;
    final path = Path();
    path.moveTo(r.left + w * 0.5, r.top);
    path.cubicTo(r.left + w * 0.66, r.top + h * 0.10, r.left + w * 0.84, r.top + h * 0.14, r.right, r.top + h * 0.14);
    path.lineTo(r.right, r.top + h * 0.52);
    path.cubicTo(r.right, r.top + h * 0.78, r.left + w * 0.72, r.top + h * 0.92, r.left + w * 0.5, r.bottom);
    path.cubicTo(r.left + w * 0.28, r.top + h * 0.92, r.left, r.top + h * 0.78, r.left, r.top + h * 0.52);
    path.lineTo(r.left, r.top + h * 0.14);
    path.cubicTo(r.left + w * 0.16, r.top + h * 0.14, r.left + w * 0.34, r.top + h * 0.10, r.left + w * 0.5, r.top);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(size.width * 0.06, size.height * 0.02, size.width * 0.88, size.height * 0.96);
    final outer = _shield(r);
    final shader = LinearGradient(colors: [b, a], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(r);

    canvas.drawPath(
        outer,
        Paint()
          ..color = b.withOpacity(0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.10
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.09));
    canvas.drawPath(
        outer,
        Paint()
          ..shader = LinearGradient(
                  colors: [const Color(0xFF0B2A66).withOpacity(0.95), const Color(0xFF05153A).withOpacity(0.95)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter)
              .createShader(r));
    canvas.drawPath(
        outer,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.045
          ..strokeJoin = StrokeJoin.round);
    final inner = _shield(Rect.fromLTWH(r.left + r.width * 0.10, r.top + r.height * 0.09, r.width * 0.80, r.height * 0.80));
    canvas.drawPath(
        inner,
        Paint()
          ..color = b.withOpacity(0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.018);

    final cx = size.width * 0.5;
    final bodyW = size.width * 0.36, bodyH = size.height * 0.27;
    final bodyTop = size.height * 0.42;
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(cx - bodyW / 2, bodyTop, bodyW, bodyH), Radius.circular(size.width * 0.045));
    final shackle = Path()
      ..moveTo(cx - bodyW * 0.30, bodyTop)
      ..lineTo(cx - bodyW * 0.30, bodyTop - size.height * 0.07)
      ..arcToPoint(Offset(cx + bodyW * 0.30, bodyTop - size.height * 0.07),
          radius: Radius.circular(bodyW * 0.30), clockwise: true)
      ..lineTo(cx + bodyW * 0.30, bodyTop);
    canvas.drawPath(
        shackle,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.05
          ..strokeCap = StrokeCap.round);
    canvas.drawRRect(
        body,
        Paint()
          ..shader = LinearGradient(colors: [b, a], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(body.outerRect));
    final kp = Paint()..color = const Color(0xFF06173F);
    canvas.drawCircle(Offset(cx, bodyTop + bodyH * 0.40), size.width * 0.032, kp);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, bodyTop + bodyH * 0.68), width: size.width * 0.026, height: size.height * 0.07), const Radius.circular(2)),
        kp);
  }

  @override
  bool shouldRepaint(covariant ShieldPainter old) => old.a != a || old.b != b;
}

class Brand extends StatelessWidget {
  final double size;
  const Brand({super.key, this.size = 90});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: Store.lite,
      builder: (context, lite, _) => NexoraLogo(size: size, glow: !lite),
    );
  }
}

class GlobePainter extends CustomPainter {
  final Color c;
  final bool on;
  final bool lite;
  final bool busy;
  GlobePainter(this.c, this.on, this.lite, {this.busy = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final glow = on
        ? const Color(0xFF29E07F)
        : (busy ? Colors.amber : c);

    // ۱. هاله نورانی و امبینت نرم در مرکز دقیق پشت دکمه
    final maxR = (size.width < size.height ? size.width : size.height) * 0.48;
    final radialPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [
          glow.withOpacity(on ? 0.28 : (busy ? 0.22 : 0.14)),
          glow.withOpacity(on ? 0.08 : 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxR));

    canvas.drawCircle(center, maxR, radialPaint);

    // ۲. حلقه‌های متمرکز سایبرپانک و متقارن
    final r1 = 68.0; // دور دکمه
    final r2 = 96.0; // حلقه میانی
    final r3 = 126.0; // حلقه بیرونی

    final ringPaint1 = Paint()
      ..color = glow.withOpacity(on ? 0.35 : 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final ringPaint2 = Paint()
      ..color = glow.withOpacity(on ? 0.20 : 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final ringPaint3 = Paint()
      ..color = glow.withOpacity(on ? 0.12 : 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawCircle(center, r1, ringPaint1);
    canvas.drawCircle(center, r2, ringPaint2);
    if (size.height >= 190) {
      canvas.drawCircle(center, r3, ringPaint3);
    }

    // ۳. نشانگرهای رادار و تیک‌های تکنولوژی در ۴ جهت
    final tickPaint = Paint()
      ..color = glow.withOpacity(on ? 0.45 : 0.25)
      ..strokeWidth = 1.5;

    for (var angle in [0.0, pi / 2, pi, 3 * pi / 2]) {
      final dx1 = center.dx + (r2 - 6) * cos(angle);
      final dy1 = center.dy + (r2 - 6) * sin(angle);
      final dx2 = center.dx + (r2 + 6) * cos(angle);
      final dy2 = center.dy + (r2 + 6) * sin(angle);
      canvas.drawLine(Offset(dx1, dy1), Offset(dx2, dy2), tickPaint);
    }

    // ۴. در صورت فعال بودن، موج نئونی بلور
    if (on && !lite) {
      final glowWave = Paint()
        ..color = glow.withOpacity(0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(center, r1 + 3, glowWave);
    }
  }

  @override
  bool shouldRepaint(covariant GlobePainter old) =>
      old.c != c || old.on != on || old.lite != lite || old.busy != busy;
}

class MasterPowerButton extends StatefulWidget {
  final bool on;
  final bool busy;
  final ValueChanged<bool> onChanged;

  const MasterPowerButton({
    super.key,
    required this.on,
    required this.busy,
    required this.onChanged,
  });

  @override
  State<MasterPowerButton> createState() => _MasterPowerButtonState();
}

class _MasterPowerButtonState extends State<MasterPowerButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.on;
    final busy = widget.busy;

    final primaryColor = on
        ? const Color(0xFF29E07F)
        : (busy ? Colors.amber : const Color(0xFF2F8CFF));

    return MouseRegion(
      cursor: busy ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          if (!busy) widget.onChanged(!on);
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.94 : (_hovered && !busy ? 1.04 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            width: 124,
            height: 124,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 0.9,
                colors: on
                    ? const [Color(0xFF0F5A3E), Color(0xFF093928), Color(0xFF051C13)]
                    : (busy
                        ? const [Color(0xFF4A3810), Color(0xFF2E2207), Color(0xFF151003)]
                        : const [Color(0xFF1B284A), Color(0xFF0F182E), Color(0xFF070D1D)]),
              ),
              border: Border.all(
                color: primaryColor.withOpacity(_hovered ? 1.0 : 0.85),
                width: on ? 3.0 : 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(on ? (_hovered ? 0.6 : 0.45) : (_hovered ? 0.4 : 0.2)),
                  blurRadius: on ? (_hovered ? 24 : 18) : (_hovered ? 18 : 10),
                  spreadRadius: on ? 2 : 0,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (busy)
                  const SizedBox(
                    width: 76,
                    height: 76,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.amber,
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.power_settings_new_rounded,
                      size: 46,
                      color: on
                          ? const Color(0xFF29E07F)
                          : (busy ? Colors.amber : const Color(0xFF33B5FF)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      busy ? '...' : (on ? 'ON' : 'OFF'),
                      style: TextStyle(
                        color: on
                            ? const Color(0xFF29E07F)
                            : (busy ? Colors.amber : const Color(0xFF8FA6CC)),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SlideSwitch extends StatefulWidget {
  final bool on;
  final bool busy;
  final ValueChanged<bool> onChanged;
  const SlideSwitch({super.key, required this.on, required this.busy, required this.onChanged});

  @override
  State<SlideSwitch> createState() => _SlideSwitchState();
}

class _SlideSwitchState extends State<SlideSwitch> {
  static const double w = 196;
  static const double h = 82;
  static const double k = 68;
  static const double maxX = w - k - 14;
  static const Color green = Color(0xFF29E07F);
  final ValueNotifier<double> _drag = ValueNotifier(0);
  bool _dragging = false;

  @override
  void dispose() {
    _drag.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final on = widget.on;
    final target = on ? 0.0 : maxX;
    final label = widget.busy ? '...' : (on ? 'ON' : 'OFF');
    return RepaintBoundary(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MouseRegion(
          cursor: widget.busy ? SystemMouseCursors.basic : SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.busy ? null : () => widget.onChanged(!on),
            onHorizontalDragStart: (_) {
              _dragging = true;
              _drag.value = target;
            },
            onHorizontalDragUpdate: (d) => _drag.value = (_drag.value + d.delta.dx).clamp(0.0, maxX),
            onHorizontalDragEnd: (_) {
              final wantOn = _drag.value < maxX / 2;
              setState(() => _dragging = false);
              if (!widget.busy && wantOn != on) widget.onChanged(wantOn);
            },
            onHorizontalDragCancel: () => setState(() => _dragging = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: w,
              height: h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(h / 2),
              gradient: LinearGradient(
                colors: on
                    ? const [Color(0xFF0E6B4A), Color(0xFF0B3F5E)]
                    : const [Color(0xFF3A4768), Color(0xFF1C2744)],
              ),
              border: Border.all(color: on ? green : const Color(0xFF5E71A0), width: 1.5),
            ),
            child: Stack(alignment: Alignment.centerLeft, children: [
              Positioned.fill(
                child: Align(
                  alignment: on ? Alignment.centerRight : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: Text(label,
                        style: TextStyle(
                            color: on ? Colors.white : const Color(0xFFD6E2FF),
                            fontSize: 24,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: _drag,
                child: Container(
                  width: k,
                  height: k,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(colors: [Colors.white, Color(0xFFD8E6FF)]),
                    border: Border.all(color: (on ? green : p.accent2).withOpacity(0.7), width: 2),
                  ),
                  child: widget.busy
                      ? const RepaintBoundary(child: Padding(padding: EdgeInsets.all(22), child: CircularProgressIndicator(strokeWidth: 3)))
                      : Icon(Icons.power_settings_new_rounded, size: 40, color: on ? const Color(0xFF14B866) : p.accent),
                ),
                builder: (_, v, child) {
                  final x = _dragging ? v : target;
                  return AnimatedPositioned(
                    duration: Duration(milliseconds: _dragging ? 0 : 180),
                    curve: Curves.easeOutCubic,
                    left: 7 + x,
                    child: child!,
                  );
                },
              ),
            ]),
          ),
        ),
      ),
    ),
  );
  }
}

class AlertMessage extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const AlertMessage({super.key, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.red.withOpacity(0.14),
          border: Border.all(color: Colors.redAccent.withOpacity(0.7)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_rounded, color: Colors.redAccent, size: 22),
          const SizedBox(width: 10),
          Flexible(child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFFF8A8A)))),
        ]),
      ),
    );
  }
}

class DesktopSidebar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const DesktopSidebar({super.key, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    Widget item(int i, IconData ic, String t) => _SideItem(sel: i == index, icon: ic, label: t, onTap: () => onTap(i));

    return Container(
      width: 236,
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.fromLTRB(14, 24, 14, 16),
      decoration: BoxDecoration(
        color: p.card.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: p.border.withOpacity(0.6)),
      ),
      child: Column(children: [
        const Brand(size: 84),
        const SizedBox(height: 12),
        NexoraWordmark(fontSize: 20, textColor: p.text),
        const SizedBox(height: 28),
        item(0, Icons.home_rounded, 'اتصال'),
        item(1, Icons.settings_rounded, 'تنظیمات'),
        item(2, Icons.info_outline_rounded, 'اطلاعات'),
        item(3, Icons.public_rounded, 'فایرفاکس'),
        const Spacer(),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onTap(2),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: p.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.accent.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.code_rounded, size: 13, color: p.accent2),
                    const SizedBox(width: 5),
                    Text('معماران نکسورا', style: TextStyle(color: p.sub, fontSize: 10.5, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 3),
                Text('Parham × CYNET', style: TextStyle(color: p.accent2, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<VpnStatus>(
          valueListenable: VpnService.I.status,
          builder: (context, s, _) {
            final on = s.phase == Phase.on;
            final col = on ? const Color(0xFF29E07F) : (s.phase == Phase.connecting ? Colors.amber : p.sub);
            return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(on ? 'متصل' : (s.phase == Phase.connecting ? 'در حال اتصال...' : 'قطع'), style: TextStyle(color: col, fontSize: 13, fontWeight: FontWeight.w700)),
            ]);
          },
        ),
      ]),
    );
  }
}

class NavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const NavBar({super.key, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    Widget item(int i, IconData ic, String t) {
      final sel = i == index;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(i),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(ic, color: sel ? p.accent2 : p.sub, size: 26),
              const SizedBox(height: 3),
              Text(t, style: TextStyle(color: sel ? p.text : p.sub, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(color: p.card, border: Border(top: BorderSide(color: p.border.withOpacity(0.6)))),
        child: Row(children: [
          item(0, Icons.home_rounded, 'اتصال'),
          item(1, Icons.settings_rounded, 'تنظیمات'),
          item(2, Icons.info_outline_rounded, 'اطلاعات'),
          item(3, Icons.public_rounded, 'فایرفاکس'),
        ]),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool back;
  final Color? iconColor;
  const PageHeader({super.key, required this.title, required this.icon, this.back = false, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 14, 10),
        child: Row(children: [
          SizedBox(
            width: 44,
            child: back
                ? IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: Icon(Icons.chevron_left_rounded, color: p.text, size: 34),
                  )
                : null,
          ),
          Expanded(child: Center(child: Text(title, style: TextStyle(color: p.text, fontSize: 20, fontWeight: FontWeight.w800)))),
          SizedBox(width: 44, child: Icon(icon, color: iconColor ?? p.accent2, size: 28)),
        ]),
      ),
    );
  }
}

class SubPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const SubPage({super.key, required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: AppBg(
        child: SafeArea(
          child: Column(children: [
            PageHeader(title: title, icon: icon, back: true),
            Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: children)),
          ]),
        ),
      ),
    );
  }
}


// ───────────────────────── افکت‌های آیفون / ویندوز ─────────────────────────
class _SideItem extends StatefulWidget {
  final bool sel;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SideItem({required this.sel, required this.icon, required this.label, required this.onTap});

  @override
  State<_SideItem> createState() => _SideItemState();
}

class _SideItemState extends State<_SideItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final sel = widget.sel;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: sel ? p.accent.withOpacity(0.22) : (_hover ? p.accent.withOpacity(0.09) : Colors.transparent),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sel ? p.accent2.withOpacity(0.75) : Colors.transparent),
            boxShadow: sel ? [BoxShadow(color: p.accent2.withOpacity(0.25), blurRadius: 14)] : null,
          ),
          child: Row(children: [
            AnimatedScale(
              scale: _hover || sel ? 1.14 : 1.0,
              duration: const Duration(milliseconds: 180),
              child: Icon(widget.icon, color: sel ? p.accent2 : p.sub, size: 24),
            ),
            const SizedBox(width: 12),
            Text(widget.label, style: TextStyle(color: sel || _hover ? p.text : p.sub, fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}

// پس‌زمینه‌ی آرورا: سه هاله‌ی رنگی که آرام حرکت می‌کنند (فقط گرادیان؛ سبک)
class _Aurora extends StatefulWidget {
  const _Aurora();

  @override
  State<_Aurora> createState() => _AuroraState();
}

class _AuroraState extends State<_Aurora> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(painter: _AuroraPainter(_c.value, p.accent, p.accent2), size: Size.infinite),
        ),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double t;
  final Color a, b;
  _AuroraPainter(this.t, this.a, this.b);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final r = max(w, h) * 0.5;
    void blob(double ph, double fx, double fy, Color c, double op) {
      final cx = w * (0.5 + 0.38 * sin(2 * pi * (t * fx + ph)));
      final cy = h * (0.45 + 0.32 * cos(2 * pi * (t * fy + ph * 1.7)));
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()..shader = RadialGradient(colors: [c.withOpacity(op), c.withOpacity(0)]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
      );
    }

    blob(0.00, 1, 1, a, 0.20);
    blob(0.35, 2, 1, b, 0.13);
    blob(0.70, 1, 2, const Color(0xFF7A5CFF), 0.12);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) => old.t != t;
}

// موج‌های سبز دور دکمه‌ی اتصال وقتی وصل هستی
class PulseRings extends StatefulWidget {
  final Color color;
  const PulseRings({super.key, required this.color});

  @override
  State<PulseRings> createState() => _PulseRingsState();
}

class _PulseRingsState extends State<PulseRings> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) => CustomPaint(painter: _RingsPainter(_c.value, widget.color), size: Size.infinite),
          ),
        ),
      );
}

class _RingsPainter extends CustomPainter {
  final double t;
  final Color c;
  _RingsPainter(this.t, this.c);

  @override
  void paint(Canvas canvas, Size size) {
    final ctr = size.center(Offset.zero);
    for (var i = 0; i < 3; i++) {
      final k = (t + i / 3) % 1.0;
      canvas.drawCircle(
        ctr,
        46 + k * 120,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 * (1 - k) + 0.4
          ..color = c.withOpacity(0.5 * (1 - k)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) => old.t != t;
}
