#!/bin/bash

# Command-line args passed by the genrule.
input=$1
start_at=$2
end_before=$3

# We want to scan until `start_at`, and the end at `end_before`.
writing=false

# We could be really clever with grep/sed, but this is more straight forward.
while IFS= read -r line
do
  if $writing
  then
    if [ "$line" = "$end_before" ]
    then
      break
    else
      echo "$line"
    fi
  else
    if [ "$line" = "$start_at" ]
    then
      writing=true
      echo "$line"
    fi
  fi
done < "$input"
