from flask import Flask, request, jsonify
from sqlalchemy import create_engine, Column, Integer, String, Boolean, Float
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
import time
from sqlalchemy.exc import OperationalError

app = Flask(__name__)

# Konfiguracja bazy danych
DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@db:5432/shoppingdb')

def init_db():
    max_retries = 5
    retry_interval = 5
    
    for attempt in range(max_retries):
        try:
            engine = create_engine(DATABASE_URL)
            Session = sessionmaker(bind=engine)
            Base = declarative_base()
            
            # Model ShoppingItem
            class ShoppingItem(Base):
                __tablename__ = 'shopping_items'
                id = Column(Integer, primary_key=True)
                name = Column(String(100), nullable=False)
                quantity = Column(Float, default=1.0)
                unit = Column(String(20), default='szt.')
                bought = Column(Boolean, default=False)
                price = Column(Float, nullable=True)
            
            # Tworzenie tabel
            Base.metadata.create_all(engine)
            return engine, Session, Base, ShoppingItem
            
        except OperationalError:
            if attempt < max_retries - 1:
                print(f"Nie można połączyć się z bazą danych. Próba {attempt + 1} z {max_retries}. Czekam {retry_interval} sekund...")
                time.sleep(retry_interval)
            else:
                raise

engine, Session, Base, ShoppingItem = init_db()

@app.route('/items', methods=['GET'])
def get_items():
    session = Session()
    items = session.query(ShoppingItem).all()
    return jsonify([{
        'id': item.id,
        'name': item.name,
        'quantity': item.quantity,
        'unit': item.unit,
        'bought': item.bought,
        'price': item.price
    } for item in items])

@app.route('/items', methods=['POST'])
def create_item():
    data = request.get_json()
    session = Session()
    item = ShoppingItem(
        name=data['name'],
        quantity=data.get('quantity', 1.0),
        unit=data.get('unit', 'szt.'),
        price=data.get('price')
    )
    session.add(item)
    session.commit()
    return jsonify({
        'id': item.id,
        'name': item.name,
        'quantity': item.quantity,
        'unit': item.unit,
        'bought': item.bought,
        'price': item.price
    }), 201

@app.route('/items/<int:item_id>', methods=['PUT'])
def update_item(item_id):
    data = request.get_json()
    session = Session()
    item = session.query(ShoppingItem).get(item_id)
    if item:
        item.name = data.get('name', item.name)
        item.quantity = data.get('quantity', item.quantity)
        item.unit = data.get('unit', item.unit)
        item.bought = data.get('bought', item.bought)
        item.price = data.get('price', item.price)
        session.commit()
        return jsonify({
            'id': item.id,
            'name': item.name,
            'quantity': item.quantity,
            'unit': item.unit,
            'bought': item.bought,
            'price': item.price
        })
    return jsonify({'error': 'Item not found'}), 404

@app.route('/items/<int:item_id>', methods=['DELETE'])
def delete_item(item_id):
    session = Session()
    item = session.query(ShoppingItem).get(item_id)
    if item:
        session.delete(item)
        session.commit()
        return '', 204
    return jsonify({'error': 'Item not found'}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000) 