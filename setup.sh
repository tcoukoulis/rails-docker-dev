#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

source .env

BOOTSTRAP_CONTAINER_NAME=rails-bootstrap
BOOTSTRAP_CONTAINER_VERSION=0.1.0

build() {
    docker build --build-arg APP_NAME=$APP_NAME \
	    --build-arg RAILS_DATABASE_ENGINE=$RAILS_DATABASE_ENGINE \
	    --build-arg RAILS_VERSION=$RAILS_VERSION \
	    --build-arg SKIP_TEST_UNIT=$SKIP_TEST_UNIT \
	    --build-arg VIEW_ENGINE=$VIEW_ENGINE \
	    -t $BOOTSTRAP_CONTAINER_NAME:$BOOTSTRAP_CONTAINER_VERSION .
}

cleanup() {
    docker image ls | \
	    grep $BOOTSTRAP_CONTAINER_NAME | \
	    awk '{ print $3 }' | \
	    xargs docker rmi
}

sync() {
  docker run --name $BOOTSTRAP_CONTAINER_NAME $BOOTSTRAP_CONTAINER_NAME:$BOOTSTRAP_CONTAINER_VERSION
  CONTAINER_ID=$(docker container ls -aq -f name=^$BOOTSTRAP_CONTAINER_NAME$)
  docker cp $CONTAINER_ID:/srv/$APP_NAME/ services/
  docker container rm $CONTAINER_ID
}

update-db-config() {
    DATABASE_CONFIG=services/${APP_NAME}/config/database.yml
    POSTGRES_IMAGE_USER=postgres
    POSTGRES_IMAGE_PW=postgres
    POSTGRES_IMAGE_DB=postgres
    DATABASE_IMAGE_NAME=database

    echo "Updating development database name..."
    sed -i '' -e "s/^${APP_NAME}_development$/${POSTGRES_IMAGE_DB}/g" $DATABASE_CONFIG
    echo "Updating development database username..."
    sed -i '' -E "s/^(  )#(username: )${APP_NAME}/\1\2${POSTGRES_IMAGE_USER}/g" $DATABASE_CONFIG
    echo "Updating development database password..."
    sed -i '' -E "s/^(  )#(password:)$/\1\2 ${POSTGRES_IMAGE_PW}/g" $DATABASE_CONFIG
    echo "Updating development database host..."
    sed -i '' -E "s/^(  )#(host: )localhost$/\1\2${DATABASE_IMAGE_NAME}/g" $DATABASE_CONFIG
    echo "Updating development database port..."
    sed -i '' -E "s/^(  )#(port: )5432$/\1\2${DATABASE_PORT}/g" $DATABASE_CONFIG
}

echo "Building initial image..."
build
echo "Making services/$APP_NAME directory..."
mkdir -p services/$APP_NAME
echo "Syncing container's /srv/$APP_NAME with services/$APP_NAME..."
sync
update-db-config
# Add option to get stdin and see if user wants to spin docker up automatically
cat << EOF
Setup complete...
Change directories to services/$APP_NAME and bring up everything with:

    docker-compose up -d

Your Rails $RAILS_VERSION application will be ready and waiting for you at http://localhost:$RAILS_LISTEN_PORT
Good luck experimenting!

EOF
