# README
# Bill4Sarover

A hotel management system built with Ruby on Rails.

## Features

- Customer management
- Room management
- Booking system
- Check-in / Check-out tracking
- Banquet bookings (without rooms)
- Status lifecycle:
  - booked
  - checked_in
  - checked_out
  - cancelled

## Tech Stack

- Ruby on Rails 7
- PostgreSQL
- Turbo / Hotwire
- HTML / CSS

## Setup

```bash
git clone https://github.com/yourusername/bill4sarover-app.git
cd bill4sarover-app
bundle install
rails db:create
rails db:migrate
rails server
