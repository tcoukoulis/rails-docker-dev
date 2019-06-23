# Configurable Rails Docker Quickstart

## Purpose

The goal of this project is to make setting up a hobby Rails application in Docker as easy and as flexible as possible without requiring a developer to configure, install and manage versions of Ruby and Node.

## Requirements

* Docker
* Bash

## Usage

### Clone the repository

```
git clone git@github.com:tcoukoulis/rails-docker-dev.git
```

Copy the `example.env` file to `.env` and configure it's settings to target the version of Rails/database you want to tinker with.

Alternatively, don't configure the file. The defaults are enough to get you set up and going.

```
cp -p example.env .env
```

_Note: by default the datastore will be set to use a [Postgres](https://hub.docker.com/_/postgres) container._

### Configure

By default the Rails application will start up no custom gems. Configure your Rails application to use whatever gems you require by modifying the [application_template.rb](https://github.com/tcoukoulis/rails-docker-dev/blob/master/application_template.rb) file.

Read more about application templates in the Rails [Guide](https://guides.rubyonrails.org/rails_application_templates.html).

### Run the setup script

```
./setup.sh
```

Your Rails application awaits at `http://localhost:<your_configurable_port>`!

## Caveats

This has only been test on Mac OS. Linux might work. YMMV. Windows? No idea.

This project assumes passing familiarity with Docker and Docker Compose.

At this time there's no plan to automatically support running the Dockerized Rails application the production environment. Running the Rails application in the test environment isn't supported yet either, but possibly one day.
