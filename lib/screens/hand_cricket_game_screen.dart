import 'dart:async';

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

  int remainingTime = 10;
  Timer? choiceTimer;

  double overlayOpacity = 0.0; // For fade-in fade-out effect

  // Artboard related variables
  Artboard? _playerArtboard;
  Artboard? _computerArtboard;
  SMINumber? _playerHandInput;
  SMINumber? _computerHandInput;

  @override
  void initState() {
    super.initState();
    _loadRiveAssets();
    _showOverlayImage('batting');
    _startChoiceTimer(); // Start timer when game starts
  }

  void _startChoiceTimer() {
    choiceTimer?.cancel();
    setState(() {
      remainingTime = 10;
    });

    choiceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        setState(() {
          remainingTime--;
        });
      } else {
        timer.cancel();
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    if (isPlayerBatting) {
      _showOverlayImage('out');
      Future.delayed(const Duration(milliseconds: 600), () {
        _showGameOver("Time's Up! You Lost!");
      });
    } else {
      // If needed: you can handle timeout for computer batting too
    }
  }

  void _loadRiveAssets() async {
    final playerData = await rootBundle.load('assets/riv/hand.riv');
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
      // At the very end of _playTurn()
      _startChoiceTimer();
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
    _showOverlayImage('game_bowl');
    _startChoiceTimer(); // Restart timer for bowling
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
      overlayImagePath = 'assets/overlays/$imageName.png';
      overlayOpacity = 0.0;
    });

    // First fade in
    Future.delayed(Duration.zero, () {
      setState(() {
        overlayOpacity = 1.0;
      });
    });

    // Then fade out after some time
    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() {
        overlayOpacity = 0.0;
      });
    });

    // Finally remove overlay image after fade-out completed
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        overlayImagePath = null;
      });
    });
  }

  void _showGameOver(String message) {
    choiceTimer?.cancel(); // Stop timer
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
    _startChoiceTimer(); // Restart timer when new game starts
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildPlayerInfoBar(),
                  _buildTimer(),
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
    return SizedBox(
      width: 150, // You can calculate dynamically too
      child: LayoutBuilder(
        builder: (context, constraints) {
          double cardWidth = constraints.maxWidth;
          double baseFontSize = cardWidth * 0.18;
          double avatarRadius = cardWidth * 0.2;

          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: cardWidth * 0.1,
              vertical: cardWidth * 0.08,
            ),
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(cardWidth * 0.4),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: Text(
                    name[0],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: baseFontSize * 0.8,
                    ),
                  ),
                ),
                SizedBox(width: cardWidth * 0.1),
                Text(
                  score,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: baseFontSize,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameArea() {
    List<int> scoresToDisplay = isPlayerBatting ? playerScores : computerScores;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            double screenWidth = constraints.maxWidth;
            double boxSize = (screenWidth - (6 * 8)) / 6;
            // 6 boxes, each with 8px margin both sides

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Container(
                  margin: const EdgeInsets.all(4),
                  width: boxSize,
                  height: boxSize,
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: boxSize * 0.4, // font size also dynamic!
                      ),
                    ),
                  ),
                );
              }),
            );
          },
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

  Widget _buildTimer() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        'Time Left: $remainingTime s',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      ),
    );
  }

  Widget _buildHandSelectionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double buttonWidth =
              (screenWidth - 2 * 10 - 2 * 16) /
              3; // spacing and padding adjusted
          double buttonHeight =
              buttonWidth * 0.75; // slightly rectangular buttons

          return SizedBox(
            height: buttonHeight * 2 + 20, // 2 rows of buttons + spacing
            child: GridView.count(
              crossAxisCount: 3,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: buttonWidth / buttonHeight,
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
                    'assets/images/${_getImageName(index)}.png',
                    fit: BoxFit.contain,
                  ),
                );
              }),
            ),
          );
        },
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
