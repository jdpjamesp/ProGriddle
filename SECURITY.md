# Security policy

## Supported versions

ProGriddle has no numbered releases yet. Only the latest commit on `main` is supported.

## Reporting a vulnerability

Please do not open a public issue for a security problem. Use GitHub's private reporting instead:

1. Go to the [Security tab](https://github.com/jdpjamesp/ProGriddle/security) of the repository.
2. Choose **Report a vulnerability** and describe what you found, how to reproduce it and what it affects.

You can expect a first reply within about a week. If the report is accepted, a fix is made on `main` and you are credited in the commit unless you prefer not to be.

## Scope

ProGriddle is a desktop framework and set of games with no server and no network code. Things that count include unsafe handling of files the games read or write (for example saved settings), and memory safety problems around `MEMPTR` and the .NET bridge.
