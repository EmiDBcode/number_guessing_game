#!/bin/bash

PSQL="psql -X --username=freecodecamp --dbname=number_guess -t --tuples-only -c"

START_GAME() {
  SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
  echo -e "Enter your username:"
  read USERNAME

  # Obtener datos del usuario
  USER_DATA=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")
  
  if [[ -z $USER_DATA ]]
  then
    echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
    $PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, NULL)"
  else
    IFS="|" read GAMES_PLAYED BEST_GAME <<< "$USER_DATA"

    # ✅ Asegurar el formato EXACTO esperado por FreeCodeCamp
    if [[ -z $BEST_GAME ]]
    then
      echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took 0 guesses."
    else
      echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
    fi
  fi

  echo -e "\nGuess the secret number between 1 and 1000:"
  PLAY_GAME $SECRET_NUMBER $USERNAME
}

PLAY_GAME() {
  local SECRET=$1
  local USERNAME=$2
  local ATTEMPTS=0

  while true
  do
    read GUESS

    # Verificar si es un número válido
    if ! [[ $GUESS =~ ^[0-9]+$ ]]
    then
      echo -e "\nThat is not an integer, guess again:"
    else
      ((ATTEMPTS++))

      if [[ $GUESS -lt $SECRET ]]
      then
        echo -e "\nIt's higher than that, guess again:"
      elif [[ $GUESS -gt $SECRET ]]
      then
        echo -e "\nIt's lower than that, guess again:"
      else
        echo -e "\nYou guessed it in $ATTEMPTS tries. The secret number was $SECRET. Nice job!"
        UPDATE_DATABASE $USERNAME $ATTEMPTS
        exit 0
      fi
    fi
  done
}

UPDATE_DATABASE() {
  local USERNAME=$1
  local ATTEMPTS=$2

  USER_DATA=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")
  IFS="|" read GAMES_PLAYED BEST_GAME <<< "$USER_DATA"

  ((GAMES_PLAYED++))
  $PSQL "UPDATE users SET games_played=$GAMES_PLAYED WHERE username='$USERNAME'"

  if [[ -z $BEST_GAME || $ATTEMPTS -lt $BEST_GAME ]]
  then
    $PSQL "UPDATE users SET best_game=$ATTEMPTS WHERE username='$USERNAME'"
  fi
}

START_GAME
