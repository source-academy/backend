# Cadet

[![Build Status](https://travis-ci.org/source-academy/cadet.svg?branch=master)](https://travis-ci.org/source-academy/cadet)
[![Coverage Status](https://coveralls.io/repos/github/source-academy/cadet/badge.svg?branch=master)](https://coveralls.io/github/source-academy/cadet?branch=master)
[![Inline docs](http://inch-ci.org/github/source-academy/cadet.svg)](http://inch-ci.org/github/source-academy/cadet)

Cadet is the web application powering Source Academy.

## Developer Setup

### System Requirements

1. Elixir 1.8
2. Erlang/OTP 21
3. PostgreSQL (>= 9.6)

### Setting Up Local Development Environment

1. Setup the development secrets (replace the values appropriately)
```bash
$ cp config/secrets.exs.example config/secrets.exs
$ vim config/secrets.exs
```    
  - A valid `luminus_api_key`, `luminus_client_id`, `luminus_client_secret` and 
    `luminus_redirect_url` are required for the application to properly authenticate with LumiNUS.
  - A valid `cs1101s_repository`, `cs1101s_rsa_key` is required for the application to 
    run with the `--updater` flag. Otherwise, the default values will suffice.
  - A valid `instance_id`, `key_id` and `key_secret` are required to use ChatKit's services. Otherwise, the placeholder values can be left as they are.

2. Install Elixir dependencies
```bash
$ mix deps.get
```

3. Initialise development database
```bash
$ mix ecto.setup
```

4. Run the server in your local machine
```bash
$ mix phx.server
```

5. You may now make API calls to the server locally via `localhost:4000`. The API documentation can
   also be accessed at http://localhost:4000/swagger.


### Obtaining `access_token` in dev environment

You can obtain `access_token` JWT of a user with a given role by simply running:

```bash
$ mix cadet.token <role>
```

For more information, run

```bash
$ mix help cadet.token
```

### Handling CORS Preflight Request

We recommend setting up nginx to handle preflight checks using the following 
[config file](https://github.com/source-academy/tools/blob/master/demo-assessments/templates/nginx.conf).

If you do this, do remember to point cadet-frontend to port `4001` instead of `4000`

### Chatkit

The chat functionality is built on top of Chatkit and provides two-way communication between cadets and avengers. This replaces the previous comment field found in assignments. Its documentation can be found [here](https://pusher.com/docs/chatkit).

If you are using Chatkit, obtain your instance ID, key ID and secret key from your account, and set them in. Instructions to that are found [here](https://pusher.com/docs/chatkit/authentication#chatkit-key-and-instance-id).

Internet connection is required for usage.


### Style Guide

We follow this style guide: https://github.com/lexmag/elixir-style-guide and https://github.com/christopheradams/elixir_style_guide

Where there is a conflict between the two, the first one (lexmag) shall be the one followed.


## Entity-Relationship Diagram

Last generated on 1 January 2019

![Entity-Relationship Diagram for cadet](schema.png)

## License

MIT
