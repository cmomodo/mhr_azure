from dotenv import load_dotenv
from flask import Flask, request, jsonify, abort, render_template
from pymongo.errors import PyMongoError

import cosmos_store

load_dotenv()

app = Flask(__name__, template_folder='templates', static_folder='static')


def _handle_store_error(error):
    if isinstance(error, RuntimeError):
        abort(503, description=str(error))
    if isinstance(error, PyMongoError):
        abort(503, description="Database unavailable")
    raise error


@app.route('/')
def index():
    return render_template('index.html')


@app.route('/health')
def health():
    try:
        cosmos_store.ping()
        return jsonify({'status': 'ok', 'database': 'connected'}), 200
    except (RuntimeError, PyMongoError) as error:
        return jsonify({'status': 'error', 'database': str(error)}), 503


@app.route('/tasks', methods=['GET'])
def get_tasks():
    try:
        return jsonify(cosmos_store.list_tasks())
    except (RuntimeError, PyMongoError) as error:
        _handle_store_error(error)


@app.route('/tasks', methods=['POST'])
def create_task():
    data = request.get_json(silent=True)
    if not data or 'title' not in data:
        abort(400, description="Missing task title")
    try:
        task = cosmos_store.create_task(
            title=data['title'],
            description=data.get('description', ''),
        )
        return jsonify(task), 201
    except (RuntimeError, PyMongoError) as error:
        _handle_store_error(error)


@app.route('/tasks/<task_id>', methods=['GET'])
def get_task(task_id):
    try:
        task = cosmos_store.get_task(task_id)
    except (RuntimeError, PyMongoError) as error:
        _handle_store_error(error)
    if not task:
        abort(404, description="Task not found")
    return jsonify(task)


@app.route('/tasks/<task_id>', methods=['PUT'])
def update_task(task_id):
    data = request.get_json(silent=True) or {}
    try:
        task = cosmos_store.update_task(
            task_id,
            title=data.get('title'),
            description=data.get('description'),
            completed=data.get('completed'),
        )
    except (RuntimeError, PyMongoError) as error:
        _handle_store_error(error)
    if not task:
        abort(404, description="Task not found")
    return jsonify(task)


@app.route('/tasks/<task_id>', methods=['DELETE'])
def delete_task(task_id):
    try:
        deleted = cosmos_store.delete_task(task_id)
    except (RuntimeError, PyMongoError) as error:
        _handle_store_error(error)
    if not deleted:
        abort(404, description="Task not found")
    return jsonify({'result': True})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000, debug=True)
