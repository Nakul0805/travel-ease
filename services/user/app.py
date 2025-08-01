import os
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///users.db'
db = SQLAlchemy(app)

API_KEY = os.environ.get('API_KEY')

def require_api_key(view_function):
    def decorated_function(*args, **kwargs):
        if request.headers.get('x-api-key') != API_KEY:
            return {'error': 'Unauthorized'}, 401
        return view_function(*args, **kwargs)
    decorated_function.__name__ = view_function.__name__
    return decorated_function

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)

@app.before_first_request
def create_tables():
    db.create_all()

@app.route('/health')
def health():
    return {'status': 'ok'}, 200

@app.route('/user', methods=['POST'])
@require_api_key
def create_user():
    data = request.get_json()
    username = data.get('username')
    email = data.get('email')
    if not username or not email:
        return {'error': 'Missing username or email'}, 400
    if User.query.filter((User.username == username) | (User.email == email)).first():
        return {'error': 'User already exists'}, 409
    user = User(username=username, email=email)
    db.session.add(user)
    db.session.commit()
    return {'message': 'User created', 'user_id': user.id}, 201

@app.route('/user/<int:user_id>', methods=['GET'])
@require_api_key
def get_user(user_id):
    user = User.query.get(user_id)
    if not user:
        return {'error': 'User not found'}, 404
    return jsonify({
        'id': user.id,
        'username': user.username,
        'email': user.email
    })

@app.route('/user/<int:user_id>', methods=['PUT'])
@require_api_key
def update_user(user_id):
    user = User.query.get(user_id)
    if not user:
        return {'error': 'User not found'}, 404
    data = request.get_json()
    user.username = data.get('username', user.username)
    user.email = data.get('email', user.email)
    db.session.commit()
    return {'message': 'User updated'}

@app.route('/user/<int:user_id>', methods=['DELETE'])
@require_api_key
def delete_user(user_id):
    user = User.query.get(user_id)
    if not user:
        return {'error': 'User not found'}, 404
    db.session.delete(user)
    db.session.commit()
    return {'message': 'User deleted'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002)