import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futebol_feminino_br/core/theme.dart';
import 'package:futebol_feminino_br/widgets/common.dart';

void main() {
  testWidgets('NeonCard renderiza o conteúdo com o tema do app', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: const Scaffold(body: NeonCard(child: Text('Tigres FC'))),
    ));
    expect(find.text('Tigres FC'), findsOneWidget);
  });
}
