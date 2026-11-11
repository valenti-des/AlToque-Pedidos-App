CREATE DATABASE IF NOT EXISTS al_toque
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE al_toque;

CREATE TABLE IF NOT EXISTS usuarios (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre_usuario VARCHAR(50) NOT NULL,
  contrasena_hash VARCHAR(255) NOT NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_usuarios_nombre (nombre_usuario)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS categorias (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(80) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_categorias_nombre (nombre)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS productos (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  categoria_id INT UNSIGNED NOT NULL,
  nombre VARCHAR(120) NOT NULL,
  descripcion VARCHAR(255) NOT NULL DEFAULT '',
  precio DECIMAL(10, 2) NOT NULL,
  emoji VARCHAR(16) NOT NULL DEFAULT '',
  color CHAR(7) NOT NULL DEFAULT '#FFFFFF',
  disponible BOOLEAN NOT NULL DEFAULT TRUE,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_productos_categoria (categoria_id),
  CONSTRAINT fk_productos_categoria
    FOREIGN KEY (categoria_id) REFERENCES categorias (id),
  CONSTRAINT chk_productos_precio CHECK (precio >= 0)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS pedidos (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id INT UNSIGNED NOT NULL,
  estado VARCHAR(30) NOT NULL DEFAULT 'pendiente',
  metodo_pago VARCHAR(40) NOT NULL DEFAULT '',
  codigo_retiro VARCHAR(12) NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_pedidos_usuario (usuario_id),
  UNIQUE KEY uq_pedidos_codigo_retiro (codigo_retiro),
  CONSTRAINT fk_pedidos_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS productos_pedido (
  pedido_id INT UNSIGNED NOT NULL,
  producto_id INT UNSIGNED NOT NULL,
  cantidad INT UNSIGNED NOT NULL,
  precio_unitario DECIMAL(10, 2) NOT NULL,
  PRIMARY KEY (pedido_id, producto_id),
  KEY ix_productos_pedido_producto (producto_id),
  CONSTRAINT fk_productos_pedido_pedido
    FOREIGN KEY (pedido_id) REFERENCES pedidos (id) ON DELETE CASCADE,
  CONSTRAINT fk_productos_pedido_producto
    FOREIGN KEY (producto_id) REFERENCES productos (id),
  CONSTRAINT chk_productos_pedido_cantidad CHECK (cantidad > 0),
  CONSTRAINT chk_productos_pedido_precio CHECK (precio_unitario >= 0)
) ENGINE = InnoDB;
