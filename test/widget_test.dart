import 'package:flutter_test/flutter_test.dart';
import 'package:nestly/main.dart';

void main() {
  testWidgets('Nestly home shows family hub and feature tiles', (tester) async {
    await tester.pumpWidget(const NestlyApp());
    await tester.pumpAndSettle();

    expect(find.text('The Ibrahims'), findsWidgets);
    expect(find.text('Lists'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Tasks'), findsWidgets);
  });
}
