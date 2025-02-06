#!/bin/bash

PSQL="psql -X --username=freecodecamp --dbname=number_guess -t --no-align -c"

GAME_INIT() {
  SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

  # ✅ Asegurar que el mensaje de entrada es EXACTAMENTE lo que FreeCodeCamp espera
  echo "Enter your username:"
  read USERNAME

  # Obtener el user_id
  USER_DATA=$($PSQL "SELECT user_id, COUNT(*), MIN(tries) FROM users LEFT JOIN games ON users.user_id=games.user_id WHERE username='$USERNAME' GROUP BY users.user_id")

  if [[ -z $USER_DATA ]]
  then
    echo "Welcome, $USERNAME! It looks like this is your first time here."
    $PSQL "INSERT INTO users(username) VALUES('$USERNAME')"
    USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
    GAMES_PLAYED=0
    BEST_GAME=0
  else
    IFS="|" read USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_DATA"

    if [[ -z $BEST_GAME ]]
    then
      BEST_GAME=0
    fi

    # ✅ Asegurar que el mensaje es EXACTAMENTE como lo espera FreeCodeCamp
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  fi

  # ✅ Asegurar que esta línea se imprime correctamente antes de leer la entrada
  echo "Guess the secret number between 1 and 1000:"
  PLAY_GAME $SECRET_NUMBER $USER_ID 0
}

PLAY_GAME() {
  local SECRET=$1
  local USER_ID=$2
  local ATTEMPTS=$3

  read GUESS

  # ✅ Asegurar que el script valida correctamente los números
  if ! [[ $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    PLAY_GAME $SECRET $USER_ID $ATTEMPTS
    return
  fi

  ((ATTEMPTS++))

  if [[ $GUESS -lt $SECRET ]]
  then
    echo "It's higher than that, guess again:"
    PLAY_GAME $SECRET $USER_ID $ATTEMPTS
  elif [[ $GUESS -gt $SECRET ]]
  then
    echo "It's lower than that, guess again:"
    PLAY_GAME $SECRET $USER_ID $ATTEMPTS
  else
    # ✅ Asegurar que el mensaje final es EXACTAMENTE lo que FreeCodeCamp espera
    echo "You guessed it in $ATTEMPTS tries. The secret number was $SECRET. Nice job!"
    INSERT_GAME_RESULT $USER_ID $SECRET $ATTEMPTS
    exit 0
  fi
}

INSERT_GAME_RESULT() {
  local USER_ID=$1
  local NUMBER=$2
  local ATTEMPTS=$3
  $PSQL "INSERT INTO games(user_id, number, tries) VALUES($USER_ID, $NUMBER, $ATTEMPTS)"
}

GAME_INIT
