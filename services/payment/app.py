import os
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///payments.db'
db = SQLAlchemy(app)

API_KEY = os.environ.get('API_KEY')

def require_api_key(view_function):
    def decorated_function(*args, **kwargs):
        if request.headers.get('x-api-key') != API_KEY:
            return {'error': 'Unauthorized'}, 401
        return view_function(*args, **kwargs)
    decorated_function.__name__ = view_function.__name__
    return decorated_function

class Payment(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    booking_id = db.Column(db.String(80), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    status = db.Column(db.String(20), nullable=False, default='pending')

@app.before_first_request
def create_tables():
    db.create_all()

@app.route('/health')
def health():
    return {'status': 'ok'}, 200

@app.route('/payment', methods=['POST'])
@require_api_key
def create_payment():
    data = request.get_json()
    booking_id = data.get('booking_id')
    amount = data.get('amount')
    if not booking_id or amount is None:
        return {'error': 'Missing booking_id or amount'}, 400
    payment = Payment(booking_id=booking_id, amount=amount, status='pending')
    db.session.add(payment)
    db.session.commit()
    return {'message': 'Payment created', 'payment_id': payment.id}, 201

@app.route('/payment/<int:payment_id>', methods=['GET'])
@require_api_key
def get_payment(payment_id):
    payment = Payment.query.get(payment_id)
    if not payment:
        return {'error': 'Payment not found'}, 404
    return jsonify({
        'id': payment.id,
        'booking_id': payment.booking_id,
        'amount': payment.amount,
        'status': payment.status
    })

@app.route('/payment/<int:payment_id>', methods=['PUT'])
@require_api_key
def update_payment(payment_id):
    payment = Payment.query.get(payment_id)
    if not payment:
        return {'error': 'Payment not found'}, 404
    data = request.get_json()
    payment.status = data.get('status', payment.status)
    db.session.commit()
    return {'message': 'Payment updated'}

@app.route('/payment/<int:payment_id>', methods=['DELETE'])
@require_api_key
def delete_payment(payment_id):
    payment = Payment.query.get(payment_id)
    if not payment:
        return {'error': 'Payment not found'}, 404
    db.session.delete(payment)
    db.session.commit()
    return {'message': 'Payment deleted'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)