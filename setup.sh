#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

source .env

BOOTSTRAP_CONTAINER_NAME=${APP_NAME}
BOOTSTRAP_CONTAINER_VERSION=0.1.0
DATABASE_ENGINE=""
match=""
BASH_REMATCH=""

set-database-engine-var() {
    if [[ "$SHELL" =~ "zsh" ]]; then
	if [[ "$RAILS_DATABASE_ENGINE" =~ ^--database=(.+)$ ]]; then
	    DATABASE_ENGINE=$match[1]
	fi
    else
	if [[ "$RAILS_DATABASE_ENGINE" =~ ^--database=(.+)$ ]]; then
	    DATABASE_ENGINE=${BASH_REMATCH[1]}
	fi
    fi
}

build() {
    echo "Building initial image..."
    docker build --build-arg API_MODE=$API_MODE \
	    --build-arg APP_NAME=$APP_NAME \
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

make-service-dir() {
    echo "Making services/$APP_NAME directory..."
    mkdir -p services/$APP_NAME
}

sync() {
    echo "Syncing container's /srv/$APP_NAME with services/$APP_NAME..."
    docker run --name $BOOTSTRAP_CONTAINER_NAME $BOOTSTRAP_CONTAINER_NAME:$BOOTSTRAP_CONTAINER_VERSION
    CONTAINER_ID=$(docker container ls -aq -f name=^$BOOTSTRAP_CONTAINER_NAME$)
    docker cp $CONTAINER_ID:/srv/$APP_NAME/ services/
    (cd services/$APP_NAME && git init)
    docker container rm $CONTAINER_ID
}

update-db-config() {
      DATABASE_CONFIG=services/${APP_NAME}/config/database.yml
      set-database-engine-var

      if [[ "$DATABASE_ENGINE" = "postgresql" ]]; then
	POSTGRES_IMAGE_USER=postgres
	POSTGRES_IMAGE_PW=postgres
	POSTGRES_IMAGE_DB=postgres
	DATABASE_IMAGE_NAME=postgres

	echo "Updating development database name..."
	sed -i '' -E "s/^(  database: )${APP_NAME}_development$/\1${POSTGRES_IMAGE_DB}/g" $DATABASE_CONFIG
	echo "Updating development database username..."
	sed -i '' -E "s/^(  )#(username: )${APP_NAME}/\1\2${POSTGRES_IMAGE_USER}/g" $DATABASE_CONFIG
	echo "Updating development database password..."
	sed -i '' -E "s/^(  )#(password:)$/\1\2 ${POSTGRES_IMAGE_PW}/g" $DATABASE_CONFIG
	echo "Updating development database host..."
	sed -i '' -E "s/^(  )#(host: )localhost$/\1\2${DATABASE_IMAGE_NAME}/g" $DATABASE_CONFIG
	echo "Updating development database port..."
	sed -i '' -E "s/^(  )#(port: 5432)$/\1\2/g" $DATABASE_CONFIG
      elif [[ "$DATABASE_ENGINE" = "mysql" ]]; then
	MYSQL_IMAGE_PW=root
	DATABASE_IMAGE_NAME=mysql

	echo "Updating development database password..."
	sed -i '' -E "s/^(  password:)$/\1 ${MYSQL_IMAGE_PW}/g" $DATABASE_CONFIG
	echo "Updating development database host..."
	sed -i '' -E "s/^(  host: )localhost$/\1${DATABASE_IMAGE_NAME}/g" $DATABASE_CONFIG
	echo "Updating development database port..."
	sed -i '' -E "s/^(  )#(port: )3306$/\1\2/g" $DATABASE_CONFIG
      fi
}

docker-compose-up() {
    echo "Booting up Rails.."
    case "$RAILS_DATABASE_ENGINE" in
      --database=postgresql)
	echo "Using postgres as datastore..."
	(cd services/$APP_NAME && docker-compose up -d rails postgres)
        ;;
      --database=mysql)
	echo "Using mysql as datastore..."
	(cd services/$APP_NAME && docker-compose up -d rails mysql)
        ;;
      *)
	echo "Falling back to sqlite as datastore..."
	(cd services/$APP_NAME && docker-compose up -d rails)
        ;;
    esac
}

goodbye() {
    cat << EOF
Setup complete...

Your Rails $RAILS_VERSION application is waiting for you at http://localhost:<3000|your configured port>

Change directories to services/$APP_NAME and get to work!

Good luck experimenting!

EOF
}

build
make-service-dir
sync
update-db-config
docker-compose-up
goodbye
