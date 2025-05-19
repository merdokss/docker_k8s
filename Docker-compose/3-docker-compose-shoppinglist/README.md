```bash
curl -X POST http://localhost:5000/items \
  -H "Content-Type: application/json" \
  -d '{"name": "Nowy produkt", "description": "Opis produktu", "price": 99.99}'
```
```bash
curl http://localhost:5000/items
```