import logging
logger = logging.getLogger(__name__)

import streamlit as st
import requests
from modules.nav import SideBarLinks

st.set_page_config(layout='wide')

SideBarLinks()

st.title("Browse Listings")

API_BASE = "http://web-api:4000"

try:
    cat_resp = requests.get(f"{API_BASE}/categories", timeout=10)
    category_names = ["All"] + [c["name"] for c in cat_resp.json()] if cat_resp.status_code == 200 else ["All"]
except requests.exceptions.RequestException:
    category_names = ["All"]

# Filtering

st.subheader("Filter Listings")

f_col1, f_col2, f_col3, f_col4 = st.columns(4)

with f_col1:
    artist_filter = st.text_input("Artist username", value="")

with f_col2:
    category_filter = st.selectbox("Category", options=category_names)

with f_col3:
    min_price = st.number_input("Min price ($)", min_value=0.0, value=0.0, step=0.50)

with f_col4:
    max_price = st.number_input("Max price ($)", min_value=0.0, value=500.0, step=0.50)

params = {"status": "active"}

if category_filter != "All":
    params["category"] = category_filter

try:
    resp = requests.get(f"{API_BASE}/listings", params=params, timeout=10)
    if resp.status_code != 200:
        st.error(f"Failed to load listings ({resp.status_code})")
        st.stop()
    listings = resp.json()
except requests.exceptions.RequestException as e:
    st.error(f"Could not reach API: {e}")
    st.stop()

if artist_filter.strip():
    listings = [
        l for l in listings
        if artist_filter.strip().lower() in (l.get("artist_username") or "").lower()
    ]

listings = [
    l for l in listings
    if min_price <= float(l.get("price", 0)) <= max_price
]

# Results

st.divider()
st.write(f"**{len(listings)} listing(s) found**")

if not listings:
    st.info("No listings match your filters. Try adjusting your search.")
    st.stop()

# Grid display

COLS = 3

for row_start in range(0, len(listings), COLS):
    row_listings = listings[row_start : row_start + COLS]
    cols = st.columns(COLS)

    for col, listing in zip(cols, row_listings):
        with col:
            with st.container(border=True):
                st.markdown(f"### {listing.get('title')}")
                st.write(f"**Artist:** {listing.get('artist_username')}")
                st.write(f"**Category:** {listing.get('category_name') or '-'}")
                st.write(f"**Item:** {listing.get('item_name')}")
                st.write(f"**Price:** ${listing.get('price')}")
                st.write(f"**Qty available:** {listing.get('quantity')}")
                st.caption(
                    f"{(listing.get('listing_type') or '-').replace('_', ' ').title()} · "
                    f"Posted {listing.get('post_time')}"
                )