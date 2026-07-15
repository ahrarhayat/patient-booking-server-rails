# Patient Booking Server (Rails)

Ruby on Rails API mirror of [`patient-booking-server`](../patient-booking-server) (Express + Prisma). Pairs with the [`patient-booking`](../patient-booking) React frontend.

Runs on port **3003** by default so it can sit alongside the Express server on 3002.

## Stack

- Rails 8 API-only
- PostgreSQL
- Puma
- rack-cors
- bcrypt (`has_secure_password`) auth tokens

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

## Auth

Login with **clinician email + password**. Responses include a Bearer token (valid 24h).

Seeded accounts:

| Email | Password | Role |
|-------|----------|------|
| `sam@clinic.example.com` | `password123` | clinician |
| `admin@clinic.example.com` | `admin123` | admin |

```bash
curl -X POST http://localhost:3003/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@clinic.example.com","password":"admin123"}'
```

Use the token on protected routes:

```bash
curl http://localhost:3003/appointments \
  -H "Authorization: Bearer <token>"
```

**Access rules**

- **Clinician** — book/cancel/list appointments only for their own slots
- **Admin** — full access to all appointments and slots
- **Public** — `GET /health`, `GET /clinicians`, `GET /clinicians/:name/slots`

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

Booking/cancel/appointment list calls need a staff login token once the frontend is wired for auth.

## API surface

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | `/health` | no | Health check |
| POST | `/auth/login` | no | `{ email, password }` → `{ token, clinician }` |
| GET | `/auth/me` | yes | Current clinician/admin |
| GET | `/clinicians` | no | List bookable clinicians |
| POST | `/clinicians` | admin | Create `{ name, email, password, role? }` |
| GET | `/clinicians/:name/slots?from=&to=` | no | Available slots |
| GET | `/appointments` | yes | Appointments (own / all for admin) |
| POST | `/appointments` | yes | Book `{ patientId, slotId }` |
| DELETE | `/appointments/:id` | yes | Cancel appointment |
| GET | `/patients` | yes | List patients (`id`, `name`, `email`) |
| POST | `/patients` | yes | Create `{ name, email }` |
| GET | `/patients/:id/appointments` | yes | Patient's upcoming appointments |

## Project layout

```
app/
  controllers/       # HTTP layer (+ auth)
  services/          # Booking + auth business logic
  models/            # ActiveRecord models
  lib/booking_json.rb
  errors/app_error.rb
```

## Query the database

Connection string (local Docker):

```text
postgresql://booking:booking@localhost:5434/patient_booking_rails
```

### Rails console

```bash
bin/rails console
```

```ruby
Clinician.all
Clinician.find_by(name: "Admin")
Clinician.pluck(:name, :role)

Patient.all
Slot.where(is_available: true).count
Appointment.includes(:patient, :slot).all
```

### Postgres (psql)

```bash
docker compose exec db psql -U booking -d patient_booking_rails
```

```sql
SELECT id, name, email, role FROM clinicians;
SELECT * FROM appointments;
SELECT * FROM slots WHERE is_available = true ORDER BY start_time;
```

## Scripts

| Command | Description |
|---------|-------------|
| `bin/dev` | Start Puma on PORT (default 3003) |
| `bin/rails db:up` | Start local Postgres via Docker |
| `bin/rails db:down` | Stop Docker Postgres |
| `bin/rails test` | Run tests |
| `bin/rails console` | Open Rails console against the DB |

## Regression tests (Playwright)

API regression suite lives in [`regression-tests/`](./regression-tests). For now it covers **GET** endpoints only (no writes that populate the DB). Login is used only to obtain a Bearer token for protected GETs.

Prerequisites: server running on port 3003 with a seeded database (`bin/dev`).

```bash
cd regression-tests
yarn install
yarn test
```

Optional env overrides: `API_BASE_URL`, `ADMIN_EMAIL`, `ADMIN_PASSWORD`, `DEFAULT_CLINICIAN_NAME`, `DEFAULT_PATIENT_ID`.
