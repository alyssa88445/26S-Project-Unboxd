import logging
logger = logging.getLogger(__name__)

import streamlit as st
import requests
from modules.nav import SideBarLinks

st.set_page_config(layout='wide')

SideBarLinks()

st.title("View Seller Verification")

API_BASE = "http://web-api:4000"

# Artists for dropdown

try:
    all_resp = requests.get(f"{API_BASE}/artists", timeout=10)
    if all_resp.status_code != 200:
        st.error(f"Failed to load sellers ({all_resp.status_code})")
        st.stop()
    all_artists = all_resp.json()
except requests.exceptions.RequestException as e:
    st.error(f"Could not reach API: {e}")
    st.stop()

username_to_id = {a["username"]: a["artist_id"] for a in all_artists}

selected_username = st.selectbox("Select a seller", options=list(username_to_id.keys()))

if st.button("Look up seller", type="primary"):
    st.session_state["lookup_artist_id"] = username_to_id[selected_username]

# Display seller verification
if "lookup_artist_id" in st.session_state:
    aid = st.session_state["lookup_artist_id"]

    try:
        resp = requests.get(f"{API_BASE}/artists/{aid}", timeout=10)
        if resp.status_code == 404:
            st.error("Seller not found.")
            st.stop()
        elif resp.status_code != 200:
            st.error(f"Failed to load seller ({resp.status_code})")
            st.stop()
        artist = resp.json()
    except requests.exceptions.RequestException as e:
        st.error(f"Could not reach API: {e}")
        st.stop()

    st.divider()

    verified = artist.get("is_verified")

    if verified:
        st.success("✓ This seller has been verified by the platform.")
    else:
        st.warning("⚠ This seller has not yet been verified by the platform.")

    st.markdown(f"## {artist.get('username')}")
    st.write(f"**Verification status:** {'Verified' if verified else 'Unverified'}")

    st.divider()
    st.markdown("### Active Listings by This Seller")

    try:
        listings_resp = requests.get(
            f"{API_BASE}/listings",
            params={"artist_id": aid, "status": "active"},
            timeout=10,
        )
        if listings_resp.status_code == 200:
            listings = listings_resp.json()
        else:
            listings = []
    except requests.exceptions.RequestException:
        listings = []

    if not listings:
        st.info("This seller has no active listings.")
    else:
        st.write(f"**{len(listings)} active listing(s)**")
        st.dataframe(
            [
                {
                    "ID": l["listing_id"],
                    "Title": l.get("title"),
                    "Item": l.get("item_name"),
                    "Price": f"${l.get('price')}",
                    "Quantity": l.get("quantity"),
                    "Type": (l.get("listing_type") or "-").replace("_", " ").title(),
                    "Posted": l.get("post_time"),
                }
                for l in listings
            ],
            use_container_width=True,
            hide_index=True,
        )