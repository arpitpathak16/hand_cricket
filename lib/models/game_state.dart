class GameState {
  int playerScore = 0;
  int computerScore = 0;
  int roundsLeft = 6;
  bool isPlayerBatting = true;
  bool isGameOver = false;

  void reset() {
    playerScore = 0;
    computerScore = 0;
    roundsLeft = 6;
    isPlayerBatting = true;
    isGameOver = false;
  }
}
