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

# --- Buttons ---
col1, col2 = st.columns([1, 1])
with col1:
    if st.button("+ Create New Item", use_container_width=True):
        st.session_state["show_new_item"] = True
        st.session_state["show_new_listing"] = False
with col2:
    if st.button("+ Create New Listing", use_container_width=True):
        st.session_state["show_new_listing"] = True
        st.session_state["show_new_item"] = False

# --- New Item Form ---
if st.session_state.get("show_new_item"):
    st.subheader("New Item")

    # Fetch categories for dropdown
    try:
        cat_resp = requests.get(f"{API_BASE}/categories", timeout=10)
        categories = cat_resp.json()
        cat_map = {c["name"]: c["category_id"] for c in categories}
    except:
        cat_map = {}

    with st.form("new_item_form"):
        name = st.text_input("Item Name*")
        description = st.text_area("Description")
        size = st.selectbox("Size", ["S", "M", "L"])
        image_link = st.text_input("Image URL")
        category = st.selectbox("Category*", list(cat_map.keys()))
        submitted = st.form_submit_button("Create Item")

    if submitted:
        if not name:
            st.error("Item name is required.")
        else:
            try:
                resp = requests.post(
                    f"{API_BASE}/artists/{artist_id}/items",
                    json={
                        "name": name,
                        "description": description,
                        "size": size,
                        "image_link": image_link,
                        "category_id": cat_map.get(category)
                    },
                    timeout=10
                )
                resp.raise_for_status()
                st.success("Item created!")
                st.session_state["show_new_item"] = False
                st.rerun()
            except requests.exceptions.RequestException as e:
                st.error(f"Failed to create item: {e}")

# --- New Listing Form ---
if st.session_state.get("show_new_listing"):
    st.subheader("New Listing")

    # Fetch artist's items for dropdown
    try:
        items_resp = requests.get(f"{API_BASE}/artists/{artist_id}/items", timeout=10)
        items = items_resp.json()
        item_map = {f"{i['name']} (#{i['item_id']})": i["item_id"] for i in items}
    except:
        item_map = {}

    with st.form("new_listing_form"):
        title = st.text_input("Listing Title*")
        selected_item = st.selectbox("Item*", list(item_map.keys()))
        price = st.number_input("Price*", min_value=0.01, step=0.01, format="%.2f")
        quantity = st.number_input("Quantity*", min_value=1, step=1)
        listing_type = st.selectbox("Listing Type*", ["standard", "limited"])
        submitted = st.form_submit_button("Create Listing")

    if submitted:
        if not title:
            st.error("Listing title is required.")
        else:
            try:
                resp = requests.post(
                    f"{API_BASE}/artists/{artist_id}/listings",
                    json={
                        "title": title,
                        "item_id": item_map.get(selected_item),
                        "price": price,
                        "quantity": quantity,
                        "listing_type": listing_type
                    },
                    timeout=10
                )
                resp.raise_for_status()
                st.success("Listing created! It will be reviewed before going live.")
                st.session_state["show_new_listing"] = False
                st.rerun()
            except requests.exceptions.RequestException as e:
                st.error(f"Failed to create listing: {e}")

# --- Fetch listings ---
try:
    response = requests.get(f"{API_BASE}/artists/{artist_id}/listings", timeout=10)
    response.raise_for_status()
    listings = response.json()
except requests.exceptions.RequestException as e:
    st.error(f"Could not reach API: {e}")
    st.stop()

if not listings:
    st.info("You have no listings yet.")
    st.stop()

df = pd.DataFrame(listings)

# --- Filters & Sorting ---
col1, col2, col3 = st.columns(3)
with col1:
    categories = ["All"] + sorted(df["category"].dropna().unique().tolist())
    selected_category = st.selectbox("Filter by category", categories)
with col2:
    statuses = ["All"] + sorted(df["status"].dropna().unique().tolist())
    selected_status = st.selectbox("Filter by status", statuses)
with col3:
    sort_by = st.selectbox("Sort by", ["post_time", "price", "total_sales", "quantity"])
    sort_order = st.radio("Order", ["Descending", "Ascending"], horizontal=True)

if selected_category != "All":
    df = df[df["category"] == selected_category]
if selected_status != "All":
    df = df[df["status"] == selected_status]

df = df.sort_values(by=sort_by, ascending=(sort_order == "Ascending"))

st.caption(f"Showing {len(df)} listing(s)")
st.divider()

# --- Status badge helper ---
status_badges = {
    "active":   "✅ Active",
    "pending":  "⏳ Pending",
    "archive":  "📦 Archived",
    "rejected": "❌ Rejected",
    "flagged":  "🚩 Flagged",
    "approved": "✅ Approved"
}

# --- Display listings ---
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
                f"Category: {listing.get('category', 'N/A')}  ·  "
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

        st.divider()