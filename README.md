# Patient Booking Server (Rails)

Ruby on Rails API mirror of [`patient-booking-server`](../patient-booking-server) (Express + Prisma). Pairs with the [`patient-booking`](../patient-booking) React frontend.

Runs on port **3003** by default so it can sit alongside the Express server on 3002.

## Stack

- Rails 8 API-only
- PostgreSQL
- Puma
- rack-cors

## Quick start

```bash
cp .env.example .env
bundle install
bin/rails db:up
bin/rails db:migrate
bin/rails db:seed
bin/dev
```

Server listens on [http://localhost:3003](http://localhost:3003).

## Connect to patient-booking frontend

1. Start this server (see above).
2. In the frontend `.env`:

   ```env
   VITE_USE_MSW=false
   VITE_API_URL=http://localhost:3003
   VITE_DEFAULT_PATIENT_ID=a0000000-0000-4000-8000-000000000001
   VITE_DEFAULT_CLINICIAN_NAME=Dr. Sam Clinician
   ```

3. Run `yarn dev` in `patient-booking`.

Vite proxies `/api/*` to `VITE_API_URL` and strips the `/api` prefix.

## API surface

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/health` | Health check |
| GET | `/clinicians` | List clinicians |
| GET | `/clinicians/:name/slots?from=&to=` | Available slots (lookup by clinician name) |
| POST | `/appointments` | Book `{ patientId, slotId }` |
| DELETE | `/appointments/:id` | Cancel appointment |
| GET | `/patients/:id/appointments` | Patient's upcoming appointments |

## Project layout

```
app/
  controllers/       # HTTP layer
  services/          # Booking business logic
  models/            # ActiveRecord models
  lib/booking_json.rb
  errors/app_error.rb
```

## Scripts

| Command | Description |
|---------|-------------|
| `bin/dev` | Start Puma on PORT (default 3003) |
| `bin/rails db:up` | Start local Postgres via Docker |
| `bin/rails db:down` | Stop Docker Postgres |
| `bin/rails test` | Run tests |
