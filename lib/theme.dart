import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Semantic tokens from the ForgeX logo (orange -> amber on black).
class FX {
  static const bg = Color(0xFF0A0A0B);
  static const surface = Color(0xFF141416);
  static const surface2 = Color(0xFF1D1D21);
  static const border = Color(0xFF2A2A30);
  static const orange = Color(0xFFFF6A00);
  static const amber = Color(0xFFFFB800);
  static const text = Color(0xFFFFFFFF);
  static const muted = Color(0xFFA1A1AA); // 7.6:1 on bg
  static const live = Color(0xFFEF4444);
  static const grad = LinearGradient(
      colors: [orange, amber], begin: Alignment.bottomLeft, end: Alignment.topRight);

  static ThemeData theme() {
    final base = ThemeData.dark(useMaterial3: true);
    final body = GoogleFonts.interTextTheme(base.textTheme);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
          primary: orange, secondary: amber, surface: surface, onPrimary: Colors.black),
      textTheme: body.copyWith(
        headlineMedium: GoogleFonts.exo2(fontSize: 28, fontWeight: FontWeight.w800, color: text),
        titleLarge: GoogleFonts.exo2(fontSize: 20, fontWeight: FontWeight.w700, color: text),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: orange.withOpacity(.18),
        labelTextStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: orange, width: 2)),
      ),
    );
  }
}

class GradButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  const GradButton(this.label, {super.key, this.onTap, this.icon});
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Opacity(
          opacity: onTap == null ? .4 : 1,
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                  gradient: FX.grad, borderRadius: BorderRadius.circular(14)),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onTap,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 52),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (icon != null) ...[Icon(icon, color: Colors.black, size: 20), const SizedBox(width: 8)],
                    Text(label,
                        style: GoogleFonts.exo2(
                            color: Colors.black, fontWeight: FontWeight.w800, fontSize: 16)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}
