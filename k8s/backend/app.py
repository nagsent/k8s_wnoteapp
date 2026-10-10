from contextlib import closing
import os

import psycopg2
from flask import Flask, jsonify, request
from prometheus_client import CONTENT_TYPE_LATEST, Counter, generate_latest

app = Flask(__name__)
REQUEST_COUNT = Counter(
    "notes_api_requests_total",
    "Total API Requests",
    ["method", "endpoint"],
)


@app.before_request
def before_request():
    REQUEST_COUNT.labels(method=request.method, endpoint=request.path).inc()


@app.route("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


def get_conn():
    connection_options = {
        "host": os.getenv("DB_HOST", "localhost"),
        "dbname": os.getenv("DB_NAME", "notesdb"),
        "user": os.getenv("DB_USER", "notesuser"),
    }
    connection_options["password"] = os.getenv("DB_PASSWORD", "securepass")
    return psycopg2.connect(**connection_options)


def ensure_notes_table(conn):
    with conn.cursor() as cur:
        cur.execute(
            "CREATE TABLE IF NOT EXISTS notes "
            "(id SERIAL PRIMARY KEY, content TEXT NOT NULL);"
        )


@app.route("/api/notes", methods=["GET"])
def list_notes():
    with closing(get_conn()) as conn, conn:
        ensure_notes_table(conn)
        with conn.cursor() as cur:
            cur.execute("SELECT id, content FROM notes ORDER BY id DESC;")
            rows = cur.fetchall()
    return jsonify([{"id": row[0], "content": row[1]} for row in rows])


@app.route("/api/notes", methods=["POST"])
def create_note():
    data = request.get_json(silent=True)
    content = data.get("content") if isinstance(data, dict) else None
    if not isinstance(content, str) or not content.strip():
        return jsonify({"error": "content required"}), 400
    content = content.strip()

    with closing(get_conn()) as conn, conn:
        ensure_notes_table(conn)
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO notes (content) VALUES (%s) RETURNING id;",
                (content,),
            )
            note_id = cur.fetchone()[0]
    return jsonify({"id": note_id, "content": content}), 201


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
