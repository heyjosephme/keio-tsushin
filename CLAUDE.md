# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Keio Tsushin is a **Keio University Distance Learning Credit Management System** built with Rails 8.1. It helps students track course enrollments, exam seasons, and deadlines using a kanban-style course planner and calendar-based deadline tracker.

The application uses modern Hotwire/Turbo stack with Tailwind CSS and **Phlex-Rails for view components**. The application is containerized and deployed using Kamal.

**Tech Stack:**
- Ruby 4.0.0
- Rails 8.1.2
- Phlex-Rails 2.3.1 (Ruby-based view components, no ERB)
- Hotwire (Turbo + Stimulus)
- Tailwind CSS 4.4.0
- SQLite3 (using Solid adapters in production)
- Importmap for JavaScript (no Node.js/npm)

## Development Commands

### Server & Development
```bash
bin/dev              # Start development server with Tailwind watch
bin/rails server     # Start Rails server only
bin/rails console    # Rails console
bin/setup            # Initial setup (install dependencies, prepare database)
```

### Database
```bash
bin/rails db:migrate              # Run pending migrations
bin/rails db:test:prepare         # Prepare test database
bin/rails db:seed:replant         # Reset and reseed database
env RAILS_ENV=test bin/rails db:seed:replant  # Test seed data (used in CI)
```

### Testing
```bash
bin/rails test               # Run all tests
bin/rails test:system        # Run system tests only
bin/rails test test/models/some_test.rb        # Run single test file
bin/rails test test/models/some_test.rb:10     # Run single test at line
```

### Code Quality & Security
```bash
bin/rubocop          # Run Ruby style linter
bin/brakeman         # Security vulnerability scanner
bin/bundler-audit    # Check gems for known vulnerabilities
bin/importmap audit  # Check JavaScript dependencies for vulnerabilities
bin/ci              # Run full CI suite locally (uses config/ci.rb)
```

### Deployment
```bash
bin/kamal setup              # Initial deployment setup
bin/kamal deploy             # Deploy to production
bin/kamal console            # Open Rails console on production
bin/kamal shell              # Open shell on production container
bin/kamal logs               # Tail production logs
bin/kamal dbc                # Open database console on production
```

**Production Environment:**
- Domain: keiotsushin.heyjoseph.me
- Server: bumplink (SSH user: thisisjosephju)
- Registry: j0s3phj/keio_tsushin
- SSL enabled via proxy

## Architecture

### Frontend Architecture
- **View Layer:** Phlex-Rails (Ruby-based components, NO ERB templates)
  - Views: `app/views/` (Phlex components, not traditional ERB)
  - Reusable components: `app/components/` (e.g., `Components::Calendar`)
  - Base classes: `Views::Base` and `Components::Base`
  - Production eager loading workaround configured in `config/initializers/phlex.rb`
- **Asset Pipeline:** Propshaft (not Sprockets)
- **JavaScript:** Import maps (no build step required for JS)
- **CSS:** Tailwind CSS 4.4.0 with live reloading in development
- **Hotwire:** Turbo for SPA-like navigation, Stimulus for JavaScript controllers
- Stimulus controllers in `app/javascript/controllers/` (minimal usage currently)

### Database Architecture (Production)
Uses Rails 8's Solid adapters for production deployment on a single server:
- **Primary DB:** Standard SQLite database for application data
- **Solid Cache:** Database-backed Rails cache (separate SQLite DB)
- **Solid Queue:** Background job processing (separate SQLite DB, runs in Puma process via `SOLID_QUEUE_IN_PUMA=true`)
- **Solid Cable:** WebSocket connections (separate SQLite DB)

All production databases are stored in `storage/` which is mounted as a Docker volume for persistence.

### Data Model Architecture

The application uses a **hybrid data model** combining YAML-based catalog data with database-backed user data:

#### YAML-Based Models (Static Catalog Data)
- **Course Model** (`app/models/course.rb`)
  - Data source: `config/courses.yml`
  - 17 courses across 4 categories: required, elective, foreign_language, physical_education
  - Types: distance, on_campus, both
  - Plain Ruby Object (not ActiveRecord)

- **Season Model** (`app/models/season.rb`)
  - Data source: `config/seasons.yml`
  - Exam seasons 2026-2027 (6 seasons defined)
  - Tracks: report_deadline, application_deadline, exam_start, exam_end
  - Plain Ruby Object (not ActiveRecord)

#### ActiveRecord Models (User Data)
- **Enrollment** - Student course enrollments
  - References Course and Season via keys
  - Status tracking: planned → report_submitted → exam_applied → completed

- **Deadline** - Deadlines for reports and exams
  - Fields: course_name, deadline_date, deadline_type, description
  - Types: report, exam

### Deployment Architecture
- **Container:** Docker-based deployment using Kamal
- **Web Server:** Thruster 0.1.17 (wraps Puma, handles HTTP/2, caching, compression)
- **Background Jobs:** Solid Queue runs inside Puma process (single-server setup)
- **Registry:** j0s3phj/keio_tsushin
- **Server:** bumplink (configured in config/deploy.yml)

### CI/CD Pipeline
GitHub Actions runs 5 parallel jobs on PRs and main pushes:
1. `scan_ruby` - Brakeman + bundler-audit
2. `scan_js` - importmap audit
3. `lint` - RuboCop
4. `test` - Rails tests
5. `system-test` - System tests with screenshot capture on failure

Local CI can be run with `bin/ci` which executes the same checks defined in `config/ci.rb`.

## Key Configuration Files
- `config/deploy.yml` - Kamal deployment configuration
- `config/importmap.rb` - JavaScript dependencies
- `config/ci.rb` - Local CI pipeline steps (includes seed testing)
- `config/courses.yml` - Course catalog data (17 courses)
- `config/seasons.yml` - Exam season schedules (2026-2027)
- `config/initializers/phlex.rb` - Phlex-Rails configuration and eager loading workaround
- `Procfile.dev` - Development processes (web + CSS watch)
- `.rubocop.yml` - Ruby style rules (Omakase)

## Phlex Views & Components

This application uses **Phlex-Rails** instead of traditional ERB templates:

### Creating Views
- Location: `app/views/` (e.g., `app/views/enrollments/index.rb`)
- Inherit from `Views::Base`
- Render in controllers: `render Views::Enrollments::Index.new`

### Creating Reusable Components
- Location: `app/components/` (e.g., `app/components/calendar.rb`)
- Inherit from `Components::Base`
- Use in views: `render Components::Calendar.new(month: @month)`

### Important Notes
- NO ERB templates - all views are Ruby classes
- Use `whitespace` method for spacing instead of HTML whitespace
- Helpers are available via `helpers` method
- Production eager loading workaround configured in `config/initializers/phlex.rb`

## JavaScript & Stimulus
- Stimulus controllers auto-load from `app/javascript/controllers/`
- No build step required - importmap serves JS directly
- Pin new JS packages with `bin/importmap pin <package-name>`
- Minimal JavaScript usage currently (Turbo handles most interactivity)

## Application Features

### Course Planner (`/courses`)
- Kanban-style board organizing courses by exam season
- Drag-and-drop between seasons (future enhancement)
- Status tracking: planned → report_submitted → exam_applied → completed
- Days-until-deadline badges with color coding

### Deadline Calendar (`/deadlines`)
- Monthly calendar view showing report and exam deadlines
- Previous/next month navigation
- Add custom deadlines for courses

### Data Management
- Courses defined in `config/courses.yml` (static catalog)
- Exam seasons defined in `config/seasons.yml` (academic schedule)
- User enrollments and deadlines stored in SQLite database
