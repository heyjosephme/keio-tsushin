# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Keio Tsushin helps Keio University distance-learning (通信教育) students do four things: plan courses across exam seasons, track report and exam deadlines, spot exam-time conflicts, and keep study PDFs at hand.

Stack: Ruby 4.0, Rails 8.1, Phlex-Rails 2.4 (all page views and components), Hotwire (Turbo + Stimulus), Tailwind CSS v4 via `tailwindcss-rails`, and importmap (no Node/npm). Data lives in SQLite with Solid Cache/Queue/Cable. Deployment uses Kamal and Thruster.

## Commands

```bash
bin/setup                  # bundle, db:prepare, then exec bin/dev (--skip-server to stop before; --reset adds db:reset)
bin/dev                    # https://keio-tsushin.localhost:3000 + Tailwind watcher, signed in as the demo user
bin/rails test             # all tests except system tests
bin/rails test test/controllers/enrollments_controller_test.rb      # one file
bin/rails test test/controllers/enrollments_controller_test.rb:19   # one test, by line
bin/rails test:system      # system tests (test/system/ is currently empty)
bin/rubocop                # lint; add -a to autocorrect
bin/brakeman               # security scan
bin/ci                     # full local pipeline, defined in config/ci.rb
bin/rails db:seed:replant  # reset DB and reseed (wipes all user data, see Seeds)
bin/kamal deploy           # deploy; aliases: bin/kamal console | shell | logs | dbc
```

`bin/ci` runs these steps in order:

1. `bin/setup --skip-server`
2. rubocop
3. bundler-audit
4. importmap audit
5. brakeman (`--exit-on-warn`)
6. `test`
7. `test:system`
8. `RAILS_ENV=test bin/rails db:seed:replant`

GitHub Actions (`.github/workflows/ci.yml`) runs the same checks as five parallel jobs, minus the seed step.

`bin/dev` gets its certificate from mkcert (issued into `tmp/certs/` on first run) and hands it to Puma through the `BINDING` env var, which `bin/rails server` reads. Without mkcert it serves plain HTTP on the same host. It stays on port 3000 because macOS lets non-root processes bind 443 only on all interfaces, which would expose the dev server to the LAN.

## Architecture

### URLs vs. controller names

Controller names don't match the URLs. Check this table before editing a page:

| URL | Controller → views | Purpose |
|---|---|---|
| `/courses`, `/courses/:id`, `/courses/new`, `/courses/dashboard` | `EnrollmentsController` → `Views::Enrollments::*` (`resources :enrollments, path: "courses"`) | The user's plan: kanban board by season, enrollment detail (`:id` is an Enrollment id), credit dashboard |
| `/catalog`, `/catalog/:key` | `CoursesController` → `Views::Catalog::*` | Browse the YAML course catalog; `:key` is a course key like `phil101` |
| `/deadlines` | `DeadlinesController` | Monthly calendar (`Components::Calendar`) |
| `/documents` | `PagesController#documents` | PDF upload/viewer page |
| `/documents/check/:key`, `/documents/file/:key` | `DocumentsController` | JSON/file API the PDF viewer uses in server mode |

Route helpers follow the resource names, not the URLs. For example, `enrollments_path` is `/courses` and `catalog_course_path(key)` is `/catalog/:key`.

### Hybrid data model: YAML catalogs + ActiveRecord user data

- `Course` (`config/courses.yml`), `Season` (`config/seasons.yml`), and `ExamTimetable` (`config/exam_timetable.yml`) are plain Ruby classes loaded from YAML. Each file's header comment documents its schema. ActiveRecord holds only per-user data: `User`, `Session`, `Enrollment`, `Deadline`, and Active Storage attachments.
- `Enrollment` stores `course_key`, `season_key`, and `status` (`planned → report_submitted → exam_applied → completed`). It finds its course and season (`#course`, `#season`) by YAML lookup and delegates `name`, `credits`, and `field` to the course.
  - The keys aren't validated against the catalogs. An unknown key saves fine, and then `enrollment.course` and the delegated methods return `nil`, so use `&.`.
  - Credit totals (`Enrollment.credit_stats`, `.credits_by_field`) are computed in Ruby because credits and field live in YAML. They can't be done in SQL, and the `by_field` scope does nothing.
- **Season keys are `"YYYYMM"` strings (`"202604"`), not `"2026_04"`.** YAML reads the unquoted key `2026_04` as the integer `202604`, and `Season` converts it to a string. So `Season.find("2026_04")` returns `nil`. Fixtures that say `season_key: 2026_04` are parsed the same way and end up as `"202604"`.
- `Course.all`, `Season.all`, and `ExamTimetable.config` are cached on the class, and the dev reloader doesn't watch `config/*.yml`. Restart the server after editing those files. In a console, `Course.reload!` also works.
- `Season.upcoming(n)` returns seasons whose report deadline hasn't passed. It drives the planner columns and every season picker. `seasons.yml` has to be extended as time passes, or the board goes empty.
- The catalog and planner show only courses for the user's major (`Course.for_major(Current.user.major)`). `majors: [all]` marks a course common to all majors, and a blank major shows everything.
- The subject-area term is **field** (分野, `Course::FIELDS`). `#field_label` gives the Japanese name. It was renamed from "category"; use "field" in new code.

### Exam timetable and conflicts

A course can have an `exam_group` (A–F), and `ExamTimetable` maps each group to a Saturday/Sunday time slot. The order depends on the season type, which comes from the `exam_start` month:

- April/July seasons (`apr_jul`) run A→F.
- October/January seasons (`oct_jan`) run F→A.

Two or more enrolled courses in the same group in one season are a conflict (`ExamTimetable.conflicts_for`). The planner board (`Views::Enrollments::Index`) and the catalog detail page (`Views::Catalog::Show`) both use this.

### Deadlines calendar

`DeadlinesController#index` merges the user's `Deadline` records with `SeasonDeadline` structs built from `seasons.yml`, which mimic the `Deadline` interface. These generated entries can have `deadline_type: "application"`, which the `Deadline` model itself rejects (it allows only `report`/`exam`).

### Authentication and data scoping

The app uses Rails 8's generated authentication (`app/controllers/concerns/authentication.rb`, `Current.session` / `Current.user`). Every controller requires login unless it calls `allow_unauthenticated_access`, and `PagesController` is fully public. Always reach user data through `Current.user.enrollments`, `.deadlines`, or `.documents`. That scoping is the only authorization layer.

In development, `start_auto_login_session` signs local requests in as `ENV["AUTO_LOGIN_EMAIL"]`, which `bin/dev` sets to `student@example.com` by default. Signing out therefore doesn't stick; run `AUTO_LOGIN_EMAIL= bin/dev` when working on the sign-in flow. It never activates outside development (`test/integration/auto_login_test.rb`).

### Document storage (two modes)

`Components::PdfViewer` and `pdf_viewer_controller.js` pick a backend from `ENV["DOCUMENT_STORAGE"]`:

- `browser` (the default, and production since `config/deploy.yml` doesn't set it): PDFs are stored in IndexedDB (`KeioTsushinPDFs`, via Dexie) and never reach the server.
- `server`: PDFs are Active Storage attachments on `User#documents`. Each blob has `metadata["key"]`, and `DocumentsController` finds it with a `LIKE` query on the metadata JSON.

The document keys are `syllabus`, `handbook`, and one `reports_*` key per field (foreign language is `reports_foreign_lang`, not `reports_foreign_language`). They are defined in `Views::Pages::Documents` and repeated in `db/seeds.rb` and `Course::REPORT_PDF_KEYS`, so keep all three in sync; `test/models/course_test.rb` checks the `Course` copy. Renaming a key orphans PDFs users have already uploaded under it. Course pages link to `/documents?pdf=<key>&page=<n>`, which opens the viewer at that page.

pdf.js is **not** in the importmap. `app/views/layouts/application.html.erb` loads it from jsdelivr and exposes it as `window.pdfjsLib`. Its version (`4.0.379`) also appears in `pdf_viewer_controller.js`, in the cMap/font URLs used for Japanese text, so update both together. Dexie is pinned to an esm.sh URL in `config/importmap.rb`.

## Phlex Views

- Pages live at `app/views/<resource>/<action>.rb` as `Views::<Resource>::<Action> < Views::Base`. Reusable pieces are `Components::<Name>` in `app/components/`. `config/initializers/phlex.rb` maps both directories to those namespaces. It also contains an eager-load workaround for phlex-rails#323 that production needs, so don't remove it.
- Controllers pass everything a view needs as keyword args (`render Views::Enrollments::Index.new(seasons:, ...)`). Views don't read controller instance variables.
- Page views wrap their content in `render Components::Layout.new do … end` (nav + footer). The ERB layout `app/views/layouts/application.html.erb` still wraps every Phlex page and supplies `<head>`, the CSRF/CSP meta tags, importmap, and pdf.js. Mailer templates are also ERB.
- `Components::Layout` doesn't render flash messages. A view that is the target of a redirect with `notice:`/`alert:` has to `include Phlex::Rails::Helpers::Flash` and render the message itself.
- Route helpers can be called directly because `Components::Base` includes `Phlex::Rails::Helpers::Routes`. Other Rails helpers are added per class, e.g. `include Phlex::Rails::Helpers::LinkTo` (or `FormWith`, `ButtonTo`).
- **Don't use `helpers.`** It's deprecated in phlex-rails 2.4 and will be removed in the next minor release. Call route helpers directly, and expose other Rails helpers with `register_value_helper` or `register_output_helper` (`Components::NavBar` does this for `authenticated?`).
- In development, `Components::Base` adds a `<!-- Before ClassName -->` HTML comment that shows which class rendered each fragment.
- Tailwind v4 is configured in CSS (`app/assets/tailwind/application.css`; there's no `tailwind.config.js`) and finds class names in the `.rb` view files automatically.

## Tests

- Integration tests sign in with `sign_in_as(users(:one))` from `test/test_helpers/session_test_helper.rb`. The fixture users' password is `password`.
- `parallelize(workers: :number_of_processors)` only takes effect at 50+ tests (Rails' threshold). Below that, tests run serially in `storage/test.sqlite3`, the same DB that `RAILS_ENV=test` scripts and the CI seed step write to. If every test suddenly errors after running such a script, reset it with `bin/rails db:test:prepare`.
- In tests and params, use real catalog keys from `config/courses.yml` (e.g. `phil101`, `eng101`) and `"YYYYMM"` season keys. Invalid keys still pass validation, so a test with bad keys can pass without testing real behavior.

## Seeds

`db/seeds.rb` **deletes all users, sessions, enrollments, and deadlines**, then creates a demo account: `student@example.com` / `password123` (also printed on the sign-in page). Never run it against data you care about. With `DOCUMENT_STORAGE=server`, it also attaches any `db/seed_documents/<key>.pdf` files.

## Style

The project uses RuboCop Omakase with no local overrides in `.rubocop.yml`. The rule most often broken is `Layout/SpaceInsideArrayLiteralBrackets`: write `[ a, b ]`, not `[a, b]`.

## Deployment

Kamal (`config/deploy.yml`) deploys the image `j0s3phj/keio_tsushin` to one server, `bumplink` (SSH user `thisisjosephju`), with SSL at `keiotsushin.heyjoseph.me`. Thruster sits in front of Puma, and Solid Queue runs inside Puma (`SOLID_QUEUE_IN_PUMA=true`). The four SQLite databases (primary, cache, queue, cable) and the Active Storage files all live in `storage/`, which is mounted as the `keio_tsushin_storage` volume. `bin/docker-entrypoint` runs `db:prepare` at boot, so pending migrations apply automatically on deploy.
