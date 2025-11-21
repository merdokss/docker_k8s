#!/usr/bin/env python3
"""
Frontend Service - wywołuje service-a
Demonstruje distributed tracing z OpenTelemetry
"""

import os
import json
import logging
import requests
from datetime import datetime
from flask import Flask, jsonify, request
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.resources import Resource
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.propagate import inject

# Konfiguracja OpenTelemetry
resource = Resource.create({
    "service.name": "frontend-service",
    "service.version": "1.0.0",
    "deployment.environment": os.getenv("ENVIRONMENT", "development")
})

trace.set_tracer_provider(TracerProvider(resource=resource))

# Tempo endpoint (gRPC OTLP)
tempo_endpoint = os.getenv("TEMPO_ENDPOINT", "http://tempo.monitoring.svc.cluster.local:4317")
otlp_exporter = OTLPSpanExporter(endpoint=tempo_endpoint)

trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(otlp_exporter)
)

tracer = trace.get_tracer(__name__)

# Konfiguracja logowania
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

# Konfiguracja backendów
SERVICE_A_URL = os.getenv("SERVICE_A_URL", "http://service-a.default.svc.cluster.local:8080")

def log_structured(level, message, **kwargs):
    """Helper do strukturalnego logowania"""
    log_entry = {
        "timestamp": datetime.utcnow().isoformat(),
        "level": level,
        "message": message,
        "service": "frontend-service",
        **kwargs
    }
    logger.info(json.dumps(log_entry))

@app.route('/')
def index():
    """Strona główna"""
    with tracer.start_as_current_span("frontend.index") as span:
        span.set_attribute("http.method", "GET")
        span.set_attribute("http.route", "/")
        
        log_structured("INFO", "Frontend index accessed", endpoint="/")
        
        return jsonify({
            "service": "frontend-service",
            "message": "Frontend Service - Distributed Tracing Demo",
            "endpoints": {
                "/api/order": "Create order (calls service-a -> service-b -> service-c)",
                "/api/user": "Get user info (calls service-a)",
                "/api/health": "Health check"
            }
        })

@app.route('/api/order')
def create_order():
    """Tworzy zamówienie - wywołuje service-a"""
    with tracer.start_as_current_span("frontend.create_order") as span:
        span.set_attribute("http.method", "GET")
        span.set_attribute("http.route", "/api/order")
        
        order_id = request.args.get('order_id', f"order-{datetime.utcnow().timestamp()}")
        span.set_attribute("order.id", order_id)
        
        log_structured("INFO", "Creating order", order_id=order_id)
        
        try:
            # Wywołaj service-a z propagacją trace context
            headers = {}
            inject(headers)  # Dodaj trace context do headers
            
            with tracer.start_as_current_span("frontend.call_service_a") as call_span:
                call_span.set_attribute("http.method", "GET")
                call_span.set_attribute("http.url", f"{SERVICE_A_URL}/api/process")
                call_span.set_attribute("peer.service", "service-a")
                
                response = requests.get(
                    f"{SERVICE_A_URL}/api/process",
                    params={"order_id": order_id, "source": "frontend"},
                    headers=headers,
                    timeout=10
                )
                
                call_span.set_attribute("http.status_code", response.status_code)
                
                if response.status_code == 200:
                    data = response.json()
                    span.set_attribute("order.status", "success")
                    
                    log_structured(
                        "INFO",
                        "Order created successfully",
                        order_id=order_id,
                        service_a_response=data
                    )
                    
                    return jsonify({
                        "service": "frontend-service",
                        "order_id": order_id,
                        "status": "created",
                        "chain": data,
                        "timestamp": datetime.utcnow().isoformat()
                    })
                else:
                    span.set_attribute("order.status", "error")
                    span.set_attribute("error", True)
                    return jsonify({"error": "Failed to create order"}), 500
                    
        except Exception as e:
            span.set_attribute("error", True)
            span.set_attribute("error.message", str(e))
            log_structured("ERROR", "Failed to create order", error=str(e), order_id=order_id)
            return jsonify({"error": str(e)}), 500

@app.route('/api/user')
def get_user():
    """Pobiera informacje o użytkowniku - wywołuje service-a"""
    with tracer.start_as_current_span("frontend.get_user") as span:
        span.set_attribute("http.method", "GET")
        span.set_attribute("http.route", "/api/user")
        
        user_id = request.args.get('user_id', 'user-123')
        span.set_attribute("user.id", user_id)
        
        log_structured("INFO", "Getting user info", user_id=user_id)
        
        try:
            # Wywołaj service-a z propagacją trace context
            headers = {}
            inject(headers)
            
            with tracer.start_as_current_span("frontend.call_service_a_user") as call_span:
                call_span.set_attribute("http.method", "GET")
                call_span.set_attribute("http.url", f"{SERVICE_A_URL}/api/user")
                call_span.set_attribute("peer.service", "service-a")
                
                response = requests.get(
                    f"{SERVICE_A_URL}/api/user",
                    params={"user_id": user_id},
                    headers=headers,
                    timeout=10
                )
                
                call_span.set_attribute("http.status_code", response.status_code)
                
                if response.status_code == 200:
                    data = response.json()
                    span.set_attribute("user.found", True)
                    
                    return jsonify({
                        "service": "frontend-service",
                        "user_info": data,
                        "timestamp": datetime.utcnow().isoformat()
                    })
                else:
                    span.set_attribute("error", True)
                    return jsonify({"error": "Failed to get user"}), 500
                    
        except Exception as e:
            span.set_attribute("error", True)
            span.set_attribute("error.message", str(e))
            log_structured("ERROR", "Failed to get user", error=str(e), user_id=user_id)
            return jsonify({"error": str(e)}), 500

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "service": "frontend-service",
        "timestamp": datetime.utcnow().isoformat()
    }), 200

if __name__ == '__main__':
    log_structured("INFO", "Starting frontend-service", port=8080, service_a_url=SERVICE_A_URL)
    app.run(host='0.0.0.0', port=8080, debug=False)

