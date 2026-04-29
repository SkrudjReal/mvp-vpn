import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.width, this.height, this.fit = BoxFit.contain, this.color});

  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: FittedBox(
          fit: fit,
          child: Text(
            "noda.",
            style: GoogleFonts.cookie(
              fontSize: 60, // large base size, FittedBox will scale it down/up
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              height: 1.0,
              color: color ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
