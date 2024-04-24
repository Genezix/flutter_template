import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:rive/rive.dart';

/// Basic example playing a Rive animation from a packaged asset.
class BasicText extends StatefulWidget {
  const BasicText({Key? key}) : super(key: key);

  @override
  State<BasicText> createState() => _BasicTextState();
}

class _BasicTextState extends State<BasicText> {
  Artboard? _artboard;
  RiveFile? _file;
  late RiveAnimationController<RuntimeArtboard> _controller;
  late TextValueRun? _dynamicTextController;
  late SMITrigger? trigger;
  late StateMachineController? stateMachineController;
  late List<String> animations;
  late List<String> loopAnimations;
  late List<String> selectedAnimations = [];
  final TextEditingController _fieldController = TextEditingController();

  /// Toggles between play and pause animation states
  void _togglePlay() => setState(() => _controller.isActive = !_controller.isActive);

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

    _file = await RiveFile.asset(
      'assets/rating_animation.riv',
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

    final Artboard artboard = _file!.mainArtboard;
    final textRun = artboard.textRun('user_name');

    animations = artboard.animations.values.map((e) => e.name).toList();

    // Remplace le texte
    if (newText != null) textRun?.text = newText;

    setState(() => _artboard = artboard);
  }

  void setDynamicText(String newText) {
    setState(() {
      _loadRiveFile(newText: newText);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POC RIVE'),
      ),
      body: SingleChildScrollView(
        child: _artboard != null
            ? Column(
                children: [
                  Container(
                    height: 300,
                    child: RiveAnimation.direct(
                      _file!,
                      animations: selectedAnimations,
                      controllers: [_controller],
                    ),
                  ),
                  // Expanded(
                  //     child: Rive(
                  //   artboard: _artboard!,
                  //   fit: BoxFit.contain,
                  // )),
                  Container(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: List.generate(
                        animations.length,
                        (index) => Row(
                          children: [
                            Checkbox(
                              value: selectedAnimations.contains(animations[index]),
                              onChanged: (value) {
                                setState(() {
                                  if (value ?? false) {
                                    selectedAnimations.add(animations[index]);
                                  } else {
                                    selectedAnimations.remove(animations[index]);
                                  }
                                });

                                _loadRiveFile(newText: _fieldController.text.isEmpty ? null : _fieldController.text);
                              },
                            ),
                            Text(animations[index]),
                          ],
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
                          child: Text(_controller.isActive ? 'Pause' : 'Start'),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: _fieldController,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: InkWell(
                          child: Card(
                            child: Container(
                              width: 70,
                              height: 70,
                              child: Center(
                                child: Text('Update'),
                              ),
                            ),
                          ),
                          onTap: () => setDynamicText(_fieldController.text),
                        ),
                      ),
                    ],
                  )
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

extension _TextExtension on Artboard {
  TextValueRun? textRun(String name) => component<TextValueRun>(name);
}
