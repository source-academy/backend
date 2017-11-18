# Cadet

Cadet is the web application powering Source Academy.

### System Requirements

1. Elixir 1.4
1. Erlang/OTP 20.1
1. Recent stable NodeJS version (>= 6.0)
1. PostgreSQL (>= 9.6)

**Important Note** Unlike the other three, Erlang/OTP version requirement is EXACT in order
for the generated server binaries to be able to run in production.

Ensure that the following command produces 20.1 as its output.
```
erl -eval '{ok, Version} = file:read_file(filename:join([code:root_dir(), "releases", erlang:system_info(otp_release), "OTP_VERSION"])), io:fwrite(Version), halt().' -noshell
```

Read DEVELOPING.md for more in-depth guide to setup development environment.

### Getting Started

1. Install Elixir dependencies using `mix deps get`
1. Initialise database using `mix ecto.setup`
1. Run the server using `mix phx.server`
1. Run the unit tests using `mix test`

### License
MIT
