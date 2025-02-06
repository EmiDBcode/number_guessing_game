#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Pedir el nombre de usuario
echo "Enter your username:"
read USERNAME

# Buscar si el usuario ya existe
USER_DATA=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")

# Si el usuario no existe
if [[ -z $USER_DATA ]]
then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  $PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, NULL)"
else
  echo "$USER_DATA" | while IFS="|" read GAMES_PLAYED BEST_GAME
  do
    if [[ -z $BEST_GAME ]]
    then
      echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and you have not set a best game record yet."
    else
      echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
    fi
  done
fi

# Generar el número aleatorio
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Inicializar número de intentos
NUMBER_OF_GUESSES=0

echo "Guess the secret number between 1 and 1000:"

while true
do
  read GUESS

  # Verificar si la entrada es un número
  if ! [[ $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
  else
    ((NUMBER_OF_GUESSES++))

    # Comprobar si el número es mayor, menor o igual al secreto
    if [[ $GUESS -lt $SECRET_NUMBER ]]
    then
      echo "It's higher than that, guess again:"
    elif [[ $GUESS -gt $SECRET_NUMBER ]]
    then
      echo "It's lower than that, guess again:"
    else
      echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"

      # Obtener datos del usuario
      USER_DATA=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")

      echo "$USER_DATA" | while IFS="|" read GAMES_PLAYED BEST_GAME
      do
        ((GAMES_PLAYED++))
        $PSQL "UPDATE users SET games_played=$GAMES_PLAYED WHERE username='$USERNAME'"

        if [[ -z $BEST_GAME || $NUMBER_OF_GUESSES -lt $BEST_GAME ]]
        then
          $PSQL "UPDATE users SET best_game=$NUMBER_OF_GUESSES WHERE username='$USERNAME'"
        fi
      done

      exit 0
    fi
  fi
done
