import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:rive/rive.dart';

/// Basic example playing a Rive animation from a packaged asset.
class BasicText extends StatefulWidget {
  const BasicText({Key? key}) : super(key: key);

  @override
  State<BasicText> createState() => _BasicTextState();
}

class _BasicTextState extends State<BasicText> {
  Artboard? _mainArtboard;
  RiveFile? _file;
  late RiveAnimationController<RuntimeArtboard> _controller;
  late List<RiveAnimationController<RuntimeArtboard>> _currentControllers;
  late TextValueRun? _dynamicTextController;
  late SMITrigger? trigger;
  late StateMachineController? stateMachineController;
  late List<String> allAnimations;
  late List<String> loopAnimations;
  late List<String> selectedAnimations = [];
  late String currentAnimation;
  late AnimationScreenData currentAnimationScreenData;
  late List<AnimationScreenData> animationScreenDatas;
  final TextEditingController _fieldController = TextEditingController();
  bool isPause = false;

  /// Tracks if the animation is playing by whether controller is running
  bool get isPlaying => _controller.isActive;

  @override
  void initState() {
    super.initState();
    _controller = SimpleAnimation('TextWave');
    _loadRiveFile();
  }

  Future<void> _loadRiveFile({String? newText}) async {
    final fontData = await rootBundle.load('assets/Inter-594377.ttf');
    final body = Uint8List.view(fontData.buffer);
    final font = await FontAsset.parseBytes(body);

    // Load asset https://help.rive.app/runtimes/loading-assets
    _file = await RiveFile.asset(
      'assets/retrainspective_2024_clean.riv',
      // Charger les fonts
      assetLoader: CallbackAssetLoader(
        (asset, bytes) async {
          if (asset is FontAsset) {
            // Set la font
            asset.font = font;
            return true;
          }
          return false;
        },
      ),
    );

    _mainArtboard = _file!.mainArtboard;
    final List<Artboard> artboards = _file!.artboards.where((element) => element != _mainArtboard).toList();

    animationScreenDatas = artboards.map((artboard) {
      // Animation
      final animationNames = artboard.linearAnimations.map((element) => element.name).toList();
      // Animation controller
      final controllers = animationNames
          .map(
            (name) => CustomOneShotAnimation(
              name,
              onStop: () => nextAnimation(comeFromOnStop: true),
            ),
          )
          .toList();

      return AnimationScreenData(
        animationNames: animationNames,
        animationControllers: controllers,
        artboard: artboard,
      );
      // Texts run ???
    }).toList();

    final textRun = _mainArtboard?.component<TextValueRun>('Nom Region');
    final components = artboards.forEach((artboard) {
      final region = artboard.component<TextValueRun>('Nom Region');
      if (region != null) region.text = 'Ile de France';
      final number = artboard.component<TextValueRun>('number');
      if (number != null) number.text = '12678';
      artboard.components.whereType<TextValueRun>().forEach((element) {
        print('${element.name} => ${element.text}');
      });
    });

    allAnimations = _mainArtboard!.linearAnimations.map((e) => e.name).toList();

    currentAnimation = allAnimations.first;

    // Remplace le texte
    // if (newText != null) textRun?.text = 'Ma bite';

    setState(() {
      currentAnimationScreenData =
          animationScreenDatas.firstWhere((element) => element.animationNames.contains(currentAnimation));
      _mainArtboard = currentAnimationScreenData.artboard;
    });
  }

  void setDynamicText(String newText) {
    setState(() {
      _loadRiveFile(newText: newText);
    });
  }

  /// Toggles between play and pause animation states
  void _togglePlay() => setState(() {
        if (currentAnimationScreenData.animationControllers.any((element) => element.isActive)) {
          isPause = true;
          setState(() {
            currentAnimationScreenData.animationControllers.forEach((element) {
              element.isActive = false;
            });
          });
        } else if (isPause) {
          isPause = false;
          setState(() {
            currentAnimationScreenData.animationControllers.forEach((element) {
              element.isActive = true;
            });
          });
        }
      });

  void nextAnimation({bool comeFromOnStop = false}) {
    if (!isPause || !comeFromOnStop) {
      isPause = false;
      final index = allAnimations.indexOf(currentAnimation);

      if (index + 1 < allAnimations.length) {
        currentAnimation = allAnimations[index + 1];

        setState(() {
          currentAnimationScreenData =
              animationScreenDatas.firstWhere((element) => element.animationNames.contains(currentAnimation));
          currentAnimationScreenData.animationControllers.forEach((element) {
            element.isActive = true;
          });
        });
      }
    }
  }

  void previousAnimation() {
    final index = allAnimations.indexOf(currentAnimation);

    if (index - 1 >= 0) {
      currentAnimation = allAnimations[index - 1];

      setState(() {
        currentAnimationScreenData =
            animationScreenDatas.firstWhere((element) => element.animationNames.contains(currentAnimation));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POC RIVE'),
      ),
      body: SingleChildScrollView(
        child: _mainArtboard != null
            ? Column(
                children: [
                  Container(
                    height: 600,
                    child: RiveAnimation.direct(
                      _file!,
                      artboard: currentAnimationScreenData.artboard.name,
                      // animations: currentAnimationScreenData.animationNames,
                      controllers: currentAnimationScreenData.animationControllers,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      InkWell(
                        onTap: previousAnimation,
                        child: Card(
                          child: Container(
                            width: 70,
                            height: 70,
                            child: Center(
                              child: Text('Previous'),
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _togglePlay,
                        child: Card(
                          child: Container(
                            width: 70,
                            height: 70,
                            child: Center(
                              child: Text(
                                  currentAnimationScreenData.animationControllers.any((element) => element.isActive)
                                      ? 'Pause'
                                      : 'Start'),
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: nextAnimation,
                        child: Card(
                          child: Container(
                            width: 70,
                            height: 70,
                            child: Center(
                              child: Text('Next'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class AnimationScreenData {
  AnimationScreenData({
    required this.animationNames,
    required this.animationControllers,
    required this.artboard,
    // required this.textRuns,
  });

  final List<String> animationNames;
  final List<SimpleAnimation> animationControllers;
  final Artboard artboard;
// final List<TextValueRun> textRuns;
}

extension _TextExtension on Artboard {
  TextValueRun? textRun(String name) => component<TextValueRun>(name);
}

/// This allows a value of type T or T?
/// to be treated as a value of type T?.
///
/// We use this so that APIs that have become
/// non-nullable can still be used with `!` and `?`
/// to support older versions of the API as well.
T? _ambiguate<T>(T? value) => value;

/// Controller tailored for managing one-shot animations
class CustomOneShotAnimation extends SimpleAnimation {
  /// Fires when the animation stops being active
  final VoidCallback? onStop;

  /// Fires when the animation starts being active
  final VoidCallback? onStart;

  CustomOneShotAnimation(
    String animationName, {
    double mix = 1,
    bool autoplay = true,
    this.onStop,
    this.onStart,
  }) : super(animationName, mix: mix, autoplay: autoplay) {
    isActiveChanged.addListener(onActiveChanged);
  }

  /// Dispose of any callback listeners
  @override
  void dispose() {
    isActiveChanged.removeListener(onActiveChanged);
    super.dispose();
  }

  /// Perform tasks when the animation's active state changes
  void onActiveChanged() {
    // Fire any callbacks
    isActive
        ? onStart?.call()
        // onStop can fire while widgets are still drawing
        : _ambiguate(WidgetsBinding.instance)?.addPostFrameCallback((_) => onStop?.call());
  }
}
