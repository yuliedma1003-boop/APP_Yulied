import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titanfit/theme.dart';
import 'package:titanfit/widgets/titan_ui.dart';

void main() {
  testWidgets('marca y título de TitanFit se renderizan', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TitanTheme.dark(),
        home: const Scaffold(
          body: Column(
            children: [
              DumbbellMark(size: 40),
              DisplayTitle('TITANFIT'),
            ],
          ),
        ),
      ),
    );
    expect(find.text('TITANFIT'), findsOneWidget);
  });
}
