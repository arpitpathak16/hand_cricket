import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';
import 'dart:math';

class HandCricketGameScreen extends StatefulWidget {
  const HandCricketGameScreen({super.key});

  @override
  State<HandCricketGameScreen> createState() => _HandCricketGameScreenState();
}

class _HandCricketGameScreenState extends State<HandCricketGameScreen> {
  // Game state variables
  bool isPlayerBatting = true;
  int playerScore = 0;
  int computerScore = 0;
  int currentBall = 0;
  List<int> playerScores = [];
  List<int> computerScores = [];

  String? overlayImagePath; // For showing overlay images

  // Artboard related variables
  Artboard? _playerArtboard;
  Artboard? _computerArtboard;
  SMINumber? _playerHandInput;
  SMINumber? _computerHandInput;

  @override
  void initState() {
    super.initState();
    _loadRiveAssets();
    _showOverlayImage('batting'); // Show "User Batting" at the start
  }

  void _loadRiveAssets() async {
    final playerData = await rootBundle.load('../../assets/riv/hand.riv');
    final playerFile = RiveFile.import(playerData);
    final playerArtboard = playerFile.mainArtboard;
    final playerController = StateMachineController.fromArtboard(
      playerArtboard,
      'State Machine 1',
    );

    if (playerController != null) {
      playerArtboard.addController(playerController);
      _playerHandInput =
          playerController.findInput<double>('Input') as SMINumber?;
      _playerHandInput?.value = 0;
    }

    final computerData = await rootBundle.load('assets/riv/hand.riv');
    final computerFile = RiveFile.import(computerData);
    final computerArtboard = computerFile.mainArtboard;
    final computerController = StateMachineController.fromArtboard(
      computerArtboard,
      'State Machine 1',
    );

    if (computerController != null) {
      computerArtboard.addController(computerController);
      _computerHandInput =
          computerController.findInput<double>('Input') as SMINumber?;
      _computerHandInput?.value = 0;
    }

    setState(() {
      _playerArtboard = playerArtboard;
      _computerArtboard = computerArtboard;
    });
  }

  void _playTurn(int playerChoice) {
    final computerChoice = Random().nextInt(6) + 1;

    _playerHandInput?.value = playerChoice.toDouble();
    _computerHandInput?.value = computerChoice.toDouble();

    setState(() {
      bool isOut = (playerChoice == computerChoice);

      if (isPlayerBatting) {
        if (isOut) {
          _showOverlayImage('out');
          _switchToComputerBatting();
        } else {
          playerScore += playerChoice;
          playerScores.add(playerChoice);
          if (playerChoice == 6) {
            _showOverlayImage('sixer');
          }
          currentBall++;
          if (currentBall == 6) {
            _switchToComputerBatting();
          }
        }
      } else {
        if (isOut) {
          _showOverlayImage('out');
          _showResult();
        } else {
          computerScore += computerChoice;
          computerScores.add(computerChoice);
          if (computerChoice == 6) {
            _showOverlayImage('sixer');
          }
          currentBall++;
          if (computerScore > playerScore) {
            _showResult();
          } else if (currentBall == 6) {
            _showResult();
          }
        }
      }
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      _playerHandInput?.value = 0;
      _computerHandInput?.value = 0;
    });
  }

  void _switchToComputerBatting() {
    setState(() {
      isPlayerBatting = false;
      currentBall = 0;
      computerScores.clear();
    });
    _showOverlayImage('game_bowl'); // Show "User Bowling" overlay
  }

  void _showResult() {
    Future.delayed(const Duration(milliseconds: 600), () {
      String message;
      String overlayName;
      if (computerScore > playerScore) {
        message = "Computer Wins!";
        overlayName = 'computer_won';
      } else if (computerScore < playerScore) {
        message = "You Win!";
        overlayName = 'you_won';
      } else {
        message = "Match Tied!";
        overlayName = 'draw';
      }
      _showOverlayImage(overlayName);
      Future.delayed(const Duration(milliseconds: 1200), () {
        _showGameOver(message);
      });
    });
  }

  void _showOverlayImage(String imageName) {
    setState(() {
      overlayImagePath = '../../assets/overlays/$imageName.png';
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      setState(() {
        overlayImagePath = null;
      });
    });
  }

  void _showGameOver(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Game Over'),
            content: Text(
              '$message\n\nPlayer: $playerScore\nComputer: $computerScore',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _resetGame();
                },
                child: const Text('Play Again'),
              ),
            ],
          ),
    );
  }

  void _resetGame() {
    setState(() {
      isPlayerBatting = true;
      playerScore = 0;
      computerScore = 0;
      currentBall = 0;
      playerScores.clear();
      computerScores.clear();
    });
    _showOverlayImage('batting');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('../../assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildPlayerInfoBar(),
                  Expanded(child: _buildGameArea()),
                  _buildHandSelectionButtons(),
                ],
              ),
            ),
          ),
          if (overlayImagePath != null)
            Center(
              child: Image.asset(
                overlayImagePath!,
                width: 250,
                height: 250,
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfoBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPlayerInfoCard("You", "$playerScore", isPlayerBatting),
          _buildPlayerInfoCard("Computer", "$computerScore", !isPlayerBatting),
        ],
      ),
    );
  }

  Widget _buildPlayerInfoCard(String name, String score, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.grey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.3),
            child: Text(
              name[0],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            score,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    List<int> scoresToDisplay = isPlayerBatting ? playerScores : computerScores;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            return Container(
              margin: const EdgeInsets.all(4),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Text(
                  index < scoresToDisplay.length
                      ? '${scoresToDisplay[index]}'
                      : '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        if (_playerArtboard != null && _computerArtboard != null)
          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final characterWidth = (totalWidth - 20) / 2;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: characterWidth,
                    height: characterWidth,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
                      child: Rive(artboard: _playerArtboard!),
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: characterWidth,
                    height: characterWidth,
                    child: Rive(artboard: _computerArtboard!),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildHandSelectionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SizedBox(
        height: 140,
        child: GridView.count(
          crossAxisCount: 3,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: List.generate(6, (index) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(0, 255, 255, 255),
                foregroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.all(8),
              ),
              onPressed: () => _playTurn(index + 1),
              child: Image.asset(
                '../../assets/images/${_getImageName(index)}.png',
                fit: BoxFit.contain,
              ),
            );
          }),
        ),
      ),
    );
  }

  String _getImageName(int index) {
    switch (index) {
      case 0:
        return 'one';
      case 1:
        return 'two';
      case 2:
        return 'three';
      case 3:
        return 'four';
      case 4:
        return 'five';
      case 5:
        return 'six';
      default:
        return 'one';
    }
  }
}
