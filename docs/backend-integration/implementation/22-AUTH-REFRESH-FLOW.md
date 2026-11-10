# Authentication refresh flow

`AuthInterceptor` adds the current bearer token to requests. A `401` starts one shared refresh operation; concurrent failed requests await that same operation rather than issuing parallel refresh calls.

On success, both returned tokens are persisted and the original request is retried once with refresh disabled. On failure, token storage is cleared and the original error is returned to the caller.

The refresh request uses a separate Dio instance so it cannot recursively trigger the authenticated-request interceptor.
