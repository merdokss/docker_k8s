const express = require("express");
const cors = require('cors');
const mongoose = require("mongoose");
const port = process.env.PORT || 3001;
const routes = require("./routes");

// Konfiguracja połączenia z bazą danych
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://mongo:27017/todos';

main().catch((err) => console.log(err));

async function main() {
  try {
    await mongoose.connect(MONGODB_URI, {
      useUnifiedTopology: true,
      useNewUrlParser: true,
    });
    console.log('Połączono z MongoDB');
    
    const app = express();
    app.use(cors());
    app.use(express.json());
    app.use("/api", routes);

    app.listen(port, () => {
      console.log(`Server is listening on port: ${port}`);
    });
  } catch (error) {
    console.error('Błąd połączenia z MongoDB:', error);
    process.exit(1);
  }
}
