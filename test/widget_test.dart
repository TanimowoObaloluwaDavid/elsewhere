import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elsewhere/app.dart';
import 'package:elsewhere/state/journal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('journal keeps and removes a place', () async {
    SharedPreferences.setMockInitialValues({});
    final journal = JournalController();
    await journal.load();

    expect(journal.isSaved('kyoto'), isFalse);
    await journal.toggle('kyoto');
    expect(journal.isSaved('kyoto'), isTrue);
    expect(journal.count, 1);
    await journal.toggle('kyoto');
    expect(journal.isSaved('kyoto'), isFalse);
    expect(journal.count, 0);
  });

  testWidgets('the journal opens on the home screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final journal = JournalController();
    await journal.load();

    await tester.pumpWidget(
      ChangeNotifierProvider<JournalController>.value(
        value: journal,
        child: const ElsewhereApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Recently collected'), findsOneWidget);
    expect(find.text('ISSUE 07'), findsOneWidget);
  });
}
