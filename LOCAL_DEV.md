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
4. Abre la carpeta del proyecto en VS Code, selecciona **Al Toque (local)**
   en Run and Debug y presiona F5. VS Code inicia la API y, cuando comprueba
   la conexión con MySQL, abre Flutter.

VS Code detiene la API automáticamente al finalizar la sesión de depuración.
