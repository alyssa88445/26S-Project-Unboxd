import logging
logger = logging.getLogger(__name__)

import streamlit as st
import requests
import pandas as pd
from modules.nav import SideBarLinks

st.set_page_config(layout='wide')

SideBarLinks()

st.title("System Dashboard")

API_BASE = "http://web-api:4000"


# Top-row KPI metrics from /analytics/dashboard

st.subheader("Platform KPIs")

try:
    resp = requests.get(f"{API_BASE}/analytics/dashboard", timeout=10)
    if resp.status_code == 200:
        dash = resp.json()
        pm = dash.get("platform_metrics") or {}

        col1, col2, col3, col4, col5 = st.columns(5)
        with col1:
            st.metric("Active Users", f"{pm.get('active_users', 0):,}")
        with col2:
            conv = pm.get("conversion_rate") or 0
            st.metric("Conversion Rate", f"{float(conv) * 100:.2f}%")
        with col3:
            ret = pm.get("retention_rate") or 0
            st.metric("Retention Rate", f"{float(ret) * 100:.2f}%")
        with col4:
            turn = pm.get("turnover_rate") or 0
            st.metric("Turnover Rate", f"{float(turn) * 100:.2f}%")
        with col5:
            oa = dash.get("open_alert_count") or {}
            st.metric("Open Alerts", oa.get("open_alerts", 0))
    else:
        st.error(f"Failed to fetch dashboard ({resp.status_code})")
except requests.exceptions.RequestException as e:
    st.error(f"Could not reach API: {e}")

st.divider()


# Active alerts table + resolve buttons (PUT /system/alerts/{id})

st.subheader("System Alerts")

filter_col1, filter_col2 = st.columns(2)
with filter_col1:
    status_filter = st.selectbox(
        "Filter by status",
        options=["All", "open", "investigating", "resolved"],
        format_func=lambda x: x.replace("_", " ").title(),
        index=0,
    )
with filter_col2:
    severity_filter = st.selectbox(
        "Filter by severity",
        options=["All", "critical", "high", "medium", "low"],
        format_func=lambda x: x.replace("_", " ").title(),
        index=0,
    )

try:
    params = {}
    if status_filter != "All":
        params["status"] = status_filter
    if severity_filter != "All":
        params["severity"] = severity_filter
    alerts_resp = requests.get(f"{API_BASE}/system/alerts", params=params, timeout=10)

    if alerts_resp.status_code == 200:
        alerts = alerts_resp.json()
        if not alerts:
            st.info("No alerts match the current filters.")
        else:
            st.write(f"**{len(alerts)} alert(s)**")
            for alert in alerts:
                severity = alert.get("severity", "low")
                alert_status = alert.get("status", "open")
                color = {
                    "critical": "🔴",
                    "high": "🟠",
                    "medium": "🟡",
                    "low": "🟢",
                }.get(severity, "⚪")
                with st.expander(
                    f"{color} [{severity.upper()}] {alert.get('alert_type')} - {alert_status.title()} - {alert.get('created_at')}"
                ):
                    st.write(f"**Message:** {alert.get('message', '(no message)')}")
                    st.write(f"**Status:** {alert_status.title()}")
                    st.write(f"**Alert ID:** {alert.get('alert_id')}")

                    if alert_status != "resolved":
                        btn_col1, btn_col2, _ = st.columns([1, 1, 3])
                        if alert_status == "open":
                            with btn_col1:
                                if st.button("Investigate",
                                             key=f"invest_{alert['alert_id']}",
                                             use_container_width=True):
                                    r = requests.put(
                                        f"{API_BASE}/system/alerts/{alert['alert_id']}",
                                        json={"status": "investigating"},
                                        timeout=10,
                                    )
                                    if r.status_code == 200:
                                        st.success("Marked as investigating")
                                        st.rerun()
                                    else:
                                        st.error(f"Update failed: {r.text}")
                        with btn_col2:
                            if st.button("Resolve",
                                         key=f"resolve_{alert['alert_id']}",
                                         type="primary",
                                         use_container_width=True):
                                r = requests.put(
                                    f"{API_BASE}/system/alerts/{alert['alert_id']}",
                                    json={"status": "resolved"},
                                    timeout=10,
                                )
                                if r.status_code == 200:
                                    st.success("Alert resolved")
                                    st.rerun()
                                else:
                                    st.error(f"Update failed: {r.text}")
    else:
        st.error(f"Failed to load alerts ({alerts_resp.status_code})")
except requests.exceptions.RequestException as e:
    st.error(f"Could not reach API: {e}")

st.divider()


# System metric time series (CPU, memory, network latency)

st.subheader("Recent System Metrics")

try:
    resp = requests.get(f"{API_BASE}/analytics/dashboard", timeout=10)
    if resp.status_code == 200:
        metrics = resp.json().get("recent_system_metrics") or []
        if metrics:
            df = pd.DataFrame(metrics)
            df["recorded_at"] = pd.to_datetime(df["recorded_at"])
            df["value"] = pd.to_numeric(df["value"], errors="coerce")

            pivot = df.pivot_table(
                index="recorded_at",
                columns="metric_type",
                values="value",
                aggfunc="mean",
            ).sort_index()
            st.line_chart(pivot)
        else:
            st.info("No recent system metrics available.")
except requests.exceptions.RequestException as e:
    st.error(f"Could not reach API: {e}")
