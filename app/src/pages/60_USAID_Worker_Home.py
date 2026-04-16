import logging
logger = logging.getLogger(__name__)

import streamlit as st
from modules.nav import SideBarLinks

st.set_page_config(layout='wide')

# Show appropriate sidebar links for the role of the currently logged in user
SideBarLinks()

st.title(f"Welcome USAID Worker, {st.session_state['first_name']}.")
st.write('### What would you like to do today?')

if st.button('View NGO Directory',
             type='primary',
             use_container_width=True):
    st.switch_page('pages/64_NGO_Directory.py')

if st.button('Add New NGO',
             type='primary',
             use_container_width=True):
    st.switch_page('pages/65_Add_NGO.py')

if st.button('Predict Value Based on Regression Model',
             type='primary',
             use_container_width=True):
    st.switch_page('pages/61_Prediction.py')

if st.button('View the Simple API Demo',
             type='primary',
             use_container_width=True):
    st.switch_page('pages/62_API_Test.py')

if st.button('View Classification Demo',
             type='primary',
             use_container_width=True):
    st.switch_page('pages/63_Classification.py')
