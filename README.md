# Keio Tsushin - Distance Learning Credit Management System

A Rails 8.1 application for managing Keio University distance learning course enrollments, exam schedules, and deadlines.

## Features

- **Course Planner**: Kanban-style board to organize courses by exam season
- **Deadline Calendar**: Monthly calendar view for tracking report and exam deadlines
- **Status Tracking**: Monitor progress from planning through completion (planned → report submitted → exam applied → completed)
- **Exam Season Management**: Track application and report deadlines across multiple exam periods

## Tech Stack

- **Ruby**: 4.0.0
- **Rails**: 8.1.2
- **View Layer**: Phlex-Rails 2.3.1 (Ruby-based components, no ERB)
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS 4.4.0
- **Database**: SQLite3 with Solid adapters (Cache, Queue, Cable)
- **JavaScript**: Import maps (no Node.js/npm required)
- **Deployment**: Kamal with Docker containers

## Getting Started

### Prerequisites

- Ruby 4.0.0
- SQLite3
- Bundler 4.0.3

### Initial Setup

```bash
bin/setup              # Install dependencies and prepare database
bin/dev                # Start development server with Tailwind watch
```

Visit http://localhost:3000

### Database Setup

```bash
bin/rails db:migrate              # Run migrations
bin/rails db:seed                 # Load sample data
bin/rails db:seed:replant         # Reset and reseed database
```

## Development

### Running the Application

```bash
bin/dev                # Start server with Tailwind CSS watch (recommended)
bin/rails server       # Start Rails server only
bin/rails console      # Open Rails console
```

### Testing

```bash
bin/rails test                              # Run all tests
bin/rails test:system                       # Run system tests only
bin/rails test test/models/enrollment_test.rb  # Run specific test file
bin/ci                                      # Run full CI suite locally
```

### Code Quality

```bash
bin/rubocop          # Ruby style linter
bin/brakeman         # Security vulnerability scanner
bin/bundler-audit    # Check gems for vulnerabilities
bin/importmap audit  # Check JS dependencies for vulnerabilities
```

## Architecture

### View Layer - Phlex Components

This application uses **Phlex-Rails** for all views (no ERB templates):

- **Views**: `app/views/` - Page-level Phlex components
- **Components**: `app/components/` - Reusable Phlex components
- **Base Classes**: `Views::Base` and `Components::Base`

Example view rendering:
```ruby
# Controller
def index
  render Views::Enrollments::Index.new(enrollments: @enrollments)
end
```

### Data Model

The application uses a hybrid data model:

#### YAML-Based Catalog Data (Static)
- **Courses** (`config/courses.yml`): 17 courses across 4 categories
  - Categories: required, elective, foreign_language, physical_education
  - Types: distance, on_campus, both
- **Seasons** (`config/seasons.yml`): Exam seasons 2026-2027
  - Tracks: report_deadline, application_deadline, exam_start, exam_end

#### Database Models (User Data)
- **Enrollment**: Student course enrollments with status tracking
- **Deadline**: Custom deadlines for reports and exams

### Frontend Stack

- **Hotwire Turbo**: SPA-like navigation without page reloads
- **Stimulus**: Minimal JavaScript controllers (in `app/javascript/controllers/`)
- **Tailwind CSS 4.4.0**: Utility-first CSS with live reloading
- **Propshaft**: Asset pipeline (not Sprockets)
- **Import Maps**: JavaScript dependencies without build step

## Deployment

### Production Environment

- **Domain**: keiotsushin.heyjoseph.me
- **Server**: bumplink
- **Registry**: j0s3phj/keio_tsushin
- **SSL**: Enabled via proxy

### Deployment Commands

```bash
bin/kamal setup        # Initial deployment setup
bin/kamal deploy       # Deploy to production
bin/kamal console      # Open Rails console on production
bin/kamal shell        # Open shell on production container
bin/kamal logs         # Tail production logs
bin/kamal dbc          # Open database console on production
```

### Production Architecture

- **Web Server**: Thruster 0.1.17 (wraps Puma, handles HTTP/2, caching, compression)
- **Background Jobs**: Solid Queue (runs in Puma process via `SOLID_QUEUE_IN_PUMA=true`)
- **Caching**: Solid Cache (database-backed)
- **WebSockets**: Solid Cable (database-backed)
- **Storage**: All databases stored in `storage/` (Docker volume)

## Configuration Files

- `config/deploy.yml` - Kamal deployment configuration
- `config/courses.yml` - Course catalog (17 courses)
- `config/seasons.yml` - Exam season schedules
- `config/importmap.rb` - JavaScript dependencies
- `config/initializers/phlex.rb` - Phlex configuration with eager loading workaround
- `config/ci.rb` - Local CI pipeline steps

## CI/CD Pipeline

GitHub Actions runs 5 parallel jobs on PRs and main branch:
1. `scan_ruby` - Brakeman + bundler-audit
2. `scan_js` - importmap audit
3. `lint` - RuboCop
4. `test` - Rails tests
5. `system-test` - System tests with screenshot capture on failure

Run locally: `bin/ci`

## Contributing

This is a personal project for managing Keio University distance learning credits. See `CLAUDE.md` for detailed guidance on working with this codebase.

## License

This project is for educational purposes.
