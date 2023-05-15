#!/bin/bash
#
# Author: Romeo Stoll <stollr@student.ethz.ch>
#
# shellcheck source=./common.sh
source "$(dirname "$0")/common.sh"

repeats=10
run_image="./run-image.sh"
out_path="$PROJECTROOT/benchmarks/"
IMAGE=""
run_image_cached_shell=""
run_image_uncached_shell=""

image_size_to_csv() {
  IMAGE=$(get_image)
  size=$(docker image ls --filter=reference=$IMAGE --format "{{.Size}}")
  echo '==========================' >>$1
  echo "Image size, $size" >>$1
}

# Measure number of layers of image produced by the current configuration
num_layers() {
  IMAGE=$(get_image)
  NUM_LAYERS=$(docker image inspect "$IMAGE" -f "{{ len .RootFS.Layers }}")
  if test $# -gt 0; then
    echo '==========================' >>$1
    echo "Number of layers in image,$NUM_LAYERS" >>$1
  fi
}

measure_container_stats() {
  name="${ENV}_container_stats_initial"
  output_csv_1="$out_path$name.csv"
  name="${ENV}_container_stats_prebuilt"
  output_csv_2="$out_path$name.csv"

  outputs=("$output_csv_1" "$output_csv_2")
  for csv in "${outputs[@]}"; do
    $run_image prune
    $run_image create
    if [[ $csv == "$output_csv_2" ]]; then
      $run_image prebuild-store
    fi
    num_layers $csv
    ./docker-volume-stats.sh $csv
    image_size_to_csv $csv
  done
}

bench_cached_shell_empty_store() {
  name="${ENV}_bench_cached_shell_empty_store"
  path="$out_path$name"
  output_csv="$path.csv"

  command_before="$run_image create"
  command_after="$run_image prune container"
  $command_after
  ./benchmark.sh -c "$run_image_cached_shell" --before "$command_before" --after "$command_after" --resamples $repeats -o "$output_csv"
}

bench_uncached_shell_empty_store() {
  name="${ENV}_bench_uncached_shell_empty_store"
  path="$out_path$name"
  output_csv="$path.csv"

  command_before="$run_image create"
  command_after="$run_image prune container"
  $command_after
  ./benchmark.sh -c "$run_image_uncached_shell" --before "$command_before" --after "$command_after" --resamples $repeats -o "$output_csv"
}

bench_cached_shell_with_seeded_store() {
  name="${ENV}_bench_cached_shell_with_seeded_store"
  path="$out_path$name"
  output_csv="$path.csv"

  $run_image prune
  update_config_seeded
  $run_image create-and-prebuild
  update_config
  $run_image prune image
  $run_image create
  ./benchmark.sh -c "$run_image_cached_shell" --resamples $repeats -o "$output_csv"
}

bench_uncached_shell_with_seeded_store() {
  name="${ENV}_bench_uncached_shell_with_seeded_store"
  path="$out_path$name"
  output_csv="$path.csv"

  $run_image prune
  update_config_seeded
  $run_image create-and-prebuild
  update_config
  $run_image prune image
  $run_image create
  ./benchmark.sh -c "$run_image_uncached_shell" --resamples $repeats -o "$output_csv"
}

bench_cached_shell_full_store() {
  name="${ENV}_bench_cached_shell_full_store"
  path="$out_path$name"
  output_csv="$path.csv"

  $run_image prune
  $run_image create
  $run_image_cached_shell
  ./benchmark.sh -c "$run_image_cached_shell" --resamples $repeats -o "$output_csv"
}

bench_uncached_shell_full_store() {
  name="${ENV}_bench_uncached_shell_full_store"
  path="$out_path$name"
  output_csv="$path.csv"

  $run_image prune
  $run_image create
  $run_image_uncached_shell
  ./benchmark.sh -c "$run_image_uncached_shell" --resamples $repeats -o "$output_csv"
}

run_benchmarks() {
  bench_cached_shell_full_store
  bench_uncached_shell_full_store
  bench_cached_shell_with_seeded_store
  bench_uncached_shell_with_seeded_store
  bench_cached_shell_empty_store
  bench_uncached_shell_empty_store

  # measure_container_stats
}

update_config_seeded() {
  tmp=$(mktemp)
  jq --arg env "$ENV" \
    '.configs.userConfigFile |= "\($env).nix"' \
    "$config" >"$tmp"
  mv -f "$tmp" "$config"
}

update_config() {
  tmp=$(mktemp)
  jq --arg env "$ENV" \
    '.configs.userConfigFile |= "bench-\($env).nix"' \
    "$config" >"$tmp"
  mv -f "$tmp" "$config"
}

# envs=("cpp" "python")
envs=("python")
run_both_env_benchmarks() {
  for env in "${envs[@]}"; do
    ENV=$env
    update_config
    IMAGE=$(get_image)
    run_image_cached_shell="docker run --rm --volumes-from=$DATA_CONTAINER -v "$PROJECTROOT/workdir/user":$WORKDIR --workdir=$WORKDIR -e USERCONFIGPATH=$USERCONFIGPATH $IMAGE cached-shell"
    run_image_uncached_shell="docker run --rm --volumes-from=$DATA_CONTAINER -v "$PROJECTROOT/workdir/user":$WORKDIR --workdir=$WORKDIR -e USERCONFIGPATH=$USERCONFIGPATH $IMAGE nix-shell"
    run_benchmarks
  done
}

python_image_size_bench() {
  for i in {0..5}; do
    if test "$i" -eq 0; then
      ENV="base"
    else
      ENV="${i}"
    fi
    name="${ENV}_container_stats_streamed_local"
    # change configuration
    update_config

    $run_image prune
    $run_image build
    $run_image pull
    image_size_to_csv "$out_path$name.csv"
  done
}

run_both_env_benchmarks

# python_image_size_bench
