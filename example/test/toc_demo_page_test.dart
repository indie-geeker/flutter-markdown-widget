import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown_widget_example/pages/toc_demo_page.dart';

void main() {
  testWidgets('opens TOC and supports basic interactions', (tester) async {
    tester.view
      ..physicalSize = const Size(900, 1600)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: TocDemoPage()));
    await tester.pumpAndSettle();

    final syncSwitchFinder = find.byType(Switch).first;
    expect(tester.widget<Switch>(syncSwitchFinder).value, isFalse);

    await tester.tap(syncSwitchFinder);
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(syncSwitchFinder).value, isTrue);

    await tester.tap(find.widgetWithText(TextButton, 'Open'));
    await tester.pumpAndSettle();

    expect(find.text('Table of Contents'), findsOneWidget);

    final tocHeadingFinder = find.descendant(
      of: find.byType(TocListWidget).first,
      matching: find.textContaining('Chapter 2'),
    );
    expect(tocHeadingFinder, findsOneWidget);

    await tester.tap(tocHeadingFinder);
    await tester.pumpAndSettle();

    expect(find.text('Table of Contents'), findsOneWidget);
  });
}
