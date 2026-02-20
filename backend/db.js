const { MongoClient } = require('mongodb');

let db = null;

async function connect() {
  if (db) return db;
  const uri = process.env.MONGO_URI || process.env.MONGO_DB_URL;
  if (!uri) throw new Error('MONGO_URI o MONGO_DB_URL no está definida');
  const client = new MongoClient(uri);
  await client.connect();
  db = client.db('tracktoger');
  console.log('✅ Conectado a MongoDB');
  return db;
}

function getDb() {
  if (!db) throw new Error('Base de datos no conectada');
  return db;
}

function toResponse(doc) {
  if (!doc) return null;
  const d = { ...doc };
  if (d._id) {
    d.id = d._id.toString();
  }
  return d;
}

module.exports = { connect, getDb, toResponse };
