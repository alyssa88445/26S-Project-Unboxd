import logging
logger = logging.getLogger(__name__)

import streamlit as st
from modules.nav import SideBarLinks

st.set_page_config(layout='wide')

SideBarLinks()

st.title(f"Welcome Buyer, {st.session_state['first_name']}.")
st.write('### What would you like to do today?')

if st.button('Filter Listings',
             type='primary',
             use_container_width=True):
    st.switch_page('pages/21_Filter_Listings.py')

if st.button('View Listing Information',
             type='primary',
             use_container_width=True):
    st.switch_page('pages/22_View_Listing_Info.py')

if st.button('View Seller Verification',
             type='primary',
             use_container_width=True):
    st.switch_page('pages/23_View_Seller_Verification.py')