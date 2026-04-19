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

# New item form
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
        st.markdown("**Item Details**")
        name = st.text_input("Item Name*")
        description = st.text_area("Description")
        col1, col2 = st.columns(2)
        with col1:
            size = st.selectbox("Size", ["S", "M", "L"])
        with col2:
            category = st.selectbox("Category*", list(cat_map.keys()))
        image_link = st.text_input("Image URL")

        st.divider()
        st.markdown("**Variants & Pull Rates**")
        st.caption("Add up to 10 variants. Pull rate is the probability of pulling this variant (0.00 - 1.00).")

        num_variants = st.number_input("Number of variants", min_value=0, max_value=10, step=1, value=1)

        variants = []
        if num_variants > 0:
            header_col1, header_col2 = st.columns([3, 1])
            with header_col1:
                st.markdown("<p style='font-size:13px;color:gray'>Variant Name</p>", unsafe_allow_html=True)
            with header_col2:
                st.markdown("<p style='font-size:13px;color:gray'>Pull Rate</p>", unsafe_allow_html=True)

            for i in range(int(num_variants)):
                col1, col2 = st.columns([3, 1])
                with col1:
                    vname = st.text_input(f"Variant name", key=f"vname_{i}", label_visibility="collapsed", placeholder=f"Variant {i+1} name")
                with col2:
                    vrate = st.number_input(f"Pull rate", key=f"vrate_{i}", label_visibility="collapsed", min_value=0.0, max_value=1.0, step=0.01, format="%.2f")
                variants.append({"name": vname, "pull_rate": vrate})

        submitted = st.form_submit_button("Create Item", use_container_width=True)

    if submitted:
        if not name:
            st.error("Item name is required.")
        else:
            # Validate variants
            variant_errors = []
            valid_variants = [v for v in variants if v["name"].strip()]
            for v in valid_variants:
                if v["pull_rate"] <= 0:
                    variant_errors.append(f"'{v['name']}' needs a pull rate greater than 0.")

            if variant_errors:
                for err in variant_errors:
                    st.error(err)
            else:
                try:
                    # Create the item
                    resp = requests.post(
                        f"{API_BASE}/items",
                        json={
                            "name": name,
                            "description": description,
                            "size": size,
                            "image_link": image_link,
                            "category_id": cat_map.get(category),
                            "artist_id": artist_id
                        },
                        timeout=10
                    )
                    resp.raise_for_status()
                    new_item_id = resp.json().get("item_id")

                    # Add variants
                    for v in valid_variants:
                        requests.post(
                            f"{API_BASE}/items/{new_item_id}/variants",
                            json={"name": v["name"], "pull_rate": v["pull_rate"]},
                            timeout=10
                        )

                    st.success(f"Item created with {len(valid_variants)} variant(s)!")
                    st.session_state["show_new_item"] = False
                    st.rerun()
                except requests.exceptions.RequestException as e:
                    st.error(f"Failed to create item: {e}")

# New listing form
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
                    f"{API_BASE}/listings",
                    json={"title": title, "item_id": item_map.get(selected_item),"price": price,
                        "quantity": quantity,"listing_type": listing_type,"status": "pending",
                        "artist_id": artist_id},
                    timeout=10
                )
                resp.raise_for_status()
                st.success("Listing created! It will be reviewed before going live.")
                st.session_state["show_new_listing"] = False
                st.rerun()
            except requests.exceptions.RequestException as e:
                st.error(f"Failed to create listing: {e}")