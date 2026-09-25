import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/ezan_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: EzanApp()));
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}
