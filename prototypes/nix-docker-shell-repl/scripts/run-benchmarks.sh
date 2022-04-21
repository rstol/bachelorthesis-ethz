#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bench jq

source $(dirname "$0")/common.sh

repeats=10
run_image="./run-image.sh"
out_path="$PROJECTROOT/benchmarks/"
run_image_cached_shell="docker run --rm --volumes-from=$DATA_CONTAINER -v "$PROJECTROOT/env":$CONFIGDIR -v "$PROJECTROOT/workdir":$WORKDIR --workdir=$WORKDIR -e PRESETPATH=$PRESETPATH -e LOCALPATH=$LOCALPATH $IMAGE cached-nix-shell"
run_image_uncached_shell="docker run --rm --volumes-from=$DATA_CONTAINER -v "$PROJECTROOT/env":$CONFIGDIR -v "$PROJECTROOT/workdir":$WORKDIR --workdir=$WORKDIR -e PRESETPATH=$PRESETPATH -e LOCALPATH=$LOCALPATH $IMAGE nix-shell"

image_size_to_csv() {
  size=$(docker image ls --filter=reference=$IMAGE --format "{{.Size}}")
  echo '==========================' >>$1
  echo "Image size, $size" >>$1
}

# Measure number of layers of image produced by the current configuration
num_layers() {
  NUM_LAYERS=$(docker image inspect "$IMAGE" -f "{{ len .RootFS.Layers }}")
  if test $# -gt 0; then
    echo '==========================' >>$1
    echo "Number of layers in image,$NUM_LAYERS" >>$1
  fi
}

measure_container_stats() {
  name="${ENV}_container_stats_initial"
  output_csv_1="$out_path$name.csv"
  name="${ENV}_container_stats_prebuild"
  output_csv_2="$out_path$name.csv"

  outputs=("$output_csv_1" "$output_csv_2")
  for csv in "${outputs[@]}"; do
    $run_image prune
    $run_image create
    if [[ $csv == $output_csv_2 ]]; then
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
  command_after="$run_image prune"
  $command_after
  ./benchmark.sh -c "$run_image_cached_shell" --before "$command_before" --after "$command_after" --resamples $repeats -o "$output_csv"
}

bench_uncached_shell_empty_store() {
  name="${ENV}_bench_uncached_shell_empty_store"
  path="$out_path$name"
  output_csv="$path.csv"

  command_before="$run_image create"
  command_after="$run_image prune"
  $command_after
  ./benchmark.sh -c "$run_image_uncached_shell" --before "$command_before" --after "$command_after" --resamples $repeats -o "$output_csv"
}

bench_cached_shell_with_prebuild_store() {
  name="${ENV}_bench_cached_shell_with_prebuild_store"
  path="$out_path$name"
  output_csv="$path.csv"

  command_before="${run_image} prune && ${run_image} create && ${run_image} prebuild-store"
  ./benchmark.sh -c "$run_image_cached_shell" --before "$command_before" --resamples $repeats -o "$output_csv"
}

bench_uncached_shell_with_prebuild_store() {
  name="${ENV}_bench_uncached_shell_with_prebuild_store"
  path="$out_path$name"
  output_csv="$path.csv"

  command_before="${run_image} prune && ${run_image} create && ${run_image} prebuild-store"
  ./benchmark.sh -c "$run_image_uncached_shell" --before "$command_before" --resamples $repeats -o "$output_csv"
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

bench_change_config_uncached_shell() { # TODO:
  name="${ENV}_bench_change_config_uncached_shell"
  path="$out_path$name"
  output_csv="$path.csv"

  $run_image prune
  $run_image create
  $run_image_uncached_shell
  ./benchmark.sh -c "$run_image_uncached_shell" --resamples $repeats -o "$output_csv"
}

bench_change_config_cached_shell() { # TODO:
  name="${ENV}_bench_change_config_cached_shell"
  path="$out_path$name"
  output_csv="$path.csv"

  $run_image prune
  $run_image create
  $run_image_uncached_shell
  ./benchmark.sh -c "$run_image_uncached_shell" --resamples $repeats -o "$output_csv"
}

run_benchmarks() {
  # bench_cached_shell_empty_store
  # bench_uncached_shell_empty_store
  # bench_cached_shell_with_prebuild_store
  # bench_uncached_shell_with_prebuild_store
  # bench_cached_shell_full_store
  # bench_uncached_shell_full_store
  # bench_change_config_uncached_shell
  # bench_change_config_cached_shell

  measure_container_stats
}

update_config() {
  tmp=$(mktemp)
  jq --arg env "$ENV" \
    '.presetPath |= "/env/bench-\($env).nix" | .localPath |= "/workdir/local-\($env).nix"' \
    $config >"$tmp"
  mv -f "$tmp" "$config"
}

# TODO: Run these benchmarks for different configurations
envs=("python" "cpp")
run_both_env_benchmarks() {
  for env in "${envs[@]}"; do
    ENV=$env
    update_config

    run_benchmarks
  done
}

python_image_size_bench() {
  for i in {0..5}; do
    # change configuration
    ENV="python-${i}"
    update_config
    # don't use local config
    json=$(jq '.userConfig | [.[] | select(.type == "local").path |= ""]' $config)
    tmp=$(mktemp)
    jq --argjson json "$json" '.userConfig = $json' $config >"$tmp"
    mv -f "$tmp" "$config"

    name="${ENV}_container_stats_streamed_local"

    $run_image prune
    $run_image build
    $run_image pull
    image_size_to_csv "$out_path$name.csv"
  done
}

run_both_env_benchmarks

# python_image_size_bench
