USE al_toque;

ALTER TABLE pedidos
  ADD COLUMN metodo_pago VARCHAR(40) NOT NULL DEFAULT '' AFTER estado,
  ADD COLUMN codigo_retiro VARCHAR(12) NULL AFTER metodo_pago,
  ADD UNIQUE KEY uq_pedidos_codigo_retiro (codigo_retiro);
