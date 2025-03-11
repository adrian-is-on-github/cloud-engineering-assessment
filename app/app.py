from flask import Flask, jsonify
import datetime
import socket
import os

app = Flask(__name__)

@app.route('/')
def index():
    """Return a simple JSON response with the current time and hostname."""
    return jsonify({
        'message': 'Hello from the Cloud Engineering Test App!',
        'timestamp': datetime.datetime.now().isoformat(),
        'hostname': socket.gethostname(),
        'version': os.environ.get('APP_VERSION', '1.0.0')
    })

@app.route('/health')
def health():
    """Health check endpoint."""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.datetime.now().isoformat()
    })

if __name__ == '__main__':
    # Use environment variables for configuration
    port = int(os.environ.get('PORT', 5000))
    
    app.run(host='0.0.0.0', port=port)