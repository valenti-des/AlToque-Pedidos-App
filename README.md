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
