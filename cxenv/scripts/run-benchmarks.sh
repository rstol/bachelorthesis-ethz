cd "$(dirname "$0")"

set -euo pipefail
PROJECTROOT="$(dirname -- $(pwd -P))"
DOCKER_REGISTRY_HOST="cxhub.ethz.ch/cx/cxenv/"
WORKDIR="/home/user"

out_path="$PROJECTROOT/benchmarks/"
images=("gcc-8" "python-3_8")

build_image="docker image build --no-cache"
run_image="docker run --rm --net none -v "$PROJECTROOT/workdir/user:$WORKDIR""

image_size_to_csv() {
  size=$(docker image ls --filter=reference=$IMG --format "{{.Size}}")
  echo '==========================' >>$1
  echo "Image size, $size" >>$1
}

# Measure number of layers of image produced by the current configuration
num_layers() {
  NUM_LAYERS=$(docker image inspect "$IMG" -f "{{ len .RootFS.Layers }}")
  if test $# -gt 0; then
    echo '==========================' >>$1
    echo "Number of layers in image,$NUM_LAYERS" >>$1
  fi
}

remove_image() {
  if [[ -n $(docker images -q "$IMG") ]]; then
    echo "Removing image: $IMG..."
    docker rmi --force=true "$IMG"
  fi
}

measure_image_stats() {
  name="${ENV}_image_stats"
  path="$out_path$name"
  output_csv="$path.csv"

  command_to_run="$run_image $IMG bash"

  num_layers $output_csv
  image_size_to_csv $output_csv
}

bench_build_local() {
  name="${ENV}_bench_build_local"
  path="$out_path$name"
  output_csv="$path.csv"

  command_to_run="$build_image $PROJECTROOT/$ENV"

  ./benchmark.sh -c "$command_to_run" -o "$output_csv"
}

bench_pull_startup() {
  name="${ENV}_bench_pull_startup"
  path="$out_path$name"
  output_csv="$path.csv"

  command_to_run="$run_image $IMG bash"
  command_before="docker rmi --force=true $IMG"

  ./benchmark.sh -c "$command_to_run" --before "$command_before" -o "$output_csv"
}

bench_startup() {
  name="${ENV}_bench_startup"
  path="$out_path$name"
  output_csv="$path.csv"

  command_to_run="$run_image ${IMG} bash"
  # pull image such that it is available locally
  ${command_to_run}

  ./benchmark.sh -c "$command_to_run" -o "$output_csv"
}

run_benchmarks() {
  bench_build_local
  bench_pull_startup
  bench_startup
  measure_image_stats
}

for img in "${images[@]}"; do
  ENV="$img"
  IMG="$DOCKER_REGISTRY_HOST$img"

  run_benchmarks
done
