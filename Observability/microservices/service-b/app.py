#!/usr/bin/env python3
"""
Service B - wywołuje service-c
Python/Flask z OpenTelemetry
"""

import os
import json
import logging
import time
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
    "service.name": "service-b",
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
SERVICE_C_URL = os.getenv("SERVICE_C_URL", "http://service-c.default.svc.cluster.local:8080")

def log_structured(level, message, **kwargs):
    """Helper do strukturalnego logowania"""
    log_entry = {
        "timestamp": datetime.utcnow().isoformat(),
        "level": level,
        "message": message,
        "service": "service-b",
        **kwargs
    }
    logger.info(json.dumps(log_entry))

@app.route('/')
def index():
    """Strona główna"""
    with tracer.start_as_current_span("service-b.index") as span:
        span.set_attribute("http.method", "GET")
        span.set_attribute("http.route", "/")
        
        log_structured("INFO", "Service B index accessed", endpoint="/")
        
        return jsonify({
            "service": "service-b",
            "message": "Service B - Validation Service",
            "endpoints": {
                "/api/validate": "Validate order (calls service-c)",
                "/api/user": "Get user info",
                "/health": "Health check"
            }
        })

@app.route('/api/validate')
def validate_order():
    """Waliduje zamówienie - wywołuje service-c"""
    with tracer.start_as_current_span("service-b.validate_order") as span:
        span.set_attribute("http.method", "GET")
        span.set_attribute("http.route", "/api/validate")
        
        order_id = request.args.get('order_id', 'unknown')
        source = request.args.get('source', 'unknown')
        span.set_attribute("order.id", order_id)
        span.set_attribute("request.source", source)
        
        log_structured("INFO", "Validating order", order_id=order_id, source=source)
        
        # Symulacja walidacji lokalnej
        with tracer.start_as_current_span("service-b.local_validation") as local_span:
            local_span.set_attribute("validation.type", "local")
            time.sleep(0.1)  # Symulacja czasu przetwarzania
            local_span.set_attribute("validation.result", "passed")
        
        try:
            # Wywołaj service-c z propagacją trace context
            headers = {}
            inject(headers)
            
            with tracer.start_as_current_span("service-b.call_service_c") as call_span:
                call_span.set_attribute("http.method", "GET")
                call_span.set_attribute("http.url", f"{SERVICE_C_URL}/api/complete")
                call_span.set_attribute("peer.service", "service-c")
                
                response = requests.get(
                    f"{SERVICE_C_URL}/api/complete",
                    params={"order_id": order_id, "source": f"service-b->{source}"},
                    headers=headers,
                    timeout=10
                )
                
                call_span.set_attribute("http.status_code", response.status_code)
                
                if response.status_code == 200:
                    data = response.json()
                    span.set_attribute("order.status", "validated")
                    
                    result = {
                        "service": "service-b",
                        "order_id": order_id,
                        "status": "validated",
                        "timestamp": datetime.utcnow().isoformat(),
                        "chain": data
                    }
                    
                    log_structured(
                        "INFO",
                        "Order validated successfully",
                        order_id=order_id,
                        service_c_response=data
                    )
                    
                    return jsonify(result)
                else:
                    span.set_attribute("order.status", "error")
                    span.set_attribute("error", True)
                    return jsonify({"error": "Failed to validate order"}), 500
                    
        except Exception as e:
            span.set_attribute("error", True)
            span.set_attribute("error.message", str(e))
            log_structured("ERROR", "Failed to validate order", error=str(e), order_id=order_id)
            return jsonify({"error": str(e)}), 500

@app.route('/api/user')
def get_user():
    """Pobiera informacje o użytkowniku"""
    with tracer.start_as_current_span("service-b.get_user") as span:
        span.set_attribute("http.method", "GET")
        span.set_attribute("http.route", "/api/user")
        
        user_id = request.args.get('user_id', 'user-123')
        span.set_attribute("user.id", user_id)
        
        log_structured("INFO", "Getting user info", user_id=user_id)
        
        # Symulacja pobrania danych użytkownika
        user_data = {
            "user_id": user_id,
            "name": f"User {user_id}",
            "email": f"{user_id}@example.com",
            "status": "active"
        }
        
        span.set_attribute("user.found", True)
        
        return jsonify({
            "service": "service-b",
            "user": user_data,
            "timestamp": datetime.utcnow().isoformat()
        })

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "service": "service-b",
        "timestamp": datetime.utcnow().isoformat()
    }), 200

if __name__ == '__main__':
    log_structured("INFO", "Starting service-b", port=8080, service_c_url=SERVICE_C_URL)
    app.run(host='0.0.0.0', port=8080, debug=False)

