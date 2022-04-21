#! /usr/bin/env nix-shell
#! nix-shell -i bash -p time

set -euo pipefail
# Benchmark runner

repeats=20
output_file='benchmark_results.csv'
command_to_run='echo 1'
command_before=""
command_after=""

run_tests() {
  # --------------------------------------------------------------------------
  # Benchmark loop
  # --------------------------------------------------------------------------
  echo 'Benchmarking ' $command_to_run '...'
  # Indicate the command we just run in the csv file
  echo '======' $command_to_run '======' >>$output_file
  echo "real,user,sys" >>$output_file
  # Run the given command [repeats] times
  for ((i = 1; i <= $repeats; i++)); do
    ${command_before}
    # percentage completion
    p=$(($i * 100 / $repeats))
    # indicator of progress
    l=$(seq -s "+" $i | sed 's/[0-9]//g')

    # runs time function for the called script, output in a comma seperated
    # format output file specified with -o command and -a specifies append
    env time -f "%E,%U,%S" -o ${output_file} -a ${command_to_run} >/dev/null 2>&1

    # Run command and
    # ${command_to_run}
    # ENV_IMAGE="$DOCKER_REGISTRY_HOST/$(./hash-files.sh)"
    # START=$(docker inspect --format='{{.State.StartedAt}}' "$ENV_IMAGE")
    # STOP=$(docker inspect --format='{{.State.FinishedAt}}' "$ENV_IMAGE")

    # START_TIMESTAMP=$(date --date=$START +%s.%3N)
    # STOP_TIMESTAMP=$(date --date=$STOP +%s.%3N)
    # echo $(($STOP_TIMESTAMP-$START_TIMESTAMP)) miliseconds

    # Clear the HDD cache (I hope?)
    # sync && echo 3 > /proc/sys/vm/drop_caches
    ${command_after}

    echo -ne ${l}' ('${p}'%) \r'
  done

  echo -ne '\n'

  # Convenience seperator for file
  echo '--------------------------' >>$output_file
}

while test $# -gt 0; do
  case "$1" in
  --resamples)
    shift
    echo "resamples: $1"
    repeats=$1
    shift
    ;;
  -o)
    shift
    echo "output file $1"
    output_file=$1
    shift
    ;;
  --before)
    shift
    echo "before command: $1"
    command_before=$1
    shift
    ;;
  --after)
    shift
    echo "after command: $1"
    command_after=$1
    shift
    ;;
  -c)
    shift
    echo "command to run: $1"
    command_to_run=$1
    shift
    ;;
  *)
    break
    ;;
  esac
done
run_tests
