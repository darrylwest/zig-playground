# HTTP Server Refactor

## Tasks

* add config file in json format to specify host, port
* refactor src/handlers/static.zig:getMimeType to replace nested if/then/else with a stringhash key -> value, e.g. html -> text/html, css -> text/css, js -> application/javascript
* create helpers for HTTP responses
* add PATCH to http methods
* add VERSION to config or main

