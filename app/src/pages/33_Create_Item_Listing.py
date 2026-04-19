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

st.title("Create a new Item or Listing")

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