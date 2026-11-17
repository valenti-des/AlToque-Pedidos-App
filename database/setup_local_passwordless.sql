-- Solo para desarrollo local. Limita la cuenta MySQL a conexiones locales.
-- No uses una cuenta sin contrasena en servidores ni redes compartidas.
-- mysql_native_password permite la autenticacion local sin clave con mysql1.
CREATE USER IF NOT EXISTS 'al_toque_api'@'localhost'
  IDENTIFIED WITH mysql_native_password BY '';
ALTER USER 'al_toque_api'@'localhost'
  IDENTIFIED WITH mysql_native_password BY '';

GRANT SELECT, INSERT, UPDATE ON al_toque.usuarios
  TO 'al_toque_api'@'localhost';
GRANT SELECT, INSERT, UPDATE ON al_toque.pedidos
  TO 'al_toque_api'@'localhost';
GRANT SELECT, INSERT, UPDATE ON al_toque.productos_pedido
  TO 'al_toque_api'@'localhost';
GRANT SELECT ON al_toque.categorias TO 'al_toque_api'@'localhost';
GRANT SELECT ON al_toque.productos TO 'al_toque_api'@'localhost';
