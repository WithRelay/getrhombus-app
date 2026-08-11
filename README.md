# Relay (getrhombus)

Relay is a multi-tenant business messaging platform built for SMB and enterprise teams.
It supports customer messaging workflows, campaigns, billing, subscriptions, usage tracking, and integrations with telephony and social channels.

## Repository Context

- Codebase provenance: Long-running private production codebase prepared for public reference
- Scope: Full-stack, multi-tenant messaging and billing platform with multi-year maintenance history
- Repository objective: Preserve enterprise architecture, domain workflows, and contributor history for technical evaluation

## Product Capabilities

- Team and customer account management
- SMS and messaging workflows
- Campaign scheduling and delivery flows
- Stripe subscription and billing workflows
- API credential management and webhooks
- Background jobs for async processing and automation
- Data import workflows for contacts/customers

## Tech Stack

- Ruby on Rails 4.2
- MySQL
- Redis + Resque / Resque Scheduler
- RSpec + Minitest
- jQuery / AngularJS-era frontend assets

Key dependencies are listed in [Gemfile](Gemfile).

## High-Level Architecture

- Web application and admin UI: Rails controllers/views
- Domain/business logic: models + service classes under app/services and app/webhooks
- Async processing: queue workers defined in [Procfile](Procfile)
- Integrations: Stripe, Twilio, Nexmo, Facebook, and others

## Getting Started (Local)

### Prerequisites

- Ruby matching project runtime (legacy app)
- Bundler
- MySQL
- Redis

### Setup

1. Install dependencies

```bash
bundle install
```

2. Configure database values in [config/database.yml](config/database.yml)

3. Configure required app secrets and environment variables

- `SECRET_KEY_BASE`
- `DEVISE_SECRET_KEY`
- provider credentials needed for any integration-specific workflows

4. Create and migrate database

```bash
bundle exec rake db:create db:migrate
```

5. Start app server

```bash
bundle exec rails server
```

6. Start Redis and workers (for async jobs)

```bash
redis-server
bundle exec rake resque:work QUEUE=*
bundle exec rake resque:scheduler
```

## Testing

RSpec and test files are present.

```bash
bundle exec rspec
```

## Notes on Public Release

This public repository preserves long-term commit history and contributors while redacting sensitive values and secret-bearing artifacts.

If you discover a sensitive value that should be removed, open an issue with file path and commit reference.
