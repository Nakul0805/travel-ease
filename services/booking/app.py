import os
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///bookings.db'
db = SQLAlchemy(app)

API_KEY = os.environ.get('API_KEY')

def require_api_key(view_function):
    def decorated_function(*args, **kwargs):
        if request.headers.get('x-api-key') != API_KEY:
            return {'error': 'Unauthorized'}, 401
        return view_function(*args, **kwargs)
    decorated_function.__name__ = view_function.__name__
    return decorated_function

class Booking(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.String(80), nullable=False)
    trip_id = db.Column(db.String(80), nullable=False)

@app.before_first_request
def create_tables():
    db.create_all()

@app.route('/health')
def health():
    return {'status': 'ok'}, 200

@app.route('/book', methods=['POST'])
@require_api_key
def book():
    data = request.get_json()
    user_id = data.get('user_id')
    trip_id = data.get('trip_id')
    if not user_id or not trip_id:
        return {'error': 'Missing user_id or trip_id'}, 400
    booking = Booking(user_id=user_id, trip_id=trip_id)
    db.session.add(booking)
    db.session.commit()
    return {'message': 'Booking created', 'booking_id': booking.id}, 201

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)