import 'package:flutter/widgets.dart';

import 'src/application/miaonotes_application.dart';
import 'src/ui/miaonotes_bootstrap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MiaoNotesBootstrap(openApplication: MiaoNotesApplication.open));
}
