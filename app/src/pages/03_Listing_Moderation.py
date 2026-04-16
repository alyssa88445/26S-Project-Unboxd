import logging
logger = logging.getLogger(__name__)

import streamlit as st
import requests
from modules.nav import SideBarLinks

st.set_page_config(layout='wide')

SideBarLinks()

st.title("Listing Moderation & Drop Management")

API_BASE = "http://web-api:4000"
admin_id = st.session_state.get("admin_id", 1)

VALID_STATUSES = ["pending", "active", "archive", "approved", "rejected", "flagged"]
LISTING_TYPES = ["standard", "limited"]


@st.dialog("Confirm Deletion")
def confirm_delete(listing_id, title):
    st.error(f"Permanently delete listing **#{listing_id} - {title}**?")
    st.caption("This removes the listing and its order_items (cascade). This cannot be undone.")
    col1, col2 = st.columns(2)
    with col1:
        if st.button("Yes, delete", type="primary", use_container_width=True):
            r = requests.delete(f"{API_BASE}/listings/{listing_id}", timeout=10)
            if r.status_code == 200:
                st.session_state["_delete_success"] = f"Listing {listing_id} deleted."
                st.rerun()
            else:
                st.error(f"Delete failed: {r.text}")
    with col2:
        if st.button("Cancel", use_container_width=True):
            st.rerun()


if "_delete_success" in st.session_state:
    st.success(st.session_state.pop("_delete_success"))


moderate_tab, drops_tab = st.tabs(["Moderate Listings", "Manage Drops"])


# Tab 1 - Moderate listings
with moderate_tab:
    f_col1, f_col2, f_col3 = st.columns(3)
    with f_col1:
        status_filter = st.selectbox(
            "Status filter",
            options=["All"] + VALID_STATUSES,
            format_func=lambda x: x.replace("_", " ").title(),
            index=0,
        )
    with f_col2:
        type_filter = st.selectbox(
            "Type filter",
            options=["All"] + LISTING_TYPES,
            format_func=lambda x: x.replace("_", " ").title(),
            index=0,
        )
    with f_col3:
        artist_filter = st.text_input("Artist username (contains)", value="")

    params = {}
    if status_filter != "All":
        params["status"] = status_filter
    if type_filter != "All":
        params["type"] = type_filter

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

    st.write(f"**{len(listings)} listing(s)**")

    for listing in listings:
        lid = listing["listing_id"]
        header = (
            f"#{lid} - {listing.get('title')} - "
            f"${listing.get('price')} - [{listing.get('status', '').title()}] - "
            f"{(listing.get('listing_type') or '-').replace('_', ' ').title()} - by {listing.get('artist_username')}"
        )
        with st.expander(header):
            info_col, act_col = st.columns([2, 2])

            with info_col:
                st.write(f"**Item:** {listing.get('item_name')}")
                st.write(f"**Quantity:** {listing.get('quantity')}")
                st.write(f"**Posted:** {listing.get('post_time')}")

                try:
                    mod_resp = requests.get(
                        f"{API_BASE}/listings/{lid}/moderation", timeout=10
                    )
                    if mod_resp.status_code == 200:
                        history = mod_resp.json()
                        if history:
                            st.write("**Moderation history:**")
                            for h in history:
                                st.caption(
                                    f"• {h.get('reviewed_at')} - {h.get('action', '').title()} "
                                    f"(reason: {h.get('reason') or '-'}, admin {h.get('reviewed_by')})"
                                )
                        else:
                            st.caption("No moderation history.")
                except requests.exceptions.RequestException:
                    pass

            with act_col:
                st.markdown("#### Actions")

                with st.form(key=f"flag_form_{lid}"):
                    flag_reason = st.text_input(
                        "Reason (for flag)",
                        key=f"flag_reason_{lid}",
                        placeholder="Ex. Suspected counterfeit item",
                    )
                    if st.form_submit_button("Flag listing"):
                        payload = {
                            "action": "flagged",
                            "reason": flag_reason or "Flagged by admin",
                            "reviewed_by": admin_id,
                        }
                        r = requests.post(
                            f"{API_BASE}/listings/{lid}/moderation",
                            json=payload,
                            timeout=10,
                        )
                        if r.status_code in (200, 201):
                            st.success("Listing flagged.")
                            st.rerun()
                        else:
                            st.error(f"Flag failed: {r.text}")

                if st.button("Approve & Activate", key=f"approve_{lid}"):
                    r = requests.post(
                        f"{API_BASE}/listings/{lid}/moderation",
                        json={
                            "action": "approved",
                            "reason": "Approved by admin",
                            "reviewed_by": admin_id,
                        },
                        timeout=10,
                    )
                    if r.status_code in (200, 201):
                        r2 = requests.put(
                            f"{API_BASE}/listings/{lid}",
                            json={"status": "active"},
                            timeout=10,
                        )
                        if r2.status_code == 200:
                            st.success("Listing approved and made active.")
                            st.rerun()
                        else:
                            st.warning("Approved but failed to set active: " + r2.text)
                    else:
                        st.error(f"Approve failed: {r.text}")

                new_status = st.selectbox(
                    "Change status to",
                    options=VALID_STATUSES,
                    format_func=lambda x: x.replace("_", " ").title(),
                    index=VALID_STATUSES.index(listing.get("status"))
                    if listing.get("status") in VALID_STATUSES
                    else 0,
                    key=f"stat_{lid}",
                )
                if st.button("Update status", key=f"update_{lid}"):
                    r = requests.put(
                        f"{API_BASE}/listings/{lid}",
                        json={"status": new_status},
                        timeout=10,
                    )
                    if r.status_code == 200:
                        st.success(f"Status updated to {new_status}.")
                        st.rerun()
                    else:
                        st.error(f"Update failed: {r.text}")

                if st.button(
                    "Delete listing",
                    key=f"delete_{lid}",
                    type="primary",
                ):
                    confirm_delete(lid, listing.get("title"))


# Tab 2 - Manage limited-edition drops
with drops_tab:
    st.subheader("Pending Limited-Edition Drops")

    try:
        drops_resp = requests.get(
            f"{API_BASE}/listings",
            params={"type": "limited"},
            timeout=10,
        )
        if drops_resp.status_code != 200:
            st.error(f"Failed to load drops ({drops_resp.status_code})")
            st.stop()
        drops = drops_resp.json()
    except requests.exceptions.RequestException as e:
        st.error(f"Could not reach API: {e}")
        st.stop()

    pending_drops = [d for d in drops if d.get("status") == "pending"]
    active_drops = [d for d in drops if d.get("status") == "active"]
    other_drops = [d for d in drops if d.get("status") not in ("pending", "active")]

    st.write(f"**{len(pending_drops)} pending drop(s) awaiting activation**")

    if not pending_drops:
        st.info("No pending limited-edition drops from sellers.")
    else:
        for drop in pending_drops:
            did = drop["listing_id"]
            header = (
                f"#{did} - {drop.get('title')} - "
                f"${drop.get('price')} - qty: {drop.get('quantity')} - "
                f"by {drop.get('artist_username')}"
            )
            with st.expander(header):
                st.write(f"**Item:** {drop.get('item_name')}")
                st.write(f"**Quantity:** {drop.get('quantity')}")
                st.write(f"**Price:** ${drop.get('price')}")
                st.write(f"**Created:** {drop.get('post_time')}")
                st.write(f"**Artist:** {drop.get('artist_username')}")

                col1, col2 = st.columns(2)
                with col1:
                    if st.button(
                        "Activate Drop",
                        key=f"activate_{did}",
                        type="primary",
                        use_container_width=True,
                    ):
                        r = requests.post(
                            f"{API_BASE}/listings/{did}/moderation",
                            json={
                                "action": "approved",
                                "reason": "Limited-edition drop activated",
                                "reviewed_by": admin_id,
                            },
                            timeout=10,
                        )
                        if r.status_code in (200, 201):
                            r2 = requests.put(
                                f"{API_BASE}/listings/{did}",
                                json={"status": "active"},
                                timeout=10,
                            )
                            if r2.status_code == 200:
                                st.success(f"Drop #{did} is now live.")
                                st.rerun()
                            else:
                                st.warning("Approved but failed to activate: " + r2.text)
                        else:
                            st.error(f"Activation failed: {r.text}")
                with col2:
                    if st.button(
                        "Reject Drop",
                        key=f"reject_drop_{did}",
                        use_container_width=True,
                    ):
                        r = requests.post(
                            f"{API_BASE}/listings/{did}/moderation",
                            json={
                                "action": "rejected",
                                "reason": "Limited-edition drop rejected by admin",
                                "reviewed_by": admin_id,
                            },
                            timeout=10,
                        )
                        if r.status_code in (200, 201):
                            st.success(f"Drop #{did} rejected.")
                            st.rerun()
                        else:
                            st.error(f"Rejection failed: {r.text}")

    if active_drops:
        st.divider()
        st.subheader("Active Limited-Edition Drops")
        st.write(f"**{len(active_drops)} currently live**")
        st.dataframe(
            [
                {
                    "ID": d["listing_id"],
                    "Title": d.get("title"),
                    "Price": d.get("price"),
                    "Quantity": d.get("quantity"),
                    "Artist": d.get("artist_username"),
                    "Posted": d.get("post_time"),
                }
                for d in active_drops
            ],
            use_container_width=True,
            hide_index=True,
        )
