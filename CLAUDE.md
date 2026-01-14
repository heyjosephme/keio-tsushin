# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Keio Tsushin is a Rails 8.1 application using modern Hotwire/Turbo stack with Tailwind CSS. The application is containerized and deployed using Kamal.

**Tech Stack:**
- Ruby 4.0.0
- Rails 8.1.1
- Hotwire (Turbo + Stimulus)
- Tailwind CSS
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
bin/rails db:migrate         # Run pending migrations
bin/rails db:test:prepare    # Prepare test database
bin/rails db:seed:replant    # Reset and reseed database
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

## Architecture

### Frontend Architecture
- **Asset Pipeline:** Propshaft (not Sprockets)
- **JavaScript:** Import maps (no build step required for JS)
- **CSS:** Tailwind CSS with live reloading in development
- **Hotwire:** Turbo for SPA-like navigation, Stimulus for JavaScript controllers
- Controllers are in `app/javascript/controllers/`

### Database Architecture (Production)
Uses Rails 8's Solid adapters for production deployment on a single server:
- **Primary DB:** Standard SQLite database for application data
- **Solid Cache:** Database-backed Rails cache (separate SQLite DB)
- **Solid Queue:** Background job processing (separate SQLite DB, runs in Puma process via `SOLID_QUEUE_IN_PUMA=true`)
- **Solid Cable:** WebSocket connections (separate SQLite DB)

All production databases are stored in `storage/` which is mounted as a Docker volume for persistence.

### Deployment Architecture
- **Container:** Docker-based deployment using Kamal
- **Web Server:** Thruster (wraps Puma, handles HTTP/2, caching, compression)
- **Background Jobs:** Solid Queue runs inside Puma process (single-server setup)
- **Registry:** Uses local registry at localhost:5555
- **Server:** Configured for 192.168.0.1 in config/deploy.yml

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
- `config/ci.rb` - Local CI pipeline steps
- `Procfile.dev` - Development processes (web + CSS watch)
- `.rubocop.yml` - Ruby style rules (Omakase)

## JavaScript & Stimulus
- Stimulus controllers auto-load from `app/javascript/controllers/`
- No build step required - importmap serves JS directly
- Pin new JS packages with `bin/importmap pin <package-name>`
