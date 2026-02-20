const express = require('express');
const { ObjectId } = require('mongodb');
const router = express.Router();
const { getDb, toResponse } = require('../db');

const idField = 'idMaquinaria'; // Flutter usa idMaquinaria

router.get('/', async (req, res) => {
  try {
    const col = getDb().collection('registros_mantenimiento');
    const filter = {};
    if (req.query.maquinariaId) filter[idField] = req.query.maquinariaId;
    if (req.query.estado) filter.estado = req.query.estado;
    const list = await col.find(filter).toArray();
    res.json(list.map(toResponse));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.get('/maquinaria/:maquinariaId', async (req, res) => {
  try {
    const col = getDb().collection('registros_mantenimiento');
    const list = await col.find({ [idField]: req.params.maquinariaId }).toArray();
    res.json(list.map(toResponse));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.get('/estado/:estado', async (req, res) => {
  try {
    const col = getDb().collection('registros_mantenimiento');
    const list = await col.find({ estado: req.params.estado }).toArray();
    res.json(list.map(toResponse));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const col = getDb().collection('registros_mantenimiento');
    const doc = await col.findOne({ _id: new ObjectId(req.params.id) });
    res.json(toResponse(doc));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const col = getDb().collection('registros_mantenimiento');
    const body = { ...req.body };
    if (body.maquinariaId && !body.idMaquinaria) body.idMaquinaria = body.maquinariaId;
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
    const col = getDb().collection('registros_mantenimiento');
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
    const col = getDb().collection('registros_mantenimiento');
    const result = await col.deleteOne({ _id: new ObjectId(req.params.id) });
    res.json({ ok: result.deletedCount > 0 });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
