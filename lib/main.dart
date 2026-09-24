import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/ezan_app.dart';
import 'infrastructure/time/time_zone_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  TimeZoneDatabase.ensureInitialized();
  runApp(const ProviderScope(child: EzanApp()));
}
