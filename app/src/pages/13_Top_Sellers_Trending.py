import logging
logger = logging.getLogger(__name__)

import streamlit as st
import requests
import pandas as pd
from modules.nav import SideBarLinks

st.set_page_config(layout='wide')

SideBarLinks()

st.title("Top Sellers & Trending")

API_BASE = "http://web-api:4000"


def format_dollars(n):
    return f"${float(n):,.2f}"


# Section 1 - Top sellers

st.subheader("Top Performing Sellers")

limit = st.slider("Number of sellers to show", min_value=5, max_value=25, value=10)

try:
    r = requests.get(f"{API_BASE}/analytics/sellers", params={"limit": limit}, timeout=10)
    if r.status_code == 200:
        sellers = r.json()
    else:
        st.error(f"Failed to load top sellers ({r.status_code})")
        sellers = []
except requests.exceptions.RequestException as e:
    st.error(f"Could not reach API: {e}")
    sellers = []

if not sellers:
    st.info("No sales data available.")
else:
    df = pd.DataFrame(sellers)
    df["total_revenue"] = pd.to_numeric(df["total_revenue"], errors="coerce").fillna(0)
    df["total_units_sold"] = pd.to_numeric(df["total_units_sold"], errors="coerce").fillna(0).astype(int)
    df["total_orders"] = pd.to_numeric(df["total_orders"], errors="coerce").fillna(0).astype(int)
    df = df.sort_values("total_revenue", ascending=False)

    table_col, chart_col = st.columns([2, 3])
    with table_col:
        st.dataframe(
            df[["artist_id", "username", "total_revenue", "total_units_sold", "total_orders"]],
            use_container_width=True,
            hide_index=True,
        )
    with chart_col:
        st.write("**Revenue by Seller**")
        chart_df = df.set_index("username")["total_revenue"]
        st.bar_chart(chart_df, horizontal=True)

    st.write("### Seller Details")
    seller_options = {
        row["username"]: int(row["artist_id"])
        for _, row in df.iterrows()
    }
    picked = st.selectbox(
        "Select a seller",
        options=list(seller_options.keys()),
    )
    if picked:
        sid = seller_options[picked]
        try:
            sales_r = requests.get(f"{API_BASE}/sellers/{sid}/sales", timeout=10)
            if sales_r.status_code == 200:
                sales = sales_r.json()
                with st.expander(f"Sales for {picked}", expanded=True):
                    mc1, mc2, mc3, mc4 = st.columns(4)
                    with mc1:
                        st.metric("Weekly", format_dollars(sales.get('weekly_sales') or 0))
                    with mc2:
                        st.metric("Monthly", format_dollars(sales.get('monthly_sales') or 0))
                    with mc3:
                        st.metric("Annual", format_dollars(sales.get('annual_sales') or 0))
                    with mc4:
                        st.metric("Total Orders", int(sales.get("total_orders") or 0))
            else:
                st.error(f"Failed to load seller sales ({sales_r.status_code})")
        except requests.exceptions.RequestException as e:
            st.error(f"Could not reach API: {e}")

st.divider()


# Section 2 - Trending searches and most liked listings

st.subheader("Search & Engagement Trends")

try:
    r = requests.get(f"{API_BASE}/analytics/trending", timeout=10)
    if r.status_code != 200:
        st.error(f"Failed to load trending data ({r.status_code})")
        trending = {}
    else:
        trending = r.json()
except requests.exceptions.RequestException as e:
    st.error(f"Could not reach API: {e}")
    trending = {}

left, right = st.columns(2)

with left:
    st.write("**Top Search Terms**")
    searches = trending.get("trending_searches") or []
    if searches:
        s_df = pd.DataFrame(searches)
        s_df["search_count"] = pd.to_numeric(s_df["search_count"], errors="coerce").fillna(0).astype(int)
        st.dataframe(s_df, use_container_width=True, hide_index=True)
        st.bar_chart(s_df.set_index("search_term")["search_count"])
    else:
        st.info("No search activity recorded yet.")

with right:
    st.write("**Most-Liked Listings**")
    liked = trending.get("most_liked_listings") or []
    if liked:
        l_df = pd.DataFrame(liked)
        l_df["price"] = pd.to_numeric(l_df["price"], errors="coerce").fillna(0)
        l_df["like_count"] = pd.to_numeric(l_df["like_count"], errors="coerce").fillna(0).astype(int)
        l_df["listing_type_display"] = l_df["listing_type"].fillna("unspecified").apply(
            lambda x: x.replace("_", " ").title()
        )
        display_df = l_df[["listing_id", "title", "listing_type_display", "price", "like_count"]].rename(
            columns={"listing_type_display": "listing_type"}
        )
        st.dataframe(display_df, use_container_width=True, hide_index=True)
        st.bar_chart(l_df.set_index("title")["like_count"])
    else:
        st.info("No listings have been liked yet.")
