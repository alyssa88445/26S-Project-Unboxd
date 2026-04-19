import logging
logger = logging.getLogger(__name__)

import streamlit as st
import requests
from modules.nav import SideBarLinks

st.set_page_config(layout='wide')

SideBarLinks()

st.title("View Listing Information")

API_BASE = "http://web-api:4000"

# Input listing ID

listing_id_input = st.number_input(
    "Enter Listing ID",
    min_value=1,
    step=1,
    value=1,
)

if st.button("Look up listing", type="primary"):
    st.session_state["lookup_listing_id"] = int(listing_id_input)

# Display listing

if "lookup_listing_id" in st.session_state:
    lid = st.session_state["lookup_listing_id"]

    try:
        resp = requests.get(f"{API_BASE}/listings/{lid}", timeout=10)
        if resp.status_code == 404:
            st.error(f"No listing found with ID #{lid}.")
            st.stop()
        elif resp.status_code != 200:
            st.error(f"Failed to load listing ({resp.status_code})")
            st.stop()
        listing = resp.json()
    except requests.exceptions.RequestException as e:
        st.error(f"Could not reach API: {e}")
        st.stop()

    st.divider()

    img_col, info_col = st.columns([1, 2])

    with img_col:
        if listing.get("image_link"):
            st.image(listing["image_link"], use_column_width=True)
        else:
            st.info("No image available.")

    with info_col:
        st.markdown(f"## {listing.get('title')}")

        verified = listing.get("is_verified")
        artist_label = (
            f"{listing.get('artist_username')} ✓ Verified"
            if verified
            else listing.get("artist_username")
        )
        st.write(f"**Artist:** {artist_label}")

        st.write(f"**Price:** ${listing.get('price')}")
        st.write(f"**Quantity available:** {listing.get('quantity')}")
        st.write(
            f"**Listing type:** {(listing.get('listing_type') or '-').replace('_', ' ').title()}"
        )
        st.write(f"**Posted:** {listing.get('post_time')}")

        st.divider()

        st.markdown("### Box Details")
        st.write(f"**Item:** {listing.get('item_name')}")
        st.write(f"**Size:** {listing.get('size') or '-'}")
        st.write(f"**Description:** {listing.get('description') or 'No description provided.'}")

    st.divider()