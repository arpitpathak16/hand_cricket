import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

class HandAnimationWidget extends StatefulWidget {
  final String animationName;

  const HandAnimationWidget({super.key, required this.animationName});

  @override
  State<HandAnimationWidget> createState() => _HandAnimationWidgetState();
}

class _HandAnimationWidgetState extends State<HandAnimationWidget> {
  Artboard? _artboard;
  SimpleAnimation? _animationController;

  @override
  void initState() {
    super.initState();
    _loadRiveFile();
  }

  Future<void> _loadRiveFile() async {
    try {
      final data = await rootBundle.load('../../assets/riv/hand.riv');
      final file = RiveFile.import(data);
      final artboard = file.mainArtboard;

      _updateAnimationController(artboard);

      setState(() => _artboard = artboard);
    } catch (e) {
      debugPrint('Error loading Rive file: $e');
    }
  }

  void _updateAnimationController(Artboard artboard) {
    // Dispose previous controller
    _animationController?.isActive = false;
    artboard.removeController(_animationController!);

    // Create new controller
    _animationController = SimpleAnimation(widget.animationName);
    if (_animationController != null) {
      artboard.addController(_animationController!);
    } else {
      debugPrint('Animation "${widget.animationName}" not found in Rive file');
    }
  }

  @override
  void didUpdateWidget(covariant HandAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animationName != widget.animationName && _artboard != null) {
      _updateAnimationController(_artboard!);
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _artboard == null
        ? const SizedBox.square(dimension: 150) // Better placeholder
        : Rive(artboard: _artboard!, fit: BoxFit.contain);
  }
}
