# ICS321 — Project 1: Horse Racing Database (Streamlit)

This repository contains a complete Streamlit implementation of the **Horse Racing Database System** with:
- Role‑based login (predefined Admin and Guest)
- All required Admin and Guest functions
- MySQL schema, seed data, **stored procedure** and **trigger**
- Simple trainer approval flow
- Clear run instructions

> The schema and data come from your assignment handout. I fixed minor PDF line breaks and one FK length mismatch so the SQL runs cleanly in MySQL 8+. fileciteturn0file0

---

## 📦 What’s inside

```
horse_racing_streamlit/
├── streamlit_app.py
├── setup.sql
├── requirements.txt
├── .env.example
└── .streamlit/
    └── secrets.toml.example
```

---

## 🔐 Login (predefined)

- **Admin** → username: `admin`, password: `Admin@123`
- **Guest** → username: `guest`, password: `Guest@123`

---

## 🗄️ Database setup (MySQL 8.x)

1. Ensure MySQL is running and you have credentials (e.g., `root`).
2. Load the schema and data:

```bash
mysql -u root -p < setup.sql
```

This creates a database named `RACING`, loads all tables and data, and creates:
- Stored procedure: `sp_delete_owner(ownerId)` — deletes an owner and related `Owns` rows.
- Trigger: `tr_horse_archive` — copies deleted horse rows into `old_info` with a timestamp.

> Notes
> - In the provided handout, `Horse.stableId` had length 30 while `Stable.stableId` had length 15.
>   MySQL requires the same length for FK columns, so this project uses **VARCHAR(15)** consistently.
> - Several `INSERT INTO Race` statements had line breaks within the date; these were fixed.

---

## ⚙️ App configuration

The app reads DB credentials in this order:
1) `.streamlit/secrets.toml` → `[mysql]` section; **or**
2) Environment variables — loaded automatically from a local `.env` (via `python-dotenv`) if present, else from your shell.

### Option A — `.env` (recommended for local dev)
Copy `.env.example` to `.env` and edit values:

```
DB_HOST=localhost
DB_USER=root
DB_PASS=your_mysql_password
DB_NAME=RACING
```

### Option B — Streamlit secrets
Copy `.streamlit/secrets.toml.example` to `.streamlit/secrets.toml` and edit values:

```toml
[mysql]
host = "localhost"
user = "root"
password = "your_mysql_password"
database = "RACING"
```

---

## ▶️ Run

```bash
pip install -r requirements.txt
streamlit run streamlit_app.py
```

Open the URL shown (usually http://localhost:8501), then log in as **admin** or **guest**.

---

## ✅ How each requirement is met

### Database Users
- **Admin**
- **Guest** (read-only features)

### Admin Functions
- **Add a new race with the results of the race**: *Admin → “Add Race + Results”*
- **Delete an owner and all the related information**: *Admin → “Delete Owner”* calls `CALL sp_delete_owner(?)`.
- **Move a horse from one stable to another**: *Admin → “Move Horse”* updates `Horse.stableId`.
- **Approve a new trainer to join a stable**: *Admin → “Approve Trainer”* from a simple queue (`TrainerApplications` table) or add directly.

### Guest Functions
- **Browse horses (name, age) and trainer names by owner last name**: *Guest → “Browse by Owner Last Name”*.
- **Browse trainers who have trained winners** (with winning horse & race details): *Guest → “Winning Trainers”*.
- **Trainer and total prize money (sorted)**: *Guest → “Winnings per Trainer”*.
- **Tracks with race counts and total participating horses**: *Guest → “Track Stats”*.

### Additional Requirement
1. **Use appropriate APIs**: The app uses the official MySQL client (`pymysql`) from Python.
2. **Procedural SQL**: Implemented in `setup.sql`:
   - Stored procedure `sp_delete_owner`.
   - Trigger `tr_horse_archive` (writes to `old_info`).

---

## 🧪 Quick smoke test
After loading `setup.sql`, try:
- Admin → Delete an owner (e.g., pick any owner). Then verify `SELECT * FROM Owner WHERE ownerId=...` returns no row and `Owns` rows are gone.
- Admin → Move a horse and check `Horse.stableId` changed.
- Guest → Enter last name `Mohammed` to see many matches.
- Guest → Winning Trainers shows winning horse, race, track, date, and prize.

---

## 🛡️ Safety & integrity
- All SQL writes are transactional with commit/rollback.
- Parameterized queries avoid SQL injection in user-provided inputs.
- The login credentials are intentionally hard-coded to satisfy the assignment requirement of predefined users.

---

## 📚 Source
Assignment PDF provided by you (DDL, DML, and requirements). fileciteturn0file0
