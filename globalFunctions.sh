#! /bin/bash

## Titre1 = 
## "#########"
## "# TITRE #"
## "#########"

function Titre1() {
  titre=$1
  lenght=${#titre};
  bandeau `expr $lenght + 3`;
  echo "# ${titre} #"
  bandeau `expr $lenght + 3`;
}

## Titre2 = "# TITRE #"
function Titre2() {
  titre=$1
  echo "${titre}"
}

## Bandeau de croisillons (parametre = nombre de croisillon)
function bandeau() {
  limit=$1
  i=0
  while [ $i -le ${limit} ]
  do
    printf "#"
    i=$(( $i + 1 ))
  done
  echo ""
}

function Pause() {
  if $pause; then
    Titre2 "[Appuyer sur une touche pour continuer ...]"
    read Continue
  fi
}

# Custom `select` implementation that allows *empty* input.
# Pass the choices as individual arguments.
# Output is the chosen item, or "", if the user just pressed ENTER.
# Example:
#   choice=$(selectWithDefault 'one' 'two' 'three')

function selectWithDefault() {
  local item i=0 numItems=$# 

  # Print numbered menu items, based on the arguments passed.
  for item; do
    printf '%s\n' "$((++i))) $item"
  done >&2 # Print to stderr, as `select` does.

  # Prompt the user for the index of the desired item.
  while :; do
    printf %s "${PS3-Votre choix ? }" >&2 # Print the prompt string to stderr, as `select` does.
    read -r index
    # Make sure that the input is either empty or that a valid index was entered.
    [[ -z $index ]] && break  # empty input
    (( index >= 1 && index <= numItems )) 2>/dev/null || { echo "Selection invalide." >&2; continue; }
    break
  done

  # Output the selected item, if any.
  [[ -n $index ]] && printf %s "${@: index:1}"

}
