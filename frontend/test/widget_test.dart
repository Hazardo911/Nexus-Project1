import 'package:exercise_form_frontend/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app loads home screen', (tester) async {
    await tester.pumpWidget(const ExerciseFormApp());

    expect(find.text('Exercise Form Detector'), findsOneWidget);
    expect(find.text('Start Analysis'), findsOneWidget);
  });
}
