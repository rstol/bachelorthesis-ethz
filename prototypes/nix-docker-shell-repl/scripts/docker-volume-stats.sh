#!/bin/bash

set -e

output_file=${1:-"docker-volume-stats.csv"}

for d in $(docker ps -a | awk '{print $1}' | tail -n +2); do
  d_name=$(docker inspect -f {{.Name}} $d)
  echo "=========================================================" >>$output_file
  echo "$d_name ($d) volumes:" >>$output_file

  VOLUME_IDS=$(docker inspect -f "{{.Config.Volumes}}" $d)
  VOLUME_IDS=$(echo ${VOLUME_IDS} | sed 's/map\[//' | sed 's/]//')

  array=(${VOLUME_IDS// / })
  for i in "${!array[@]}"; do
    VOLUME_ID=$(echo ${array[i]} | sed 's/:{}//')
    if [[ -z $(docker ps | grep $d) ]]; then
      IMAGE=$(docker inspect -f "{{.Config.Image}}" $d)
      VOLUME_SIZE=$(docker run --rm -it --volumes-from="$d" "$IMAGE" du -d 0 -h /nix)
    else
      VOLUME_SIZE=$(docker exec -ti $d_name du -d 0 -h ${VOLUME_ID})
    fi
    echo "$VOLUME_SIZE" >>$output_file
  done
done

exit 0
