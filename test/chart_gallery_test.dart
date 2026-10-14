import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_companion/features/dev/chart_gallery_screen.dart';

void main() {
  testWidgets('gallery fits 360 and 430 at text scale 1.3', (tester) async {
    for (final size in const [Size(360, 800), Size(430, 932)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size, textScaler: const TextScaler.linear(1.3)),
          child: const MaterialApp(home: ChartGalleryScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.drag(find.byType(ListView), const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
