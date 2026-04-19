import logging
logger = logging.getLogger(__name__)

import streamlit as st
import requests
from modules.nav import SideBarLinks

st.set_page_config(layout='wide')
SideBarLinks()

artist_id = st.session_state.get("artist_id", 1)
API_BASE = "http://web-api:4000"

# Fetch artist profile
try:
    response = requests.get(f"{API_BASE}/artists/{artist_id}", timeout=10)
    response.raise_for_status()
    artist = response.json()
except requests.exceptions.RequestException as e:
    st.error(f"Could not reach API: {e}")
    st.stop()

# Fetch primary email
try:
    email_resp = requests.get(f"{API_BASE}/artists/{artist_id}/email", timeout=10)
    email_data = email_resp.json()
    current_email = email_data.get("email", "")
except requests.exceptions.RequestException:
    current_email = ""

#
col1, col2 = st.columns([1, 4])
with col1:
    if artist.get("photo_link"):
        st.image(artist["photo_link"], width=200)
    else:
        initials = f"{artist.get('first_name', '?')[0]}{artist.get('last_name', '?')[0]}"
        st.markdown(
            f"<div style='width:80px;height:80px;border-radius:50%;background:#B5D4F4;"
            f"display:flex;align-items:center;justify-content:center;font-size:24px;"
            f"font-weight:500;color:#0C447C'>{initials}</div>",
            unsafe_allow_html=True
        )
with col2:
    st.title(f"{artist.get('first_name')} {artist.get('last_name')}")
    st.caption(f"@{artist.get('username')}")
    if artist.get("is_verified"):
        st.success("✓ Verified Artist")
    else:
        st.warning("Not Verified")

st.divider()

# display artist profile form
st.subheader("Profile Information")

with st.form("profile_form"):
    col1, col2 = st.columns(2)

    with col1:
        st.markdown("**Account**")
        # Read-only fields
        st.text_input("Username", value=artist.get("username", ""), disabled=True)
        st.text_input("First Name", value=artist.get("first_name", ""), disabled=True)
        st.text_input("Last Name", value=artist.get("last_name", ""), disabled=True)
        st.text_input("Gender", value=artist.get("gender", "") or "", disabled=True)
        st.text_input("Date of Birth", value=str(artist.get("dob", "") or ""), disabled=True)
        st.text_input("Member Since", value=str(artist.get("created_at", "") or ""), disabled=True)

        # Editable
        phone = st.text_input("Phone", value=artist.get("phone", "") or "")
        email = st.text_input("Primary Email", value=current_email)
        photo_link = st.text_input("Photo URL", value=artist.get("photo_link", "") or "")

    with col2:
        st.markdown("**About & Location**")
        bio = st.text_area("Bio", value=artist.get("bio", "") or "", height=120)

        st.markdown("**Address**")
        street = st.text_input("Street Address", value=artist.get("street_address", "") or "")
        city = st.text_input("City", value=artist.get("city", "") or "")
        state = st.text_input("State", value=artist.get("state", "") or "")

    submitted = st.form_submit_button("Save Changes", use_container_width=True)

if submitted:
    errors = []

    # Update profile fields
    try:
        resp = requests.put(
            f"{API_BASE}/artists/{artist_id}",
            json={
                "bio": bio,
                "photo_link": photo_link,
                "city": city,
                "state": state,
                "street_address": street
            },
            timeout=10
        )
        resp.raise_for_status()
    except requests.exceptions.RequestException as e:
        errors.append(f"Profile update failed: {e}")

    # Update email separately
    try:
        email_resp = requests.put(
            f"{API_BASE}/artists/{artist_id}/email",
            json={"email": email},
            timeout=10
        )
        email_resp.raise_for_status()
    except requests.exceptions.RequestException as e:
        errors.append(f"Email update failed: {e}")

    if errors:
        for err in errors:
            st.error(err)
    else:
        st.success("Profile updated!")
        st.rerun()