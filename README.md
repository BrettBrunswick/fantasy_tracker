# Fantasy Tracker

A Rails 8 application for tracking and analyzing Yahoo Fantasy Football league history. Import your leagues, view lifetime statistics, head-to-head records, and matchup performance across multiple seasons.

## Features

- OAuth authentication with Yahoo Fantasy Sports API
- Import historical league data (seasons, teams, matchups, standings)
- Lifetime statistics for managers across all seasons
- Head-to-head records between managers
- Background jobs for automated data syncing

## Prerequisites

- Ruby 3.4.1
- PostgreSQL
- Redis (for Sidekiq background jobs)
- [ngrok](https://ngrok.com/) (for local OAuth development)

### Installing Prerequisites (macOS)

```bash
# Install Ruby (via rbenv or asdf)
brew install rbenv
rbenv install 3.4.1

# Install PostgreSQL
brew install postgresql@16
brew services start postgresql@16

# Install Redis
brew install redis
brew services start redis

# Install ngrok
brew install ngrok
```

## Yahoo Developer App Setup

Yahoo OAuth requires HTTPS callback URLs, which is why we use ngrok for local development.

### 1. Create a Yahoo App

1. Go to [Yahoo Developer Network](https://developer.yahoo.com/apps/)
2. Click **Create an App**
3. Fill in the application details:
   - **Application Name**: Fantasy Tracker (or your preferred name)
   - **Application Type**: Web Application
   - **Redirect URI(s)**: Leave blank for now (we'll add the ngrok URL)
   - **API Permissions**: Select **Fantasy Sports** (Read)
4. Click **Create App**
5. Note your **Client ID** and **Client Secret**

### 2. Start ngrok

Start ngrok to create a public HTTPS URL that tunnels to your local server:

```bash
ngrok http 3000
```

ngrok will display a forwarding URL like:
```
Forwarding  https://abc123.ngrok-free.app -> http://localhost:3000
```

Copy the HTTPS URL (e.g., `https://abc123.ngrok-free.app`).

> **Note**: Free ngrok URLs change each time you restart ngrok. If you have a paid ngrok account, you can use a stable subdomain.

### 3. Update Yahoo App Redirect URI

1. Go back to your [Yahoo Developer Apps](https://developer.yahoo.com/apps/)
2. Click on your app to edit it
3. Add the redirect URI using your ngrok URL:
   ```
   https://abc123.ngrok-free.app/auth/yahoo/callback
   ```
4. Save the changes

> **Important**: Every time your ngrok URL changes, you must update the redirect URI in your Yahoo app settings.

## Application Setup

### 1. Clone and Install Dependencies

```bash
git clone <repository-url>
cd fantasy_tracker
bundle install
```

### 2. Configure Environment Variables

Copy the example environment file and add your Yahoo credentials:

```bash
cp .env.example .env
```

Edit `.env` with your values:

```bash
YAHOO_CLIENT_ID=your_yahoo_client_id
YAHOO_CLIENT_SECRET=your_yahoo_client_secret
OAUTH_CALLBACK_URL=https://your-ngrok-url.ngrok-free.app/auth/yahoo/callback
```

Replace the values with:
- Your Yahoo app's Client ID and Client Secret
- Your ngrok HTTPS URL + `/auth/yahoo/callback`

### 3. Setup Database

```bash
bin/rails db:create
bin/rails db:migrate
```

## Running the Application

You'll need to run three processes: the Rails server, Sidekiq, and ngrok.

### Terminal 1: Start ngrok

```bash
ngrok http 3000
```

### Terminal 2: Start Rails Server

```bash
bin/rails server
```

### Terminal 3: Start Sidekiq (for background jobs)

```bash
bundle exec sidekiq
```

### Access the Application

Open your browser to your **ngrok URL** (not localhost):
```
https://abc123.ngrok-free.app
```

> **Important**: You must access the app through the ngrok URL for OAuth to work correctly. Accessing via `localhost:3000` will cause OAuth callback failures.

## Development Workflow

### When ngrok URL Changes

1. Stop the Rails server
2. Note your new ngrok URL
3. Update the redirect URI in your [Yahoo Developer App](https://developer.yahoo.com/apps/)
4. Update `OAUTH_CALLBACK_URL` in your `.env` file
5. Restart the Rails server

### Using a Stable ngrok URL (Recommended)

If you have a paid ngrok account, you can use a stable subdomain:

```bash
ngrok http 3000 --subdomain=fantasy-tracker
```

This gives you a consistent URL like `https://fantasy-tracker.ngrok.io`, eliminating the need to update Yahoo settings repeatedly.

## Running Tests

```bash
bin/rails test
```

## Background Jobs

The application uses Sidekiq for background processing with the following scheduled jobs:

| Job | Schedule | Description |
|-----|----------|-------------|
| `SyncCurrentWeekJob` | 6am & 6pm Sun-Tue | Syncs active week matchups |
| `SyncStandingsJob` | 8am daily | Updates standings data |
| `RecalculateLifetimeStatsJob` | 9am Wednesdays | Recomputes lifetime stats |

View the Sidekiq dashboard at `/sidekiq` (when running locally).

## Troubleshooting

### OAuth Callback Error

If you see "Invalid redirect_uri" or callback errors:
- Verify your ngrok URL matches exactly in Yahoo app settings
- Ensure `OAUTH_CALLBACK_URL` environment variable is set correctly
- Make sure you're accessing the app via the ngrok URL, not localhost

### Database Connection Error

```bash
# Ensure PostgreSQL is running
brew services start postgresql@16

# Check if database exists
bin/rails db:create
```

### Redis Connection Error

```bash
# Ensure Redis is running
brew services start redis

# Verify Redis is accessible
redis-cli ping
```

### Token Refresh Issues

Yahoo OAuth tokens expire. The application handles token refresh automatically, but if you encounter persistent auth issues:
1. Log out
2. Clear your session: `bin/rails runner "Session.delete_all"`
3. Log in again

## Project Structure

```
app/
├── controllers/
│   ├── dashboard_controller.rb    # Main dashboard
│   ├── sessions_controller.rb     # OAuth login/logout
│   └── admin/
│       └── sync_controller.rb     # Manual sync triggers
├── models/
│   ├── user.rb                    # OAuth user accounts
│   ├── league.rb                  # Fantasy leagues
│   ├── season.rb                  # League seasons
│   ├── manager.rb                 # Team managers
│   ├── team.rb                    # Teams per season
│   ├── matchup.rb                 # Head-to-head games
│   ├── standing.rb                # Season standings
│   ├── lifetime_record.rb         # Career statistics
│   └── head_to_head_record.rb     # Manager vs manager records
├── services/
│   ├── yahoo_api/
│   │   ├── client.rb              # API client with token refresh
│   │   ├── league_sync.rb         # League data import
│   │   ├── matchup_sync.rb        # Matchup import
│   │   └── standings_sync.rb      # Standings import
│   └── stats/
│       ├── lifetime_calculator.rb      # Career stats calculation
│       └── head_to_head_calculator.rb  # H2H records calculation
└── jobs/
    ├── sync_current_week_job.rb
    ├── sync_standings_job.rb
    └── recalculate_lifetime_stats_job.rb
```
