import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/hand_animation_widget.dart'; // Make sure this exists

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int userScore = 0;
  int botScore = 0;
  int ballsLeft = 6;
  bool isUserBatting = true;
  String statusMessage = "Your Turn!";
  int timerSeconds = 10;
  Timer? countdownTimer;
  int? botChoice;
  String botAnimation = "idle";

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    timerSeconds = 10;
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (timerSeconds > 0) {
          timerSeconds--;
        } else {
          timer.cancel();
          showResultDialog("Time's Up ⏰\nYou Lost!");
        }
      });
    });
  }

  void onUserChoice(int userChoice) {
    countdownTimer?.cancel();

    final int generatedBotChoice =
        (1 + (DateTime.now().millisecondsSinceEpoch % 6));
    setState(() {
      botChoice = generatedBotChoice;
      botAnimation = getAnimationName(generatedBotChoice);
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;

      if (isUserBatting) {
        if (userChoice == botChoice) {
          setState(() {
            statusMessage = "You're OUT!";
            isUserBatting = false;
            ballsLeft = 0;
          });
          Future.delayed(const Duration(seconds: 2), () => startBotBatting());
        } else {
          setState(() {
            userScore += userChoice;
            ballsLeft--;
            statusMessage = "You scored $userChoice runs!";
          });
          if (ballsLeft == 0) {
            setState(() => isUserBatting = false);
            Future.delayed(const Duration(seconds: 2), () => startBotBatting());
          } else {
            startTimer();
          }
        }
      } else {
        if (userChoice == botChoice) {
          setState(() {
            statusMessage = "Bot is OUT!";
            ballsLeft = 0;
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (botScore < userScore) {
              showResultDialog("You Win 🎉");
            } else if (botScore == userScore) {
              showResultDialog("It's a Tie 🤝");
            } else {
              showResultDialog("Bot Wins 🤖");
            }
          });
        } else {
          setState(() {
            botScore += botChoice!;
            ballsLeft--;
            statusMessage = "Bot scored $botChoice runs!";
          });

          if (botScore > userScore) {
            showResultDialog("Bot Wins 🤖");
          } else if (ballsLeft == 0) {
            if (botScore < userScore) {
              showResultDialog("You Win 🎉");
            } else if (botScore == userScore) {
              showResultDialog("It's a Tie 🤝");
            } else {
              showResultDialog("Bot Wins 🤖");
            }
          } else {
            startTimer();
          }
        }
      }
    });
  }

  void startBotBatting() {
    setState(() {
      isUserBatting = false;
      ballsLeft = 6;
      statusMessage = "Now you bowl!";
    });
    startTimer();
  }

  void showResultDialog(String result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(result),
            content: Text("Final Score\nYou: $userScore\nBot: $botScore"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  resetGame();
                },
                child: const Text("Play Again"),
              ),
            ],
          ),
    );
  }

  void resetGame() {
    setState(() {
      userScore = 0;
      botScore = 0;
      ballsLeft = 6;
      isUserBatting = true;
      botChoice = null;
      botAnimation = "idle";
      statusMessage = "Your Turn!";
    });
    startTimer();
  }

  String getAnimationName(int number) {
    switch (number) {
      case 1:
        return "one";
      case 2:
        return "two";
      case 3:
        return "three";
      case 4:
        return "four";
      case 5:
        return "five";
      case 6:
        return "six";
      default:
        return "idle";
    }
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hand Cricket'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("You: $userScore", style: const TextStyle(fontSize: 20)),
                Text("Bot: $botScore", style: const TextStyle(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Balls Left: $ballsLeft",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              "Timer: $timerSeconds",
              style: const TextStyle(fontSize: 18, color: Colors.red),
            ),
            const SizedBox(height: 30),
            Text(
              statusMessage,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            /// 👇 Rive Bot Hand Animation
            HandAnimationWidget(animationName: botAnimation),
            const SizedBox(height: 30),

            const Text("Choose a number (1-6)", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: List.generate(6, (index) {
                return ElevatedButton(
                  onPressed: () => onUserChoice(index + 1),
                  child: Text('${index + 1}'),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
