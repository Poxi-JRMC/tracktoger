# Tracktoger API

API REST para la aplicación Tracktoger. Conecta la app Flutter con MongoDB Atlas, evitando las limitaciones de conexión directa desde móvil.

## Requisitos

- Node.js 18+
- MongoDB Atlas (misma base de datos que usa la app)

## Instalación

```bash
cd backend
npm install
```

## Configuración

Crea un archivo `.env` en la carpeta `backend/` con:

```
PORT=3000
MONGO_URI=mongodb+srv://usuario:password@cluster.mongodb.net/tracktoger?retryWrites=true&w=majority
```

(O usa `MONGO_DB_URL` con la misma URL que tienes en el .env de la app)

## Ejecutar

```bash
npm start
```

La API estará en `http://localhost:3000`

## Endpoints

- `GET /api/health` - Verificar que la API responde
- `GET/POST/PUT/DELETE /api/usuarios`
- `GET/POST/PUT/DELETE /api/roles`
- `GET/POST/PUT/DELETE /api/maquinaria`
- `GET/POST/PUT/DELETE /api/clientes`
- `GET/POST/PUT/DELETE /api/alquileres`
- `GET/POST/PUT/DELETE /api/pagos`
- `GET/POST/PUT/DELETE /api/analisis`
- `GET/POST/PUT/DELETE /api/registros-mantenimiento`
- `GET/POST/PUT/DELETE /api/herramientas`
- `GET/POST/PUT/DELETE /api/gastos-operativos`

## Configurar la app Flutter

En el archivo `.env` de la raíz del proyecto Flutter, añade:

```
API_BASE_URL=http://10.0.2.2:3000
```

- **Emulador Android**: usa `http://10.0.2.2:3000` (10.0.2.2 = localhost del PC)
- **Dispositivo físico**: usa la IP de tu PC, ej: `http://192.168.1.100:3000`
- **Producción**: la URL de tu servidor desplegado

Si `API_BASE_URL` está definida, la app usará la API en lugar de conectar directamente a MongoDB.
