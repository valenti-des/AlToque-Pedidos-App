USE al_toque;

ALTER TABLE usuarios
  MODIFY nombre_usuario VARCHAR(50) NULL,
  ADD COLUMN email VARCHAR(254) NULL AFTER nombre_usuario,
  ADD COLUMN nombre VARCHAR(100) NOT NULL DEFAULT '' AFTER email,
  ADD COLUMN rol VARCHAR(20) NOT NULL DEFAULT 'cliente' AFTER nombre,
  ADD COLUMN activo BOOLEAN NOT NULL DEFAULT TRUE AFTER rol,
  ADD UNIQUE KEY uq_usuarios_email (email);

ALTER TABLE pedidos
  ADD COLUMN cliente_nombre VARCHAR(100) NOT NULL DEFAULT '' AFTER usuario_id,
  ADD COLUMN cliente_curso VARCHAR(50) NOT NULL DEFAULT '' AFTER cliente_nombre,
  ADD COLUMN token_seguimiento_hash CHAR(64) NULL AFTER codigo_retiro,
  ADD COLUMN motivo_cancelacion VARCHAR(255) NULL AFTER token_seguimiento_hash,
  ADD KEY ix_pedidos_estado (estado, creado_en);

ALTER TABLE productos_pedido
  ADD COLUMN estado VARCHAR(20) NOT NULL DEFAULT 'activo' AFTER precio_unitario,
  ADD COLUMN motivo_rechazo VARCHAR(255) NULL AFTER estado;
