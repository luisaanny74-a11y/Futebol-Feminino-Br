import 'package:flutter/material.dart';

/// Pontos de quebra usados no app.
class Breakpoints {
  /// A partir daqui a navegação inferior vira NavigationRail lateral.
  static const double rail = 800;

  /// Largura máxima do conteúdo (evita linhas enormes em monitores grandes).
  static const double content = 1100;
}

/// Imagem responsiva: escolhe a variante `_sm` (480 px de largura) ou `_lg`
/// (tamanho original, ~735 px) conforme a largura disponível × densidade de
/// pixels da tela. Assim celulares baixam/decodificam menos dados e telas
/// grandes mantêm nitidez, sem nunca fazer upscaling.
class ResponsiveAsset extends StatelessWidget {
  const ResponsiveAsset(
    this.name, {
    super.key,
    this.alignment = Alignment.center,
    this.semanticLabel,
  });

  /// Nome base, ex.: `banner_partidas`.
  final String name;
  final Alignment alignment;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final width = box.maxWidth.isFinite
          ? box.maxWidth
          : MediaQuery.sizeOf(context).width;
      final pixels = width * MediaQuery.devicePixelRatioOf(context);
      final variant = pixels > 480 ? 'lg' : 'sm';
      return Image.asset(
        'assets/images/${name}_$variant.jpg',
        fit: BoxFit.cover,
        alignment: alignment,
        width: double.infinity,
        height: double.infinity,
        semanticLabel: semanticLabel,
        excludeFromSemantics: semanticLabel == null,
        gaplessPlayback: true,
      );
    });
  }
}
