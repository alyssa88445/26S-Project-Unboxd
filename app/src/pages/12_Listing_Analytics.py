import logging
logger = logging.getLogger(__name__)

from datetime import date, timedelta

import streamlit as st
import requests
import pandas as pd
import plotly.express as px
from modules.nav import SideBarLinks

st.set_page_config(layout='wide')

SideBarLinks()

st.title("Listing Analytics")

API_BASE = "http://web-api:4000"


def format_dollars(n):
    return f"${float(n):,.2f}"


# Filters (the time range, category, listing type)

st.subheader("Filters")

try:
    items_resp = requests.get(f"{API_BASE}/items", timeout=10)
    items = items_resp.json() if items_resp.status_code == 200 else []
except requests.exceptions.RequestException as e:
    st.error(f"Could not reach API: {e}")
    items = []

category_options = {"All": None}
seen = set()
for it in items:
    cid = it.get("category_id")
    cname = it.get("category_name")
    if cid is not None and cid not in seen:
        seen.add(cid)
        category_options[cname] = cid

f_col1, f_col2, f_col3, f_col4 = st.columns(4)
with f_col1:
    default_start = date.today() - timedelta(days=70)
    start_date = st.date_input("Start date", value=default_start)
with f_col2:
    end_date = st.date_input("End date", value=date.today())
with f_col3:
    category_label = st.selectbox("Category", options=list(category_options.keys()))
with f_col4:
    type_filter = st.selectbox(
        "Listing type",
        options=["All", "standard", "auction", "limited_edition"],
        format_func=lambda x: x.replace("_", " ").title(),
    )

if start_date > end_date:
    st.error("Start date must be before end date.")
    st.stop()

params = {
    "start_date": start_date.isoformat(),
    "end_date": end_date.isoformat(),
}
if category_options.get(category_label) is not None:
    params["category_id"] = category_options[category_label]
if type_filter != "All":
    params["type"] = type_filter


# Fetch analytics

try:
    r = requests.get(f"{API_BASE}/analytics/listings", params=params, timeout=10)
    if r.status_code != 200:
        st.error(f"Failed to load analytics ({r.status_code})")
        st.stop()
    rows = r.json()
except requests.exceptions.RequestException as e:
    st.error(f"Could not reach API: {e}")
    st.stop()

if not rows:
    st.info("No data matches the selected filters.")
    st.stop()

df = pd.DataFrame(rows)
for c in ("total_revenue", "avg_price"):
    if c in df.columns:
        df[c] = pd.to_numeric(df[c], errors="coerce").fillna(0)
for c in ("total_listings", "total_orders"):
    if c in df.columns:
        df[c] = pd.to_numeric(df[c], errors="coerce").fillna(0).astype(int)
df["listing_type"] = df["listing_type"].fillna("unspecified")
df["listing_type_display"] = df["listing_type"].apply(lambda x: x.replace("_", " ").title())

st.divider()


# Summary metrics

st.subheader("Summary")
m1, m2, m3, m4 = st.columns(4)
with m1:
    st.metric("Total Listings", f"{df['total_listings'].sum():,}")
with m2:
    st.metric("Total Orders", f"{df['total_orders'].sum():,}")
with m3:
    st.metric("Total Revenue", format_dollars(df['total_revenue'].sum()))
with m4:
    avg_overall = df["avg_price"].mean() if len(df) else 0
    st.metric("Avg Listing Price", format_dollars(avg_overall))

st.divider()


# Listing-type comparison

st.subheader("Comparison by Listing Type")

table_col, pie_col = st.columns([3, 2])
with table_col:
    display_df = df[[
        "listing_type_display",
        "total_listings",
        "total_orders",
        "total_revenue",
        "avg_price",
    ]].rename(columns={"listing_type_display": "Listing Type"})
    st.dataframe(
        display_df,
        use_container_width=True,
        hide_index=True,
    )

with pie_col:
    pie_df = df[df["total_revenue"] > 0]
    if not pie_df.empty:
        fig = px.pie(
            pie_df,
            values="total_revenue",
            names="listing_type_display",
            title="Revenue Share by Listing Type",
        )
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.info("No revenue recorded for this filter set.")

st.subheader("Breakdown by Listing Type")
bar_col1, bar_col2 = st.columns(2)
with bar_col1:
    st.write("**Revenue**")
    st.bar_chart(df.set_index("listing_type_display")["total_revenue"])
with bar_col2:
    st.write("**Orders**")
    st.bar_chart(df.set_index("listing_type_display")["total_orders"])
