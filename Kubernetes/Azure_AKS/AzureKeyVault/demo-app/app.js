const express = require('express');
const fs = require('fs');
const app = express();
const port = process.env.PORT || 3000;

// Ścieżka do secretów montowanych przez CSI Driver
const SECRETS_PATH = '/mnt/secrets';

app.get('/', (req, res) => {
  res.send(`
    <html>
      <head>
        <title>Azure Key Vault Demo</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f0f0; }
          .container { background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
          h1 { color: #0078d4; }
          .secret-box { background-color: #e8f4fd; padding: 15px; margin: 10px 0; border-left: 4px solid #0078d4; }
          .success { color: #107c10; }
          .error { color: #d13438; }
          code { background-color: #f5f5f5; padding: 2px 6px; border-radius: 3px; }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>🔐 Azure Key Vault - Demo Aplikacji</h1>
          <p>Aplikacja używa Azure Key Vault do bezpiecznego przechowywania secretów.</p>
          
          <h2>Status połączenia z Key Vault</h2>
          <div class="secret-box">
            <p><strong>Metoda:</strong> Secrets Store CSI Driver + Workload Identity</p>
            <p><strong>Ścieżka montowania:</strong> <code>${SECRETS_PATH}</code></p>
          </div>

          <h2>📋 Dostępne sekrety:</h2>
          ${getSecretsInfo()}

          <h2>🌍 Zmienne środowiskowe:</h2>
          ${getEnvVarsInfo()}

          <hr>
          <p><em>Wszystkie sekrety są bezpiecznie pobierane z Azure Key Vault</em></p>
        </div>
      </body>
    </html>
  `);
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.get('/secrets', (req, res) => {
  const secrets = readSecretsFromFiles();
  res.json({
    status: 'success',
    secretsPath: SECRETS_PATH,
    availableSecrets: Object.keys(secrets),
    message: 'Sekrety zostały pomyślnie odczytane z Key Vault'
  });
});

function readSecretsFromFiles() {
  const secrets = {};
  
  try {
    if (fs.existsSync(SECRETS_PATH)) {
      const files = fs.readdirSync(SECRETS_PATH);
      
      files.forEach(file => {
        try {
          const filePath = `${SECRETS_PATH}/${file}`;
          const stat = fs.statSync(filePath);
          
          if (stat.isFile()) {
            const content = fs.readFileSync(filePath, 'utf8');
            // Nie pokazujemy pełnej wartości ze względów bezpieczeństwa
            secrets[file] = {
              length: content.length,
              preview: content.substring(0, 4) + '***',
              available: true
            };
          }
        } catch (err) {
          secrets[file] = { error: err.message, available: false };
        }
      });
    }
  } catch (err) {
    console.error('Błąd odczytu secretów:', err);
  }
  
  return secrets;
}

function getSecretsInfo() {
  const secrets = readSecretsFromFiles();
  const secretKeys = Object.keys(secrets);
  
  if (secretKeys.length === 0) {
    return '<div class="secret-box error">⚠️ Brak zamontowanych secretów</div>';
  }
  
  let html = '';
  secretKeys.forEach(key => {
    const secret = secrets[key];
    if (secret.available) {
      html += `
        <div class="secret-box success">
          <strong>✅ ${key}</strong><br>
          Długość: ${secret.length} znaków<br>
          Podgląd: <code>${secret.preview}</code>
        </div>
      `;
    } else {
      html += `
        <div class="secret-box error">
          <strong>❌ ${key}</strong><br>
          Błąd: ${secret.error}
        </div>
      `;
    }
  });
  
  return html;
}

function getEnvVarsInfo() {
  const envVars = ['DB_PASSWORD', 'API_KEY', 'NODE_ENV', 'HOSTNAME'];
  let html = '<ul>';
  
  envVars.forEach(varName => {
    const value = process.env[varName];
    if (value) {
      const preview = value.length > 20 ? value.substring(0, 8) + '***' : value.substring(0, 4) + '***';
      html += `<li><strong>${varName}:</strong> <code>${preview}</code> (długość: ${value.length})</li>`;
    } else {
      html += `<li><strong>${varName}:</strong> <em>nie ustawiona</em></li>`;
    }
  });
  
  html += '</ul>';
  return html;
}

app.listen(port, () => {
  console.log(`🚀 Aplikacja uruchomiona na porcie ${port}`);
  console.log(`📁 Ścieżka do secretów: ${SECRETS_PATH}`);
  
  // Sprawdź dostępne sekrety przy starcie
  const secrets = readSecretsFromFiles();
  console.log(`🔐 Znaleziono secretów: ${Object.keys(secrets).length}`);
  Object.keys(secrets).forEach(key => {
    console.log(`   - ${key}: ${secrets[key].available ? '✅' : '❌'}`);
  });
});

