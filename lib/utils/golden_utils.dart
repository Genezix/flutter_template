import 'package:flutter/material.dart';
import 'package:flutter_template/app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

const _defaultWidth = 375.0;

const Device smallPhone = Device(
  name: 'smallPhone',
  size: Size(375, 667),
  safeArea: EdgeInsets.only(top: 44, bottom: 34),
);

const Device smallPhoneWithZoom2 = Device(
  name: 'smallPhoneTextScale2',
  size: Size(375, 667),
  textScale: 2.0,
  safeArea: EdgeInsets.only(top: 44, bottom: 34),
);

void heliosTestGoldensWithTextScale(String title, {required Widget widget, required double height, double? width}) {
  GoldenBuilder builder(Color color) => GoldenBuilder.column(bgColor: color)
    ..addScenario('Default font size', widget)
    ..addTextScaleScenario('Large font size', widget, textScaleFactor: 2.0)
    ..addTextScaleScenario('Largest font', widget);

  _heliosTestGoldens(title,
      widget: builder(Colors.white).build(), height: height, width: width, themeMode: ThemeMode.light);
  _heliosTestGoldens(title,
      widget: builder(Colors.black).build(), height: height, width: width, themeMode: ThemeMode.dark);
}

void heliosSimpleTestGoldens(String title, {required Widget widget, required double height, double? width}) {
  _heliosTestGoldens(title, widget: widget, height: height, width: width, themeMode: ThemeMode.light);
  _heliosTestGoldens(title, widget: widget, height: height, width: width, themeMode: ThemeMode.dark);
}

void heliosScreenTestGoldens(
  String title, {
  Function(WidgetTester)? initScreen,
  required Widget widget,
  int? waitDurationForAnimationInMs,
}) {
  void heliosTest(ThemeMode mode, List<Device> devices) => _runTestGoldens(
        title: title,
        widget: widget,
        mode: mode,
        test: (tester) async {
          await initScreen?.call(tester);
          await multiScreenGolden(
            tester,
            '${title}_${mode.name}',
            autoHeight: true,
            devices: devices,
            customPump: waitDurationForAnimationInMs != null
                ? (tester) async => tester.pump(
                      // We need to provide a duration to make the fake timer
                      // advance, otherwise it remains on the 0 time slot and
                      // raises an exception.
                      Duration(milliseconds: waitDurationForAnimationInMs),
                    )
                : null,
          );
        },
      );

  heliosTest(ThemeMode.light, [Device.iphone11, smallPhone, smallPhoneWithZoom2]);
  heliosTest(ThemeMode.dark, [Device.iphone11]);
}

void _heliosTestGoldens(String title,
    {required Widget widget, required double height, double? width, required ThemeMode themeMode}) {
  _runTestGoldens(
    title: title,
    widget: widget,
    surfaceSize: Size(width ?? _defaultWidth, height),
    mode: themeMode,
    test: (tester) async {
      await screenMatchesGolden(
        tester,
        '${title}_${themeMode.name}',
      );
    },
  );
}

void _runTestGoldens({
  required String title,
  required Widget widget,
  required Function(WidgetTester) test,
  required ThemeMode mode,
  Size? surfaceSize,
}) {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoldenToolkit.runWithConfiguration(
    () async {
      return testGoldens(
        '${title}_${mode.name}',
        (tester) async {
          await loadAppFonts();
          await tester.pumpWidgetBuilder(
            widget,
            wrapper: _materialAppWrapper(mode: mode),
            surfaceSize: surfaceSize ?? const Size(800, 600),
          );
          await test.call(tester);
        },
        tags: 'goldens',
      );
    },
    config: GoldenToolkitConfiguration(
      enableRealShadows: true,
    ),
  );
}

WidgetWrapper _materialAppWrapper({
  TargetPlatform platform = TargetPlatform.android,
  Iterable<LocalizationsDelegate<dynamic>>? localizations,
  NavigatorObserver? navigatorObserver,
  Iterable<Locale>? localeOverrides,
  ThemeMode? mode = ThemeMode.light,
}) {
  return (child) => MaterialApp(
        localizationsDelegates: localizations,
        supportedLocales: localeOverrides ?? const [Locale('en')],
        // theme: lightTheme().copyWith(platform: platform),
        // darkTheme: darkTheme().copyWith(platform: platform),
        themeMode: mode,
        debugShowCheckedModeBanner: false,
        home: Material(child: child),
        navigatorObservers: [
          if (navigatorObserver != null) navigatorObserver,
        ],
      );
}
