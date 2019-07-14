FROM ruby:2.6.3-alpine3.9

ARG API_MODE=""
ARG APP_NAME=app
ARG RAILS_DATABASE_ENGINE=postgresql
ARG RAILS_VERSION=5.2.3
ARG SKIP_TEST_UNIT=""
ARG VIEW_ENGINE=react

RUN apk add build-base=0.5-r1 \
	mariadb-dev=10.3.15-r0 \
	nodejs=10.14.2-r0 \
	postgresql-dev=11.4-r0 \
	sqlite-dev=3.28.0-r0 \
	tzdata=2019a-r0 \
	yarn=1.12.3-r0 \
	--no-cache && \
	gem install bundler minitest "rails:$RAILS_VERSION" rake tzinfo-data

WORKDIR /srv

RUN rails new $APP_NAME --database=$RAILS_DATABASE_ENGINE \
	--webpack=$VIEW_ENGINE \
	$API_MODE \
	$SKIP_TEST_UNIT

COPY . /srv/$APP_NAME/

WORKDIR /srv/$APP_NAME

RUN rails app:template LOCATION=./application_template.rb && \
	bundle install && \
	ruby -v | awk {'print $1 " " $2'} | tr ' ' '-' | cut -c 1-10 | xargs echo > .ruby-version

VOLUME ["/srv/$APP_NAME"]
