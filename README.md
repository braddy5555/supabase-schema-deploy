# Supabase Schema Deployment

Automated deployment of database schemas to Supabase.

## Projects

- **Cosmic Puppies** - Lead management, orders, traffic tracking
- **Tribes Community** - Community management, members, subscriptions

## Setup

Add these secrets to GitHub:
- `SUPABASE_ACCESS_TOKEN` - From https://supabase.com/dashboard/account/tokens
- `COSMIC_DB_PASSWORD` - Database password for cosmic-puppies
- `TRIBES_DB_PASSWORD` - Database password for tribes-community

## Deployment

Pushing to `supabase/migrations/` triggers automatic deployment.
