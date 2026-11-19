USE al_toque;

ALTER TABLE pedidos
  ADD COLUMN empleado_id INT UNSIGNED NULL;

ALTER TABLE pedidos
  ADD CONSTRAINT fk_pedidos_empleado
  FOREIGN KEY (empleado_id) REFERENCES usuarios (id);
