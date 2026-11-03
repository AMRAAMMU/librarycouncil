# താലൂക്ക് ലൈബ്രറി കൗൺസിൽ — Taluk Library Council Management & Cash Book Suite

A bilingual (**Malayalam + English**) administrative, accounting, general ledger, and audit management web application built for a **Taluk Library Council** (affiliated with the Kerala State Library Council), backed by **Supabase PostgreSQL** with **Staff Authentication**, **Row Level Security (RLS)**, **Realtime multi-device sync**, **Malayalam Unicode PDF exports**, and **GitHub Pages PWA** support.

---

## Core Modules

1. **Dashboard (`ഡാഷ്‌ബോർഡ്`)** — Live KPI cards (Affiliated Libraries, Active Schemes, Total Income, Total Expense, Closing Balance with Cash/Bank split, Grant Utilization), Income vs. Expense bar chart, Grade (`A`–`D`) doughnut chart, and recent voucher feed.
2. **Library Management (`ലൈബ്രറി മാനേജ്‌മെന്റ്`)** — Directory of affiliated libraries with unique registration codes (`LIB-...`), grade (`A`, `B`, `C`, `D`), secretary contact details, and inspection remarks.
3. **Schemes & Grants (`പദ്ധതികളും ഗ്രാൻഡുകളും`)** — Grant allocation vs. disbursement tracking (`Active`, `Completed`, `Planning`) with beneficiary lists and utilization progress bars.
4. **Cash Book (`ക്യാഷ് ബുക്ക്`)** — Dual-account (`Cash in Hand` & `Cash in Bank`) accounting with Opening Balance configuration, Income/Receipt & Expense/Voucher entries, automated **Daily Opening (`B/F`)** and **Daily Closing (`C/F`)** audit rows, and official printable Money Receipts.
5. **General Ledger (`ജനറൽ ലെഡ്ജർ`)** — Account-head-wise Credit/Debit statement with date-range filtering and running balance (`Cr`/`Dr`).
6. **Letters & Documents (`കത്തുകളും രേഖകളും`)** — Inward & Outward correspondence register with file/reference number search.
7. **Reports & Backup (`റിപ്പോർട്ടുകളും ബാക്കപ്പും`)** — 5 Malayalam-capable audit PDF reports, full JSON backup export/restore (with UUID normalization & Supabase upsert), and protected database reset.

---

## Repository Structure

| File | Purpose |
| :--- | :--- |
| `index.html` | Main single-page application (HTML5, Tailwind CSS, Chart.js, Lucide Icons, `html2pdf` + `jsPDF`, `@supabase/supabase-js` v2). |
| `config.js` | Central Supabase Project URL & `anon` public key configuration (`window.COUNCIL_SUPABASE_CONFIG`). |
| `supabase_sql_migration.sql` | Idempotent PostgreSQL schema migration (5 tables, indexes, `updated_at` triggers, `authenticated` RLS policies, and Realtime publication). |
| `manifest.json` | Web App Manifest for native installability on Windows, Android, and iOS. |
| `sw.js` | Service Worker providing offline app-shell caching while bypassing Supabase API/Auth/Realtime endpoints. |
| `icon.svg` | Vector app icon & favicon. |
| `.nojekyll` | Disables Jekyll processing on GitHub Pages. |
| `.github/workflows/deploy-pages.yml` | Automated GitHub Actions workflow to deploy to GitHub Pages on every push to `main`. |

---

## Step 1: Connect Supabase SQL Database

1. **Create a Supabase Project**
   - Sign in at [https://supabase.com/dashboard](https://supabase.com/dashboard) and click **New Project**.

2. **Run the SQL Schema Migration**
   - Open **SQL Editor** -> **New Query** in your Supabase Dashboard.
   - Paste the entire contents of `supabase_sql_migration.sql` and click **Run**.
   - This creates `council_opening_balance`, `libraries`, `schemes`, `cashbook`, and `documents`, attaches `updated_at` triggers, enables Realtime sync, and locks Row Level Security (RLS) strictly to signed-in staff (`authenticated`).

3. **Create Staff Login Accounts (Required for Cloud Read/Write)**
   - In Supabase Dashboard, go to **Authentication** -> **Users** -> **Add User** -> **Create New User**.
   - Enter the staff member's **Email** and **Password**, check **Auto Confirm User**, and click **Create User**.
   - Go to **Authentication** -> **Sign In / Providers** (or **User Signups**) and **disable** *"Allow new users to sign up"* so only admin-created council staff can sign in.

4. **Configure Your Project URL & Anon Key**
   - In Supabase Dashboard, go to **Project Settings** -> **API** and copy:
     - **Project URL** (`https://<project-ref>.supabase.co`)
     - **Project API Keys -> `anon` `public`** key *(Never put the `service_role` secret key in browser code!)*
   - Paste both values into `config.js`:
     ```js
     window.COUNCIL_SUPABASE_CONFIG = {
       url: "https://your-project-ref.supabase.co",
       anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
     };
     ```
   - *(Optional)* You can also enter or override credentials per browser using the **⚡ Supabase** button in the bottom-left sidebar.

---

## Step 2: Host on GitHub & GitHub Pages

1. **Create a GitHub Repository**
   - Go to [https://github.com/new](https://github.com/new), name your repository (e.g., `taluk-library-council`), keep it **Public** (for free GitHub Pages hosting) or **Private** (GitHub Pro/Enterprise), and **do not** initialize with a README (this project already has one).

2. **Link & Push from Your Project Folder**
   ```powershell
   git remote add origin https://github.com/<YOUR-USERNAME>/<YOUR-REPO>.git
   git branch -M main
   git push -u origin main
   ```

3. **Enable GitHub Pages**
   - On GitHub, open your repository -> **Settings** -> **Pages**.
   - Under **Build and deployment** -> **Source**, select **GitHub Actions**.
   - `.github/workflows/deploy-pages.yml` will automatically deploy your site within ~30 seconds to:
     `https://<YOUR-USERNAME>.github.io/<YOUR-REPO>/`

---

## Security Architecture on Public Hosting

- **Safe Public Keys**: The Supabase `anon` key only identifies your project endpoint; PostgreSQL **Row Level Security (RLS)** enforces access control on the database server.
- **Strict `authenticated` Policies**: Unauthenticated visitors opening your GitHub Pages URL cannot read, insert, update, or delete any council records until they sign in with a valid council staff Email & Password.
- **Offline Local Mode**: Users without cloud credentials can still test or operate the application locally in browser `localStorage` via Offline Mode.

