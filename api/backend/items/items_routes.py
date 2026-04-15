from flask import Blueprint, jsonify, request, current_app
from backend.db_connection import get_db
from mysql.connector import Error

# Create a Blueprint for itmes routes
items = Blueprint("items", __name__)

# GET /items - Returns all items for a seller, filterable by category
@items.route("/items", methods=["GET"])
def get_items():
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info('GET /items') 
        artist_id = request.args.get('artist_id')
        category_id = request.args.get('category_id')

        query = '''
            SELECT i.item_id, i.name, i.description, i.size, i.image_link, i.artist_id, i.category_id, c.name AS category_name,
            COUNT(DISTINCT l.listing_id) AS listing_count, COUNT(DISTINCT lk.user_id) AS total_likes
            FROM item i
            LEFT JOIN category c ON i.category_id = c.category_id
            LEFT JOIN listing l ON i.item_id = l.item_id
            LEFT JOIN likes lk ON l.listing_id = lk.listing_id
            WHERE 1=1
        '''
        params = []
        if artist_id:
            query += ' AND i.artist_id = %s'
            params.append(artist_id)
        if category_id:
            query += ' AND i.category_id = %s'
            params.append(category_id)
        query += ' GROUP BY i.item_id ORDER BY i.name'
        
        cursor.execute(query, params)
        return jsonify(cursor.fetchall()), 200 
    
    except Error as e:
        current_app.logger.error(f'Database error in get_items: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# POST /item - Creates a new item
@items.route("/items", methods=["POST"])
def create_items():
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info('POST /items') 
        data = request.get_json()

        for field in ('name', 'artist_id'):
            if field not in data:
                return jsonify({'error': f'{field} is required'}), 400
        
        cursor.execute('''
            INSERT INTO item(name, description, size, image_link, artist_id, category_id)
            VALUES (%s, %s, %s, %s, %s, %s)
        ''', (data['name'], data.get('description'), data.get('size'), 
                data.get('image_link'), data['artist_id'], data.get('category_id')
        ))
        get_db().commit()
        return jsonify({'message': 'Item created', 'item_id': cursor.lastrowid}), 200
    except Error as e:
        current_app.logger.error(f'Database error in create_items: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# GET /items/{id} - Returns full details of a specific item
@items.route("/items/<int:item_id>", methods=["GET"])
def get_item(item_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'GET /items/{item_id}') 
        cursor.execute('''
            SELECT i.item_id, i.name, i.description, i.size, i.image_link, i.artist_id, i.category_id, c.name AS category_name
            FROM item i
            LEFT JOIN category c on i.category_id = c.category_id
            WHERE i.item_id = %s
        ''', (item_id,))
        item = cursor.fetchone()
        if not item:
            return jsonify({'error': 'Item not found'}), 404
        return jsonify(item), 200
    except Error as e:
        current_app.logger.error(f'Database error in get_item: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# PUT /items/{id} - Update item details 
@items.route("/items/<int:item_id>", methods=["PUT"])
def update_item(item_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'PUT /items/{item_id}') 
        data = request.get_json()

        cursor.execute('SELECT item_id FROM item WHERE item_id = %s', (item_id,))
        if not cursor.fetchone():
            return jsonify({'error': 'Item not found'}), 404
        
        allowed = ['description', 'image_link', 'category_id', 'size', 'name']
        fields = [f for f in allowed if f in data]
        if not fields:
            return jsonify({'error': 'No valid fields to update'}), 400
        
        set_clause = ', '.join(f'{f} = %s' for f in fields)
        params = [data[f] for f in fields] + [item_id]
        
        cursor.execute(f'UPDATE item SET {set_clause} WHERE item_id = %s', params)
        get_db().commit()
        return jsonify({'message': 'Item updated successfully'}), 200
    except Error as e:
        current_app.logger.error(f'Database error in update_item: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# DELETE /items/{id} - delete item and its associated listings 
@items.route('/items/<int:item_id>', methods=["DELETE"])
def delete_item(item_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'DELETE /items/{item_id}') 
        cursor.execute('SELECT item_id FROM item WHERE item_id = %s', (item_id,))
        if not cursor.fetchone():
            return jsonify({'error': 'Item not found'}), 404
        
        cursor.execute('DELETE FROM item WHERE item_id = %s', (item_id,))
        get_db().commit()
        return jsonify({'message': 'Item and associated listing deleted successfully'}), 200
    except Error as e:
        current_app.logger.error(f'Database error in delete_item: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# GET items/{id}/variants - Returns all variants and pull rates for an item
@items.route("/items/<int:item_id>/variants", methods=["GET"])
def get_variants(item_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'GET /items/{item_id}/variants') 
        cursor.execute('SELECT item_id, name, pull_rate FROM variants WHERE item_id = %s', (item_id,))
        return jsonify(cursor.fetchall()), 200
    except Error as e:
        current_app.logger.error(f'Database error in get_variants: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# POST items/{id}/variants - Add a new variant with a name and pull rate
@items.route("/items/<int:item_id>/variants", methods=["POST"])
def add_variant(item_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'POST /items/{item_id}/variants') 
        data = request.get_json()
            
        if 'name' not in data or 'pull_rate' not in data:
            return jsonify({'error': 'name and pull rate are required'}), 400

        cursor.execute('INSERT INTO variants (item_id, name, pull_rate) VALUES (%s, %s, %s)', (
            item_id, data['name'], data['pull_rate']))
        
        get_db().commit()
        return jsonify({'message': 'Variant added successfully'}), 201
    except Error as e:
        current_app.logger.error(f'Database error in add_variant: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# PUT /items/{id}/variants/{variant_id} - Update the pull rate or name of an existing variants
@items.route("/items/<int:item_id>/variants/<string:variant_name>", methods=["PUT"])
def update_variant(item_id, variant_name):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'PUT /items/{item_id}/variants/{variant_name}')
        data = request.get_json()

        cursor.execute('SELECT item_id FROM variants WHERE item_id = %s AND name = %s', (item_id, variant_name))
        if not cursor.fetchone():
            return jsonify({'error': 'Variant not found'}), 404
        
        allowed = ['pull_rate', 'name']
        fields = [f for f in allowed if f in data]
        if not fields:
            return jsonify({'error': 'No valid fields to update'}), 400
        
        set_clause = ', '.join(f'{f} = %s' for f in fields)
        params = [data[f] for f in fields] + [item_id, variant_name]
        cursor.execute(f'UPDATE variants SET {set_clause} WHERE item_id = %s AND name = %s', params)
        get_db().commit()
        return jsonify({'message': 'Variant updated successfully'}), 200
    except Error as e:
        current_app.logger.error(f'Database error in update_variant: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()