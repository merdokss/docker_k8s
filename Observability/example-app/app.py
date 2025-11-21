#!/usr/bin/env python3
"""
Przykładowa aplikacja demonstrująca metryki, logi i traces
- Prometheus metrics na /metrics
- Structured logs w formacie JSON
- OpenTelemetry traces wysyłane do Tempo
"""

import os
import time
import json
import logging
from datetime import datetime
from flask import Flask, jsonify, request
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.resources import Resource
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor

# Konfiguracja OpenTelemetry
resource = Resource.create({
    "service.name": "example-app",
    "service.version": "1.0.0",
    "deployment.environment": os.getenv("ENVIRONMENT", "development")
})

trace.set_tracer_provider(TracerProvider(resource=resource))

# Tempo endpoint (HTTP OTLP)
tempo_endpoint = os.getenv("TEMPO_ENDPOINT", "http://tempo.monitoring.svc.cluster.local:4317")
otlp_exporter = OTLPSpanExporter(
    endpoint=tempo_endpoint
)

trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(otlp_exporter)
)

tracer = trace.get_tracer(__name__)

# Konfiguracja logowania (strukturalne logi JSON)
logging.basicConfig(
    level=logging.INFO,
    format='%(message)s',
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger(__name__)

# Flask app
app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()

# Prometheus metrics
http_requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

http_request_duration_seconds = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['method', 'endpoint']
)

active_connections = Gauge(
    'active_connections',
    'Number of active connections'
)

business_operations_total = Counter(
    'business_operations_total',
    'Total business operations',
    ['operation_type', 'status']
)

# Stan aplikacji
connections = 0

def log_structured(level, message, **kwargs):
    """Helper do strukturalnego logowania"""
    log_entry = {
        "timestamp": datetime.utcnow().isoformat(),
        "level": level,
        "message": message,
        "service": "example-app",
        **kwargs
    }
    logger.info(json.dumps(log_entry))

@app.route('/')
def index():
    """Strona główna"""
    with tracer.start_as_current_span("index") as span:
        span.set_attribute("http.method", "GET")
        span.set_attribute("http.route", "/")
        
        log_structured("INFO", "Index page accessed", endpoint="/", method="GET")
        http_requests_total.labels(method='GET', endpoint='/', status='200').inc()
        
        return jsonify({
            "message": "Example App - Observability Demo",
            "endpoints": {
                "/api/hello": "Prosty endpoint z logami i traces",
                "/api/calculate": "Endpoint z obliczeniami (generuje metryki)",
                "/api/error": "Endpoint generujący błędy",
                "/metrics": "Prometheus metrics",
                "/health": "Health check"
            }
        })

@app.route('/api/hello')
def hello():
    """Prosty endpoint demonstrujący logi i traces"""
    with tracer.start_as_current_span("hello") as span:
        span.set_attribute("http.method", "GET")
        span.set_attribute("http.route", "/api/hello")
        
        name = request.args.get('name', 'World')
        span.set_attribute("user.name", name)
        
        log_structured(
            "INFO",
            "Hello endpoint called",
            endpoint="/api/hello",
            method="GET",
            user_name=name
        )
        
        http_requests_total.labels(method='GET', endpoint='/api/hello', status='200').inc()
        
        response = {"message": f"Hello, {name}!", "timestamp": datetime.utcnow().isoformat()}
        
        span.set_attribute("response.message", response["message"])
        
        return jsonify(response)

@app.route('/api/calculate')
def calculate():
    """Endpoint z obliczeniami - generuje metryki czasu wykonania"""
    start_time = time.time()
    
    with tracer.start_as_current_span("calculate") as span:
        span.set_attribute("http.method", "GET")
        span.set_attribute("http.route", "/api/calculate")
        
        # Symulacja obliczeń
        numbers = request.args.getlist('numbers', type=int)
        if not numbers:
            numbers = [1, 2, 3, 4, 5]
        
        span.set_attribute("input.numbers_count", len(numbers))
        
        log_structured(
            "INFO",
            "Calculate endpoint called",
            endpoint="/api/calculate",
            method="GET",
            numbers_count=len(numbers)
        )
        
        # Wykonaj obliczenia
        with tracer.start_as_current_span("computation") as comp_span:
            result = sum(numbers)
            avg = result / len(numbers) if numbers else 0
            comp_span.set_attribute("result.sum", result)
            comp_span.set_attribute("result.average", avg)
        
        duration = time.time() - start_time
        
        http_request_duration_seconds.labels(method='GET', endpoint='/api/calculate').observe(duration)
        http_requests_total.labels(method='GET', endpoint='/api/calculate', status='200').inc()
        business_operations_total.labels(operation_type='calculation', status='success').inc()
        
        span.set_attribute("result.sum", result)
        span.set_attribute("result.average", avg)
        span.set_attribute("duration", duration)
        
        log_structured(
            "INFO",
            "Calculation completed",
            endpoint="/api/calculate",
            result=result,
            average=avg,
            duration=duration
        )
        
        return jsonify({
            "numbers": numbers,
            "sum": result,
            "average": avg,
            "duration_seconds": duration
        })

@app.route('/api/error')
def error():
    """Endpoint generujący błędy - do testowania alertów"""
    with tracer.start_as_current_span("error") as span:
        span.set_attribute("http.method", "GET")
        span.set_attribute("http.route", "/api/error")
        
        error_type = request.args.get('type', 'generic')
        span.set_attribute("error.type", error_type)
        
        log_structured(
            "ERROR",
            "Error endpoint called",
            endpoint="/api/error",
            method="GET",
            error_type=error_type
        )
        
        http_requests_total.labels(method='GET', endpoint='/api/error', status='500').inc()
        business_operations_total.labels(operation_type='error', status='failure').inc()
        
        if error_type == 'timeout':
            time.sleep(5)  # Symulacja timeout
            return jsonify({"error": "Request timeout"}), 500
        elif error_type == 'exception':
            raise Exception("Simulated exception")
        else:
            return jsonify({"error": "Generic error occurred"}), 500

@app.route('/api/connection')
def connection():
    """Endpoint do zarządzania połączeniami - demonstruje Gauge metrics"""
    global connections
    
    with tracer.start_as_current_span("connection") as span:
        action = request.args.get('action', 'connect')
        span.set_attribute("action", action)
        
        if action == 'connect':
            connections += 1
            log_structured("INFO", "Connection established", action="connect", total_connections=connections)
        elif action == 'disconnect':
            connections = max(0, connections - 1)
            log_structured("INFO", "Connection closed", action="disconnect", total_connections=connections)
        
        active_connections.set(connections)
        span.set_attribute("connections.active", connections)
        
        http_requests_total.labels(method='GET', endpoint='/api/connection', status='200').inc()
        
        return jsonify({
            "action": action,
            "active_connections": connections
        })

@app.route('/metrics')
def metrics():
    """Endpoint Prometheus metrics"""
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "timestamp": datetime.utcnow().isoformat()}), 200

if __name__ == '__main__':
    log_structured("INFO", "Starting example-app", port=8080)
    app.run(host='0.0.0.0', port=8080, debug=False)

