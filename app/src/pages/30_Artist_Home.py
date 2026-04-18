import logging
logger = logging.getLogger(__name__)

import streamlit as st
from modules.nav import SideBarLinks

st.set_page_config(layout='wide')

SideBarLinks()

st.title(f"Welcome Artist, {st.session_state['first_name']}.")
st.write('### What would you like to do today?')

if st.button('View Profile',
             type='primary',
             use_container_width=True):
    st.switch_page('pages/31_Artist_Profile.py')

if st.button('View Listings',
             type='primary',
             use_container_width=True):
    st.switch_page('pages/32_Artist_Listings.py')

if st.button('Analyze Sales Metrics',
             type='primary',
             use_container_width=True):
    st.switch_page('pages/33_Artist_Sales_Analytics.py')
