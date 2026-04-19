from flask import Blueprint, jsonify, request, current_app
from backend.db_connection import get_db
from mysql.connector import Error

# Create a Blueprint for artist routes
artists = Blueprint("artists", __name__)

# GET /artists - list all artists with verification status 
@artists.route("/artists", methods=["GET"])
def get_artists():
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info('GET /artists') 
        cursor.execute('''
            SELECT a.artist_id, u.username, u.first_name, u.last_name, u.gender, u.dob, u.phone, u.created_at, u.bio, u.photo_link, u.street_address, u.city, u.state, a.is_verified
            FROM artist a
            JOIN user u ON a.artist_id = u.user_id
            ORDER BY u.username
        ''')
        return jsonify(cursor.fetchall()), 200
    except Error as e:
        current_app.logger.error(f'Database error in get_artists: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
# GET /artists/{id}/items - get all items for an artist
@artists.route("/artists/<int:artist_id>/items", methods=["GET"])
def get_artist_items(artist_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'GET /artists/{artist_id}/items')
        cursor.execute('''
            SELECT i.item_id, i.name
            FROM item i
            WHERE i.artist_id = %s
            ORDER BY i.name
        ''', (artist_id,))
        return jsonify(cursor.fetchall()), 200
    except Error as e:
        current_app.logger.error(f'Database error in get_artist_items: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# GET /artists/{id} - return artist profile and verification status 
@artists.route("/artists/<int:artist_id>", methods=["GET"])
def get_artist(artist_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'GET /artists/{artist_id}') 
        cursor.execute('''
            SELECT a.artist_id, u.username, u.first_name, u.last_name, u.gender, u.dob, u.phone, u.created_at, u.bio, u.photo_link, u.street_address, u.city, u.state, a.is_verified
            FROM artist a
            JOIN user u ON a.artist_id = u.user_id
            WHERE a.artist_id = %s
        ''', (artist_id,))
        artist = cursor.fetchone() 
        if not artist:
            return jsonify({'error': 'Artist not found'}), 404
        return jsonify(artist), 200
    except Error as e:
        current_app.logger.error(f'Database error in get_artist: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# PUT /artists/{id} - update artist profile or set verification flag
@artists.route("/artists/<int:artist_id>", methods=["PUT"])
def update_artist(artist_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'PUT /artists/{artist_id}') 
        data = request.get_json()

        # Check artist existsç
        cursor.execute('SELECT artist_id FROM artist WHERE artist_id = %s', (artist_id,))
        if not cursor.fetchone():
            return jsonify({'error': 'Artist not found'}), 404
        
        # Update user profile fields if provided
        user_allowed = ['bio', 'photo_link', 'street_address', 'phone', 'city', 'state', 'first_name', 'last_name']
        user_fields = [f for f in user_allowed if f in data]
        if user_fields:
            set_clause = ', '.join(f'{f} = %s' for f in user_fields)
            params = [data[f] for f in user_fields] + [artist_id]
            cursor.execute(f'UPDATE user SET {set_clause} WHERE user_id = %s', params)
        
        # Update verification flag separately 
        if 'is_verified' in data:
            cursor.execute(
                'UPDATE artist SET is_verified = %s WHERE artist_id = %s', (data['is_verified'], artist_id)
            )
        
        if not user_fields and 'is_verified' not in data:
            return jsonify({'error': 'No valid fields to update'}), 400
        
        get_db().commit()
        return jsonify({'message': 'Artist updated successfully'}), 200
    except Error as e:
        current_app.logger.error(f'Database error in update_artist: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# GET /artists/{id}/application - return application status and portfolio link
@artists.route("/artists/<int:artist_id>/application", methods=["GET"])
def get_application(artist_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'GET /artists/{artist_id}/application')
        cursor.execute('''
            SELECT application_id, status, portfolio_link, submitted_at, reviewed_at, artist_id, reviewer_id
            FROM artist_application
            WHERE artist_id = %s
            ORDER BY submitted_at DESC
            LIMIT 1
        ''', (artist_id,))
        application = cursor.fetchone()
        if not application:
            return jsonify({'error': 'No application found for this artist'}), 404
        return jsonify(application), 200
    except Error as e:
        current_app.logger.error(f'Database error in get_application: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
    
# POST /artists/{id}/application - submit a new artist application
@artists.route("/artists/<int:artist_id>/application", methods=["POST"])
def submit_application(artist_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'POST /artists/{artist_id}/application')
        data = request.get_json()

        if 'portfolio_link' not in data:
            return jsonify({'error': 'portfolio_link is required'}), 400
        
        cursor.execute('''
            INSERT INTO artist_application (status, portfolio_link, artist_id)
            VALUES ('pending', %s, %s)
        ''', (data['portfolio_link'], artist_id))

        get_db().commit()
        return jsonify({
            'message': 'Application submitted successfully',
            'application_id': cursor.lastrowid
        }), 201
    except Error as e:
        current_app.logger.error(f'Database error in submit_application: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# PUT /artists/<id>/application - approve or reject an application
@artists.route("/artists/<int:artist_id>/application", methods=["PUT"])
def review_application(artist_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        current_app.logger.info(f'PUT /artists/{artist_id}/application')
        data = request.get_json()

        status = data.get('status')
        reviewer_id = data.get('reviewer_id')

        if status not in ('approved', 'rejected'):
            return jsonify({'error': 'status must be approved or rejected'}), 400
        if not reviewer_id:
            return jsonify({'error': 'reviewer_id is required'}), 400

        cursor.execute('''
            UPDATE artist_application
            SET status = %s,
                reviewer_id = %s,
                reviewed_at = NOW()
            WHERE artist_id = %s
            ORDER BY submitted_at DESC
            LIMIT 1
        ''', (status, reviewer_id, artist_id))
    
        # If approved, set the artist's verified flag
        if status == 'approved':
            cursor.execute('UPDATE artist SET is_verified = 1 WHERE artist_id = %s', (artist_id,))
            cursor.execute('''
                INSERT INTO artist_status (status, artist_id, reviewer_id)
                VALUES ('verified', %s, %s)
            ''', (artist_id, reviewer_id))
        get_db().commit()
        return jsonify({'message': f'Application {status} successfully'}), 200

    except Error as e:
        current_app.logger.error(f'Database error in review_application: {e}')
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# GET /artists/{id}/email - get primary email
@artists.route("/artists/<int:artist_id>/email", methods=["GET"])
def get_artist_email(artist_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        cursor.execute('''
            SELECT email FROM user_email 
            WHERE user_id = %s AND is_primary = 1
            LIMIT 1
        ''', (artist_id,))
        result = cursor.fetchone()
        return jsonify(result or {}), 200
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# PUT /artists/{id}/email - update primary email
@artists.route("/artists/<int:artist_id>/email", methods=["PUT"])
def update_artist_email(artist_id):
    cursor = get_db().cursor(dictionary=True)
    try:
        data = request.get_json()
        cursor.execute('''
            UPDATE user_email SET email = %s 
            WHERE user_id = %s AND is_primary = 1
        ''', (data.get("email"), artist_id))
        get_db().commit()
        return jsonify({'message': 'Email updated'}), 200
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()

# GET /categories - for the listing dropdown
@artists.route("/categories", methods=["GET"])
def get_categories():
    cursor = get_db().cursor(dictionary=True)
    try:
        cursor.execute('SELECT category_id, name FROM category ORDER BY name')
        return jsonify(cursor.fetchall()), 200
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()