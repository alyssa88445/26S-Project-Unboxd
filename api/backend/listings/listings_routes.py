from flask import Blueprint, jsonify, request, current_app
from backend.db_connection import get_db
from mysql.connector import Error

# Create a Blueprint for listing routes
listings = Blueprint("listings", __name__)

# GET /listings - returns all listings, filterable by type/status/category/artist/price
@listings.route("/listings", methods=["GET"])
def get_listings():
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info('GET /listings') 
        listing_type = request.args.get('type')
        status = request.args.get('status')
        category_id = request.args.get('category_id')
        artist_id = request.args.get('artist_id')
        min_price = request.args.get('min_price')
        max_price = request.args.get('max_price')

        query = '''
            SELECT l.listing_id, l.title, l.quantity, l.price, l.status, l.listing_type, l.post_time,
                    l.item_id, l.artist_id, i.name AS item_name, i.image_link, u.username AS artist_username
            FROM listing l
            JOIN item i on l.item_id = i.item_id
            JOIN user u on l.artist_id = u.user_id
            WHERE 1 = 1
        '''
        params = []
        if listing_type:
            query += ' AND l.listing_type = %s'
            params.append(listing_type)
        if status:
            query += ' AND l.status = %s'
            params.append(status)
        if category_id:
            query += ' AND i.category_id = %s'
            params.append(category_id)
        if artist_id:
            query += ' AND l.artist_id = %s'
            params.append(artist_id)
        if min_price:
            query += ' AND l.price >= %s'
            params.append(min_price)
        if max_price:
            query += ' AND l.price <= %s'
            params.append(max_price)
        query += ' ORDER BY l.post_time DESC'

        cursor.execute(query, params)
        return jsonify(cursor.fetchall()), 200
    except Error as e:
        current_app.logger.error(f'Database error in get_listings: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# POST /listings - Create a new listing
@listings.route("/listings", methods=["POST"])
def create_listing():
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info('POST /listings') 
        data = request.get_json()

        for field in ('title', 'quantity', 'price', 'status', 'listing_type', 'item_id', 'artist_id'):
            if field not in data:
                return jsonify({'error': f'{field} is required'}), 400
            
        cursor.execute('''
            INSERT INTO listing (title, quantity, price, status, listing_type, item_id, artist_id)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        ''', (
            data['title'], data['quantity'], data['price'], data['status'], 
            data['listing_type'], data['item_id'], data['artist_id']))
        get_db().commit()
        return jsonify({'message': 'Listing created', 'listing_id': cursor.lastrowid}), 201
    except Error as e:
        current_app.logger.error(f'Database error in create_listings: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# GET /listing/{id} - Returns full listing details 
@listings.route("/listings/<int:listing_id>", methods=["GET"])
def get_listing(listing_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'GET /listings/{listing_id}') 
        cursor.execute('''
            SELECT l.listing_id, l.title, l.quantity, l.price, l.status, l.listing_type, l.post_time,
                    l.item_id, l.artist_id, i.name as item_name, i.description, i.size, i.image_link,
                    u.username AS artist_username, a.is_verified
            FROM listing l
            JOIN item i on l.item_id = i.item_id
            JOIN user u on l.artist_id = u.user_id
            JOIN artist a ON l.artist_id = a.artist_id
            WHERE l.listing_id = %s
        ''', (listing_id,))
        listing = cursor.fetchone()  
        if not listing:
            return jsonify({'error': 'Listing not found'}), 404
        return jsonify(listing), 200  
    except Error as e:
        current_app.logger.error(f'Database error in get_listing: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# PUT /listing/{id} - Update status, price, quantity, or re-list
@listings.route("/listings/<int:listing_id>", methods=["PUT"])
def update_listing(listing_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'PUT /listings/{listing_id}') 
        data = request.get_json()

        cursor.execute('SELECT listing_id FROM listing WHERE listing_id = %s', (listing_id,))
        if not cursor.fetchone():
            return jsonify({'error': 'Listing not found'}), 404
        
        allowed = ['status', 'price', 'quantity', 'listing_type', 'title']
        fields = [f for f in allowed if f in data]
        if not fields:
            return jsonify({'error': 'No fields to update'}), 400

        set_clause = ', '.join(f'{f} = %s' for f in fields)
        params = [data[f] for f in fields] + [listing_id]
        cursor.execute(f'UPDATE listing SET {set_clause} WHERE listing_id = %s', params)

        get_db().commit()
        return jsonify({'message': 'Listing updated successfully'}), 200
    except Error as e:
        current_app.logger.error(f'Database error in update_listing: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# DELETE /listing{id} - Delete a fraudulent listing
@listings.route("/listings/<int:listing_id>", methods=["DELETE"])
def delete_listing(listing_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'DELETE /listings/{listing_id}')
        cursor.execute('SELECT listing_id FROM listing WHERE listing_id = %s', (listing_id,))
        if not cursor.fetchone():
            return jsonify({'error': 'Listing not found'}), 404
        
        cursor.execute('DELETE FROM listing WHERE listing_id = %s', (listing_id,))
        get_db().commit()
        return jsonify({'message': 'Listing deleted successfully'}), 200
    except Error as e:
        current_app.logger.error(f'Database error in delete_listing: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# GET /listings/{id}/moderation - Returns moderation history
@listings.route("/listings/<int:listing_id>/moderation", methods=["GET"])
def get_moderation(listing_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'GET /listings/{listing_id}/moderation')
        cursor.execute('''
            SELECT moderation_id, reason, action, reviewed_at, listing_id, reviewed_by
            FROM listing_moderation
            WHERE listing_id = %s
            ORDER BY reviewed_at DESC
        ''', (listing_id,))
        return jsonify(cursor.fetchall()), 200
    except Error as e:
        current_app.logger.error(f'Database error in get_moderation: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# POST /listings/{id}/moderation - Creates a moderation action
@listings.route("/listings/<int:listing_id>/moderation", methods=["POST"])
def create_moderation(listing_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'POST /listings/{listing_id}/moderation')
        data = request.get_json()
        action = data.get('action')
        reviewed_by = data.get('reviewed_by')

        if action not in ('approved', 'rejected', 'flagged'):
            return jsonify({'error':'action must be approved, rejected, or flagged'}), 400
        if not reviewed_by:
            return jsonify({'error': 'reviewed_by is required'}), 400

        cursor.execute('''
            INSERT INTO listing_moderation (reason, action, listing_id, reviewed_by)
            VALUES (%s, %s, %s, %s)
        ''', (data.get('reason'), action, listing_id, reviewed_by))

        cursor.execute('UPDATE listing SET status = %s WHERE listing_id = %s', (action, listing_id)) 
        get_db().commit()
        return jsonify({'message': 'Moderation action recorded'}), 201
    except Error as e:
        current_app.logger.error(f'Database error in create_moderation: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()   

# GET /listings/{id}/bids - Returns full bid history for an auction listing 
@listings.route("/listings/<int:listing_id>/bids", methods=["GET"])
def get_bids(listing_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'GET /listings/{listing_id}/bids')
        cursor.execute('''
            SELECT oi.order_item_id, oi.quantity, oi.price_at_purchase,
                    o.buyer_id, o.order_time, u.username AS buyer_username
            FROM order_items oi
            JOIN `order` o ON oi.order_id = o.order_id
            JOIN user u ON o.buyer_id = u.user_id
            WHERE oi.listing_id = %s
            ORDER BY oi.price_at_purchase DESC
        ''', (listing_id,))
        return jsonify(cursor.fetchall()), 200
    except Error as e:
        current_app.logger.error(f'Database error in get_bids: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()      