# Guía para Yulied Marcela Lopez — TitanFit (Windows)

**Proyecto Final de Clase · ADSO SENA · Ficha 3311983 · Temática: Gimnasio**

Esta carpeta trae el código, el informe y el APK. Sigue los pasos en orden.

## 1. Qué debe quedar en tu PC

Después de descomprimir verás:

- `entregable/TitanFit-YuliedMarcelaLopez.apk` → se instala en el celular
- `api/` → backend (lo enciendes en el computador)
- `app/` → código de la aplicación Flutter (lo muestras en Visual Studio)
- `INFORME.md` y `README.md` → documento para el instructor
- `start-api.sh` → en Windows no se usa; abajo está el equivalente

## 2. Instalar Node.js (una sola vez)

1. Entra a https://nodejs.org
2. Descarga la versión **LTS**.
3. Instala con siguiente, siguiente, siguiente (deja marcada la opción de npm).
4. Cierra y abre de nuevo Visual Studio (o la terminal).
5. Comprueba. Abre **Símbolo del sistema** o **PowerShell** y escribe:

```bat
node -v
npm -v
```

Si salen números (por ejemplo `v22.x`), ya quedó.

## 3. Encender la API en tu computador

1. Abre la carpeta `TitanFit-Yulied-ProyectoFinal`.
2. Entra a la carpeta `api`.
3. En la barra de direcciones de esa carpeta escribe `cmd` y pulsa Enter.
4. Ejecuta, uno por uno:

```bat
npm install
npm start
```

5. Debe aparecer algo como:

```
TitanFit API lista en http://localhost:3000
LAN: http://192.168.x.x:3000
```

**No cierres esa ventana** mientras presentas.

### Si Windows pide permiso de firewall

Acepta **redes privadas**. Si no, el celular no va a alcanzar la API.

## 4. Saber la IP de tu PC (la necesitas en el celular)

En PowerShell o cmd:

```bat
ipconfig
```

Busca **Adaptador de LAN inalámbrica Wi-Fi** → **Dirección IPv4**.  
Ejemplo: `192.168.1.21`

El celular y el PC deben estar en **la misma red WiFi**.  
No uses datos móviles en el teléfono para hablar con la API.

## 5. Instalar el APK en el celular

1. Pasa el archivo `entregable/TitanFit-YuliedMarcelaLopez.apk` al teléfono (USB, Drive o el mismo WhatsApp).
2. Ábrelo en el celular.
3. Si pide **orígenes desconocidos** / **permitir instalar apps**, acéptalo.
4. Instala **TitanFit**.

## 6. Conectar la app con tu API

1. Abre TitanFit.
2. Entra con una cuenta de demostración.
3. Ve a **Perfil**.
4. En **URL** escribe exactamente (cambia la IP por la tuya):

```
http://192.168.1.21:3000
```

5. Pulsa **Guardar URL y probar**.
6. El banner de arriba debe decir **En línea**.

## 7. Cuentas para la sustentación

| Rol | Correo | Contraseña |
|---|---|---|
| Cliente | yulied@titanfit.co | Yulied123* |
| Administrador | admin@titanfit.co | Admin123* |

## 8. Guion corto para presentar (5 módulos)

1. **Login** — entra como Yulied.
2. **Registro** — (opcional) muestra la pantalla Crear cuenta.
3. **Agendar clase** — pestaña Clases → Agendar.
4. **Cancelar reserva** — pestaña Reservas → Cancelar.
5. **Gestión admin** — cierra sesión, entra como administrador → pestaña Gestión → Confirmar o Cancelar.

Luego enseña **modo avión**: agenda o cancela sin internet (banner offline / SQLite). Quita el modo avión y pulsa el banner o **Sincronizar ahora**.

También puedes mostrar Planes, Rutinas e Inventario (admin).

## 9. Abrir el código en Visual Studio (Windows)

El instructor suele pedir ver el código.

1. Abre **Visual Studio**.
2. **Archivo → Abrir → Carpeta…** (o *Open a local folder*).
3. Elige la carpeta descomprimida `TitanFit-Yulied-ProyectoFinal`.
4. Muestra estas rutas:

- `api/src/server.js` y `api/src/db.js` → API y base del servidor
- `app/lib/main.dart` → arranque de la app
- `app/lib/data/local_db.dart` → SQLite del celular
- `app/lib/state/app_state.dart` → login, reservas y sincronización
- `app/lib/screens/` → pantallas de cada módulo
- `INFORME.md` → documento del proyecto

Si tu Visual Studio es **Visual Studio Code** (icono azul), es aún más cómodo: Archivo → Abrir carpeta.

Para encender la API desde Visual Studio:

1. **Terminal → Nueva terminal**
2. `cd api`
3. `npm install`
4. `npm start`

## 10. Si algo falla

- **La app dice modo offline**  
  Misma WiFi, IP correcta, `npm start` abierto, firewall permitiendo el puerto 3000.

- **Emulador Android (si lo usas)**  
  La URL no es la IP del PC, es `http://10.0.2.2:3000`.

- `npm` no se reconoce  
  Reinstala Node.js LTS y reinicia el computador.

- El APK no instala  
  En Ajustes del teléfono permite instalar apps de esa fuente (Archivos / WhatsApp / Chrome).

No necesitas Flutter instalado para **presentar** el APK. Flutter solo haría falta si quisieras volver a generar el APK desde cero.
