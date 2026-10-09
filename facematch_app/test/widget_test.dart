
import 'package:flutter_test/flutter_test.dart';
import 'package:facematch_app/main.dart';

void main() {
  testWidgets('FaceMatch app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const FaceMatchApp());

    expect(find.text('FaceMatch'), findsOneWidget);
  });
}
