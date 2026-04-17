import logging
logger = logging.getLogger(__name__)

import streamlit as st
import requests
from modules.nav import SideBarLinks

st.set_page_config(layout='wide')

SideBarLinks()

st.title("Fraud Reports")

API_BASE = "http://web-api:4000"
admin_id = st.session_state.get("admin_id", 1)


# Section 1 - File a new fraud report (POST /fraud-reports)

st.subheader("File a New Fraud Report")

try:
    orders_resp = requests.get(f"{API_BASE}/orders", timeout=10)
    orders = orders_resp.json() if orders_resp.status_code == 200 else []
except requests.exceptions.RequestException as e:
    st.error(f"Could not reach API: {e}")
    orders = []

if not orders:
    st.info("No orders available to report.")
else:
    order_labels = {
        f"#{o['order_id']} - {o.get('buyer_username')} - "
        f"${o.get('order_total')} - {o.get('status', '').replace('_', ' ').title()}": o
        for o in orders
    }

    with st.form("new_fraud_form"):
        sel = st.selectbox("Suspicious order *", options=list(order_labels.keys()))
        reason = st.text_area(
            "Reason *",
            placeholder="Ex. Payment fraud",
        )
        submitted = st.form_submit_button("File fraud report", type="primary")
        if submitted:
            if not reason.strip():
                st.error("Please provide a reason.")
            else:
                order = order_labels[sel]
                payload = {
                    "reason": reason.strip(),
                    "order_id": order["order_id"],
                    "reviewer_id": admin_id,
                }
                try:
                    r = requests.post(
                        f"{API_BASE}/fraud-reports", json=payload, timeout=10
                    )
                    if r.status_code == 201:
                        body = r.json()
                        st.success(
                            f"Fraud report filed (report_id={body.get('report_id')})."
                        )
                    else:
                        st.error(f"Failed to file report: {r.text}")
                except requests.exceptions.RequestException as e:
                    st.error(f"Could not reach API: {e}")

st.divider()


# Section 2 - Investigate existing reports (tabs by status)

st.subheader("Existing Fraud Reports")

tab_labels = ["Open", "Investigating", "Resolved", "Dismissed"]
tab_objs = st.tabs(tab_labels)

order_lookup = {o["order_id"]: o for o in orders}


def render_report_actions(report, order):
    rid = report["report_id"]
    col1, col2, col3, col4 = st.columns(4)

    with col1:
        if report["status"] not in ("investigating", "resolved", "dismissed"):
            if st.button("Investigate", key=f"inv_{rid}", use_container_width=True):
                r = requests.put(
                    f"{API_BASE}/fraud-reports/{rid}",
                    json={"status": "investigating"},
                    timeout=10,
                )
                if r.status_code == 200:
                    st.success("Marked as investigating")
                    st.rerun()
                else:
                    st.error(f"Update failed: {r.text}")

    with col2:
        if report["status"] != "resolved":
            if st.button(
                "Resolve", key=f"res_{rid}", type="primary", use_container_width=True
            ):
                r = requests.put(
                    f"{API_BASE}/fraud-reports/{rid}",
                    json={"status": "resolved"},
                    timeout=10,
                )
                if r.status_code == 200:
                    st.success("Report resolved.")
                    st.rerun()
                else:
                    st.error(f"Update failed: {r.text}")

    with col3:
        if report["status"] != "dismissed":
            if st.button("Dismiss", key=f"dis_{rid}", use_container_width=True):
                r = requests.put(
                    f"{API_BASE}/fraud-reports/{rid}",
                    json={"status": "dismissed"},
                    timeout=10,
                )
                if r.status_code == 200:
                    st.success("Report dismissed.")
                    st.rerun()
                else:
                    st.error(f"Update failed: {r.text}")

    with col4:
        if order and order.get("status") in ("in cart", "purchased"):
            if st.button(
                "Release order",
                key=f"rel_{rid}",
                use_container_width=True,
                help="Flip order status to 'processing' if investigation cleared it.",
            ):
                r = requests.put(
                    f"{API_BASE}/orders/{order['order_id']}",
                    json={"status": "processing"},
                    timeout=10,
                )
                if r.status_code == 200:
                    st.success(f"Order {order['order_id']} set to processing.")
                    st.rerun()
                else:
                    st.error(f"Order update failed: {r.text}")


for label, tab in zip(tab_labels, tab_objs):
    with tab:
        try:
            r = requests.get(
                f"{API_BASE}/fraud-reports",
                params={"status": label.lower()},
                timeout=10,
            )
            if r.status_code != 200:
                st.error(f"Failed to load fraud reports ({r.status_code})")
                continue
            reports = r.json()
        except requests.exceptions.RequestException as e:
            st.error(f"Could not reach API: {e}")
            continue

        if not reports:
            st.info(f"No {label.lower()} reports.")
            continue

        st.write(f"**{len(reports)} {label.lower()} report(s)**")
        for report in reports:
            order = order_lookup.get(report["order_id"])
            buyer = order.get("buyer_username") if order else "?"
            total = order.get("order_total") if order else "?"

            header = (
                f"Report #{report['report_id']} - order #{report['order_id']} - "
                f"buyer: {buyer} - ${total}"
            )
            with st.expander(header):
                detail = report
                try:
                    r = requests.get(f"{API_BASE}/fraud-reports/{report['report_id']}", timeout=10)
                    if r.status_code == 200:
                        detail = r.json()
                except requests.exceptions.RequestException:
                    pass

                st.write(f"**Reason:** {detail.get('reason')}")
                st.write(f"**Created:** {detail.get('created_at')}")
                if detail.get("resolved_at"):
                    st.write(f"**Resolved:** {detail.get('resolved_at')}")
                st.write(f"**Reviewer (admin_id):** {detail.get('reviewer_id')}")

                try:
                    order_detail = requests.get(
                        f"{API_BASE}/orders/{report['order_id']}", timeout=10
                    )
                    if order_detail.status_code == 200:
                        items = order_detail.json().get("items") or []
                        if items:
                            st.write("**Order Items:**")
                            for item in items:
                                st.caption(
                                    f"- {item.get('listing_title', 'Unknown')} "
                                    f"(qty: {item.get('quantity')}, "
                                    f"${item.get('price_at_purchase')})"
                                )
                except requests.exceptions.RequestException:
                    pass

                render_report_actions(report, order)
