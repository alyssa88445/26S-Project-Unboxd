import logging
logger = logging.getLogger(__name__)

import streamlit as st
from modules.nav import SideBarLinks

st.set_page_config(layout='wide')

SideBarLinks()

st.title(f"Welcome Platform Marketer, {st.session_state['first_name']}.")
st.write('### What would you like to do today?')

if st.button('View KPI Dashboard',
             type='primary',
             use_container_width=True):
    st.switch_page('pages/11_Marketer_Dashboard.py')

if st.button('Explore Listing Analytics',
             type='primary',
             use_container_width=True):
    st.switch_page('pages/12_Listing_Analytics.py')

if st.button('View Top Sellers & Trending',
             type='primary',
             use_container_width=True):
    st.switch_page('pages/13_Top_Sellers_Trending.py')
