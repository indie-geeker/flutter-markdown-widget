import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown_widget_example/pages/toc_demo_page.dart';

void main() {
  Future<void> jumpFromTocAndExpectHeadingNearTop(
    WidgetTester tester, {
    required String heading,
  }) async {
    final tocFinder = find.descendant(
      of: find.byType(TocListWidget).first,
      matching: find.textContaining(heading),
    );
    expect(tocFinder, findsOneWidget);

    await tester.tap(tocFinder);
    await tester.pumpAndSettle();

    final contentHeadingFinder = find.descendant(
      of: find.byType(MarkdownWidget),
      matching: find.textContaining(heading),
    );
    expect(contentHeadingFinder, findsOneWidget);

    final markdownTop = tester.getTopLeft(find.byType(MarkdownWidget)).dy;
    final headingTop = tester.getTopLeft(contentHeadingFinder).dy;
    expect(
      headingTop - markdownTop,
      lessThan(180),
      reason: 'Heading "$heading" should be near top after TOC jump.',
    );
  }

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

  testWidgets('TOC sheet does not overflow on shorter viewports',
      (tester) async {
    tester.view
      ..physicalSize = const Size(900, 600)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: TocDemoPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Open'));
    await tester.pumpAndSettle();

    expect(find.text('Table of Contents'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'TOC jumps still work after switching between wide and narrow layouts',
      (tester) async {
    tester.view
      ..physicalSize = const Size(1200, 900)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: TocDemoPage()));
    await tester.pumpAndSettle();

    await jumpFromTocAndExpectHeadingNearTop(
      tester,
      heading: '2.2 Streaming Content',
    );

    tester.view.physicalSize = const Size(900, 900);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Open'));
    await tester.pumpAndSettle();

    await jumpFromTocAndExpectHeadingNearTop(
      tester,
      heading: '3.2 TOC Generation',
    );

    tester.view.physicalSize = const Size(1200, 900);
    await tester.pumpAndSettle();

    if (find.byType(BottomSheet).evaluate().isNotEmpty) {
      await tester.tapAt(const Offset(24, 24));
      await tester.pumpAndSettle();
    }

    await jumpFromTocAndExpectHeadingNearTop(
      tester,
      heading: '1.1.2 Installation',
    );
  });
}
