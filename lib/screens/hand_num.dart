import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

class HandNumberSelector extends StatefulWidget {
  const HandNumberSelector({super.key});

  @override
  State<HandNumberSelector> createState() => _HandNumberSelectorState();
}

class _HandNumberSelectorState extends State<HandNumberSelector> {
  Artboard? _artboard;
  StateMachineController? _controller;
  SMINumber? _numberInput;

  @override
  void initState() {
    super.initState();
    _loadRiveFile();
  }

  Future<void> _loadRiveFile() async {
    final data = await rootBundle.load('assets/riv/hand.riv');
    final file = RiveFile.import(data);
    final artboard = file.mainArtboard;

    final controller = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1', // Match your state machine name
    );

    if (controller != null) {
      artboard.addController(controller);
      _numberInput = controller.findInput<double>('Input') as SMINumber?;
      _numberInput?.value = 0.0; // Initial idle state
    }

    setState(() => _artboard = artboard);
  }

  void _updateNumber(int number) {
    if (_numberInput != null) {
      setState(() => _numberInput!.value = number.toDouble());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hand States: Idle (0) to 5')),
      body: Column(
        children: [
          Expanded(
            child:
                _artboard == null
                    ? const Center(child: CircularProgressIndicator())
                    : Rive(artboard: _artboard!, fit: BoxFit.contain),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 10,
              children:
                  [0, 1, 2, 3, 4, 5, 6].map((number) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(60, 60),
                        backgroundColor:
                            number == 0 ? Colors.grey : Colors.blue,
                      ),
                      onPressed: () => _updateNumber(number),
                      child: Text(
                        number == 0 ? 'Idle' : number.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
            ),
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
