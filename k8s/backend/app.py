from flask import Flask, request, jsonify
import psycopg2
import os
from prometheus_client import Counter, generate_latest

app = Flask(__name__)

# Metrics
REQUEST_COUNT = Counter("notes_api_requests_total", "Total API Requests", ["method", "endpoint"])

@app.before_request
def before_request():
    REQUEST_COUNT.labels(method=request.method, endpoint=request.path).inc()

@app.route("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": "text/plain"}

