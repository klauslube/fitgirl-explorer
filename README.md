# FitGirl Explorer

A searchable catalog of the **Lossless Repack** posts published on https://fitgirl-repacks.site/, with the filters the
original site lacks: comment count, genres/tags, publication date, repack size and name — combinable, shareable by URL.

It indexes **public metadata only** (title, date, tags, sizes, cover URL, comment count). It never reads, stores or links
download mirrors, magnets or torrents; every game links back to the original post.

## Stack

Ruby 3.4 · Rails 8.1 · PostgreSQL · Hotwire (Turbo + Stimulus) · Tailwind CSS · Nokogiri · Pagy · RSpec.
No SPA framework, no separate API.

## Setup

```bash
bundle install
bin/rails db:create db:migrate
bin/rails fitgirl:import     # initial import, ~10-15 min (polite 4 s delay between requests)
bin/dev                      # Rails + Tailwind watcher on http://localhost:3000
```

PostgreSQL needs the `pg_trgm` extension (bundled with the standard `postgresql-contrib`).
If port 3000 is taken: `PORT=3100 bin/dev`.

## Keeping the data fresh

```bash
bin/rails fitgirl:sync        # posts modified since the last run + comment counts of the last 30 days
bin/rails fitgirl:comments    # recount comments for every game
```

Run `fitgirl:sync` hourly (cron, systemd timer, or enqueue `SyncCatalogJob`). Runs are recorded in `scrape_runs`
(status, stats, error). The request delay can be changed with `FITGIRL_REQUEST_DELAY` (seconds, default 4).

## Where the data comes from

| Data | Source |
|---|---|
| Posts, dates, tags | public WordPress REST API (`/wp-json/wp/v2/posts`, 100 per page, `modified_after` for incrementals) |
| Sizes, companies, languages, cover | the post's info block, parsed from `content.rendered` (no per-page scraping) |
| Comment count | the third-party Tolstoy widget the site embeds: `web.tolstoycomments.com/api/chat/countcomment`, keyed by `md5("fitgirl-repacks.site/<slug>/")`, 100 posts per request |

The Tolstoy endpoint is undocumented. All knowledge of it lives in `Fitgirl::TolstoyClient`; if its response changes the
client raises a clear error and the rest of the catalog keeps working.

### Access etiquette

`robots.txt` allows everything. The client identifies itself, waits between requests, retries only transient errors
(429/5xx, timeouts) with backoff and honours `Retry-After`. A 403 or a non-JSON "challenge" page aborts the run —
nothing tries to bypass protection.

## Architecture

```
app/services/fitgirl/   Http, WpClient, TolstoyClient, PostParser, SizeParser, TitleNormalizer,
                        GameImporter, CatalogSync, CommentsSync
app/queries/            GameSearch  (GET params -> composed Game scopes)
app/models/             Game, Tag, GameTag, ScrapeRun
app/jobs/               SyncCatalogJob, SyncCommentsJob
```

* Genres and tags are the same thing on the source (WordPress tags), so there is a single `Tag` model.
* Sizes are stored in bytes (`repack_size_min_bytes`/`max` because posts sometimes give a range like `2.1/2.3 GB`).
  Size filtering and sorting use the minimum.
* Duplicates are impossible by construction: unique indexes on `wp_post_id` and `slug`, idempotent upserts.
* Filters run in PostgreSQL (trigram index for name search); the catalog is paginated server-side with Pagy and
  eager-loads tags.
* Filtering uses a plain GET form, so every filtered view is a shareable URL. Turbo Frames update only the results.

## Catalog URL parameters

`q`, `tag_ids[]` (must match all), `min_comments`, `from`, `to` (ISO dates), `min_size`, `max_size` (GB),
`sort` = `comments_desc | comments_asc | newest | oldest | name | size_desc | size_asc`, `page`.

## Tests

```bash
bundle exec rspec
```

Scraper specs use real (sanitised) post HTML and API responses in `spec/fixtures/fitgirl/`; no test touches the network.
