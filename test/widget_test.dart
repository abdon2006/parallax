import 'package:flutter_test/flutter_test.dart';
import 'package:parallax/main.dart';

void main() {
  testWidgets('app boots and shows the brand name', (tester) async {
    await tester.pumpWidget(const ParallaxApp());

    expect(find.text('Parallax'), findsOneWidget);
  });
}
