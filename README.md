# Al Toque Pedidos — Aplicación del Buffet Escolar

**Institución:** Escuela Técnica N° 12 "Libertador Gral. José de San Martín"  
**Materia:** Proyecto Informático II & Economía  
**Equipo:** Grupo 1  

---

## 1. Descripción General del Proyecto

### 1.1. Diagnóstico de la Problemática
Durante los recreos escolares se generan altas concentraciones de estudiantes en el mostrador del buffet. Esta aglomeración simultánea dificulta la atención organizada, la preparación rápida, el cobro y la entrega de productos, provocando demoras excesivas para los alumnos y sobrecarga operativa para el personal.

### 1.2. Propuesta de Solución
**"Al Toque Pedidos"** es una aplicación de preórdenes digitales diseñada para descongestionar el punto de venta durante los recesos escolares. Permite a los estudiantes explorar el catálogo digital y realizar pedidos con anticipación antes del recreo. A su vez, otorga al personal del buffet un panel de gestión en tiempo real para organizar, preparar y despachar las solicitudes oportunamente.

### 1.3. Ciclo Principal de Operación y Funcionalidades
1. **Consulta del Menú Categorizado:** Los usuarios navegan los productos distribuidos en categorías (*Comidas/Menú*, *Bebidas* y *Snacks/Golosinas*) visualizando precios, descripciones e imágenes.
2. **Preorden Unificada:** Permite consolidar artículos de distintas categorías en un único pedido dentro de una ventana horaria previa al recreo.
3. **Gestión Operativa del Buffet:** El personal monitorea pedidos entrantes y actualiza sus estados (`Pendiente`, `En preparación`, `Listo para retirar`, `Entregado`, `Cancelado`).
4. **Diferenciación por Modalidad de Pago:**
   * **Pago Anticipado (Transferencia):** Habilita la preparación previa a la llegada del usuario.
   * **Pago en Efectivo:** Se abona presencialmente al momento de la entrega en barra.
5. **Cancelación Manual con Motivo:** El personal puede cancelar una orden indicando la razón (p. ej., falta puntual del producto) sin depender de inventarios automatizados.

> **Definición de Alcance (Out of Scope):**  
> El sistema **no gestiona control automatizado de stock**, alertas de reposición, reserva de unidades ni descuentos automáticos de existencias.

---

## 2. Integrantes y Roles de Scrum (Grupo 1)

El proyecto es llevado a cabo por el **Grupo 1** bajo el marco de trabajo ágil Scrum:

| Integrante | Rol Scrum | Responsabilidades Principales |
| :--- | :--- | :--- |
| **Thiago Rojas** | **Product Owner (PO)** | Definición de la visión del producto, backlog, historias de usuario y requerimientos funcionales. |
| **Federico Mendoza** | **Scrum Master (SM)** | Facilitador ágil, eliminación de impedimentos y gestión de Sprints de 3 a 4 semanas. |
| **Fernando Alcalá** | **Desarrollador** | Desarrollo de componentes, lógica de negocio y pruebas de integración. |
| **Valentín Destri** | **Desarrollador** | Arquitectura de software, repositorio de GitHub y desarrollo de la API backend. |
| **Dimas Godoy** | **Desarrollador** | Desarrollo de la interfaz de usuario en Flutter y maquetado de pantallas. |

---

## 3. Arquitectura Técnica y Contratos JSON

### 3.1. Stack Tecnológico
* **Frontend (Cliente Mobile/Web):** **Flutter** (lenguaje **Dart** por Google). Interfaz multiplataforma, reactiva y fluida.
* **Backend (Servidor API):** **Servidor API local en Dart / API C# (.NET)**. API REST que procesa peticiones y valida reglas de negocio.
* **Base de Datos:** **MySQL** (Oracle Corporation). Sistema relacional (RDBMS) para el almacenamiento persistente de menús, usuarios y pedidos.

### 3.2. Comunicación entre Capas y Contratos JSON
Para preservar la seguridad del sistema, la aplicación Flutter nunca se conecta directamente a MySQL (evitando exponer credenciales en los dispositivos cliente). La comunicación sigue el patrón REST:

1. **Petición HTTP:** El cliente Flutter emite solicitudes `GET` o `POST` hacia la API (p. ej., `http://localhost:8080/health` o endpoints de pedidos/menú).
2. **Procesamiento Backend:** La API recibe la solicitud, valida la lógica y ejecuta consultas SQL sobre la base de datos MySQL.
3. **Respuesta JSON:** El backend empaqueta los datos procesados en formato **JSON** (*JavaScript Object Notation*) y los devuelve en una respuesta HTTP para actualizar la interfaz.

---

## 4. Instrucciones para Ejecutar el Prototipo (PoC en Localhost)

### 4.1. Requisitos Previos
* **Flutter SDK** (canal estable) y **Dart SDK**.
* **MySQL Server** y **MySQL Workbench** (o XAMPP).
* **Git** y consola de comandos (PowerShell / Bash).

### 4.2. Paso 1: Configurar la Base de Datos MySQL
1. Inicie el servidor MySQL en `localhost` (puerto `3306`).
2. Abra MySQL Workbench o consola y ejecute los scripts del repositorio para estructurar la base y cargar el menú inicial:

```sql
-- Crear base y estructura de tablas
SOURCE database/ddl.sql;

-- Cargar datos de prueba, menú y usuario técnico
SOURCE database/seed_local.sql;
```

### 4.3. Paso 2: Iniciar el Servidor API (Backend)
1. Navegue hasta la carpeta del servidor en su terminal y configure las variables de entorno (credenciales de MySQL).
2. Ejecute el servidor local en el puerto `8080`:

```bash
cd backend
dart run bin/server.dart # O 'dotnet run' según la rama de la API utilizada
```
*(Verifique el estado ingresando a `http://localhost:8080/health` en su navegador).*

### 4.4. Paso 3: Ejecutar la Aplicación Cliente (Frontend)
1. En una nueva terminal, acceda al directorio de la aplicación Flutter:

```bash
cd frontend
flutter pub get
flutter run
```

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

Para iniciar la API local y Flutter juntos desde VS Code, consulta
[Inicio local sin contraseña de MySQL](LOCAL_DEV.md).

- **Emulador Android en la misma PC:** desde la carpeta del proyecto ejecuta
  `flutter run`. La dirección predeterminada `http://10.0.2.2:8080` apunta a la
  PC anfitriona.
- **Teléfono físico:** para probar desde la misma Wi-Fi, sigue la sección
  de [conexión desde un teléfono](LOCAL_DEV.md).
- El cliente ingresa nombre y curso. El personal inicia sesión con su correo y
  contraseña. En la gestión de empleados, usa doble toque en “Agregar empleado”;
  en el tablero, doble toque sobre una comanda abre su detalle.
- Los cambios de estado se reflejan en el historial del cliente con consultas
  periódicas mientras la app sigue abierta. No se envían notificaciones push.

Esta API es una demo para una red privada de confianza. Usa HTTP sin cifrar,
no expongas el puerto a Internet. Las credenciales del personal se almacenan
con PBKDF2-SHA256 y las rutas administrativas requieren una sesión firmada.
