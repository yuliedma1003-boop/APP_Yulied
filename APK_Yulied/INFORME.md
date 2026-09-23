# Informe de proyecto — TitanFit

**Proyecto Final de Clase**  
**Aprendiz:** Yulied Marcela Lopez  
**Programa:** Análisis y Desarrollo de Software (ADSO)  
**Centro / entidad:** SENA  
**Ficha:** 3311983  
**Temática seleccionada:** Gimnasio  
**Fecha de vencimiento:** 23 de septiembre, 11:59 a. m.

## 1. Objetivo

Desarrollar una aplicación móvil propia de gimnasio que cubra el ciclo de negocio de reservas de clases, con autenticación, dos perfiles (cliente y administrador), una API de backend y operación offline mediante SQLite. Cuando el dispositivo recupera conexión, la información generada sin internet se persiste en el servidor a través de la API.

## 2. Módulos entregados

El enunciado pide Login, Registro y **mínimo tres módulos adicionales** alineados al objetivo del negocio. TitanFit entrega el equivalente al ejemplo de agenda médica, aplicado a gimnasio:

| # | Módulo | Perfil | Equivalente del ejemplo |
|---|---|---|---|
| 1 | Login | Ambos | Login |
| 2 | Registro de cuenta | Cliente | Registro |
| 3 | Agendar clase | Cliente | Agendar citas |
| 4 | Gestión de reservas (confirmar o cancelar) | Administrador | Gestión de citas |
| 5 | Cancelación de reserva | Cliente | Cancelación de cita |

Módulos de apoyo al negocio:

6. Planes y membresías  
7. Rutinas de entrenamiento  
8. Inventario de equipos (administrador)

## 3. Arquitectura

La solución es **offline-first**:

1. Toda acción de negocio se escribe primero en SQLite del teléfono.
2. Si no hay red, el cambio entra a la tabla `sync_queue`.
3. Al detectar la API, la app envía la cola a `POST /api/sync` y recibe un snapshot del servidor.
4. SQLite se actualiza con lo confirmado en backend.

```
[App Flutter + SQLite]  --HTTP JSON-->  [API Express + SQLite servidor]
        |                                        |
   funciona sin internet                    persiste el negocio
```

### Backend (`/api`)

- Node.js, Express, JWT, bcrypt.
- SQLite nativo (`node:sqlite`).
- Endpoints: autenticación, clases, reservas, planes, rutinas, inventario y sincronización por lote.

### App (`/app`)

- Flutter 3, Provider, sqflite, connectivity_plus.
- Roles: `cliente` y `administrador`.
- Banner permanente de estado: en línea / modo offline / pendientes de cola.

## 4. Modelo de datos (resumen)

- **users:** cuentas y rol.
- **classes:** sesiones con fecha, entrenador, cupo y sala.
- **bookings:** reserva con estado `pendiente`, `confirmada` o `cancelada`.
- **membership_plans / memberships:** comercialización del gimnasio.
- **routines:** programas de entrenamiento.
- **inventory:** estado operativo de equipos.
- **sync_queue (solo app):** bitácora de cambios locales no enviados.

## 5. Reglas de negocio y roles

### Cliente
- Registrarse e iniciar sesión.
- Agendar una clase (la reserva nace **pendiente**).
- Cancelar **su** reserva, esté pendiente o confirmada.
- Activar un plan de membresía y consultar rutinas.
- No puede confirmar reservas ni entrar a inventario.

### Administrador
- Iniciar sesión (cuenta precargada `admin@titanfit.co`).
- Ver todas las reservas.
- **Confirmar** reservas pendientes.
- **Cancelar** cualquier reserva (pendiente o ya confirmada).
- Crear, editar y eliminar clases.
- Gestionar inventario de equipos.
- No agenda como cliente ni activa membresías personales.

El registro público siempre crea perfil **cliente**. El administrador no se auto-registra.

- Una persona no puede tener dos reservas activas de la misma clase.
- Si el cupo se agota, no se agenda.
- Las acciones hechas sin internet quedan pendientes y no se pierden.

## 6. Cuentas para la sustentación

| Rol | Correo | Contraseña |
|---|---|---|
| Cliente | yulied@titanfit.co | Yulied123* |
| Administrador | admin@titanfit.co | Admin123* |

URL por defecto de la API: `http://192.168.1.21:3000` (se cambia en Perfil si el equipo usa otra IP).

## 7. Entregable

- Código fuente de API y aplicación.
- APK: `entregable/TitanFit-YuliedMarcelaLopez.apk`.
- Este informe.

## 8. Conclusión

TitanFit cubre el objetivo de un gimnasio digital: el cliente agenda y cancela su entrenamiento; el administrador confirma, rechaza y controla inventario; y el sistema no depende de tener internet en el momento de la operación gracias a SQLite y a la sincronización posterior con la API.
