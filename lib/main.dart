import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'state/journal.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final journal = JournalController();
  await journal.load();
  runApp(
    ChangeNotifierProvider<JournalController>.value(
      value: journal,
      child: const ElsewhereApp(),
    ),
  );
}
