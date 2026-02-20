# Guía de Despliegue - Tracktoger

Guía paso a paso para subir a GitHub, desplegar la API en Render y compilar el APK.

---

## PARTE 1: Subir a GitHub

### Paso 1.1 - Inicializar Git (si no lo has hecho)

Abre PowerShell en la carpeta del proyecto y ejecuta:

```powershell
cd C:\Users\POXIFLOW\Documents\TRABAJOS\proyectoFINAL\hoy\tracktoger

git init
```

### Paso 1.2 - Crear archivo .env.example

Crea un archivo `.env.example` en la raíz con esto (sin credenciales reales):

```
MONGO_DB_URL=mongodb+srv://usuario:password@cluster.mongodb.net/tracktoger
API_BASE_URL=https://TU-API.onrender.com
```

### Paso 1.3 - Añadir y hacer commit

```powershell
git add .
git status
git commit -m "Tracktoger - Proyecto completo con API backend"
```

### Paso 1.4 - Crear repositorio en GitHub

1. Ve a https://github.com/new
2. Nombre: `tracktoger`
3. Descripción opcional
4. **No** marques "Add README"
5. Clic en **Create repository**

### Paso 1.5 - Conectar y subir

Copia la URL de tu repo (ej: `https://github.com/TU_USUARIO/tracktoger.git`) y ejecuta:

```powershell
git remote add origin https://github.com/TU_USUARIO/tracktoger.git
git branch -M main
git push -u origin main
```

(Te pedirá usuario y contraseña/token de GitHub)

---

## PARTE 2: Desplegar API en Render

### Paso 2.1 - Crear cuenta

1. Ve a https://render.com
2. Regístrate con **Sign up with GitHub**
3. Autoriza a Render a acceder a tus repositorios

### Paso 2.2 - Crear Web Service

1. Dashboard → **New +** → **Web Service**
2. Conecta el repositorio **tracktoger**
3. Configuración:
   - **Name:** `tracktoger-api`
   - **Region:** Oregon (o la más cercana)
   - **Root Directory:** `backend` ← importante
   - **Runtime:** Node
   - **Build Command:** `npm install`
   - **Start Command:** `npm start`
   - **Instance Type:** Free

### Paso 2.3 - Variables de entorno

En **Environment Variables** → Add Environment Variable:

- **Key:** `MONGO_URI`
- **Value:** Tu URL completa de MongoDB Atlas (la misma que tienes en backend/.env)
  ```
  mongodb+srv://johanutb_db_user:TU_PASSWORD@cluster0.xl6k3iu.mongodb.net/tracktoger?retryWrites=true&w=majority
  ```

### Paso 2.4 - Crear servicio

Clic en **Create Web Service**. Render empezará a desplegar (2-5 min).

### Paso 2.5 - Obtener la URL

Cuando termine, verás algo como:
```
https://tracktoger-api.onrender.com
```
Copia esa URL (será tu API_BASE_URL).

---

## PARTE 3: Configurar la app y compilar APK

### Paso 3.1 - Actualizar .env

Edita el archivo `.env` en la raíz del proyecto:

```
MONGO_DB_URL=mongodb+srv://... (puedes dejarlo o quitarlo)
API_BASE_URL=https://tracktoger-api.onrender.com
```

**Importante:** Usa la URL exacta que te dio Render (con https://).

Con esta configuración:
- ✅ Emulador en tu PC → conecta a Render
- ✅ Teléfono físico → conecta a Render
- ✅ No necesitas tener el backend corriendo en tu PC

### Paso 3.2 - Compilar el APK

```powershell
cd C:\Users\POXIFLOW\Documents\TRABAJOS\proyectoFINAL\hoy\tracktoger

flutter clean
flutter pub get
flutter build apk --release
```

El APK se generará en:
```
build\app\outputs\flutter-apk\app-release.apk
```

### Paso 3.3 - Instalar en tu teléfono

1. Copia `app-release.apk` a tu teléfono (USB, Drive, etc.)
2. En el teléfono: abre el archivo e instala (permite "Fuentes desconocidas" si lo pide)
3. Asegúrate de tener **internet** en el móvil

---

## PARTE 4: Desarrollar en tu PC (opcional)

Si quieres probar con el backend local mientras desarrollas:

1. Comenta o borra temporalmente `API_BASE_URL` del `.env` → la app usará MongoDB directo
2. O deja `API_BASE_URL` con la URL de Render → siempre usará la API en la nube (más fácil)

Para desarrollo con backend local:
- `.env` con `API_BASE_URL=http://10.0.2.2:3000`
- Inicia el backend: `cd backend && npm start`
- Ejecuta la app: `flutter run`

---

## Resumen rápido

| Acción | Comando / Dónde |
|--------|-----------------|
| Subir a GitHub | `git add .` → `git commit` → `git push` |
| Desplegar API | Render.com → New Web Service → Root: `backend` |
| Variable en Render | `MONGO_URI` = tu cadena de MongoDB |
| URL de la API | `https://tracktoger-api.onrender.com` (ejemplo) |
| Actualizar app | `.env` → `API_BASE_URL=https://tu-url.onrender.com` |
| Compilar APK | `flutter build apk --release` |
