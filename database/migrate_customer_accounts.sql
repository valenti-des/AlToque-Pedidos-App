USE al_toque;

ALTER TABLE usuarios
  ADD COLUMN curso VARCHAR(50) NULL AFTER nombre;
