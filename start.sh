#!/bin/bash
set -e

# Path to repo/project root dir (independent of pwd)
PROJECT_ROOT=$( cd $(dirname $(readlink -f $0) ); pwd )

# Load environment variables from (non-tracked) .env file
if [ -f "$PROJECT_ROOT/.env" ]
then
    export $(cat $PROJECT_ROOT/.env | xargs)
fi

# Docker image name for this project
DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-tobias/default}"

# Path to where in the docker container the project root will be mounted
export DOCKER_WORKSPACE_PATH="${DOCKER_WORKSPACE_PATH:-/workspace}"

# Path to data dir
DATA_DIR="${DATA_DIR:-$PROJECT_ROOT/data}"


while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --gpu)
    RUNTIME_ARGS="--gpus all"
    shift # past argument
    ;;
    --notebook)
    JUPYTER_PORT="-p 8888:8888"
    shift # past argument
    ;;
    -v|--mount)
    MOUNT="-v $2"
    shift # past argument
    shift # past value
    ;;
    --tensorboard)
    TENSORBOARD_PORT="-p 6006:6006"
    shift # past argument
    ;;
    -d|--detach)
    DETACH="--detach"
    shift # past argument
    ;;
    *)    # unknown option
    echo "Unrecognized argument '$1'"
    exit 1
    ;;
esac
done

USER_MAP="-u $(id -u):$(id -g)"
CONTAINER_NAME=${DOCKER_IMAGE_NAME##*/}

# Stop any potentially running container with the same name
docker stop $CONTAINER_NAME 2> /dev/null || true

set -x
docker build --rm --build-arg DOCKER_WORKSPACE_PATH -t $DOCKER_IMAGE_NAME $PROJECT_ROOT
docker run --rm -it \
  --name $CONTAINER_NAME \
  -v $PROJECT_ROOT:$DOCKER_WORKSPACE_PATH \
  -v $DATA_DIR:$DOCKER_WORKSPACE_PATH/data \
  --ipc host \
  $MOUNT \
  $USER_MAP \
  $RUNTIME_ARGS \
  $JUPYTER_PORT \
  $TENSORBOARD_PORT \
  $DETACH \
  $DOCKER_IMAGE_NAME bash
