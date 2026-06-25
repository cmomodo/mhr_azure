import os
import uuid

from pymongo import MongoClient
from pymongo.errors import PyMongoError

CONNECTION_STRING = os.environ.get("COSMOS_CONNECTION_STRING")
DATABASE_NAME = os.environ.get("COSMOS_DATABASE_NAME", "taskdb")
COLLECTION_NAME = os.environ.get("COSMOS_COLLECTION_NAME", "tasks")

_client = None
_collection = None


def _get_collection():
    global _client, _collection

    if _collection is not None:
        return _collection

    if not CONNECTION_STRING:
        raise RuntimeError("COSMOS_CONNECTION_STRING environment variable is required")

    _client = MongoClient(CONNECTION_STRING)
    _collection = _client[DATABASE_NAME][COLLECTION_NAME]
    return _collection


def _serialize(document):
    if document is None:
        return None
    return {key: value for key, value in document.items() if key != "_id"}


def ping():
    collection = _get_collection()
    collection.database.client.admin.command("ping")


def list_tasks():
    collection = _get_collection()
    return [_serialize(task) for task in collection.find({})]


def get_task(task_id):
    collection = _get_collection()
    return _serialize(collection.find_one({"id": task_id}))


def create_task(title, description=""):
    collection = _get_collection()
    task = {
        "id": str(uuid.uuid4()),
        "title": title,
        "description": description,
        "completed": False,
    }
    collection.insert_one(task)
    return _serialize(task)


def update_task(task_id, title=None, description=None, completed=None):
    collection = _get_collection()
    existing = collection.find_one({"id": task_id})
    if not existing:
        return None

    updates = {}
    if title is not None:
        updates["title"] = title
    if description is not None:
        updates["description"] = description
    if completed is not None:
        updates["completed"] = completed

    if not updates:
        return _serialize(existing)

    updated = collection.find_one_and_update(
        {"id": task_id},
        {"$set": updates},
        return_document=True,
    )
    return _serialize(updated)


def delete_task(task_id):
    collection = _get_collection()
    result = collection.delete_one({"id": task_id})
    return result.deleted_count > 0


def is_connection_error(error):
    return isinstance(error, PyMongoError)
