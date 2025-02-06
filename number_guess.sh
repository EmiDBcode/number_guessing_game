#!/bin/bash

PSQL="psql -X --username=freecodecamp --dbname=number_guess -t --no-align -c"

GAME_INIT() {
  RANDOM_NUM=$(( RANDOM % 1000 + 1 ))
  
  echo -n "Enter your username: "
  read USERNAME

  # Obtener el user_id
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")

  if [[ -z $USER_ID ]]
  then
    echo "Welcome, $USERNAME! It looks like this is your first time here."
    $PSQL "INSERT INTO users(username) VALUES('$USERNAME')"
    USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
    GAMES_PLAYED=0
    BEST_GAME=0
  else
    GAMES_PLAYED=$($PSQL "SELECT COUNT(*) FROM games WHERE user_id=$USER_ID")
    BEST_GAME=$($PSQL "SELECT MIN(tries) FROM games WHERE user_id=$USER_ID")

    if [[ -z $BEST_GAME ]]
    then
      BEST_GAME=0
    fi

    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  fi

  echo "Guess the secret number between 1 and 1000:"
  PLAY_GAME 0
}

PLAY_GAME() {
  local ATTEMPTS=$1
  read GUESS
  ((ATTEMPTS++))

  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    PLAY_GAME $ATTEMPTS
  fi

  if [[ $GUESS -lt $RANDOM_NUM ]]
  then
    echo "It's higher than that, guess again:"
    PLAY_GAME $ATTEMPTS
  elif [[ $GUESS -gt $RANDOM_NUM ]]
  then
    echo "It's lower than that, guess again:"
    PLAY_GAME $ATTEMPTS
  elif [[ $GUESS -eq $RANDOM_NUM ]]
  then
    echo "You guessed it in $ATTEMPTS tries. The secret number was $RANDOM_NUM. Nice job!"
    INSERT_GAME_RESULT $USER_ID $RANDOM_NUM $ATTEMPTS
  fi
}

INSERT_GAME_RESULT() {
  local USER_ID=$1
  local NUMBER=$2
  local ATTEMPTS=$3
  $PSQL "INSERT INTO games(user_id, number, tries) VALUES($USER_ID, $NUMBER, $ATTEMPTS)"
}

GAME_INIT
