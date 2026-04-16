import logging
logger = logging.getLogger(__name__)

from datetime import date, timedelta

import streamlit as st
import requests
import pandas as pd
from modules.nav import SideBarLinks

st.set_page_config(layout='wide')

SideBarLinks()

st.title("KPI Dashboard")

API_BASE = "http://web-api:4000"


# Latest snapshot metrics

st.subheader("Current Metrics")

try:
    resp = requests.get(f"{API_BASE}/analytics/dashboard", timeout=10)
    if resp.status_code == 200:
        pm = resp.json().get("platform_metrics") or {}

        col1, col2, col3, col4, col5 = st.columns(5)
        with col1:
            st.metric("Active Users", f"{pm.get('active_users', 0):,}")
        with col2:
            st.metric("Conversions", f"{pm.get('conversions', 0):,}")
        with col3:
            st.metric(
                "Conversion Rate",
                f"{float(pm.get('conversion_rate') or 0) * 100:.2f}%",
            )
        with col4:
            st.metric(
                "Retention Rate",
                f"{float(pm.get('retention_rate') or 0) * 100:.2f}%",
            )
        with col5:
            st.metric(
                "Turnover Rate",
                f"{float(pm.get('turnover_rate') or 0) * 100:.2f}%",
            )
        st.caption(f"Recorded at: {pm.get('recorded_at')}")
    else:
        st.error(f"Failed to fetch dashboard ({resp.status_code})")
except requests.exceptions.RequestException as e:
    st.error(f"Could not reach API: {e}")

st.divider()


# Retention and turnover over time

st.subheader("Retention & Turnover")

col_date1, col_date2 = st.columns(2)
with col_date1:
    default_start = date.today() - timedelta(days=70)
    start_date = st.date_input("Start date", value=default_start)
with col_date2:
    end_date = st.date_input("End date", value=date.today())

if start_date > end_date:
    st.error("Start date must be before end date.")
else:
    try:
        params = {
            "start_date": start_date.isoformat(),
            "end_date": end_date.isoformat(),
        }
        r = requests.get(f"{API_BASE}/analytics/retention", params=params, timeout=10)
        if r.status_code == 200:
            rows = r.json()
            if not rows:
                st.info("No metrics recorded in this date range.")
            else:
                df = pd.DataFrame(rows)
                df["recorded_at"] = pd.to_datetime(df["recorded_at"])
                df = df.sort_values("recorded_at").set_index("recorded_at")

                for c in (
                    "retention_rate",
                    "turnover_rate",
                    "conversion_rate",
                ):
                    if c in df.columns:
                        df[c] = pd.to_numeric(df[c], errors="coerce")

                rate_col, count_col = st.columns(2)
                with rate_col:
                    st.write("**Engagement Rates**")
                    rate_df = df[["retention_rate", "turnover_rate", "conversion_rate"]]
                    st.line_chart(rate_df)
                with count_col:
                    st.write("**User Activity**")
                    count_df = df[["active_users", "retained_users", "churned_users"]]
                    st.line_chart(count_df)

                with st.expander("View data table"):
                    st.dataframe(df.reset_index(), use_container_width=True)
        else:
            st.error(f"Failed to load retention data ({r.status_code})")
    except requests.exceptions.RequestException as e:
        st.error(f"Could not reach API: {e}")
