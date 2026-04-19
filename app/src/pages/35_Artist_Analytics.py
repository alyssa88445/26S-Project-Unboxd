import logging
logger = logging.getLogger(__name__)

import streamlit as st
import requests
import pandas as pd
from modules.nav import SideBarLinks

st.set_page_config(layout='wide')

SideBarLinks()

st.title("Your Sales Summary")

API_BASE = "http://web-api:4000"
artist_id = st.session_state.get("artist_id", 1)

def format_dollars(n):
    return f"${float(n):,.2f}"
    
try:
    sales_r = requests.get(f"{API_BASE}/sellers/{artist_id}/sales", timeout=10)
    if sales_r.status_code == 200:
        sales = sales_r.json()
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
        st.error(f"Failed to load your sales ({sales_r.status_code})")
except requests.exceptions.RequestException as e:
    st.error(f"Could not reach API: {e}")

st.subheader("Top Selling Items")
limit = st.slider("Number of items to show", min_value=5, max_value=25, value=10)

try:
    r = requests.get(
        f"{API_BASE}/analytics/items",
        params={"limit": limit, "artist_id": artist_id},
        timeout=10
    )
    if r.status_code == 200:
        items = r.json()
        if items:
            df = pd.DataFrame(items)
            df["total_revenue"] = pd.to_numeric(df["total_revenue"], errors="coerce").fillna(0)
            df["total_units_sold"] = pd.to_numeric(df["total_units_sold"], errors="coerce").fillna(0).astype(int)
            df["total_orders"] = pd.to_numeric(df["total_orders"], errors="coerce").fillna(0).astype(int)
            df.insert(0, "rank", df.index + 1)
            st.dataframe(
                df[["rank", "item_name", "category", "total_units_sold", "total_orders", "total_revenue"]],
                use_container_width=True,
                hide_index=True,
            )
        else:
            st.info("No sales data available.")
    else:
        st.error(f"Failed to load top items ({r.status_code})")
except requests.exceptions.RequestException as e:
    st.error(f"Could not reach API: {e}")