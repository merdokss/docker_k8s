/**
 * Service C - końcowy serwis w łańcuchu
 * Node.js/Express z OpenTelemetry
 */

const express = require('express');
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-otlp-grpc');

// Konfiguracja OpenTelemetry
const tempoEndpoint = process.env.TEMPO_ENDPOINT || 'http://tempo.monitoring.svc.cluster.local:4317';

const sdk = new NodeSDK({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'service-c',
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

const log = (level, message, ...args) => {
  const logEntry = {
    timestamp: new Date().toISOString(),
    level,
    message,
    service: 'service-c',
    ...args
  };
  console.log(JSON.stringify(logEntry));
};

// Symulacja bazy danych lub cache
const orders = new Map();
const users = new Map([
  ['user-123', { id: 'user-123', name: 'John Doe', email: 'john@example.com', tier: 'premium' }],
  ['user-456', { id: 'user-456', name: 'Jane Smith', email: 'jane@example.com', tier: 'standard' }],
]);

app.get('/', (req, res) => {
  log('INFO', 'Service C index accessed', { endpoint: '/' });
  res.json({
    service: 'service-c',
    message: 'Service C - Data Service (Final)',
    endpoints: {
      '/api/complete': 'Complete order processing',
      '/api/user': 'Get user details',
      '/health': 'Health check'
    }
  });
});

app.get('/api/complete', async (req, res) => {
  const orderId = req.query.order_id || `order-${Date.now()}`;
  const source = req.query.source || 'unknown';
  
  log('INFO', 'Completing order', { order_id: orderId, source });

  // Symulacja przetwarzania końcowego
  await new Promise(resolve => setTimeout(resolve, 50 + Math.random() * 100));

  const orderData = {
    order_id: orderId,
    status: 'completed',
    completed_at: new Date().toISOString(),
    items: [
      { id: 'item-1', name: 'Product A', quantity: 2, price: 29.99 },
      { id: 'item-2', name: 'Product B', quantity: 1, price: 49.99 }
    ],
    total: 109.97,
    source_chain: source
  };

  // Zapisz zamówienie
  orders.set(orderId, orderData);

  const result = {
    service: 'service-c',
    order: orderData,
    timestamp: new Date().toISOString(),
    message: 'Order processing completed'
  };

  log('INFO', 'Order completed successfully', { order_id: orderId });
  res.json(result);
});

app.get('/api/user', async (req, res) => {
  const userId = req.query.user_id || 'user-123';
  
  log('INFO', 'Getting user details', { user_id: userId });

  // Symulacja zapytania do bazy danych
  await new Promise(resolve => setTimeout(resolve, 30 + Math.random() * 50));

  const user = users.get(userId) || {
    id: userId,
    name: `User ${userId}`,
    email: `${userId}@example.com`,
    tier: 'standard'
  };

  const result = {
    service: 'service-c',
    user: user,
    timestamp: new Date().toISOString()
  };

  log('INFO', 'User details retrieved', { user_id: userId });
  res.json(result);
});

app.get('/api/orders/:orderId', (req, res) => {
  const orderId = req.params.orderId;
  const order = orders.get(orderId);
  
  if (order) {
    log('INFO', 'Order retrieved', { order_id: orderId });
    res.json({
      service: 'service-c',
      order: order
    });
  } else {
    log('WARN', 'Order not found', { order_id: orderId });
    res.status(404).json({
      service: 'service-c',
      error: 'Order not found',
      order_id: orderId
    });
  }
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'service-c',
    timestamp: new Date().toISOString(),
    stats: {
      orders_processed: orders.size,
      users_cached: users.size
    }
  });
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  log('INFO', 'Service C started', { 
    port: PORT,
    tempo_endpoint: tempoEndpoint 
  });
});

