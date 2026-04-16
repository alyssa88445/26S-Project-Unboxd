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

# For each of the user personas for which we are implementing
# functionality, we put a button on the screen that the user
# can click to MIMIC logging in as that mock user.

if st.button("Act as John, a Political Strategy Advisor",
             type='primary',
             use_container_width=True):
    # when user clicks the button, they are now considered authenticated
    st.session_state['authenticated'] = True
    # we set the role of the current user
    st.session_state['role'] = 'pol_strat_advisor'
    # we add the first name of the user (so it can be displayed on
    # subsequent pages).
    st.session_state['first_name'] = 'John'
    # finally, we ask streamlit to switch to another page, in this case, the
    # landing page for this particular user type
    logger.info("Logging in as Political Strategy Advisor Persona")
    st.switch_page('pages/50_Pol_Strat_Home.py')

if st.button('Act as Mohammad, a USAID Worker',
             type='primary',
             use_container_width=True):
    st.session_state['authenticated'] = True
    st.session_state['role'] = 'usaid_worker'
    st.session_state['first_name'] = 'Mohammad'
    st.switch_page('pages/60_USAID_Worker_Home.py')

if st.button('Act as System Administrator',
             type='primary',
             use_container_width=True):
    st.session_state['authenticated'] = True
    st.session_state['role'] = 'administrator'
    st.session_state['first_name'] = 'SysAdmin'
    st.switch_page('pages/70_Sample_Admin_Home.py')
