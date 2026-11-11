# Al Toque Pedidos

La app Flutter usa una API Dart local que accede a MySQL. El cliente puede
consultar el menú y crear pedidos con nombre y curso. El personal inicia sesión
para gestionar comandas; solo el administrador puede crear o desactivar
empleados.

## Preparar MySQL

1. Instala e inicia MySQL Server en la computadora que alojará la API.
2. En MySQL Workbench, ejecuta `database/ddl.sql` para una base nueva. Si tu
   base ya tiene las columnas `metodo_pago` y `codigo_retiro` de la API local
   anterior, ejecuta una sola vez `database/migrate_admin_modules.sql`. Si parte
   del esquema original, ejecuta antes `database/migrate_local_api.sql`.
3. En ambos casos, ejecuta `database/seed_local.sql` para cargar el menú y el
   usuario técnico que registra pedidos.
4. Crea un usuario MySQL dedicado para la API; reemplaza la contraseña por una
   propia y no la guardes en el repositorio. Si ese usuario ya existe, conserva
   su contraseña y vuelve a ejecutar solo los `GRANT`:

   ```sql
   CREATE USER IF NOT EXISTS 'al_toque_api'@'localhost' IDENTIFIED BY 'CAMBIA_ESTA_CLAVE';
   GRANT SELECT, INSERT, UPDATE ON al_toque.usuarios TO 'al_toque_api'@'localhost';
   GRANT SELECT, INSERT, UPDATE ON al_toque.pedidos TO 'al_toque_api'@'localhost';
   GRANT SELECT, INSERT, UPDATE ON al_toque.productos_pedido TO 'al_toque_api'@'localhost';
   GRANT SELECT ON al_toque.categorias TO 'al_toque_api'@'localhost';
   GRANT SELECT ON al_toque.productos TO 'al_toque_api'@'localhost';
   ```

## Crear el primer administrador

Abre PowerShell en `backend` y configura la conexión a MySQL:

```powershell
$env:DB_HOST = "127.0.0.1"
$env:DB_PORT = "3306"
$env:DB_NAME = "al_toque"
$env:DB_USER = "al_toque_api"
$env:DB_PASSWORD = "TU_CLAVE_MYSQL"
$env:ADMIN_EMAIL = "admin@buffet.local"
$env:ADMIN_NAME = "Administrador"
$env:ADMIN_PASSWORD = "TU_CLAVE_ADMIN"
dart pub get
dart run bin/create_admin.dart
Remove-Item Env:ADMIN_PASSWORD
```

El comando solo crea la cuenta inicial si todavía no existe un administrador.
Usa una contraseña propia de al menos 8 caracteres; no subas credenciales al
repositorio.

## Iniciar la API

Genera una clave aleatoria de 32 bytes la primera vez en PowerShell y guárdala
en tu perfil de Windows para reutilizarla. No vuelvas a generarla en cada
inicio:

```powershell
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$bytes = New-Object byte[] 32
$rng.GetBytes($bytes)
$secret = [Convert]::ToBase64String($bytes)
[Environment]::SetEnvironmentVariable("API_TOKEN_SECRET", $secret, "User")
$env:API_TOKEN_SECRET = $secret
$rng.Dispose()
```

Conserva el mismo valor entre reinicios para mantener válidas las sesiones
actuales. Luego, desde `backend`, inicia el servidor:

```powershell
dart run bin/server.dart
```

La API escucha en el puerto `8080`. Comprueba API y MySQL en
`http://localhost:8080/health`.
Mantén abierta la terminal donde ejecutas `dart run bin/server.dart` mientras
usas la app. Para comprobar también el catálogo, abre
`http://localhost:8080/products`: debe responder con una lista JSON. Si `/health`
falla, revisa que MySQL esté iniciado y que las variables `DB_*` estén
configuradas en esa misma terminal. Si `/health` funciona pero `/products`
devuelve `[]`, ejecuta `database/seed_local.sql`.

## Usar la app

- **Emulador Android en la misma PC:** desde la carpeta del proyecto ejecuta
  `flutter run`. La dirección predeterminada `http://10.0.2.2:8080` apunta a la
  PC anfitriona.
- **Teléfono en el mismo Wi-Fi:** ejecuta `ipconfig`, busca la IPv4 Wi-Fi de la
  PC y ejecuta:

  ```powershell
  flutter run --dart-define=API_BASE_URL=http://192.168.1.25:8080
  ```

  Sustituye la IP de ejemplo por la real. Si es necesario, permite TCP `8080`
  en Windows Firewall para redes privadas.
- El cliente ingresa nombre y curso. El personal inicia sesión con su correo y
  contraseña. En la gestión de empleados, usa doble toque en “Agregar empleado”;
  en el tablero, doble toque sobre una comanda abre su detalle.
- Los cambios de estado se reflejan en el historial del cliente con consultas
  periódicas mientras la app sigue abierta. No se envían notificaciones push.

Esta API es una demo para una red privada de confianza. Usa HTTP sin cifrar,
no expongas el puerto a Internet. Las credenciales del personal se almacenan
con PBKDF2-SHA256 y las rutas administrativas requieren una sesión firmada.
