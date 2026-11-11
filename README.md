# Al Toque Pedidos

La app Flutter obtiene el catálogo y guarda los pedidos mediante una API Dart
local. La API se conecta a MySQL; las credenciales de MySQL no se guardan en la
app.

## Preparar MySQL en Windows

1. Instala e inicia MySQL Server en la computadora que alojará la API.
2. Desde MySQL Workbench o la consola, ejecuta `database/ddl.sql` para crear la
   base y las tablas, y luego `database/seed_local.sql` para cargar el menú y el
   usuario técnico que registra pedidos.
3. Crea un usuario para que la API tenga permisos limitados. Elige una
   contraseña propia y no la guardes en el repositorio:

   ```sql
   CREATE USER 'al_toque_api'@'localhost' IDENTIFIED BY 'CAMBIA_ESTA_CLAVE';
   GRANT SELECT ON al_toque.* TO 'al_toque_api'@'localhost';
   GRANT INSERT, UPDATE ON al_toque.pedidos TO 'al_toque_api'@'localhost';
   GRANT INSERT ON al_toque.productos_pedido TO 'al_toque_api'@'localhost';
   ```

Si ya habías creado `al_toque` con el esquema anterior, ejecuta primero
`database/migrate_local_api.sql` y después `database/seed_local.sql`. No ejecutes
la migración sobre una base recién creada con el `ddl.sql` actualizado.

## Iniciar la API

Abre PowerShell en la carpeta `backend` y ejecuta:

```powershell
dart pub get
$env:DB_HOST = "127.0.0.1"
$env:DB_PORT = "3306"
$env:DB_NAME = "al_toque"
$env:DB_USER = "al_toque_api"
$env:DB_PASSWORD = "TU_CLAVE_MYSQL"
dart run bin/server.dart
```

La API escucha en el puerto `8080` de todas las interfaces de red. Puedes
comprobar que API y MySQL están disponibles abriendo
`http://localhost:8080/health` en el navegador.

## Conectar Flutter

- **Emulador Android en la misma PC:** ejecuta Flutter desde la carpeta del
  proyecto:

  ```powershell
  flutter run
  ```

  La dirección predeterminada `http://10.0.2.2:8080` apunta desde el emulador a
  la PC anfitriona.

- **Teléfono conectado al mismo Wi-Fi:** ejecuta `ipconfig` en la PC, busca su
  dirección IPv4 de la red Wi-Fi (por ejemplo, `192.168.1.25`) y ejecuta:

  ```powershell
  flutter run --dart-define=API_BASE_URL=http://192.168.1.25:8080
  ```

  Si Windows Firewall lo solicita, permite el acceso en redes privadas. Si no
  aparece el aviso, crea una regla de entrada para TCP `8080` en el perfil
  privado. El teléfono y la PC deben estar en la misma red.

Para cada teléfono o red usa la IP local actual de la PC. No uses
`0.tcp.ngrok.io`: para esta configuración local no se necesita ngrok. La API de
demo no tiene autenticación y usa HTTP sin cifrar; úsala solo en una red privada
de confianza, no la expongas a Internet ni la incluyas como backend de
producción.

La pantalla de inicio de sesión sigue siendo una validación de demostración
local (`buffet` / `1234`); no es autenticación real del servidor.
