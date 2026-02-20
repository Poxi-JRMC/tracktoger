const express = require('express');
const { ObjectId } = require('mongodb');
const { getDb, toResponse } = require('../db');

function createRouter(collectionName) {
  const router = express.Router();

  router.get('/', async (req, res) => {
    try {
      const col = getDb().collection(collectionName);
      const filter = {};
      if (req.query.soloActivos === 'true') filter.activo = true;
      if (req.query.soloActivas === 'true') filter.activo = true;
      if (req.query.estado) filter.estado = req.query.estado;
      const list = await col.find(filter).toArray();
      res.json(list.map(toResponse));
    } catch (e) {
      res.status(500).json({ error: e.message });
    }
  });

  router.get('/:id', async (req, res) => {
    try {
      const col = getDb().collection(collectionName);
      const doc = await col.findOne({ _id: new ObjectId(req.params.id) });
      res.json(toResponse(doc));
    } catch (e) {
      res.status(500).json({ error: e.message });
    }
  });

  router.post('/', async (req, res) => {
    try {
      const col = getDb().collection(collectionName);
      const body = { ...req.body };
      if (body.id) {
        try { body._id = new ObjectId(body.id); } catch (_) {}
      }
      await col.insertOne(body);
      res.status(201).json(toResponse(body));
    } catch (e) {
      res.status(500).json({ error: e.message });
    }
  });

  router.put('/:id', async (req, res) => {
    try {
      const col = getDb().collection(collectionName);
      const body = { ...req.body };
      delete body._id;
      delete body.id;
      const result = await col.updateOne(
        { _id: new ObjectId(req.params.id) },
        { $set: body }
      );
      res.json({ ok: result.modifiedCount > 0 });
    } catch (e) {
      res.status(500).json({ error: e.message });
    }
  });

  router.delete('/:id', async (req, res) => {
    try {
      const col = getDb().collection(collectionName);
      const result = await col.deleteOne({ _id: new ObjectId(req.params.id) });
      res.json({ ok: result.deletedCount > 0 });
    } catch (e) {
      res.status(500).json({ error: e.message });
    }
  });

  return router;
}

module.exports = { createRouter };
