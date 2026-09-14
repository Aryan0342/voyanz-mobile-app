import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// Canonical in-app Voyanz lockup.
///
/// The symbol is the official static brand asset. The wordmark is rendered as
/// text so the product name can never be replaced by stale outlined lettering
/// embedded in an older logo file.
class VoyanzBrandLogo extends StatelessWidget {
  final double width;
  final Color wordmarkColor;

  const VoyanzBrandLogo({
    super.key,
    required this.width,
    this.wordmarkColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Voyanz',
      image: true,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/voyanz-official-mark.svg',
              width: width * .55,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
            SizedBox(height: width * .025),
            Text(
              'VOYANZ',
              maxLines: 1,
              style: GoogleFonts.lora(
                fontSize: width * .17,
                fontWeight: FontWeight.w600,
                letterSpacing: width * .025,
                color: wordmarkColor,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
