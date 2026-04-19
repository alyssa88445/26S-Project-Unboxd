import logging
logger = logging.getLogger(__name__)

import streamlit as st
import requests
from modules.nav import SideBarLinks

st.set_page_config(layout='wide')
SideBarLinks()

API_BASE = "http://web-api:4000"

listing_id = st.session_state.get("selected_listing_id")
item_id = st.session_state.get("selected_item_id")

if not listing_id:
    st.error("No listing selected. Please go back to your listings.")
    st.stop()

# Fetch listing (includes item info)
try:
    resp = requests.get(f"{API_BASE}/listings/{listing_id}", timeout=10)
    resp.raise_for_status()
    listing = resp.json()
except requests.exceptions.RequestException as e:
    st.error(f"Could not load listing: {e}")
    st.stop()

# Fetch categories
try:
    cat_resp = requests.get(f"{API_BASE}/categories", timeout=10)
    categories = cat_resp.json()
    cat_map = {c["name"]: c["category_id"] for c in categories}
    cat_id_to_name = {c["category_id"]: c["name"] for c in categories}
except:
    cat_map = {}
    cat_id_to_name = {}

# Header
if st.button("← Go Back to Listings"):
    st.switch_page("pages/32_Artist_Listings.py")

st.title(listing.get("title", "Listing Detail"))
st.caption(f"Listing #{listing_id}  ·  Item: {listing.get('item_name', 'N/A')}  ·  Artist: @{listing.get('artist_username', 'N/A')}")
st.divider()

# Photo + status
col1, col2 = st.columns([1, 3])
with col1:
    if listing.get("image_link"):
        st.image(listing["image_link"], width=200)
    else:
        st.markdown(
            "<div style='width:200px;height:200px;background:#F1EFE8;"
            "border-radius:8px;display:flex;align-items:center;"
            "justify-content:center;color:#888;font-size:13px'>No image</div>",
            unsafe_allow_html=True
        )
with col2:
    status = listing.get("status", "")
    status_badges = {
        "active":   "✅ Active",
        "pending":  "⏳ Pending",
        "archive":  "📦 Archived",
        "rejected": "❌ Rejected",
        "flagged":  "🚩 Flagged",
        "approved": "✅ Approved"
    }
    st.markdown(f"**Status:** {status_badges.get(status, status)}")
    st.markdown(f"**Type:** {listing.get('listing_type', 'N/A')}")
    st.markdown(f"**Size:** {listing.get('size', 'N/A')}")
    st.markdown(f"**Listed:** {str(listing.get('post_time', ''))[:10]}")
    if listing.get("is_verified"):
        st.success("✓ Verified Artist")

st.divider()

# Edit Form
st.subheader("Edit Listing & Item")

with st.form("edit_form"):
    st.markdown("**Listing Details**")
    col1, col2 = st.columns(2)
    with col1:
        title = st.text_input("Title", value=listing.get("title", ""))
        price = st.number_input("Price", min_value=0.01, step=0.01, format="%.2f",
                                value=float(listing.get("price", 0)))
    with col2:
        quantity = st.number_input("Quantity", min_value=0, step=1,
                                   value=int(listing.get("quantity", 0)))
        status_options = ["pending", "active", "archive", "rejected", "flagged"]
        new_status = st.selectbox(
            "Status",
            status_options,
            index=status_options.index(status) if status in status_options else 0
        )

    st.divider()
    st.markdown("**Item Details**")
    col1, col2 = st.columns(2)
    with col1:
        item_name = st.text_input("Item Name", value=listing.get("item_name", ""))
        image_link = st.text_input("Image URL", value=listing.get("image_link", "") or "")
    with col2:
        current_category = cat_id_to_name.get(listing.get("category_id"), "")
        category_names = list(cat_map.keys())
        cat_index = category_names.index(current_category) if current_category in category_names else 0
        category = st.selectbox("Category", category_names, index=cat_index)
        size = st.selectbox(
            "Size", ["S", "M", "L"],
            index=["S", "M", "L"].index(listing.get("size", "S"))
            if listing.get("size") in ["S", "M", "L"] else 0
        )

    description = st.text_area("Item Description", value=listing.get("description", "") or "")

    st.divider()
    col1, col2 = st.columns(2)
    with col1:
        save = st.form_submit_button("Save Changes", use_container_width=True)
    with col2:
        archive = st.form_submit_button("Archive Listing", use_container_width=True)

if save or archive:
    errors = []
    target_status = "archive" if archive else new_status

    # Update listing
    try:
        listing_resp = requests.put(
            f"{API_BASE}/listings/{listing_id}",
            json={
                "title": title,
                "price": price,
                "quantity": quantity,
                "status": target_status
            },
            timeout=10
        )
        listing_resp.raise_for_status()
    except requests.exceptions.RequestException as e:
        errors.append(f"Listing update failed: {e}")

    # Update item
    try:
        item_resp = requests.put(
            f"{API_BASE}/items/{item_id}",
            json={
                "name": item_name,
                "image_link": image_link,
                "description": description,
                "category_id": cat_map.get(category),
                "size": size
            },
            timeout=10
        )
        item_resp.raise_for_status()
    except requests.exceptions.RequestException as e:
        errors.append(f"Item update failed: {e}")

    if errors:
        for err in errors:
            st.error(err)
    else:
        st.success("Archived!" if archive else "Changes saved!")
        st.rerun()