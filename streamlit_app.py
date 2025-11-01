\
import os
from datetime import datetime
from dotenv import load_dotenv
import pandas as pd
import pymysql
import streamlit as st

# -------------------------------------------------------------
# App config
# -------------------------------------------------------------
st.set_page_config(page_title="Horse Racing DB System", page_icon="🏇", layout="wide")

# Load environment variables from .env if present
load_dotenv()
import os
print("DBG:", os.getenv("DB_HOST"), os.getenv("DB_PORT"), os.getenv("DB_NAME"))


# -------------------------------------------------------------
# Credentials (predefined, per your request)
# -------------------------------------------------------------
ADMIN_CREDENTIALS = {"username": "admin", "password": "Admin@123"}
GUEST_CREDENTIALS = {"username": "guest", "password": "Guest@123"}

# -------------------------------------------------------------
# Database helpers
# -------------------------------------------------------------
def get_db_config():
    """
    Read DB credentials in this priority:
    1) Streamlit secrets (st.secrets["mysql"]),
    2) Environment variables (.env or shell env).
    """
    cfg = {}
    if "mysql" in st.secrets:
        s = st.secrets["mysql"]
        cfg["host"] = s.get("host", "localhost")
        cfg["user"] = s.get("user", "root")
        cfg["password"] = s.get("password", "")
        cfg["database"] = s.get("database", "RACING")
    else:
        cfg["host"] = os.getenv("DB_HOST", "localhost")
        cfg["user"] = os.getenv("DB_USER", "root")
        cfg["password"] = os.getenv("DB_PASS", "")
        cfg["database"] = os.getenv("DB_NAME", "RACING")
    return cfg

def connect():
    return pymysql.connect(
        host=os.getenv("DB_HOST", "localhost"),
        user=os.getenv("DB_USER", "root"),
        password=os.getenv("DB_PASS", ""),
        database=os.getenv("DB_NAME", "RACING"),
        port=int(os.getenv("DB_PORT", "3306")),
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=True,
    )


def run_query(sql, params=None):
    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
            rows = cur.fetchall()
    return rows

def run_execute(sql, params=None, many=False, seq=None):
    with connect() as conn:
        with conn.cursor() as cur:
            try:
                if many and seq is not None:
                    cur.executemany(sql, seq)
                else:
                    cur.execute(sql, params or ())
                conn.commit()
                return True, None
            except Exception as e:
                conn.rollback()
                return False, str(e)

def call_proc(proc_name, args):
    with connect() as conn:
        with conn.cursor() as cur:
            try:
                cur.callproc(proc_name, args)
                conn.commit()
                return True, None
            except Exception as e:
                conn.rollback()
                return False, str(e)

# -------------------------------------------------------------
# Auth helpers
# -------------------------------------------------------------
def login_form():
    with st.form("login_form", clear_on_submit=False):
        st.subheader("Login")
        username = st.text_input("Username")
        password = st.text_input("Password", type="password")
        submitted = st.form_submit_button("Sign in")
        if submitted:
            if username == ADMIN_CREDENTIALS["username"] and password == ADMIN_CREDENTIALS["password"]:
                st.session_state["auth"] = {"role": "admin", "username": username}
                st.success("Logged in as Admin")
                st.rerun()
            elif username == GUEST_CREDENTIALS["username"] and password == GUEST_CREDENTIALS["password"]:
                st.session_state["auth"] = {"role": "guest", "username": username}
                st.success("Logged in as Guest")
                st.rerun()

            else:
                st.error("Invalid username or password")

def ensure_session():
    if "auth" not in st.session_state:
        st.session_state["auth"] = None

def logout():
    if "auth" in st.session_state:
        st.session_state["auth"] = None
        st.rerun()


# -------------------------------------------------------------
# UI blocks: Admin
# -------------------------------------------------------------
def admin_add_race_and_results():
    st.markdown("### ➕ Add a New Race and its Results")
    with st.form("add_race_form"):
        col1, col2, col3 = st.columns(3)
        with col1:
            race_id = st.text_input("Race ID", help="e.g., race99")
            race_name = st.text_input("Race Name")
        with col2:
            # Tracks
            tracks = [r["trackName"] for r in run_query("SELECT trackName FROM Track ORDER BY trackName;")]
            if not tracks:
                st.info("No tracks found — add a new one")
            use_existing_track = st.radio("Track option", ["Use existing track", "Add new track"], horizontal=True)
            if use_existing_track == "Use existing track" and tracks:
                track_name = st.selectbox("Track", tracks)
            else:
                track_name = st.text_input("New Track Name")
        with col3:
            race_date = st.date_input("Race Date", value=datetime(2007, 6, 1))
            race_time = st.time_input("Race Time", value=datetime.strptime("12:00", "%H:%M").time())

        # Additional fields for new track
        if use_existing_track == "Add new track":
            colt1, colt2 = st.columns(2)
            with colt1:
                track_location = st.text_input("Track Location (e.g., SA, UE)")
            with colt2:
                track_length = st.number_input("Track Length", min_value=1, value=18)

        # Results - dynamic rows
        st.markdown("#### Results")
        horses = run_query("SELECT horseId, horseName FROM Horse ORDER BY horseName;")
        horse_options = {f"{h['horseName']} ({h['horseId']})": h["horseId"] for h in horses}
        result_labels = ["first", "second", "third", "fourth", "no show", "last"]
        num_rows = st.number_input("Number of result rows to add", min_value=1, max_value=20, value=3)

        result_inputs = []
        for i in range(int(num_rows)):
            c1, c2, c3 = st.columns([4, 2, 2])
            with c1:
                horse_sel = st.selectbox(f"Horse #{i+1}", list(horse_options.keys()), key=f"res_horse_{i}")
            with c2:
                res_val = st.selectbox(f"Result #{i+1}", result_labels, key=f"res_val_{i}")
            with c3:
                prize_val = st.number_input(f"Prize #{i+1}", min_value=0.0, value=0.0, step=100.0, key=f"res_prize_{i}")
            result_inputs.append((horse_options[horse_sel], res_val, prize_val))

        submitted = st.form_submit_button("Create Race and Results")
        if submitted:
            # Basic validation
            if not race_id or not race_name or not track_name:
                st.error("Please fill all required fields.")
                return
            # Insert
            if use_existing_track == "Add new track":
                ok, err = run_execute(
                    "INSERT INTO Track(trackName, location, length) VALUES (%s, %s, %s);",
                    (track_name, track_location or None, int(track_length)),
                )
                if not ok and "Duplicate entry" not in (err or ""):
                    st.error(f"Could not insert new track: {err}")
                    return

            ok, err = run_execute(
                "INSERT INTO Race(raceId, raceName, trackName, raceDate, raceTime) VALUES (%s,%s,%s,%s,%s);",
                (race_id, race_name, track_name, race_date, race_time),
            )
            if not ok:
                st.error(f"Could not insert race: {err}")
                return

            # RaceResults
            seq = [(race_id, hid, res, float(prz)) for (hid, res, prz) in result_inputs]
            ok, err = run_execute(
                "INSERT INTO RaceResults(raceId, horseId, results, prize) VALUES (%s,%s,%s,%s);",
                many=True,
                seq=seq,
            )
            if not ok:
                st.error(f"Inserted race, but results failed: {err}")
            else:
                st.success(f"Race {race_id} and {len(seq)} result rows inserted.")

def admin_delete_owner():
    st.markdown("### 🗑️ Delete an Owner (uses Stored Procedure)")
    owners = run_query("SELECT ownerId, fname, lname FROM Owner ORDER BY lname, fname;")
    if not owners:
        st.info("No owners to delete.")
        return

    lookup = {f"{o['lname']}, {o['fname']} ({o['ownerId']})": o["ownerId"] for o in owners}
    sel = st.selectbox("Pick Owner", list(lookup.keys()))
    owner_id = lookup[sel]
    if st.button("Delete Owner via sp_delete_owner"):
        ok, err = call_proc("sp_delete_owner", (owner_id,))
        if ok:
            st.success(f"Owner {owner_id} deleted (and related rows in Owns).")
        else:
            st.error(f"Delete failed: {err}")

def admin_move_horse():
    st.markdown("### 🔁 Move a Horse to Another Stable")
    horses = run_query("SELECT horseId, horseName, stableId FROM Horse ORDER BY horseName;")
    stables = run_query("SELECT stableId, stableName FROM Stable ORDER BY stableName;")
    if not horses or not stables:
        st.info("Need horses and stables to perform this action.")
        return
    h_lookup = {f"{h['horseName']} ({h['horseId']}) — current: {h['stableId']}": h["horseId"] for h in horses}
    s_lookup = {f"{s['stableName']} ({s['stableId']})": s["stableId"] for s in stables}
    c1, c2 = st.columns(2)
    with c1:
        horse_choice = st.selectbox("Horse", list(h_lookup.keys()))
    with c2:
        new_stable = st.selectbox("New Stable", list(s_lookup.keys()))
    if st.button("Move Horse"):
        ok, err = run_execute("UPDATE Horse SET stableId=%s WHERE horseId=%s;", (s_lookup[new_stable], h_lookup[horse_choice]))
        if ok:
            st.success("Horse moved successfully.")
        else:
            st.error(f"Failed to move horse: {err}")

def admin_approve_trainer():
    st.markdown("### ✅ Approve a New Trainer to Join a Stable")
    st.caption("This uses a simple application queue (TrainerApplications). Approving creates a row in Trainer.")
    apps = run_query("""
        SELECT ta.appId, ta.fname, ta.lname, ta.stableId, s.stableName, ta.created_at
        FROM TrainerApplications ta
        JOIN Stable s ON s.stableId = ta.stableId
        ORDER BY ta.created_at;
    """)
    if not apps:
        st.info("No pending trainer applications.")
        # Provide quick form to manually add a trainer without application.
        with st.expander("Or add a trainer directly"):
            with st.form("add_trainer_direct"):
                tf = st.text_input("First name")
                tl = st.text_input("Last name")
                stables = run_query("SELECT stableId, stableName FROM Stable ORDER BY stableName;")
                s_lookup = {f"{s['stableName']} ({s['stableId']})": s["stableId"] for s in stables}
                sid = st.selectbox("Stable", list(s_lookup.keys()))
                submitted = st.form_submit_button("Add Trainer")
                if submitted:
                    # generate trainerId
                    new_id = f"trainer{int(datetime.utcnow().timestamp())}"
                    ok, err = run_execute("INSERT INTO Trainer(trainerId, lname, fname, stableId) VALUES (%s,%s,%s,%s);",
                                          (new_id, tl, tf, s_lookup[sid]))
                    if ok:
                        st.success(f"Trainer {tf} {tl} added (ID={new_id}).")
                    else:
                        st.error(f"Failed to add trainer: {err}")
        return

    df = pd.DataFrame(apps)
    st.dataframe(df, use_container_width=True, hide_index=True)

    for app in apps:
        col1, col2, col3 = st.columns([6, 1, 1])
        with col1:
            st.write(f"Application #{app['appId']}: **{app['fname']} {app['lname']}** → {app['stableId']} ({app['stableName']})")
        with col2:
            if st.button("Approve", key=f"approve_{app['appId']}"):
                new_id = f"trainer{int(datetime.utcnow().timestamp())}{app['appId']}"
                ok1, err1 = run_execute(
                    "INSERT INTO Trainer(trainerId, lname, fname, stableId) VALUES (%s,%s,%s,%s);",
                    (new_id, app["lname"], app["fname"], app["stableId"]),
                )
                if not ok1:
                    st.error(f"Could not approve: {err1}")
                else:
                    ok2, err2 = run_execute("DELETE FROM TrainerApplications WHERE appId=%s;", (app["appId"],))
                    if not ok2:
                        st.warning(f"Approved but failed to remove application: {err2}")
                    else:
                        st.success(f"Approved trainer {app['fname']} {app['lname']} (ID={new_id}).")
                        st.rerun()

        with col3:
            if st.button("Reject", key=f"reject_{app['appId']}"):
                ok, err = run_execute("DELETE FROM TrainerApplications WHERE appId=%s;", (app["appId"],))
                if ok:
                    st.info(f"Application #{app['appId']} rejected and removed.")
                    st.rerun()

                else:
                    st.error(f"Reject failed: {err}")

# -------------------------------------------------------------
# UI blocks: Guest
# -------------------------------------------------------------
def guest_browse_by_owner():
    st.markdown("### 🐎 Horses (name & age) and their Trainer names by Owner last name")
    lname = st.text_input("Owner Last Name (exact match)", value="Mohammed")
    if st.button("Search"):
        sql = """
        SELECT h.horseName, h.age,
               t.fname AS trainer_fname, t.lname AS trainer_lname
        FROM Owner o
        JOIN Owns ow ON o.ownerId = ow.ownerId
        JOIN Horse h ON ow.horseId = h.horseId
        LEFT JOIN Trainer t ON t.stableId = h.stableId
        WHERE o.lname = %s
        ORDER BY h.horseName, t.lname, t.fname;
        """
        rows = run_query(sql, (lname,))
        if rows:
            st.dataframe(pd.DataFrame(rows), use_container_width=True, hide_index=True)
        else:
            st.info("No results.")

def guest_winning_trainers():
    st.markdown("### 🏆 Trainers who have trained winners (first place)")
    sql = """
    SELECT DISTINCT t.fname AS trainer_fname, t.lname AS trainer_lname,
           h.horseName AS winning_horse, r.raceName AS winning_race,
           r.trackName, r.raceDate, rr.prize
    FROM Trainer t
    JOIN Horse h ON h.stableId = t.stableId
    JOIN RaceResults rr ON rr.horseId = h.horseId
    JOIN Race r ON r.raceId = rr.raceId
    WHERE rr.results = 'first'
    ORDER BY r.raceDate DESC, t.lname, t.fname;
    """
    rows = run_query(sql)
    st.dataframe(pd.DataFrame(rows), use_container_width=True, hide_index=True)

def guest_winnings_per_trainer():
    st.markdown("### 💰 Total prize money per Trainer (sorted)")
    sql = """
    SELECT t.trainerId, t.fname AS trainer_fname, t.lname AS trainer_lname,
           COALESCE(SUM(rr.prize), 0) AS total_winnings
    FROM Trainer t
    JOIN Horse h ON h.stableId = t.stableId
    LEFT JOIN RaceResults rr ON rr.horseId = h.horseId
    GROUP BY t.trainerId, t.fname, t.lname
    ORDER BY total_winnings DESC, t.lname, t.fname;
    """
    rows = run_query(sql)
    st.dataframe(pd.DataFrame(rows), use_container_width=True, hide_index=True)

def guest_track_stats():
    st.markdown("### 🏟️ Tracks: race count and total participating horses")
    sql = """
    SELECT tr.trackName,
           COUNT(DISTINCT r.raceId) AS race_count,
           COUNT(rr.horseId) AS total_horses
    FROM Track tr
    LEFT JOIN Race r ON r.trackName = tr.trackName
    LEFT JOIN RaceResults rr ON rr.raceId = r.raceId
    GROUP BY tr.trackName
    ORDER BY race_count DESC, total_horses DESC, tr.trackName;
    """
    rows = run_query(sql)
    st.dataframe(pd.DataFrame(rows), use_container_width=True, hide_index=True)

def guest_apply_trainer():
    st.markdown("### (Optional) Apply to be a Trainer")
    with st.form("apply_trainer"):
        tf = st.text_input("First name")
        tl = st.text_input("Last name")
        stables = run_query("SELECT stableId, stableName FROM Stable ORDER BY stableName;")
        lookup = {f"{s['stableName']} ({s['stableId']})": s["stableId"] for s in stables}
        sid = st.selectbox("Choose Stable", list(lookup.keys()) if lookup else ["No stables available"])
        submitted = st.form_submit_button("Submit Application")
        if submitted:
            if not tf or not tl or not lookup:
                st.error("Please fill all fields.")
            else:
                ok, err = run_execute(
                    "INSERT INTO TrainerApplications(fname, lname, stableId) VALUES (%s,%s,%s);",
                    (tf, tl, lookup[sid])
                )
                if ok:
                    st.success("Application submitted.")
                else:
                    st.error(f"Failed to submit: {err}")

# -------------------------------------------------------------
# Main
# -------------------------------------------------------------
ensure_session()

st.title("🏇 Horse Racing Database System")

if not st.session_state["auth"]:
    login_form()
    st.stop()

role = st.session_state["auth"]["role"]

with st.sidebar:
    st.markdown(f"**Signed in as:** `{st.session_state['auth']['username']}` ({role})")
    if st.button("Logout"):
        logout()

if role == "admin":
    st.header("Admin Console")
    tab1, tab2, tab3, tab4 = st.tabs([
        "Add Race + Results",
        "Delete Owner",
        "Move Horse",
        "Approve Trainer"
    ])
    with tab1:
        admin_add_race_and_results()
    with tab2:
        admin_delete_owner()
    with tab3:
        admin_move_horse()
    with tab4:
        admin_approve_trainer()

elif role == "guest":
    st.header("Guest Portal")
    tab1, tab2, tab3, tab4, tab5 = st.tabs([
        "Browse by Owner Last Name",
        "Winning Trainers",
        "Winnings per Trainer",
        "Track Stats",
        "Apply as Trainer (optional)"
    ])
    with tab1:
        guest_browse_by_owner()
    with tab2:
        guest_winning_trainers()
    with tab3:
        guest_winnings_per_trainer()
    with tab4:
        guest_track_stats()
    with tab5:
        guest_apply_trainer()
