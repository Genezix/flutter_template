import 'package:flutter/material.dart';
import 'package:flutter_template/counter/counter.dart';
import 'package:rive/src/rive_core/text/text_style.dart' as riveStyle;
import 'package:flutter_template/l10n/l10n.dart';
import 'package:rive/rive.dart';

import '../animation.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Inter',
        appBarTheme: AppBarTheme(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // home: RiveAnimation.asset(
      //   'assets/rating_animation.riv',
      //   animations: const ['Example'],
      //   // stateMachines: ['Idle_empty'],
      //   // onInit: (artboard) {
      //   //   final textRun = artboard.textRun('user_name')!; // find text run named "MyRun"
      //   //   print('Run text used to be ${textRun.text}');
      //   //   textRun.text = 'Coucou Jean Claude!';
      //   // },
      // ),
      home: BasicText(),
    );
  }
}
