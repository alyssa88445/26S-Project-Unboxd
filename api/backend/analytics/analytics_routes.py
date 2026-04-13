from flask import Blueprint, jsonify, request, current_app
from backend.db_connection import get_db
from mysql.connector import Error

# Create a Blueprint for analytics routes
analytics = Blueprint("analytics", __name__)

# =============================================================
# Sellers
# =============================================================

# GET /sellers - return all sellers with basic profile info
@analytics.route("/sellers", methods=["GET"])
def get_sellers():
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info('GET /sellers')
        cursor.execute('''
            SELECT a.artist_id AS seller_id, u.username, u.first_name, u.last_name, u.city, u.state, a.is_verified
            FROM artist a
            JOIN user u on a.artist_id = u.user_id
            ORDER BY u.username
        ''')
        return jsonify(cursor.fetchall()), 200
    except Error as e:
        current_app.logger.error(f'Database error in get_sellers: {e}')
        return jsonify({'error': str{e}}), 500
    finally:
        cursor.close()

# GET /sellers/<id> - return a specific seller's profile
@analytics.route('/sellers/<int:seller_id>', methods=["GET"])
def get_seller(seller_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'GET /sellers/{seller_id}')
        cursor.execute('''
            SELECT a.artist_id AS seller_id, u.username, u.first_name, u.last_name, u.bio, u.photo_link, u.city, u.state, a.is_verified
            FROM artist a
            JOIN user u on a.artist_id = u.user_id
            WHERE a.artist_id = %s
        ''', (seller_id,))
        seller = cursor.fetchone()
        if not seller:
            return jsonify({'error': 'Seller not found'}), 404
        return jsonify(seller), 200
    except Error as e:
        current_app.logger.error(f'Database error in get_seller: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# GET /sellers/<id>/sales - weekly, monthly, and annual sales totals 
@analytics.route('/sellers/<int:seller_id>/sales', methods=["GET"])
def get_seller_sales(seller_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'GET /seller/{seller_id}/sales')

        cursor.execute('''
            SELECT SUM(oi.price_at_purchase * oi.quantity) AS weekly_sales
            FROM order_items oi
            JOIN listing l ON oi.listing_id = l.listing_id
            JOIN `order` o ON oi.order_id   = o.order_id
            WHERE l.artist_id = %s
              AND o.status != 'in cart'
              AND o.order_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)
        ''', (seller_id,))
        weekly = cursor.fetchone()
 
        cursor.execute('''
            SELECT SUM(oi.price_at_purchase * oi.quantity) AS monthly_sales
            FROM order_items oi
            JOIN listing l ON oi.listing_id = l.listing_id
            JOIN `order` o ON oi.order_id   = o.order_id
            WHERE l.artist_id = %s
              AND o.status != 'in cart'
              AND o.order_time >= DATE_SUB(NOW(), INTERVAL 1 MONTH)
        ''', (seller_id,))
        monthly = cursor.fetchone()
 
        cursor.execute('''
            SELECT SUM(oi.price_at_purchase * oi.quantity) AS annual_sales
            FROM order_items oi
            JOIN listing l ON oi.listing_id = l.listing_id
            JOIN `order` o ON oi.order_id   = o.order_id
            WHERE l.artist_id = %s
              AND o.status != 'in cart'
              AND o.order_time >= DATE_SUB(NOW(), INTERVAL 1 YEAR)
        ''', (seller_id,))
        annual = cursor.fetchone()
 
        cursor.execute('''
            SELECT COUNT(DISTINCT o.order_id) AS total_orders
            FROM order_items oi
            JOIN listing l ON oi.listing_id = l.listing_id
            JOIN `order` o ON oi.order_id   = o.order_id
            WHERE l.artist_id = %s
              AND o.status != 'in cart'
        ''', (seller_id,))
        total = cursor.fetchone()

        return jsonify({
            'weekly_sales':  weekly['weekly_sales'],
            'monthly_sales': monthly['monthly_sales'],
            'annual_sales':  annual['annual_sales'],
            'total_orders':  total['total_orders']
        }), 200
    except Error as e:
        current_app.logger.error(f'Database error in get_seller_sales: {e}')
        return jsonify({'error': str{e}}), 500
    finally:
        cursor.close()

# =============================================================
# Analytics
# =============================================================

# GET /analytics/dashboard - real-time platform KPIs
@analytics.route('/analytics/dashboard', methods=["GET"])
def get_dashboard():
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info('GET /analytics/dashboard')
        cursor.execute('''
            SELECT active_users, churned_users, conversions, retained_users, user_rate, conversion_rate, 
                    retention_rate, turnover_rate, recorded_at
            FROM platform_metrics
            ORDER BY recorded_at DESC
            LIMIT 1
        ''')
        platform = cursor.fetchone()
        
        cursor.execute('''
            SELECT metric_type, value, recorded_at
            FROM system_metric
            ORDER BY recorded_at DESC
            LIMIT 10
        ''')
        system_metrics = cursor.fetchall()

        cursor.execute('SELECT COUNT(*) AS open_alerts FROM system_alerts WHERE status = 'open'')
        alert_count = cursor.fetchone()

        return jsonify({
            'platform_metrics': platform,
            'recent_system_metrics': system_metrics,
            'open_alert_count', alert_count
        }), 200

    except Error as e:
        current_app.logger.error(f'Database error in get_dashboard: {e}')
        return jsonify({'error': str(e)}), 500
    finally: 
        cursor.close()

# GET /analytics/listings - performance breakdown by listing type
@analytics.route('/analytics/listings', methods=["GET"])
def get_listing_analytics():
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info('GET /analytics/listings')
        listing_type = request.args.get('type')
        category_id = request.args.get('category_id')
        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')

        query = '''
            SELECT l.listing_type, 
                    COUNT(DISTINCT l.listing_id) AS total_listings,
                    COUNT(DISTINCT oi.order_item_id) AS total_orders,
                    SUM(oi.price_at_purchase * oi_quantity) AS total_revenue,
                    AVG(l.price) AS avg_price
            FROM listing l
            LEFT JOIN order_items oi ON l.listing_id = oi.listing_id
            LEFT JOIN `order` o ON oi.order_id = o.order_id
            LEFT JOIN item i ON l.item_id = i.item_id
            WHERE 1 = 1
        '''
        params = []
        if listing_type:
            query += ' AND l.listing_type = %s'
            params.append(listing_type)
        if category_id:
            query += ' AND i.category_id = %s'
            params.append(category_id)
        if start_date:
            query += ' AND o.order_time >= %s'
            params.append(start_date)
        if end_date:
            query += ' AND o.order_time <= %s'
            params.append(end_date)
        query += ' GROUP BY l.listing_type'
        
        cursor.execute(query, params)
        return jsonify(cursor.fetchall()), 200
    except Error as e:
        current_app.logger.error(f'Database error in get_listing_analytics: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# GET /analytics/sellers - top performing sellers by revenue and units sold
@analytics.route('/analytics/sellers', methods=["GET"])
def get_top_sellers():
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info('GET /analytics/sellers')
        limit = request.args.get('limit', 10)

        cursor.execute('''
            SELECT l.artist_id, u.username, SUM(oi.price_at_purchase * oi.quantity) AS total_revenue,
                    SUM(oi.quantity) AS total_units_sold, COUNT(DISTINCT oi.order_id) AS total_orders
            FROM order_items oi
            JOIN listing l ON oi.listing_id = l.listing_id
            JOIN user u on l.artist_id = u.user_id
            JOIN `order` o on oi.order_id = o.order_id
            WHERE o.status != 'in cart'
            GROUP BY l.artist_id, u.username
            ORDER BY total_revenue DESC
            LIMIT %s
        ''' (limit,))
        return jsonify(cursor.fetchall()), 200
    except Error as e:
        current_app.logger.error(f'Database error in get_top_sellers: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# GET /analytics/retention - retention and churn metrics over time
@analytics.route('/analytics/retention', methods=["GET"])
def get_retention():
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info('GET /analytics/retention')
        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')

        query = '''
            SELECT active_users, churned_users, retained_users, retention_rate, turnover_rate, conversion_rate, recorded_at
            FROM platform metrics
            WHERE 1 = 1
        '''
        params = []
        if start_date:
            query += ' AND recorded_at >= %s'
            params.append(start_date)
        if end_date:
            query += ' AND recorded_at <= %s'
            params.append(end_date)
        query += ' ORDER BY recorded_at DESC'
        cursor.execute(query, params)
        return jsonify(cursor.fatchall()), 200
    except Error as e:
        current_app.logger.error(f'Database error in get_retention: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# GET /analytics/trending - trending searches and most liked listings 
@analytics.route('/analytics/trending', methods=["GET"])
def get_trending():
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info('GET /analytics/trending')
        cursor.execute('''
            SELECT search_term, COUNT(*) AS search_count
            FROM user_activity
            WHERE activity_type = 'search' AND search_term IS NOT NULL
            GROUP BY search_term
            ORDER BY search_COUNT DESC
            LIMIT 10
        ''')
        trending_searches = cursor.fetchall()

        cursor.execute('''
            SELECT l.listing_id, l.title, l.price, l.listing_type, COUNT(lk.user_id) AS like_count
            FROM likes lk
            JOIN listing l ON lk.listing_id = l.listing_id
            GROUP BY l.listing_id, l.title, l.price, l.listing_type
            ORDER BY like_count DESC
            LIMIT 10
        ''')
        most_liked = cursor.fetchall()

        return jsonify({
            'trending_searches': trending_searches,
            'most_liked_listings': most_liked
        }), 200
    except Error as e:
        current_app.logger.error(f'Database error in get_trending: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# =============================================================
# System alerts
# =============================================================

# GET /system/alerts - return all system alerts with severity and status
@analytics.route('/system/alerts', methods=["GET"])
def get_alerts():
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info('GET /system/alerts')
        severity = request.args.get('severity')
        status = request.args.get('status')

        query = '''
            SELECT alert_id, alert_type, severity, status, message, created_at, resolved_at
            FROM system_alert
            WHERE 1=1
        '''
        params = []
        if severity:
            query += ' AND severity = %s'
            params.append(severity)
        if status:
            query += ' AND status = %s'
            params.append(status)
        query += ' ORDER BY created_at DESC'

        cursor.execute(query, params)
        return jsonify(cursor.fetchall()), 200
    except Error as e:
        current_app.logger.error(f'Database error in get_alerts: {e}')
        return jsonify({'error'L str(e)}), 500
    finally:
        cursor.close()

# GET /system/alerts/{id} - return full details of a specific alert
@analytics.route('/system/alerts/<int:alert_id>', methods=["GET"])
def get_alert(alert_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'GET /system/alerts/{alert_id}')
        cursor.execute('''
            SLECT alert_id, alert_type, severity, status, message, created_at, resolved_at
            FROM system_alert
            WHERE alert_id = %s
        ''', (alert_id,))
        alert = cursor.fetchone()
        if not alert:
            return jsonify({'error': 'Alert not found'}), 404
        return jsonify(alert), 200
    except Error as e:
        current_app.logger.error(f'Database error in get_alert: {e}')
        return jsonify({'error': str{e}}), 500
    finally:
        cursor.close()

# PUT /system/alerts/{id} - update alert status and resolved_at 
@analytics.route('/system/alerts/<int:alert_id>', methods=["PUT"])
def update_alert(alert_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'PUT /system/alerts/{alert_id}')
        data = request.get_json()
        status = data.get('status')
        
        valid_statuses = ('open', 'investigating', 'resolved')
        if status not in valid_statuses:
            return jsonify({'error': f'status must be one of {valid_statuses}'}), 400
        
        cursor.execute('SELECT alert_id FROM system_alert WHERE alert_id = %s', (alert_id,))
        if not cursor.fetchone():
            return jsonify({'error': 'Alert not found'}), 404
        
        if status == 'resolved':
            cursor.execute('''
                UPDATE system_alert
                SET status = %s, resolved_at = NOW()
                WHERE alert_id = %s
            ''', (status, alert_id))
        else:
            cursor.execute('UPDATE system_alert SET status = %s WHERE alert_id = %s', (status, alert_id))
        
        get_db().commit()
        return jsonify({'message': 'Alert updated successfully'}), 200
    except Error as e:
        current_app.logger.error(f'Database error in update_alert: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()