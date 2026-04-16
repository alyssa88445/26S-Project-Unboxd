import logging
logger = logging.getLogger(__name__)

import streamlit as st
from modules.nav import SideBarLinks

st.set_page_config(layout='wide')

SideBarLinks()

st.title(f"Welcome Systems Administrator, {st.session_state['first_name']}.")
st.write('### What would you like to do today?')

if st.button('View System Dashboard',
             type='primary',
             use_container_width=True):
    st.switch_page('pages/01_Admin_Dashboard.py')

if st.button('Review Artist Applications',
             type='primary',
             use_container_width=True):
    st.switch_page('pages/02_Artist_Applications.py')

if st.button('Moderate Listings & Manage Drops',
             type='primary',
             use_container_width=True):
    st.switch_page('pages/03_Listing_Moderation.py')

if st.button('Investigate Fraud Reports',
             type='primary',
             use_container_width=True):
    st.switch_page('pages/04_Fraud_Reports.py')
