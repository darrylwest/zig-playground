# Simple HTTP / REST Server

I wanted to create a very simple REST service in zig without using any 3rd party frameworks or tools.  The service includes...

- custom logging
- static pages
- routed end-points
- support for GET, POST, PUT, DELETE, PATCH, and OPTIONS methods
- unit and integration tests

I started with **zig init** to create the basic framework, then after working through the **project specs** had clause build the project out.

Here is a copy of the project plan:

## Zig HTTP Server

### Overview

Build a HTTP server in **zig** starting with `zig init` and using the **std.http** lib.  Server should support static pages, REST routing, json encode/decoding.

### Landing Page

* A simple static page with header, body and footer sections
* minimal css for styling
* navigation in header to show other pages, About, Contact Us, API Reference

### REST endpoints

* /api/v1/health - returns "ok"
* /api/v1/ping - returns "PONG"
* /api/v1/status - returns json: { uptime: "", session_count: 0, timestamp: "iso8601 datetime"}
* /api/v1/version - returns the current application version, e.g., 0.1.0  (major, minor, patch)

### Testing

Add minimal unit tests with **std.testing** framework

### Tasks

1. evaluate project objectives
2. create an implementation plan
3. iteratate over plan to refine
4. agree on a plan
5. implement the plan

## Final Product

The service runs on the **host** and **port** as specified in a **config.json** file.  The home page shows the API Endpoints with links to exercise each one.  End points include:

- /api/v1/health - health check
- /api/v1/ping - returns PONG
- /api/v1/version - returns current version as specified in the **build.zig.zon** file
- /api/v1/status - returns uptime, number of accesses, current timestamp etc.

Static pages include About, Contact Us, and API Reference.

## Next Steps

- [ ] research 3rd-party HTTP server frameworks
- [ ] create a library to support the creation of simple REST servers
- [ ] find 3rd-party logger
- [ ] add a **contact form** to Contact Us page to capture first, last, and email address.

###### dpw | 2025.09.22
