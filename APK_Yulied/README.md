# TitanFit — Proyecto Final de Clase

**Estudiante:** Yulied Marcela Lopez  
**Programa:** ADSO — SENA  
**Ficha:** 3311983  
**Temática:** Gimnasio  
**Entregable:** APK Android + API REST + SQLite offline con sincronización  

## Qué cumple del enunciado

| Requisito del instructor | Cómo quedó |
|---|---|
| Aplicación propia de la temática Gimnasio | App **TitanFit** |
| Login y Registro | Módulos 1 y 2 |
| Al menos 3 módulos extra | Agendar clase, Gestión admin (confirmar/cancelar), Cancelar reserva (usuario) |
| Perfil administrador y perfil usuario | Roles `administrador` y `cliente` |
| API de backend | Node.js + Express + SQLite en `/api` |
| Offline con SQLite | Base local `titanfit.db` en el celular |
| Sincronización al reconectar | Cola `sync_queue` + `POST /api/sync` |
| Entregable APK | `entregable/TitanFit-YuliedMarcelaLopez.apk` |

Módulos extra de negocio: **Planes / membresías**, **Rutinas** e **Inventario** (admin).

## Cómo arrancar

### 1. API

```bash
cd api
npm install
npm start
```

Queda en `http://0.0.0.0:3000`. En la consola imprime la IP de la red local.

### 2. App (Flutter)

```bash
cd app
flutter pub get
flutter run
```

En **Perfil** pega la URL de la API, por ejemplo `http://192.168.1.21:3000`.  
Si pruebas en emulador Android usa `http://10.0.2.2:3000`.

### 3. Instalar el APK

Copia `entregable/TitanFit-YuliedMarcelaLopez.apk` al teléfono e instálalo (orígenes desconocidos).

## Cuentas de demostración

| Rol | Correo | Clave |
|---|---|---|
| Cliente | `yulied@titanfit.co` | `Yulied123*` |
| Administrador | `admin@titanfit.co` | `Admin123*` |

## Cómo demostrar offline + sync

1. Entra con Yulied o Admin (con o sin API).
2. Activa modo avión.
3. Agenda o cancela una clase: se guarda en SQLite y el banner dice **Modo offline**.
4. Reactiva datos / WiFi y pulsa el banner o **Sincronizar ahora**.
5. Los cambios suben a la API y el resto de datos se descargan.

## Estructura

```
api/                 API REST (Node + SQLite)
app/                 Aplicación Flutter (Android + Linux)
entregable/          APK de entrega
INFORME.md           Documento del proyecto para el instructor
```
