# Configurable Rails Docker Quickstart

## Purpose

The goal of this project is to make setting up a hobby Rails application in Docker as easy and as flexible as possible without requiring a developer to configure, install and manage versions of Ruby and Node.

## Requirements

* Docker
* Bash

## Usage

Clone this repo:

```
clone this repo
```

Copy the `example.env` file to `.env` and configure it's settings to target the version of Rails/database you want to tinker with.

Alternatively, don't configure the file. The defaults are enough to get you set up and going.

```
cp -p example.env .env
```

Run the setup script:

```
./setup.sh
```

Your Rails application awaits at `http://localhost:<your_configurable_port>`!

## Caveats

This has only been test on Mac OS. Linux might work. YMMV. Windows? No idea.

This project assumes passing familiarity with Docker and Docker Compose.

At this time there's no plan to automatically support running the Dockerized Rails application the production environment. Running the Rails application in the test environment isn't supported yet either, but possibly one day.
