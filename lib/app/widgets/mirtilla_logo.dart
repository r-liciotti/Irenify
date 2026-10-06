import 'package:flutter/material.dart';

/// Logo dell'app: Mirtilla dal concept 2, con la cornice (D-55). Solo
/// decorativo: il nome dell'app è sempre scritto accanto.
class MirtillaLogo extends StatelessWidget {
  const MirtillaLogo({this.size = 48, super.key});

  static const assetPath = 'assets/branding/mirtilla.png';

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    assetPath,
    width: size,
    height: size,
    excludeFromSemantics: true,
  );
}
