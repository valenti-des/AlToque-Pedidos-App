# Inicio local sin contraseña de MySQL

Esta configuracion es solo para desarrollo en una computadora de confianza.
Por defecto, la API solo escucha en loopback: el emulador Android de esta PC
puede acceder por `10.0.2.2`, pero un teléfono físico u otro equipo de la red
no. Para pruebas desde un teléfono, sigue la sección al final de este archivo.
Para hacer pedidos, los alumnos deben crear una cuenta o iniciar sesión; no
se aceptan pedidos como invitado.

1. Inicia el servicio MySQL.
2. Si la base todavía no está creada, ejecuta `database/ddl.sql` y
   `database/seed_local.sql`.
   Si ya existía y todavía no tiene los campos de alumnos y pedidos, ejecuta
   una sola vez `database/migrate_admin_modules.sql`.
   Si todavía no tiene la columna del empleado que entrega o cancela pedidos,
   ejecuta una vez `database/migrate_order_analytics.sql`.
   Si la base ya existía antes de esta actualización, ejecuta también una vez
   `database/migrate_order_status_timestamps.sql`.
3. En MySQL Workbench, conectado con una cuenta administradora, ejecuta
   `database/setup_local_passwordless.sql`. El script crea o actualiza el
   usuario local `al_toque_api` sin contraseña y le asigna los permisos
   necesarios. Si MySQL rechaza contraseñas vacias por su politica, no
   desactives esa politica globalmente; usa una cuenta local con contraseña.
4. Para crear las cuentas de prueba, abre PowerShell en la carpeta del
   proyecto y ejecuta:

   ```powershell
   $env:ALLOW_EMPTY_DB_PASSWORD = 'true'
   $env:ALLOW_DEMO_ACCOUNTS = 'true'
   Set-Location backend
   dart run bin/create_demo_accounts.dart
   Remove-Item Env:ALLOW_DEMO_ACCOUNTS
   ```

   El comando crea estas cuentas demo locales con contraseñas fijas:

   - Administrador: `admin.demo@al-toque.local` / `Admin123!`
   - Empleado: `empleado.demo@al-toque.local` / `Empleado123!`

   Las contraseñas quedan almacenadas en la base de datos como hashes PBKDF2.
   Si configuraste MySQL con clave, define también `DB_PASSWORD` antes de ejecutarlo.
5. Abre la carpeta del proyecto en VS Code, selecciona **Al Toque (local)**
   en Run and Debug y presiona F5. VS Code inicia la API y, cuando comprueba
   la conexión con MySQL, abre Flutter.

Los empleados y administradores inician sesión desde **Personal** y usan el
mismo tablero de comandas. El tablero recibe cambios mediante
`ws://127.0.0.1:8080/ws/orders` (en Android, `10.0.2.2`), autenticado con la
sesión del personal; el acceso a gestión de empleados sigue limitado al
administrador.

VS Code detiene la API automáticamente al finalizar la sesión de depuración.

## Probar desde un teléfono en la misma red Wi-Fi

La APK se conecta a la API; la API sigue conectándose a MySQL en esta
computadora. No abras el puerto de MySQL en la red. Esta configuración usa
HTTP sin cifrar y es solo para una red privada y de confianza; no expongas el
puerto de la API a Internet.

1. Conecta el teléfono y la computadora a la misma Wi-Fi. En la computadora,
   ejecuta `ipconfig` y anota la dirección IPv4 del adaptador Wi-Fi (por
   ejemplo, `192.168.1.25`; no uses `127.0.0.1`).
2. Si la API ya está corriendo desde VS Code u otra terminal, detenla primero.
   Desde la carpeta del proyecto, inicia la API para la red local:

   ```powershell
   .\backend\tool\stop_local_api.ps1
   $env:API_LISTEN_LAN = 'true'
   .\backend\tool\run_local_api.ps1
   ```

   La API escuchará en la red local en el puerto `8080`. MySQL seguirá
   accesible solo desde la computadora.
3. En otra PowerShell abierta en la carpeta del proyecto, genera la APK de
   prueba:

   ```powershell
   flutter build apk --debug
   ```

   El archivo queda en
   `build\app\outputs\flutter-apk\app-debug.apk`. Instálalo en el teléfono.
   Antes de iniciar sesión, toca el icono de configuración y escribe
   `http://IP_DE_TU_PC:8080`. Puedes cambiar esta dirección desde la app cuando
   cambies de red; no hace falta volver a compilar el APK. Deja MySQL y la API
   encendidos mientras la uses.
4. Si el teléfono no conecta, permite el puerto TCP `8080` en el Firewall de
   Windows solo para redes privadas. Comprueba también que la Wi-Fi no tenga
   aislamiento entre dispositivos.
