# Cadet

[![Build Status](https://travis-ci.org/source-academy/cadet.svg?branch=master)](https://travis-ci.org/source-academy/cadet)
[![Coverage Status](https://coveralls.io/repos/github/source-academy/cadet/badge.svg?branch=master)](https://coveralls.io/github/source-academy/cadet?branch=master)
[![Inline docs](http://inch-ci.org/github/source-academy/cadet.svg)](http://inch-ci.org/github/source-academy/cadet)

Cadet is the web application powering Source Academy.

## Developer Setup

### System Requirements

1. Elixir 1.5, (1.6.0-dev is recommended for the code formatter)
2. Erlang/OTP 20.1
3. NodeJS Stable
4. PostgreSQL (>= 9.6)
5. git (>= 2.13.2)

### Setting Up Local Development Environment

Install Elixir dependencies

    mix deps.get

Initialise development database

    mix ecto.setup

Copy the file `.env.example` as `.env` in the project root, and replace the
value of `IVLE_KEY` in with your [IVLE LAPI Key](https://ivle.nus.edu.sg/LAPI/default.aspx).
If you've compiled the application before setting a valid value, you must force
a recompilation with `mix clean && mix`.

    IVLE_KEY=your_ivle_lapi_key

If available, also replace the values for GUEST\_USER and GUEST\_PASSWORD

Run the server in your local machine

    mix cadet.server


## Style Guide

We follow this style guide: https://github.com/lexmag/elixir-style-guide and https://github.com/christopheradams/elixir_style_guide

Where there is a conflict between the two, the first one (lexmag) shall be the one followed.

## API documentation

When the server is running, API documentation can then be accessed through http://localhost:4000/swagger

## Obtaining `access_token` in dev environment

You can obtain `access_token` JWT of a user with a given role by simply running:

    mix cadet.token <role>

For more information, run

    mix help cadet.token

## License

MIT
