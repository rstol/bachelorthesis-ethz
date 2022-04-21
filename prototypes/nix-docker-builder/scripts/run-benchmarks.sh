#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bench jq

source $(dirname "$0")/common.sh

repeats=10
run_image="./run-image.sh"
run_builder="./run-builder.sh"
out_path="$PROJECTROOT/benchmarks/"
build_layered_image="docker run --rm --volumes-from=$DATA_CONTAINER -v $PROJECTROOT:/home/user --workdir="/home/user" $BUILDER_CONTAINER layered"
build_streamed_image="docker run --rm --volumes-from=$DATA_CONTAINER -v $PROJECTROOT:/home/user --workdir="/home/user" $BUILDER_CONTAINER streamed"

image_size_to_csv() {
  size=$(docker image ls --filter=reference="$DOCKER_REGISTRY_HOST/$(./hash-files.sh)" --format "{{.Size}}")
  echo '==========================' >>$1
  echo "Image size, $size" >>$1
}

bench_empty_build_cache_streamed_local() {
  # We Empty the build cache between each test run.
  # We push the streamed image layers to a local registry.
  name="${ENV}_bench_empty_build_cache_streamed_local"
  path="$out_path$name"
  output_csv="$path.csv"

  command_to_run="$build_streamed_image"
  command_before="$run_builder create"
  command_after="$run_builder prune store"

  # init with empty cache
  $command_after

  # bench --before "$command_before" --after "$command_after" "$command_to_run" --resamples $repeats --csv "$output_csv" --output "$output_html"
  ./benchmark.sh --before "$command_before" --after "$command_after" -c "$command_to_run" --resamples $repeats -o "$output_csv"
}

bench_empty_build_cache_layered_local() {
  # We Empty the build cache between each test run.
  # We push the layered image layers to a local registry.
  name="${ENV}_bench_empty_build_cache_layered_local"
  path="$out_path$name"
  output_csv="$path.csv"

  command_to_run="$build_layered_image"
  command_before="$run_builder create"
  command_after="$run_builder prune store"

  # init with empty cache
  $command_after

  ./benchmark.sh --before "$command_before" --after "$command_after" -c "$command_to_run" --resamples $repeats -o "$output_csv"
}

bench_full_build_cache_streamed_local() {
  # We start with a full build cache. In particular the image derivation is in the cache.
  # We push the streamed image layers to a local registry.
  name="${ENV}_bench_full_build_cache_streamed_local"
  path="$out_path$name"
  output_csv="$path.csv"

  command_to_run="$build_streamed_image"
  command_after="$run_image prune"

  # init builder container and fill cache
  $run_builder prune store
  $run_builder create
  ${command_to_run}

  ./benchmark.sh -c "$command_to_run" --resamples $repeats -o "$output_csv"
}

bench_full_build_cache_layered_local() {
  # We start with a full build cache. In particular the image derivation is in the cache.
  # We push the layered image layers to a local registry.
  name="${ENV}_bench_full_build_cache_layered_local"
  path="$out_path$name"
  output_csv="$path.csv"

  command_to_run="$build_layered_image"
  command_after="$run_image prune"

  # init builder container and fill cache
  $run_builder prune store
  $run_builder create
  ${command_to_run}

  ./benchmark.sh -c "$command_to_run" --resamples $repeats -o "$output_csv"
}

# TODO: have only the packages in the cache and not the derivation of the image.
#       Find a way to not put the derivation to $out in the store.
# bench_full_packages_cache_streamed_local() {

# }

bench_pull_create_start_streamed_local() {
  name="${ENV}_bench_pull_create_start_streamed_local"
  path="$out_path$name"
  output_csv="$path.csv"

  command_after="$run_image prune"
  command_to_run="docker run --rm --net none -v $PROJECTROOT/workdir/user:/home/user --workdir="/home/user" "$DOCKER_REGISTRY_HOST/$(./hash-files.sh)""
  # init builder container and fill cache
  $run_builder prune store
  $run_builder create
  $build_streamed_image
  # Remove image if it is available locally
  ${command_after}

  ./benchmark.sh -c "$command_to_run" --after "$command_after" --resamples $repeats -o "$output_csv"
}

# Measure number of layers of image produced by the current configuration
get_num_layers() {
  $build_streamed_image
  $run_image pull
  get_image
  NUM_LAYERS=$(docker image inspect "$ENV_IMAGE" -f "{{ len .RootFS.Layers }}")
  if test $# -gt 0; then
    echo '==========================' >>$1
    echo "Number of layers in image,$NUM_LAYERS" >>$1
  fi
}

measure_container_stats() {
  name="${ENV}_container_stats_streamed_local"
  path="$out_path$name"
  output_csv="$path.csv"

  get_num_layers $output_csv

  $run_builder prune store
  $run_builder create
  $build_streamed_image
  ./docker-volume-stats.sh $output_csv

  $run_image prune
  $run_image build
  $run_image pull
  image_size_to_csv $output_csv
}

# Measure startup time
bench_startup_streamed_local() {
  name="${ENV}_bench_startup_streamed_local"
  path="$out_path$name"
  output_csv="$path.csv"

  command_to_run="docker run --rm --net none -v $PROJECTROOT/workdir/user:/home/user --workdir="/home/user" "$DOCKER_REGISTRY_HOST/$(./hash-files.sh)""
  # init builder container and fill cache
  $run_builder prune store
  $run_builder create
  $build_streamed_image
  $run_image pull

  ./benchmark.sh -c "$command_to_run" --resamples $repeats -o "$output_csv"
}

run_benchmarks() {
  bench_full_build_cache_streamed_local
  # bench_full_build_cache_layered_local
  bench_empty_build_cache_streamed_local
  # bench_empty_build_cache_layered_local

  # bench_pull_create_start_streamed_local
  # bench_startup_streamed_local

  # measure_container_stats
}

update_config() {
  json=$(jq \
    --arg env "$ENV" \
    '.userConfig |
      [.[] | select(.type == "extend").path |= "/env/bench-\($env).nix"
           | select(.type == "local").path |= "/workdir/local-\($env).nix"]' \
    $config)

  tmp=$(mktemp)
  jq --argjson json "$json" '.userConfig = $json' $config >"$tmp"
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
