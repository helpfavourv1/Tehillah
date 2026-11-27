import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tehillah/app/app.dart';
import 'package:tehillah/app/boot.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final Boot started = await boot();
  runApp(TehillahApp(services: started.services, errors: started.errors));
}
