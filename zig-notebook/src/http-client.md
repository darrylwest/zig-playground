# Zig HTTP Client

An HTTP client from the `std.http` library.

## Simple GET JSON Example

The endpoint is `https://jsonplaceholder.typicode.com/todos/3` for a test fetch.

Response:

```
HTTP Client Example
==================
Making request to: https://jsonplaceholder.typicode.com/todos/1
Status: .ok
Request completed successfully!

Simulated Response Body (actual request was made to the API):
{
  "userId": 1,
  "id": 3,
  "title": "delectus aut autem",
  "completed": false
}

Todo title: delectus aut autem
User ID: 1
Todo ID: 3
Completed: false
```

###### dpw | 2025.09.23


