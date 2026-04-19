import logging
logger = logging.getLogger(__name__)

import streamlit as st
import requests
import pandas as pd
from modules.nav import SideBarLinks

st.set_page_config(layout='wide')
SideBarLinks()

artist_id = st.session_state.get("artist_id", 1)
API_BASE = "http://web-api:4000"

st.title("My Listings")

# Access button to create new item or listing
if st.button(" + Create New Item or Listing",
             use_container_width=True):
    st.switch_page("pages/33_Create_Item_Listing.py")

# Fetch listings
try:
    response = requests.get(f"{API_BASE}/listings", params={"artist_id": artist_id}, timeout=10)
    response.raise_for_status()
    listings = response.json()
except requests.exceptions.RequestException as e:
    st.error(f"Could not reach API: {e}")
    st.stop()

if not listings:
    st.info("You have no listings yet.")
    st.stop()

df = pd.DataFrame(listings)

# filters
col1, col2, col3 = st.columns(3)
with col1:
    categories = ["All"] + sorted(df["category_name"].dropna().unique().tolist())
    selected_category = st.selectbox("Filter by category", categories)
with col2:
    statuses = ["All"] + sorted(df["status"].dropna().unique().tolist())
    selected_status = st.selectbox("Filter by status", statuses)
with col3:
    sortable = [c for c in ["post_time", "price", "total_sales", "quantity"] if c in df.columns]
    sort_by = st.selectbox("Sort by", sortable)
    sort_order = st.radio("Order", ["Descending", "Ascending"], horizontal=True)

if selected_category != "All":
    df = df[df["category_name"] == selected_category]
if selected_status != "All":
    df = df[df["status"] == selected_status]

df = df.sort_values(by=sort_by, ascending=(sort_order == "Ascending"))

st.caption(f"Showing {len(df)} listing(s)")
st.divider()

# Status badge helper 
status_badges = {
    "active":   "✅ Active",
    "pending":  "⏳ Pending",
    "archive":  "📦 Archived",
    "rejected": "❌ Rejected",
    "flagged":  "🚩 Flagged",
    "approved": "✅ Approved"
}

# Display listings
for _, listing in df.iterrows():
    with st.container():
        col1, col2 = st.columns([1, 3])

        with col1:
            if listing.get("image_link"):
                st.image(listing["image_link"], width=160)
            else:
                st.markdown(
                    "<div style='width:160px;height:160px;background:#F1EFE8;"
                    "border-radius:8px;display:flex;align-items:center;"
                    "justify-content:center;color:#888;font-size:13px'>No image</div>",
                    unsafe_allow_html=True
                )

        with col2:
            st.subheader(listing.get("title", "Untitled"))
            st.caption(
                f"Item: {listing.get('item_name', 'N/A')}  ·  "
                f"Category: {listing.get('category_name', 'N/A')}  ·  "
                f"Size: {listing.get('size', 'N/A')}  ·  "
                f"Type: {listing.get('listing_type', 'N/A')}"
            )

            if listing.get("description"):
                st.write(listing["description"])

            m1, m2, m3, m4 = st.columns(4)
            with m1:
                st.metric("Price", f"${float(listing.get('price', 0)):.2f}")
            with m2:
                st.metric("Quantity", int(listing.get("quantity", 0)))
            with m3:
                st.metric("Likes", int(listing.get("like_count", 0)))
            with m4:
                st.metric("Revenue", f"${float(listing.get('total_sales', 0)):,.2f}")

            status = listing.get("status", "")
            st.caption(
                f"{status_badges.get(status, status)}  ·  "
                f"Listed: {str(listing.get('post_time', ''))[:10]}"
            )

            # Button to view listings
            if st.button("View / Edit", key=f"listing_{listing['listing_id']}"):
                st.session_state["selected_listing_id"] = listing["listing_id"]
                st.session_state["selected_item_id"] = listing["item_id"]
                st.switch_page("pages/34_Listing_Detail.py")

        st.divider()