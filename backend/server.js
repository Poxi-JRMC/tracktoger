require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { connect } = require('./db');

const usuariosRouter = require('./routes/usuarios');
const alquileresRouter = require('./routes/alquileres');
const pagosRouter = require('./routes/pagos');
const analisisRouter = require('./routes/analisis');
const registrosMantenimientoRouter = require('./routes/registros-mantenimiento');
const { createRouter } = require('./routes/generic');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: '10mb' }));

app.use('/api/usuarios', usuariosRouter);
app.use('/api/roles', createRouter('roles'));
app.use('/api/permisos', createRouter('permisos'));
app.use('/api/maquinaria', createRouter('maquinaria'));
app.use('/api/herramientas', createRouter('herramientas'));
app.use('/api/gastos-operativos', createRouter('gastos_operativos'));
app.use('/api/clientes', createRouter('clientes'));
app.use('/api/alquileres', alquileresRouter);
app.use('/api/pagos', pagosRouter);
app.use('/api/analisis', analisisRouter);
app.use('/api/registros-mantenimiento', registrosMantenimientoRouter);

app.get('/api/health', (req, res) => {
  res.json({ ok: true, message: 'Tracktoger API' });
});

async function start() {
  try {
    await connect();
    app.listen(PORT, () => {
      console.log(`🚀 API Tracktoger corriendo en http://localhost:${PORT}`);
      console.log(`   Endpoints: /api/usuarios, /api/alquileres, /api/maquinaria, etc.`);
    });
  } catch (e) {
    console.error('❌ Error al iniciar:', e.message);
    process.exit(1);
  }
}

start();
