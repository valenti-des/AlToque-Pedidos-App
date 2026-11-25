USE al_toque;

ALTER TABLE pedidos
  ADD COLUMN estado_actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
  AFTER creado_en;

UPDATE pedidos
SET estado_actualizado_en = creado_en;
