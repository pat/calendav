## Unreleased

## 0.5.0 - 2025-08-02

* Support for todos (Josh Huckabee #8, #9)
* Improved documentation for development/testing environments (Josh Huckabee #7)
* Support for expanded recurring events (Sayooj Surendran #12)
* Support for OAuth authentication header (Ilya Nikitenkov #13)
* Updated tested Ruby versions to 3.1-3.4 (2.7 and 3.0 are no longer officially supported).

## 0.4.0 - 2023-02-27

* **Breaking**: calls to create/update events return event objects that only have a URL and etag populated (so: no calendar data), or nil if the request failed due to an etag precondition. This is instead of returning true on success or false on failure.
* Removed test files from the gem/gemspec.
* Increased nuance of error handler, raising a RedirectError (with location method) if the CalDAV server returns a redirect status.

## 0.3.0 - 2022-03-14

* Add location to event wrapper.
* Allow setting timeouts for client calls.
* Avoid external calls to calculate calendar URLs where possible.

## 0.2.0 - 2021-07-07

* Improve serialisation of Event and Calendar objects (easily converted to/from hashes).
* Add `more?` to sync collection objects, indicating whether there are further changes available.

## 0.1.1 - 2021-06-28

* Fix reports lists to just the relevant calendar.

## 0.1.0 - 2021-06-14

* Support creating and deleting calendars.
* Updating of events (with optional etag check).
* List all events on a calendar (no timespan required).
* Updating of calendars.
* Allow for etag check to be used on event deletions.
* Finding of single events and calendars by URLs.
* Check if calendar creation is possible.
* WebDAV-Sync support.
* A vastly more useful README.

## 0.0.1 - 2021-06-13

An initial release with very limited (and likely buggy) support:

* Determining the principal URL.
* Determining the calendar home path.
* Listing available calendars.
* Creating events on a calendar.
* Listing events on a calendar within a given timespan.
* Deleting events on a calendar.
