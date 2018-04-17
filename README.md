# Cadet

[![Build Status](https://travis-ci.org/source-academy/cadet.svg?branch=master)](https://travis-ci.org/source-academy/cadet)
[![Coverage Status](https://coveralls.io/repos/github/source-academy/cadet/badge.svg?branch=master)](https://coveralls.io/github/source-academy/cadet?branch=master)

Cadet is the web application powering Source Academy.

## Developer Setup

### System Requirements

1. Elixir 1.5, (1.6.0-dev is recommended for the code formatter)
1. Erlang/OTP 20.1
1. NodeJS Stable
1. PostgreSQL (>= 9.6)

### Setting Up Local Development Environment

Install Elixir dependencies

    mix deps.get

Initialise Development Database

    mix ecto.setup

Install frontend dependencies

    cd frontend
    npm install

Run the server in your local machine

    mix cadet.server

## License

MIT
