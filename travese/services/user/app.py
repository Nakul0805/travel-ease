from flask import Flask
app = Flask(__name__)

@app.route('/health')
def health():
    return {'status': 'ok'}, 200

@app.route('/user', methods=['POST'])
def user():
    return {'message': 'User created'}, 201

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002)
