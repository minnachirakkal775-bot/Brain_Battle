
import 'package:flutter_test/flutter_test.dart';

import 'package:brain_battle/main.dart';

void main() {
testWidgets('Brain Battle app loads', (WidgetTester tester) async {
await tester.pumpWidget(const BrainBattleApp());

expect(find.text('Brain Battle'), findsOneWidget);
expect(
find.text('Think Fast. Train Smart. Beat Your Best.'),
findsOneWidget,
);
});
}
