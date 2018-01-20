# Cadet

[![Build Status](https://travis-ci.org/evansb/cadet.svg?branch=master&service=github)](https://travis-ci.org/evansb/cadet)
[![Coverage Status](https://coveralls.io/repos/github/evansb/cadet/badge.svg)](https://coveralls.io/github/evansb/cadet)

Cadet is the web application powering Source Academy.

## Developer Setup

### System Requirements

1. Elixir 1.5, (1.6.0-dev is recommended for the code formatter)
1. Erlang/OTP 20.1
1. NodeJS Stable
1. PostgreSQL (>= 9.6)

### Setting Up Local Development Environment

Install Elixir dependencies

    mix deps get

Initialise Development Database

    mix ecto.setup

Install frontend dependencies

    cd frontend
    npm install

Run the server in your local machine

    mix cadet.server

## License

MIT
