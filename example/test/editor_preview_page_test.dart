import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown_widget_example/pages/editor_preview_page.dart';

void main() {
  testWidgets('switches between editor and preview on narrow screens', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(900, 1600)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: EditorPreviewPage()));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Write markdown content'), findsOneWidget);

    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Write markdown content'), findsNothing);
    expect(find.textContaining('chars'), findsOneWidget);

    await tester.tap(find.text('Editor'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Write markdown content'), findsOneWidget);
  });
}
