# Idea borrowed from https://github.com/fsmosca/sample-streamlit-authenticator

# This file has functions to add links to the left sidebar based on the user's role.

import streamlit as st


# ---- General ----------------------------------------------------------------

def home_nav():
    st.sidebar.page_link("Home.py", label="Home", icon="🏠")


def about_page_nav():
    st.sidebar.page_link("pages/99_About.py", label="About", icon="🧠")


# - Role: systems_admin (Jordan Kim - Unboxd Persona 1)

def unboxd_admin_home_nav():
    st.sidebar.page_link(
        "pages/00_Admin_Home.py", label="Admin Home", icon="🛡️"
    )


def admin_dashboard_nav():
    st.sidebar.page_link(
        "pages/01_Admin_Dashboard.py", label="System Dashboard", icon="📊"
    )


def artist_applications_nav():
    st.sidebar.page_link(
        "pages/02_Artist_Applications.py", label="Artist Applications", icon="🎨"
    )


def listing_moderation_nav():
    st.sidebar.page_link(
        "pages/03_Listing_Moderation.py", label="Listing Moderation", icon="🚩"
    )


def fraud_reports_nav():
    st.sidebar.page_link(
        "pages/04_Fraud_Reports.py", label="Fraud Reports", icon="🔍"
    )


# - Role: platform_marketer (Adam Smith - Unboxd Persona 2)

def marketer_home_nav():
    st.sidebar.page_link(
        "pages/10_Marketer_Home.py", label="Marketer Home", icon="📈"
    )


def marketer_dashboard_nav():
    st.sidebar.page_link(
        "pages/11_Marketer_Dashboard.py", label="KPI Dashboard", icon="📉"
    )


def listing_analytics_nav():
    st.sidebar.page_link(
        "pages/12_Listing_Analytics.py", label="Listing Analytics", icon="🗂️"
    )


def top_sellers_trending_nav():
    st.sidebar.page_link(
        "pages/13_Top_Sellers_Trending.py", label="Top Sellers & Trending", icon="🔥"
    )


# ---- Role: artist (Tina Gordon - Unboxd Persona 4)

def artist_home_nav():
    st.sidebar.page_link(
        "pages/30_Artist_Home.py", label="Artist Home", icon="🏠")

def artist_profile_nav():
    st.sidebar.page_link(
        "pages/31_Artist_Profile.py", label="Artist Profile", icon="😊")

def artist_listings_nav():
    st.sidebar.page_link("pages/32_Artist_Listings.py", label="Artist Listings", icon="🎨")

def create_item_listings_nav():
<<<<<<< Updated upstream
    st.sidebar.page_link("pages/33_Create_Item_Listing.py", label="New Items / Listings", icon="➕")
=======
    st.sidebar.page_link("pages/33_Create_Item_Listing.py", label="Add New Items / Listings", icon="➕")
>>>>>>> Stashed changes

def artist_metrics_nav():
    st.sidebar.page_link("pages/35_Artist_Analytics.py", label="View Sales Analytics", icon="📈")

# ---- Role: usaid_worker (sample/demo, retained as backup) -------------------

def usaid_worker_home_nav():
    st.sidebar.page_link(
        "pages/60_USAID_Worker_Home.py", label="USAID Worker Home", icon="🏠"
    )


def ngo_directory_nav():
    st.sidebar.page_link("pages/64_NGO_Directory.py", label="NGO Directory", icon="📁")


def add_ngo_nav():
    st.sidebar.page_link("pages/65_Add_NGO.py", label="Add New NGO", icon="➕")


def prediction_nav():
    st.sidebar.page_link(
        "pages/61_Prediction.py", label="Regression Prediction", icon="📈"
    )


def api_test_nav():
    st.sidebar.page_link("pages/62_API_Test.py", label="Test the API", icon="🛜")


def classification_nav():
    st.sidebar.page_link(
        "pages/63_Classification.py", label="Classification Demo", icon="🌺"
    )


# ---- Role: administrator (sample/demo, retained as backup) ------------------

def admin_home_nav():
    st.sidebar.page_link("pages/70_Sample_Admin_Home.py", label="System Admin (Demo)", icon="🖥️")


def ml_model_mgmt_nav():
    st.sidebar.page_link(
        "pages/71_ML_Model_Mgmt.py", label="ML Model Management", icon="🏢"
    )


# ---- Sidebar assembly -------------------------------------------------------

def SideBarLinks(show_home=False):
    """
    Renders sidebar navigation links based on the logged-in user's role.
    The role is stored in st.session_state when the user logs in on Home.py.
    """

    # Logo appears at the top of the sidebar on every pages
    st.sidebar.image("assets/logo.png", width=150)

    # If no one is logged in, send them to the Home (login) page
    if "authenticated" not in st.session_state:
        st.session_state.authenticated = False
        st.switch_page("Home.py")

    if show_home:
        home_nav()

    if st.session_state["authenticated"]:

        # - Unboxd personas
        if st.session_state["role"] == "systems_admin":
            unboxd_admin_home_nav()
            admin_dashboard_nav()
            artist_applications_nav()
            listing_moderation_nav()
            fraud_reports_nav()

        if st.session_state["role"] == "platform_marketer":
            marketer_home_nav()
            marketer_dashboard_nav()
            listing_analytics_nav()
            top_sellers_trending_nav()

        if st.session_state["role"] == "artist":
            artist_home_nav()
            artist_profile_nav()
            artist_listings_nav()
            create_item_listings_nav()
            artist_metrics_nav()

        # - Sample/demo personas (retained as backup)
        if st.session_state["role"] == "pol_strat_advisor":
            pol_strat_home_nav()
            world_bank_viz_nav()
            map_demo_nav()

        if st.session_state["role"] == "usaid_worker":
            usaid_worker_home_nav()
            ngo_directory_nav()
            add_ngo_nav()
            prediction_nav()
            api_test_nav()
            classification_nav()

        if st.session_state["role"] == "administrator":
            admin_home_nav()
            ml_model_mgmt_nav()

    # About link appears at the bottom for all roles
    about_page_nav()

    if st.session_state["authenticated"]:
        if st.sidebar.button("Logout"):
            del st.session_state["role"]
            del st.session_state["authenticated"]
            st.switch_page("Home.py")
