##################################################
# This is the main/entry-point file for the
# sample application for your project
##################################################

# Set up basic logging infrastructure
import logging
logging.basicConfig(format='%(filename)s:%(lineno)s:%(levelname)s -- %(message)s', level=logging.INFO)
logger = logging.getLogger(__name__)

# import the main streamlit library as well
# as SideBarLinks function from src/modules folder
import streamlit as st
from modules.nav import SideBarLinks

# streamlit supports regular and wide layout (how the controls
# are organized/displayed on the screen).
st.set_page_config(layout='wide')

# If a user is at this page, we assume they are not
# authenticated.  So we change the 'authenticated' value
# in the streamlit session_state to false.
st.session_state['authenticated'] = False

# Use the SideBarLinks function from src/modules/nav.py to control
# the links displayed on the left-side panel.
# IMPORTANT: ensure src/.streamlit/config.toml sets
# showSidebarNavigation = false in the [client] section
SideBarLinks(show_home=True)

# ***************************************************
#    The major content of this page
# ***************************************************

logger.info("Loading the Home page of the app")
st.title('Unboxd')
st.write('#### A data-driven marketplace connecting blind-box artists with collectors.')


# Unboxd Users
st.divider()
st.write('## Unboxd Users')
st.write('#### Select a persona and click login:')

# Persona 1 - Systems Administrator (Jordan Kim)
admin_user = st.selectbox(
    "Systems Administrator",
    options=["Jordan Kim (Systems Admin)"],
    key="admin_select",
)
if st.button("Login as Systems Admin",
             type="primary",
             use_container_width=True):
    st.session_state["authenticated"] = True
    st.session_state["role"] = "systems_admin"
    st.session_state["first_name"] = "Jordan"
    st.session_state["admin_id"] = 1  # Jordan Kim's admin_id per DDL
    logger.info("Logging in as Systems Administrator (Jordan Kim)")
    st.switch_page("pages/00_Admin_Home.py")

# Persona 2 - Platform Marketer (Adam Smith)
marketer_user = st.selectbox(
    "Platform Marketer",
    options=["Adam Smith (Platform Marketer)"],
    key="marketer_select",
)
if st.button("Login as Platform Marketer",
             type="primary",
             use_container_width=True):
    st.session_state["authenticated"] = True
    st.session_state["role"] = "platform_marketer"
    st.session_state["first_name"] = "Adam"
    logger.info("Logging in as Platform Marketer (Adam Smith)")
    st.switch_page("pages/10_Marketer_Home.py")

st.divider()

# Persona 3 - Buyer
marketer_user = st.selectbox(
    "Buyer",
    options=["Katie Joy (Buyer)"],
    key="buyer_select",
)
if st.button("Login as Buyer",
             type="primary",
             use_container_width=True):
    st.session_state["authenticated"] = True
    st.session_state["role"] = "Buyer"
    st.session_state["first_name"] = "Katie"
    logger.info("Logging in as Buyer (Katie Joy)")
    st.switch_page("pages/20_Buyer_Home.py")

# Persona 4 - Artist (Tina Gordon)
marketer_user = st.selectbox(
    "Artist",
    options=["Tina Gordon (Artist)"],
    key="Artist_select",
)
if st.button("Login as Artist",
             type="primary",
             use_container_width=True):
    st.session_state["authenticated"] = True
    st.session_state["role"] = "artist"
    st.session_state["first_name"] = "Tina"
    st.session_state["artist_id"] = "1" 
    logger.info("Logging in as Artist (Tina Gordon)")
    st.switch_page("pages/30_Artist_Home.py")
