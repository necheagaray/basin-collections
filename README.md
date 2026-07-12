# Basin Collections Tracker

A shared, real-time collections workboard for the Collections Team. Upload the
weekly aged AR export, notes stick to invoices across weeks, priorities get
flagged with a "sound the alarm" panel, and everyone sees the same live data.

It's a single static site (`index.html`) — no build step — backed by
[Supabase](https://supabase.com) (free tier) for the database, login, and
live sync. Hosting is GitHub + Netlify.

---

## 1. Create the Supabase project (5 min)

1. Go to [supabase.com](https://supabase.com) → **New project**. Pick any
   name/region, set a database password (save it somewhere), and wait ~2 min
   for it to spin up.
2. In the project, go to **SQL Editor → New query**, paste the entire
   contents of `schema.sql` from this folder, and click **Run**. This creates
   all the tables and the security rules (editors can edit, everyone can
   view).
3. Go to **Project Settings → API**. Copy:
   - **Project URL**
   - **anon public** key

---

## 2. Create the four logins

Go to **Authentication → Users → Add user** in Supabase, and create one user
per teammate. Use this email pattern exactly (the app maps a plain username
to this behind the scenes, so nobody has to remember an email):

| Username you'll type in the app | Email to create in Supabase              | Suggested password |
|---|---|---|
| `joel`    | `joel@basin-collections.local`    | pick something strong |
| `heather` | `heather@basin-collections.local` | pick something strong |
| `nick`    | `nick@basin-collections.local`    | pick something strong |
| `guest`   | `guest@basin-collections.local`   | one shared guest password |

For each user, check **Auto Confirm User** so they don't need an email
confirmation step (these are internal accounts, not real inboxes).

Then, back in **SQL Editor**, add a matching profile row for each person —
copy the **User UID** from the Authentication table for each one:

```sql
insert into profiles (id, display_name, initials, role) values
  ('paste-joels-uid-here',    'Joel',    'JS', 'editor'),
  ('paste-heathers-uid-here', 'Heather', 'HL', 'editor'),
  ('paste-nicks-uid-here',    'Nick',    'NR', 'editor'),
  ('paste-guests-uid-here',   'Guest',   'GU', 'guest');
```

Swap in real initials. `role = 'guest'` is what makes that login view-only —
guest won't see the upload button, priority flag, or note box.

---

## 3. Point the app at your project

Open `index.html` and edit these three lines near the top of the `<script>`
block:

```js
const SUPABASE_URL = "https://YOUR-PROJECT-REF.supabase.co";
const SUPABASE_ANON_KEY = "YOUR-ANON-PUBLIC-KEY";
const EMAIL_DOMAIN = "basin-collections.local";
```

Paste in the Project URL and anon key from step 1. Leave `EMAIL_DOMAIN` as-is
unless you changed the email pattern in step 2.

---

## 4. Push to GitHub

```bash
cd basin-collections
git init
git add .
git commit -m "Basin Collections Tracker"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/basin-collections.git
git push -u origin main
```

---

## 5. Deploy on Netlify

1. [app.netlify.com](https://app.netlify.com) → **Add new site → Import an
   existing project** → connect GitHub → pick this repo.
2. Build settings: leave **Build command** blank and set **Publish
   directory** to `.` (the repo root, since `index.html` lives there
   directly). Deploy.
3. Netlify gives you a live URL immediately. Optionally set a custom
   subdomain in **Site settings → Domain management**.

That's it — the whole team hits the same Netlify URL, logs in with their own
username/password, and everything syncs live through Supabase.

---

## How the weekly upload works

- Only Joel, Heather, and Nick (editor role) see the **Upload Weekly Aged
  AR** button. Guest doesn't.
- Upload the *full* aged AR Excel export each week (same format as the
  files used to build this — Customer / Transaction Type / Date / Document
  Number / P.O. No. / Due Date / Age / Open Balance, grouped by customer).
- The app reads every row where **Transaction Type = Invoice** (payments and
  totals are ignored).
- Each invoice is matched by **Document Number**:
  - Still on the new report → balance and due date update, **notes
    stay attached**.
  - New Document Number → added fresh.
  - Was on the app but missing from the new report → removed automatically,
    along with its notes (it's been paid or written off).
- A quick summary toast shows how many were added/removed each time.
- **Age is calculated by the app itself, from the Invoice Date, not pulled
  from the report's "Age" column** (that column in the export measures days
  relative to the *due date*, which isn't what we want). The app takes
  today's date minus the invoice date, so the day count keeps climbing every
  day automatically — it doesn't sit frozen until the next weekly upload.

## Notes & priorities

- Click any invoice row to open its notes panel — a running, dated,
  initialed log, five-plus lines of room per entry, newest first.
- Click the flag icon (🔕 / 🚨) on a row, or the ✕ inside a priority card, to
  toggle it as a **weekly priority**. Flagged invoices jump into the pulsing
  "This Week's Priorities" panel at the top for the whole team to see.
- Everything updates live for all logged-in users — no refresh needed.

## Customizing

- Colors/theme: the CSS variables at the top of `index.html` (`--neon-cyan`,
  `--neon-pink`, etc.) control the whole palette.
- Aging thresholds (currently: 0–45 green, 46–75 amber, 75+ red/pink,
  measured from invoice date) are in the `ageBucketClass()` and
  `computeAge()` functions.
- Everything is one file, so it's easy to hand to another AI assistant or
  developer for further tweaks.
