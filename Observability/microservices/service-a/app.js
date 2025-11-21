/**
 * Service A - wywołuje service-b
 * Node.js/Express z OpenTelemetry
 */

const express = require('express');
const axios = require('axios');
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-otlp-grpc');

// Konfiguracja OpenTelemetry
const tempoEndpoint = process.env.TEMPO_ENDPOINT || 'http://tempo.monitoring.svc.cluster.local:4317';

const sdk = new NodeSDK({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'service-a',
    [SemanticResourceAttributes.SERVICE_VERSION]: '1.0.0',
    'deployment.environment': process.env.ENVIRONMENT || 'development',
  }),
  traceExporter: new OTLPTraceExporter({
    url: tempoEndpoint,
  }),
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();

const app = express();
app.use(express.json());

// Konfiguracja backendów
const SERVICE_B_URL = process.env.SERVICE_B_URL || 'http://service-b.default.svc.cluster.local:8080';

const log = (level, message, ...args) => {
  const logEntry = {
    timestamp: new Date().toISOString(),
    level,
    message,
    service: 'service-a',
    ...args
  };
  console.log(JSON.stringify(logEntry));
};

app.get('/', (req, res) => {
  log('INFO', 'Service A index accessed', { endpoint: '/' });
  res.json({
    service: 'service-a',
    message: 'Service A - Middleware Service',
    endpoints: {
      '/api/process': 'Process order (calls service-b -> service-c)',
      '/api/user': 'Get user info',
      '/health': 'Health check'
    }
  });
});

app.get('/api/process', async (req, res) => {
  const orderId = req.query.order_id || `order-${Date.now()}`;
  const source = req.query.source || 'unknown';
  
  log('INFO', 'Processing order', { order_id: orderId, source });

  try {
    // Wywołaj service-b z propagacją trace context
    const response = await axios.get(`${SERVICE_B_URL}/api/validate`, {
      params: {
        order_id: orderId,
        source: `service-a->${source}`
      },
      timeout: 10000,
      // Axios automatycznie propaguje trace context przez auto-instrumentation
    });

    const result = {
      service: 'service-a',
      order_id: orderId,
      status: 'processed',
      timestamp: new Date().toISOString(),
      chain: response.data
    };

    log('INFO', 'Order processed successfully', { order_id: orderId });
    res.json(result);

  } catch (error) {
    log('ERROR', 'Failed to process order', { 
      order_id: orderId, 
      error: error.message,
      stack: error.stack 
    });
    res.status(500).json({
      service: 'service-a',
      error: error.message,
      order_id: orderId
    });
  }
});

app.get('/api/user', async (req, res) => {
  const userId = req.query.user_id || 'user-123';
  
  log('INFO', 'Getting user info', { user_id: userId });

  try {
    // Wywołaj service-b
    const response = await axios.get(`${SERVICE_B_URL}/api/user`, {
      params: { user_id: userId },
      timeout: 10000,
    });

    const result = {
      service: 'service-a',
      user_info: response.data,
      timestamp: new Date().toISOString()
    };

    log('INFO', 'User info retrieved', { user_id: userId });
    res.json(result);

  } catch (error) {
    log('ERROR', 'Failed to get user', { 
      user_id: userId, 
      error: error.message 
    });
    res.status(500).json({
      service: 'service-a',
      error: error.message,
      user_id: userId
    });
  }
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'service-a',
    timestamp: new Date().toISOString()
  });
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  log('INFO', 'Service A started', { 
    port: PORT, 
    service_b_url: SERVICE_B_URL,
    tempo_endpoint: tempoEndpoint 
  });
});

