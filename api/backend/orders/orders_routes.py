from flask import Blueprint, jsonify, request, current_app
from backend.db_connection import get_db
from mysql.connector import Error

# Create a Blueprint for order routes
orders = Blueprint("orders", __name__)

# GET /orders - Returns all orders which are filterable by buyer or status
@orders.route("/orders", methods=["GET"])
def get_orders():
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info('GET /orders') 
        buyer_id = request.args.get('buyer_id')
        status = request.args.get('status')

        query = '''
            SELECT o.order_id, o.order_time, o.status, o.buyer_id, o.order_total, u.username AS buyer_username
            FROM `order` o
            JOIN user u ON o.buyer_id = u.user_id
            WHERE 1=1
        '''
        params = []
        if buyer_id:
            query += ' AND o.buyer_id = %s'
            params.append(buyer_id)
        if status:
            query += ' AND o.status = %s'
            params.append(status)
        query += ' ORDER BY o.order_time DESC'

        cursor.execute(query, params)
        return jsonify(cursor.fetchall()), 200
    except Error as e:
        current_app.logger.error(f'Database error in get_orders: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
# POST /orders - Create a new order for a buyer
@orders.route("/orders", methods=["POST"])
def create_order():
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info('POST /orders') 
        data = request.get_json()
        
        buyer_id = data.get('buyer_id')
        order_total = data.get('order_total')
        items = data.get('items', [])

        if not buyer_id or order_total is None or not items:
            return jsonify({'error': 'buyer_id, order_total, and items are required'}), 400
        
        for item in items:
            for field in ('quantity', 'price_at_purchase', 'listing_id'):
                if field not in item:
                    return jsonify({'error': f'{field} is required in each item'}), 400
                    
        cursor.execute('''
            INSERT INTO `order` (status, buyer_id, order_total)
            VALUES ('in cart', %s, %s)
        ''', (buyer_id, order_total))
        order_id = cursor.lastrowid
        
        for item in items:
            cursor.execute('''
                INSERT INTO order_items (quantity, price_at_purchase, order_id, listing_id)
                VALUES (%s, %s, %s, %s)
            ''', (item['quantity'], item['price_at_purchase'], order_id, item['listing_id']))
        
        get_db().commit()
        return jsonify({'message': 'Order created', 'order_id': order_id}), 201
    except Error as e:
        current_app.logger.error(f'Database error in create_order: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# GET /orders/{id} - Returns full order details 
@orders.route("/orders/<int:order_id>", methods=["GET"])
def get_order(order_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'GET /orders/{order_id}') 
        cursor.execute('''
            SELECT o.order_id, o.order_time, o.status, o.buyer_id, o.order_total, u.username AS buyer_username
            FROM `order` o
            JOIN user u ON o.buyer_id = u.user_id
            WHERE o.order_id = %s
        ''', (order_id,))
        order = cursor.fetchone()
        if not order:
            return jsonify({'error': 'Order not found'}), 404
        
        cursor.execute('''
            SELECT oi.order_item_id, oi.quantity, oi.price_at_purchase, oi.listing_id, l.title AS listing_title 
            FROM order_items oi
            JOIN  listing l ON oi.listing_id = l.listing_id
            WHERE oi.order_id = %s
        ''', (order_id,))
        order['items'] = cursor.fetchall()

        return jsonify(order), 200
    except Error as e:
        current_app.logger.error(f'Database error in get_order: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# PUT /orders/{id} - Update order status 
@orders.route("/orders/<int:order_id>", methods=["PUT"])
def update_order(order_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'PUT /orders/{order_id}') 
        data = request.get_json()
        status = data.get('status')

        valid_statuses = ('in cart', 'purchased', 'processing', 'shipped')
        if status not in valid_statuses:
            return jsonify({'error': f'status must be one of {valid_statuses}'}), 400
        
        cursor.execute('SELECT order_id FROM `order` WHERE order_id = %s', (order_id,))
        if not cursor.fetchone():
            return jsonify({'error': 'Order not found'}), 404
        
        cursor.execute('UPDATE `order` SET status = %s WHERE order_id = %s', (status, order_id))
        get_db().commit()
        return jsonify({'message': 'Order status updated'}), 200
    except Error as e:
        current_app.logger.error(f'Database error in update_order: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# ===================================================
# Fraud Report
# ===================================================

# GET /fraud-reports - Returns all fraud reports with status, filterable by status
@orders.route("/fraud-reports", methods=["GET"])
def get_fraud_reports():
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info('GET /fraud-reports') 
        status = request.args.get('status')

        query = '''
            SELECT report_id, reason, status, created_at, resolved_at, order_id, reviewer_id
            FROM fraud_report
            WHERE 1=1
        '''
        params = []
        if status:
            query += ' AND status = %s'
            params.append(status)
        query += ' ORDER BY created_at DESC'

        cursor.execute(query, params)
        return jsonify(cursor.fetchall()), 200
    except Error as e:
        current_app.logger.error(f'Database error in get_fraud_reports: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# POST /fraud-reports - File a new fraud report tied to an order with reason and reviewer 
@orders.route("/fraud-reports", methods=["POST"])
def create_fraud_report():
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info('POST /fraud-reports') 
        data = request.get_json()

        for field in ('reason', 'order_id', 'reviewer_id'):
            if field not in data:
                return jsonify({'error': f'{field} is required'}), 400
        
        cursor.execute('''
            INSERT INTO fraud_report (reason, status, order_id, reviewer_id)
            VALUES (%s, 'open', %s, %s)
        ''', (data['reason'], data['order_id'], data['reviewer_id']))
        get_db().commit()
        return jsonify({'message': 'Fraud report filed', 'report_id': cursor.lastrowid}), 201
    except Error as e:
        current_app.logger.error(f'Database error in create_fraud_reports: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# GET /fraud-reports/{id} - Return full details of a specific fraud report
@orders.route("/fraud-reports/<int:report_id>", methods=["GET"])
def get_fraud_report(report_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'GET /fraud-reports/{report_id}')
        cursor.execute('''
            SELECT report_id, reason, status, created_at, resolved_at, order_id, reviewer_id
            FROM fraud_report
            WHERE report_id = %s
        ''', (report_id,)) 
        report = cursor.fetchone()
        if not report:
            return jsonify({'error': 'Fraud report not found'}), 404
        return jsonify(report), 200
    except Error as e:
        current_app.logger.error(f'Database error in get_fraud_report: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# PUT /fraud-reports/{id} - Update fraud report status 
@orders.route("/fraud-reports/<int:report_id>", methods=["PUT"])
def update_fraud_report(report_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'PUT /fraud-reports/{report_id}')
        data = request.get_json()
        status = data.get('status')

        valid_statuses = ('open', 'investigating', 'resolved', 'dismissed')
        if status not in valid_statuses:
            return jsonify({'error': f'status must be one of {valid_statuses}'}), 400
        
        cursor.execute('SELECT report_id FROM fraud_report WHERE report_id = %s', (report_id,))
        if not cursor.fetchone():
            return jsonify({'error': 'Fraud report not found'}), 404
        
        # Set resolved_at only when closing the report
        if status in ('resolved', 'dismissed'):
            cursor.execute('''
                UPDATE fraud_report
                SET status = %s, resolved_at = NOW()
                WHERE report_id = %s
            ''', (status, report_id))
        else:
            cursor.execute('UPDATE fraud_report SET status = %s WHERE report_id = %s', (status, report_id))
    
        get_db().commit()
        return jsonify({'message': 'Fraud report updated'}), 200
    except Error as e:
        current_app.logger.error(f'Database error in update_fraud_report: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
