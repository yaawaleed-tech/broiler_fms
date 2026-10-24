# Broiler FMS

Offline-first batch records, finances and sync for broiler farms.

Broiler FMS is a Broiler Farm Record Management System built as a final year project (SWE4600, Software Engineering). The case study is Bluelite Poultry, a broiler farm in Kano, Nigeria, which kept its records in a paper Batch/Harvest Book and a Google Sheets dashboard. The system replaces them with one app that works without internet on the farm and shows the finances of each batch while the batch is still running.

- Web app and landing page: https://broiler-fms.web.app/
- Admin web app: https://broiler-fms.web.app/admin/
- Android app: download the APK from the [Releases](../../releases) page.

## Features

- Four roles: Super Admin, Admin, Manager and Staff, each seeing only what its role allows.
- Offline-first Android app for the Manager and Staff. Entries are saved on the phone first and sent to the server when a connection is available.
- Batch registration, Staff assignment and reassignment, and manager-confirmed batch closing and reopening.
- Daily records: mortality, feed used, weight samples, vaccinations and harvests.
- Expenses in four categories: day-old chicks, feed, veterinary and medication, and other.
- Harvest pricing per kilogram or as a flat total, or as a gift or cull, with each sale marked paid or pending.
- Automatic financial summary of every batch: total expenses, revenue, profit or loss, break-even price per bird and approximate Feed Conversion Ratio (FCR).
- Profit simulator: the profit at a chosen selling price, or the price needed for a target profit.
- A rule that mortality plus harvested birds can never exceed the starting bird count, enforced on the phone and on the server.
- Sign-in with a one-time code sent by email. No passwords.

## Roles

| Role | Platform | What it does |
|---|---|---|
| Super Admin | Web | Creates, deactivates and reactivates Admin accounts. Sees no farm data. |
| Admin | Web | Registers the business, adds one Manager and up to 18 Staff, and views every batch in read-only form. |
| Manager | Android | Registers batches, assigns Staff, logs expenses, prices harvests, reads the financial summary and uses the simulator. Can also record daily activity on batches with no Staff assigned. |
| Staff | Android | Records daily activity on the batches assigned to them. Sees no money figures. |

## How it works

The app has four layers and a sync engine:

- **Presentation:** the screens (Flutter).
- **Domain:** the business rules and the financial calculations.
- **Repository:** reads and writes data, local only on the phone.
- **Data:** the local SQLite database (Drift) on Android, and the Supabase client.
- **Sync Engine:** sends the waiting entries to Supabase and downloads what other devices recorded.

The financial figures are calculated by the same functions on the phone and on the web, so both show the same numbers:

- Profit or loss = total revenue - total expenses
- Break-even price = (total expenses - revenue so far) / (birds in stock + harvested birds not yet priced)
- FCR = total feed used (kg) / (latest average sample weight x total harvested birds)

## Tech stack

| Part | Tool |
|---|---|
| Framework | Flutter 3.38.2 and Dart 3.10.0 |
| Local database (Android) | Drift 2.31.0 on SQLite |
| Backend, database, sign-in and access rules | Supabase (PostgreSQL with Row Level Security), `supabase_flutter` 2.17.2 |
| State management | Riverpod 3.1.0 |
| Email for sign-in codes | Gmail SMTP through Supabase |
| Hosting | Firebase Hosting |

## Getting started

### Requirements

- Flutter 3.38.2 (Dart 3.10.0)
- A Supabase project
- Android Studio or the Android SDK, to run the Android app

### 1. Set up the database

Open the SQL editor in your Supabase project and run [`docs/supabase.sql`](docs/supabase.sql) once, from top to bottom. It creates the tables, the access rules and the bird count check.

### 2. Add your Supabase settings

The app reads its settings from `env/config.json`. This file is **not** in the repository on purpose. Create it yourself:

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-publishable-or-anon-key"
}
```

Use only the publishable (anon) key. Never put the service-role key in this file or anywhere in the app.

### 3. Run

```bash
flutter pub get

# Android app (Manager and Staff)
flutter run

# Web app (Admin and Super Admin)
flutter run -d chrome -t lib/main_web.dart
```

The web app must be started with `-t