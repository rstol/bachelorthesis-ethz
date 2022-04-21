cd "$(dirname "$0")"

set -euo pipefail
PROJECTROOT="$(dirname -- $(pwd -P))"
DOCKER_REGISTRY_HOST="cxhub.ethz.ch/cx/cxenv/"
WORKDIR="/home/user"

repeats=10
out_path="$PROJECTROOT/benchmarks/"
images=("base-rhel8" "python-3_8" "gcc-8")

build_image="docker image build --no-cache=true --rm=true"
run_image="docker run --rm --net none -v "$PROJECTROOT/workdir/user:$WORKDIR""

remove_image() {
  if [[ -n $(docker images -q "$IMG") ]]; then
    echo "Removing image: $IMG..."
    docker rmi --force=true "$IMG"
  fi
}

bench_build_local() {
  name="${ENV}_bench_build_local"
  path="$out_path$name"
  output_csv="$path.csv"

  command_to_run="$build_image $ENV"
  command_before="docker rmi --force=true $IMG"

  ./benchmark.sh -c "$command_to_run" --before "$command_before" --resamples $repeats -o "$output_csv"
}

bench_pull_startup() {
  name="${IMG}_bench_pull_startup"
  path="$out_path$name"
  output_csv="$path.csv"

  command_to_run="$run_image $IMG"
  command_before="docker rmi --force=true $IMG"

  ./benchmark.sh -c "$command_to_run" --before "$command_before" --resamples $repeats -o "$output_csv"
}

bench_startup() {
  name="${IMG}_bench_startup"
  path="$out_path$name"
  output_csv="$path.csv"

  command_to_run="$run_image $IMG"
  # pull image such that it is available locally
  $run_image $IMG

  ./benchmark.sh -c "$command_to_run" --resamples $repeats -o "$output_csv"
}

run_benchmarks() {
  bench_build_local
  bench_pull_startup
  bench_startup
}

for img in "${images[@]}"; do
  ENV=$img
  IMG="$DOCKER_REGISTRY_HOST$img"

  run_benchmarks
done
