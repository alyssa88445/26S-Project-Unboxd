import logging
logger = logging.getLogger(__name__)

import streamlit as st
from modules.nav import SideBarLinks

st.set_page_config(layout='wide')

SideBarLinks()

API_BASE = "http://web-api:4000"

st.title(f"Welcome {st.session_state['first_name']}.")



