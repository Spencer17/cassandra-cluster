#!/bin/bash
function generate_build_args {
  RESULT=""
  for arg in $@
  do
    RESULT="$RESULT --build-arg=$arg"
  done
  echo $RESULT | xargs
}

CLEAN=0

if [ $1 == "--clean" ]
then
  CLEAN=1
  shift 1
fi

if [ $# -lt 1 ]
then
  echo "Usage: ./build.sh [--clean] <imageTag> <dockerBuildArgs>"
  exit 1
fi

DOCKER_TAG=$1

shift 1

pushd java
 if [ $CLEAN -eq 0 ]
 then
   mvn package
   cp target/kubernetes-cassandra.jar ../image
 else
   echo "Cleaning Java Maven project"
   mvn clean
 fi
popd

pushd image
  if [ $CLEAN -eq 0 ]
  then
    # TODO Continue Here
    echo "Building Docker image with tag $DOCKER_TAG and build args "
    DOCKER_BUILD_ARGS=$(generate_build_args $@)
    #echo $DOCKER_BUILD_ARGS
    docker build -t $DOCKER_TAG $DOCKER_BUILD_ARGS .
  else
    echo "Removing Docker image"
    docker rmi $DOCKER_TAG
  fi
popd
