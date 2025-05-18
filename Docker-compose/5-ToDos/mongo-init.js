db = db.getSiblingDB('admin');

db.createUser({
  user: 'root',
  pwd: 'password',
  roles: [
    { role: 'userAdminAnyDatabase', db: 'admin' },
    { role: 'readWriteAnyDatabase', db: 'admin' },
    { role: 'dbAdminAnyDatabase', db: 'admin' }
  ]
});

db = db.getSiblingDB('todos');
db.createCollection('todos'); 