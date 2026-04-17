import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.colorFilter,
  });

  static const _lightLogoPath = 'assets/images/logo.svg';
  static const _darkLogoPath = 'assets/images/logo white.svg';

  final double? width;
  final double? height;
  final BoxFit fit;
  final ColorFilter? colorFilter;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final assetPath = brightness == Brightness.dark ? _darkLogoPath : _lightLogoPath;

    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      colorFilter: colorFilter,
    );
  }
}
