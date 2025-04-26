// screens/rive_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

class RiveTestScreen extends StatefulWidget {
  const RiveTestScreen({Key? key}) : super(key: key);

  @override
  State<RiveTestScreen> createState() => _RiveTestScreenState();
}

class _RiveTestScreenState extends State<RiveTestScreen> {
  Artboard? _artboard;
  StateMachineController? _controller;

  // Example inputs (customize based on your .riv file)
  SMITrigger? _trigger;
  SMIBool? _toggle;
  SMINumber? _speed;

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

      // Try common state machine names if unsure
      final controller = StateMachineController.fromArtboard(
        artboard,
        'State Machine 1', // Replace with your state machine name
      );

      if (controller != null) {
        artboard.addController(controller);
        _controller = controller;

        // Discover inputs (print for debugging)
        print('Available inputs:');
        for (final input in controller.inputs) {
          print('- ${input.name} (${input.runtimeType})');
        }

        // Get references to inputs (customize these names)
        _trigger = controller.findInput('trigger') as SMITrigger?;
        _toggle = controller.findInput('isActive') as SMIBool?;
        _speed = controller.findInput('speed') as SMINumber?;
      }

      setState(() => _artboard = artboard);
    } catch (e) {
      print('Error loading Rive file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rive State Machine Demo')),
      body: Center(
        child:
            _artboard == null
                ? const CircularProgressIndicator()
                : Rive(artboard: _artboard!),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Example trigger button
          FloatingActionButton(
            onPressed: () => _trigger?.fire(),
            child: const Icon(Icons.bolt),
            tooltip: 'Fire Trigger',
          ),
          const SizedBox(height: 10),
          // Example toggle button
          FloatingActionButton(
            onPressed: () => _toggle?.value = !(_toggle?.value ?? false),
            child: const Icon(Icons.toggle_on),
            tooltip: 'Toggle State',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
