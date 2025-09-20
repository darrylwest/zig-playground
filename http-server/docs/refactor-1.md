# HTTP Server Refactor

## Tasks

* [x] add config file in json format to specify host, port
* [ ] refactor src/handlers/static.zig:getMimeType to replace nested if/then/else with a stringhash key -> value, e.g. html -> text/html, css -> text/css, js -> application/javascript
* [ ] create helpers for HTTP responses
* [x] add PATCH to http methods
* [x] add VERSION to config or main
* [ ] test coverage?
* [ ] a http client?
* [ ] improved the logger to support log.info(), log.warn, etc.
* [ ] add OkRedis to project and add get, set, del to the REST endpoints to act on redis/valkey

## Research

* [ ] search for HTTP 3rd-party support/frameworks
* [ ] create a library for REST routing and handling

