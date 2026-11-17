# Inicio local sin contraseña de MySQL

Esta configuracion es solo para desarrollo en una computadora de confianza.
La API solo escucha en loopback: el emulador Android de esta PC puede acceder
por `10.0.2.2`, pero un teléfono físico u otro equipo de la red no.
Para hacer pedidos, los alumnos deben crear una cuenta o iniciar sesión; no
se aceptan pedidos como invitado.

1. Inicia el servicio MySQL.
2. Si la base todavía no está creada, ejecuta `database/ddl.sql` y
   `database/seed_local.sql`.
   Si ya existía y todavía no tiene los campos de alumnos y pedidos, ejecuta
   una sola vez `database/migrate_admin_modules.sql`.
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

   El comando muestra un correo fijo para cada rol y contraseñas aleatorias.
   No guarda las contraseñas en archivos; al ejecutarlo otra vez, las
   contraseñas de esas cuentas se regeneran. Si configuraste MySQL con clave,
   define también `DB_PASSWORD` antes de ejecutarlo.
5. Abre la carpeta del proyecto en VS Code, selecciona **Al Toque (local)**
   en Run and Debug y presiona F5. VS Code inicia la API y, cuando comprueba
   la conexión con MySQL, abre Flutter.

Los empleados y administradores inician sesión desde **Personal** y usan el
mismo tablero de comandas. El tablero recibe cambios mediante
`ws://127.0.0.1:8080/ws/orders` (en Android, `10.0.2.2`), autenticado con la
sesión del personal; el acceso a gestión de empleados sigue limitado al
administrador.

VS Code detiene la API automáticamente al finalizar la sesión de depuración.
