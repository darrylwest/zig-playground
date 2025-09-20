# Zig HTTP Server

## Overview

Build a HTTP server in **zig** starting with `zig init` and using the **std.http** lib.  Server should support static pages, REST routing, json encode/decoding.

## Landing Page

* A simple static page with header, body and footer sections
* minimal css for styling
* navigation in header to show other pages, About, Contact Us, API Reference

## REST endpoints

* /api/v1/health - returns "ok"
* /api/v1/ping - returns "PONG"
* /api/v1/status - returns json: { uptime: "", session_count: 0, timestamp: "iso8601 datetime"}
* /api/v1/version - returns the current application version, e.g., 0.1.0  (major, minor, patch)

## Testing

Add minimal unit tests with **std.testing** framework

## Tasks

1. evaluate project objectives
2. create an implementation plan
3. iteratate over plan to refine
4. agree on a plan
5. implement the plan


