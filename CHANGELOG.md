## Unreleased

...

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
