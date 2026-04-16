import logging
logger = logging.getLogger(__name__)

import streamlit as st
import requests
from modules.nav import SideBarLinks

st.set_page_config(layout='wide')

SideBarLinks()

st.title("Artist Applications")

API_BASE = "http://web-api:4000"
admin_id = st.session_state.get("admin_id", 1)


# Filter control

status_filter = st.selectbox(
    "Filter by application status",
    options=["Pending", "All", "Approved", "Rejected"],
    index=0,
)


# Fetch artists + their applications

try:
    artists_resp = requests.get(f"{API_BASE}/artists", timeout=10)
    if artists_resp.status_code != 200:
        st.error(f"Failed to load artists ({artists_resp.status_code})")
        st.stop()
    artists = artists_resp.json()
except requests.exceptions.RequestException as e:
    st.error(f"Could not reach API: {e}")
    st.stop()

applications = []
for artist in artists:
    aid = artist.get("artist_id")
    try:
        app_resp = requests.get(
            f"{API_BASE}/artists/{aid}/application", timeout=10
        )
        if app_resp.status_code == 200:
            app = app_resp.json()
            app["_artist"] = artist
            applications.append(app)
    except requests.exceptions.RequestException:
        continue

# Apply status filter
if status_filter != "All":
    applications = [
        a for a in applications if a.get("status", "").lower() == status_filter.lower()
    ]


# Render applications

st.write(f"**{len(applications)} application(s) matching filter: {status_filter}**")

if not applications:
    st.info("No applications match the current filter.")
else:
    for app in applications:
        artist = app["_artist"]
        status = app.get("status", "unknown")
        status_badge = {
            "pending": "🟡",
            "approved": "✅",
            "rejected": "❌",
        }.get(status, "⚪")

        header = (
            f"{status_badge} {artist.get('username', '?')} "
            f"({artist.get('first_name', '')} {artist.get('last_name', '')}) "
            f"- Status: {status.title()}"
        )
        with st.expander(header):
            info_col, action_col = st.columns([2, 1])

            with info_col:
                st.write(f"**Bio:** {artist.get('bio') or '(no bio)'}")
                st.write(
                    f"**Location:** {artist.get('city') or '?'}, "
                    f"{artist.get('state') or '?'}"
                )
                st.write(f"**Verified:** {'Yes' if artist.get('is_verified') else 'No'}")
                st.write(
                    f"**Portfolio:** "
                    f"[{app.get('portfolio_link')}]({app.get('portfolio_link')})"
                )
                st.write(f"**Submitted at:** {app.get('submitted_at')}")
                if app.get("reviewed_at"):
                    st.write(f"**Reviewed at:** {app.get('reviewed_at')}")

            with action_col:
                if status == "pending":
                    if st.button(
                        "Approve",
                        key=f"approve_{app['application_id']}",
                        type="primary",
                        use_container_width=True,
                    ):
                        r = requests.put(
                            f"{API_BASE}/artists/{artist['artist_id']}/application",
                            json={"status": "approved", "reviewer_id": admin_id},
                            timeout=10,
                        )
                        if r.status_code == 200:
                            st.success("Application approved - artist verified.")
                            st.rerun()
                        else:
                            st.error(f"Approve failed: {r.text}")

                    if st.button(
                        "Reject",
                        key=f"reject_{app['application_id']}",
                        use_container_width=True,
                    ):
                        r = requests.put(
                            f"{API_BASE}/artists/{artist['artist_id']}/application",
                            json={"status": "rejected", "reviewer_id": admin_id},
                            timeout=10,
                        )
                        if r.status_code == 200:
                            st.success("Application rejected.")
                            st.rerun()
                        else:
                            st.error(f"Reject failed: {r.text}")
                else:
                    st.caption(f"Already {status.title()} - no action available.")
