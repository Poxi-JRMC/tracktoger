const express = require('express');
const { ObjectId } = require('mongodb');
const router = express.Router();
const { getDb, toResponse } = require('../db');

router.get('/', async (req, res) => {
  try {
    const col = getDb().collection('analisis');
    const filter = {};
    if (req.query.maquinariaId) filter.maquinariaId = req.query.maquinariaId;
    if (req.query.resultado) filter.resultado = req.query.resultado;
    const list = await col.find(filter).toArray();
    res.json(list.map(toResponse));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.get('/maquinaria/:maquinariaId', async (req, res) => {
  try {
    const col = getDb().collection('analisis');
    const list = await col.find({ maquinariaId: req.params.maquinariaId }).toArray();
    res.json(list.map(toResponse));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.get('/resultado/:resultado', async (req, res) => {
  try {
    const col = getDb().collection('analisis');
    const list = await col.find({ resultado: req.params.resultado }).toArray();
    res.json(list.map(toResponse));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const col = getDb().collection('analisis');
    const doc = await col.findOne({ _id: new ObjectId(req.params.id) });
    res.json(toResponse(doc));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const col = getDb().collection('analisis');
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
    const col = getDb().collection('analisis');
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
    const col = getDb().collection('analisis');
    const result = await col.deleteOne({ _id: new ObjectId(req.params.id) });
    res.json({ ok: result.deletedCount > 0 });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
