-- =====================================================================
-- IMAX | 01_estructura_base.sql
-- Estructura compartida: 20 tablas, 4 vistas, 8 funciones/trigger,
-- 8 disparadores y un indice parcial para QR.
-- =====================================================================
-- Ejecutar UNA SOLA VEZ en una base de datos VACIA llamada IMAX.
-- No ejecutar sobre la base IMAX actual: los objetos ya existen.
-- No contiene los datos ficticios usados durante las pruebas.
-- Aun requiere reglas adicionales antes de usarse en produccion,
-- particularmente permisos, cancelaciones, reembolsos y concurrencia.
-- =====================================================================

BEGIN;

-- ==================== 1. ESTRUCTURA DEL CINE ==========================

CREATE TABLE pelicula (
    id_pelicula SERIAL PRIMARY KEY,
    titulo VARCHAR(150) NOT NULL,
    sinopsis TEXT,
    duracion INTEGER NOT NULL,
    clasificacion VARCHAR(20) NOT NULL,
    CONSTRAINT chk_pelicula_duracion CHECK (duracion > 0)
);

CREATE TABLE cine (
    id_cine SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    direccion VARCHAR(200) NOT NULL,
    ciudad VARCHAR(100) NOT NULL,
    pais VARCHAR(100) NOT NULL
);

CREATE TABLE sala (
    id_sala SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    tipo_proyeccion VARCHAR(30) NOT NULL,
    estado VARCHAR(20) NOT NULL,
    id_cine INTEGER NOT NULL,
    CONSTRAINT fk_sala_cine FOREIGN KEY (id_cine) REFERENCES cine(id_cine),
    CONSTRAINT uq_sala_cine_nombre UNIQUE (id_cine, nombre)
);

CREATE TABLE asiento (
    id_asiento SERIAL PRIMARY KEY,
    fila VARCHAR(5) NOT NULL,
    numero INTEGER NOT NULL,
    estado VARCHAR(20) NOT NULL,
    id_sala INTEGER NOT NULL,
    CONSTRAINT fk_asiento_sala FOREIGN KEY (id_sala) REFERENCES sala(id_sala),
    CONSTRAINT chk_asiento_numero CHECK (numero > 0),
    CONSTRAINT uq_asiento_sala_fila_numero UNIQUE (id_sala, fila, numero)
);

CREATE TABLE funcion (
    id_funcion SERIAL PRIMARY KEY,
    fecha_inicio TIMESTAMPTZ NOT NULL,
    fecha_fin TIMESTAMPTZ NOT NULL,
    estado VARCHAR(20) NOT NULL,
    id_pelicula INTEGER NOT NULL,
    id_sala INTEGER NOT NULL,
    CONSTRAINT fk_funcion_pelicula FOREIGN KEY (id_pelicula) REFERENCES pelicula(id_pelicula),
    CONSTRAINT fk_funcion_sala FOREIGN KEY (id_sala) REFERENCES sala(id_sala),
    CONSTRAINT chk_funcion_fechas CHECK (fecha_fin > fecha_inicio)
);

-- ==================== 2. USUARIOS Y RESERVAS ==========================

CREATE TABLE usuario (
    id_usuario SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    correo VARCHAR(150) NOT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_usuario_correo UNIQUE (correo)
);

CREATE TABLE reserva (
    id_reserva SERIAL PRIMARY KEY,
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_vencimiento TIMESTAMPTZ NOT NULL,
    estado VARCHAR(20) NOT NULL,
    id_usuario INTEGER NOT NULL,
    id_funcion INTEGER NOT NULL,
    CONSTRAINT fk_reserva_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
    CONSTRAINT fk_reserva_funcion FOREIGN KEY (id_funcion) REFERENCES funcion(id_funcion),
    CONSTRAINT chk_reserva_fechas CHECK (fecha_vencimiento > fecha_creacion),
    CONSTRAINT chk_reserva_estado CHECK (
        estado IN ('Activa', 'Confirmada', 'Vencida', 'Cancelada')
    )
);

CREATE TABLE reserva_asiento (
    id_reserva INTEGER NOT NULL,
    id_asiento INTEGER NOT NULL,
    CONSTRAINT pk_reserva_asiento PRIMARY KEY (id_reserva, id_asiento),
    CONSTRAINT fk_reserva_asiento_reserva FOREIGN KEY (id_reserva) REFERENCES reserva(id_reserva),
    CONSTRAINT fk_reserva_asiento_asiento FOREIGN KEY (id_asiento) REFERENCES asiento(id_asiento)
);

-- ==================== 3. VENTAS Y COBROS ==============================

CREATE TABLE tarifa (
    id_tarifa SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT,
    precio_base NUMERIC(12,2) NOT NULL,
    estado VARCHAR(20) NOT NULL,
    CONSTRAINT chk_tarifa_precio CHECK (precio_base >= 0),
    CONSTRAINT chk_tarifa_estado CHECK (estado IN ('Activa', 'Inactiva'))
);

CREATE TABLE promocion (
    id_promocion SERIAL PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL,
    tipo_descuento VARCHAR(20) NOT NULL,
    valor_descuento NUMERIC(12,2) NOT NULL,
    fecha_inicio TIMESTAMPTZ NOT NULL,
    fecha_fin TIMESTAMPTZ NOT NULL,
    estado VARCHAR(20) NOT NULL,
    CONSTRAINT uq_promocion_codigo UNIQUE (codigo),
    CONSTRAINT chk_promocion_fechas CHECK (fecha_fin > fecha_inicio),
    CONSTRAINT chk_promocion_tipo CHECK (tipo_descuento IN ('Porcentaje', 'Monto fijo')),
    CONSTRAINT chk_promocion_valor CHECK (valor_descuento > 0),
    CONSTRAINT chk_promocion_porcentaje CHECK (
        tipo_descuento <> 'Porcentaje' OR valor_descuento <= 100
    ),
    CONSTRAINT chk_promocion_estado CHECK (estado IN ('Activa', 'Inactiva'))
);

CREATE TABLE compra (
    id_compra SERIAL PRIMARY KEY,
    fecha_compra TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total NUMERIC(12,2) NOT NULL,
    estado VARCHAR(20) NOT NULL,
    id_reserva INTEGER NOT NULL,
    id_promocion INTEGER,
    CONSTRAINT fk_compra_reserva FOREIGN KEY (id_reserva) REFERENCES reserva(id_reserva),
    CONSTRAINT fk_compra_promocion FOREIGN KEY (id_promocion) REFERENCES promocion(id_promocion),
    CONSTRAINT uq_compra_reserva UNIQUE (id_reserva),
    CONSTRAINT chk_compra_total CHECK (total >= 0),
    CONSTRAINT chk_compra_estado CHECK (estado IN ('Pendiente', 'Pagada', 'Cancelada'))
);

CREATE TABLE pago (
    id_pago SERIAL PRIMARY KEY,
    monto NUMERIC(12,2) NOT NULL,
    metodo_pago VARCHAR(30) NOT NULL,
    fecha_intento TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) NOT NULL,
    id_compra INTEGER NOT NULL,
    CONSTRAINT fk_pago_compra FOREIGN KEY (id_compra) REFERENCES compra(id_compra),
    CONSTRAINT chk_pago_monto CHECK (monto > 0),
    CONSTRAINT chk_pago_estado CHECK (estado IN ('Pendiente', 'Aprobado', 'Rechazado'))
);

CREATE TABLE boleto (
    id_boleto SERIAL PRIMARY KEY,
    codigo_qr VARCHAR(255) NOT NULL,
    fecha_emision TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    precio_final NUMERIC(12,2) NOT NULL,
    estado VARCHAR(20) NOT NULL,
    id_compra INTEGER NOT NULL,
    id_asiento INTEGER NOT NULL,
    id_tarifa INTEGER NOT NULL,
    CONSTRAINT fk_boleto_compra FOREIGN KEY (id_compra) REFERENCES compra(id_compra),
    CONSTRAINT fk_boleto_asiento FOREIGN KEY (id_asiento) REFERENCES asiento(id_asiento),
    CONSTRAINT fk_boleto_tarifa FOREIGN KEY (id_tarifa) REFERENCES tarifa(id_tarifa),
    CONSTRAINT uq_boleto_codigo_qr UNIQUE (codigo_qr),
    CONSTRAINT uq_boleto_compra_asiento UNIQUE (id_compra, id_asiento),
    CONSTRAINT chk_boleto_precio CHECK (precio_final >= 0),
    CONSTRAINT chk_boleto_estado CHECK (estado IN ('Emitido', 'Usado', 'Anulado'))
);

CREATE TABLE reembolso (
    id_reembolso SERIAL PRIMARY KEY,
    monto NUMERIC(12,2) NOT NULL,
    motivo TEXT NOT NULL,
    fecha_solicitud TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_resolucion TIMESTAMPTZ,
    estado VARCHAR(20) NOT NULL,
    id_compra INTEGER NOT NULL,
    CONSTRAINT fk_reembolso_compra FOREIGN KEY (id_compra) REFERENCES compra(id_compra),
    CONSTRAINT chk_reembolso_monto CHECK (monto > 0),
    CONSTRAINT chk_reembolso_estado CHECK (
        estado IN ('Solicitado', 'Aprobado', 'Rechazado', 'Procesado')
    ),
    CONSTRAINT chk_reembolso_fechas CHECK (
        fecha_resolucion IS NULL OR fecha_resolucion >= fecha_solicitud
    )
);

-- ==================== 4. CONTROL Y SEGURIDAD ==========================

CREATE TABLE validacion_qr (
    id_validacion SERIAL PRIMARY KEY,
    fecha_hora TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resultado VARCHAR(20) NOT NULL,
    motivo_rechazo TEXT,
    id_boleto INTEGER NOT NULL,
    CONSTRAINT fk_validacion_qr_boleto FOREIGN KEY (id_boleto) REFERENCES boleto(id_boleto),
    CONSTRAINT chk_validacion_qr_resultado CHECK (resultado IN ('Aprobado', 'Rechazado'))
);

CREATE TABLE rol (
    id_rol SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT,
    CONSTRAINT uq_rol_nombre UNIQUE (nombre)
);

CREATE TABLE permiso (
    id_permiso SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    CONSTRAINT uq_permiso_nombre UNIQUE (nombre)
);

CREATE TABLE usuario_rol (
    id_usuario INTEGER NOT NULL,
    id_rol INTEGER NOT NULL,
    CONSTRAINT pk_usuario_rol PRIMARY KEY (id_usuario, id_rol),
    CONSTRAINT fk_usuario_rol_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
    CONSTRAINT fk_usuario_rol_rol FOREIGN KEY (id_rol) REFERENCES rol(id_rol)
);

CREATE TABLE rol_permiso (
    id_rol INTEGER NOT NULL,
    id_permiso INTEGER NOT NULL,
    CONSTRAINT pk_rol_permiso PRIMARY KEY (id_rol, id_permiso),
    CONSTRAINT fk_rol_permiso_rol FOREIGN KEY (id_rol) REFERENCES rol(id_rol),
    CONSTRAINT fk_rol_permiso_permiso FOREIGN KEY (id_permiso) REFERENCES permiso(id_permiso)
);

CREATE TABLE auditoria (
    id_auditoria SERIAL PRIMARY KEY,
    accion VARCHAR(100) NOT NULL,
    fecha_hora TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    entidad_afectada VARCHAR(100) NOT NULL,
    detalle TEXT,
    id_usuario INTEGER NOT NULL,
    CONSTRAINT fk_auditoria_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
);

-- ==================== 5. INDICE PARA QR ===============================
-- Permite varios intentos rechazados, pero un solo registro aprobado
-- por boleto. La aplicacion tambien debe validar el horario y la funcion.

CREATE UNIQUE INDEX uq_validacion_qr_aprobada
ON validacion_qr (id_boleto)
WHERE resultado = 'Aprobado';

-- ==================== 6. FUNCIONES DE PROTECCION =======================

-- Validar la asignacion de un asiento a una reserva.
CREATE FUNCTION proteger_reserva_asiento()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_id_funcion INTEGER;
    v_id_sala INTEGER;
BEGIN
    SELECT r.id_funcion, f.id_sala
      INTO v_id_funcion, v_id_sala
      FROM reserva r
      JOIN funcion f ON f.id_funcion = r.id_funcion
     WHERE r.id_reserva = NEW.id_reserva;

    IF NOT EXISTS (
        SELECT 1 FROM asiento a
        WHERE a.id_asiento = NEW.id_asiento AND a.id_sala = v_id_sala
    ) THEN
        RAISE EXCEPTION 'El asiento no pertenece a la sala de la funcion';
    END IF;

    PERFORM pg_advisory_xact_lock(v_id_funcion, NEW.id_asiento);

    IF EXISTS (
        SELECT 1
          FROM reserva_asiento ra
          JOIN reserva r ON r.id_reserva = ra.id_reserva
         WHERE r.id_funcion = v_id_funcion
           AND ra.id_asiento = NEW.id_asiento
           AND (
               r.estado = 'Confirmada'
               OR (r.estado = 'Activa' AND r.fecha_vencimiento > CURRENT_TIMESTAMP)
           )
    ) THEN
        RAISE EXCEPTION 'El asiento ya esta reservado para esta funcion';
    END IF;

    RETURN NEW;
END;
$$;

-- Impedir cambios directos de una asignacion existente.
CREATE FUNCTION impedir_cambio_reserva_asiento()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.id_reserva IS DISTINCT FROM OLD.id_reserva
       OR NEW.id_asiento IS DISTINCT FROM OLD.id_asiento THEN
        RAISE EXCEPTION 'No se permite modificar directamente una asignacion de asiento';
    END IF;
    RETURN NEW;
END;
$$;

-- Impedir cambiar la funcion si ya existen asientos asignados.
CREATE FUNCTION impedir_cambio_funcion_reserva()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.id_funcion IS DISTINCT FROM OLD.id_funcion
       AND EXISTS (
           SELECT 1 FROM reserva_asiento ra
           WHERE ra.id_reserva = OLD.id_reserva
       ) THEN
        RAISE EXCEPTION 'No se puede cambiar la funcion de una reserva con asientos asignados';
    END IF;
    RETURN NEW;
END;
$$;

-- Proteger las transiciones de estado de reservas.
CREATE FUNCTION proteger_estado_reserva()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.estado IN ('Cancelada', 'Vencida')
       AND NEW.estado IS DISTINCT FROM OLD.estado THEN
        RAISE EXCEPTION 'No se puede reactivar una reserva cancelada o vencida';
    END IF;

    IF OLD.estado = 'Confirmada'
       AND NEW.estado NOT IN ('Confirmada', 'Cancelada') THEN
        RAISE EXCEPTION 'Una reserva confirmada no puede volver a estar activa';
    END IF;

    IF OLD.estado = 'Activa'
       AND NEW.estado = 'Confirmada'
       AND OLD.fecha_vencimiento <= CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'No se puede confirmar una reserva vencida';
    END IF;

    IF OLD.estado = 'Activa'
       AND OLD.fecha_vencimiento <= CURRENT_TIMESTAMP
       AND NEW.fecha_vencimiento > OLD.fecha_vencimiento THEN
        RAISE EXCEPTION 'No se puede extender una reserva que ya vencio';
    END IF;

    RETURN NEW;
END;
$$;

-- Evitar mover de sala un asiento ya utilizado en reservas o boletos.
CREATE FUNCTION proteger_sala_asiento()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.id_sala IS DISTINCT FROM OLD.id_sala
       AND (
           EXISTS (SELECT 1 FROM reserva_asiento ra WHERE ra.id_asiento = OLD.id_asiento)
           OR EXISTS (SELECT 1 FROM boleto b WHERE b.id_asiento = OLD.id_asiento)
       ) THEN
        RAISE EXCEPTION 'No se puede cambiar de sala un asiento asociado a reservas o boletos';
    END IF;
    RETURN NEW;
END;
$$;

-- Evitar trasladar una funcion cuando ya tiene asientos reservados.
CREATE FUNCTION proteger_sala_funcion()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.id_sala IS DISTINCT FROM OLD.id_sala
       AND EXISTS (
           SELECT 1 FROM reserva r
           JOIN reserva_asiento ra ON ra.id_reserva = r.id_reserva
           WHERE r.id_funcion = OLD.id_funcion
       ) THEN
        RAISE EXCEPTION 'No se puede cambiar la sala de una funcion con asientos reservados';
    END IF;
    RETURN NEW;
END;
$$;

-- Proteger asignaciones de reservas confirmadas y con boletos.
CREATE FUNCTION proteger_eliminacion_reserva_asiento()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM reserva r
        WHERE r.id_reserva = OLD.id_reserva AND r.estado = 'Confirmada'
    ) THEN
        RAISE EXCEPTION 'No se puede eliminar un asiento de una reserva confirmada';
    END IF;

    IF EXISTS (
        SELECT 1 FROM compra c
        JOIN boleto b ON b.id_compra = c.id_compra
        WHERE c.id_reserva = OLD.id_reserva AND b.id_asiento = OLD.id_asiento
    ) THEN
        RAISE EXCEPTION 'No se puede eliminar un asiento con boleto emitido';
    END IF;
    RETURN OLD;
END;
$$;

-- Evitar cancelaciones directas con boletos emitidos o usados.
CREATE FUNCTION proteger_cancelacion_con_boleto()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.estado = 'Cancelada'
       AND OLD.estado IS DISTINCT FROM NEW.estado
       AND EXISTS (
           SELECT 1 FROM compra c
           JOIN boleto b ON b.id_compra = c.id_compra
           WHERE c.id_reserva = OLD.id_reserva
             AND b.estado IN ('Emitido', 'Usado')
       ) THEN
        RAISE EXCEPTION 'No se puede cancelar directamente una reserva con boletos vigentes';
    END IF;
    RETURN NEW;
END;
$$;

-- ==================== 7. TRIGGERS =====================================

CREATE TRIGGER trg_proteger_reserva_asiento
BEFORE INSERT ON reserva_asiento
FOR EACH ROW EXECUTE FUNCTION proteger_reserva_asiento();

CREATE TRIGGER trg_impedir_cambio_reserva_asiento
BEFORE UPDATE ON reserva_asiento
FOR EACH ROW EXECUTE FUNCTION impedir_cambio_reserva_asiento();

CREATE TRIGGER trg_impedir_cambio_funcion_reserva
BEFORE UPDATE OF id_funcion ON reserva
FOR EACH ROW EXECUTE FUNCTION impedir_cambio_funcion_reserva();

CREATE TRIGGER trg_proteger_estado_reserva
BEFORE UPDATE OF estado, fecha_vencimiento ON reserva
FOR EACH ROW EXECUTE FUNCTION proteger_estado_reserva();

CREATE TRIGGER trg_proteger_sala_asiento
BEFORE UPDATE OF id_sala ON asiento
FOR EACH ROW EXECUTE FUNCTION proteger_sala_asiento();

CREATE TRIGGER trg_proteger_sala_funcion
BEFORE UPDATE OF id_sala ON funcion
FOR EACH ROW EXECUTE FUNCTION proteger_sala_funcion();

CREATE TRIGGER trg_proteger_eliminacion_reserva_asiento
BEFORE DELETE ON reserva_asiento
FOR EACH ROW EXECUTE FUNCTION proteger_eliminacion_reserva_asiento();

CREATE TRIGGER trg_proteger_cancelacion_con_boleto
BEFORE UPDATE OF estado ON reserva
FOR EACH ROW EXECUTE FUNCTION proteger_cancelacion_con_boleto();

-- ==================== 8. VISTAS ANALITICAS =============================

-- Ocupacion real medida en boletos pagados no anulados.
CREATE VIEW vista_ocupacion_funciones AS
SELECT
    f.id_funcion,
    p.titulo AS titulo_pelicula,
    f.id_sala,
    COALESCE(cap.total_asientos, 0) AS total_asientos,
    COALESCE(ven.boletos_vendidos, 0) AS boletos_vendidos,
    COALESCE(
        ROUND(
            COALESCE(ven.boletos_vendidos, 0) * 100.0
            / NULLIF(cap.total_asientos, 0),
            2
        ), 0
    )::NUMERIC(5,2) AS porcentaje_ocupacion
FROM funcion f
JOIN pelicula p ON p.id_pelicula = f.id_pelicula
LEFT JOIN (
    SELECT id_sala, COUNT(*) AS total_asientos
    FROM asiento
    GROUP BY id_sala
) cap ON cap.id_sala = f.id_sala
LEFT JOIN (
    SELECT r.id_funcion, COUNT(*) AS boletos_vendidos
    FROM boleto b
    JOIN compra c ON c.id_compra = b.id_compra
    JOIN reserva r ON r.id_reserva = c.id_reserva
    WHERE c.estado = 'Pagada'
      AND b.estado IN ('Emitido', 'Usado')
    GROUP BY r.id_funcion
) ven ON ven.id_funcion = f.id_funcion;

-- Recaudacion por funcion sin multiplicar boletos por reembolsos.
CREATE VIEW vista_recaudacion_funciones AS
WITH boletos_por_compra AS (
    SELECT id_compra,
           COUNT(*) AS cantidad_boletos,
           SUM(precio_final) AS total_boletos
    FROM boleto
    WHERE estado IN ('Emitido', 'Usado')
    GROUP BY id_compra
),
reembolsos_por_compra AS (
    SELECT id_compra,
           SUM(monto) AS total_reembolsado
    FROM reembolso
    WHERE estado = 'Procesado'
    GROUP BY id_compra
),
recaudacion AS (
    SELECT r.id_funcion,
           SUM(COALESCE(b.cantidad_boletos, 0)) AS cantidad_boletos,
           SUM(COALESCE(b.total_boletos, 0)) AS recaudacion_bruta,
           SUM(COALESCE(re.total_reembolsado, 0)) AS total_reembolsado
    FROM compra c
    JOIN reserva r ON r.id_reserva = c.id_reserva
    LEFT JOIN boletos_por_compra b ON b.id_compra = c.id_compra
    LEFT JOIN reembolsos_por_compra re ON re.id_compra = c.id_compra
    WHERE c.estado = 'Pagada'
    GROUP BY r.id_funcion
)
SELECT f.id_funcion,
       p.titulo AS titulo_pelicula,
       COALESCE(rec.cantidad_boletos, 0)::BIGINT AS cantidad_boletos,
       COALESCE(rec.recaudacion_bruta, 0)::NUMERIC(14,2) AS recaudacion_bruta,
       COALESCE(rec.total_reembolsado, 0)::NUMERIC(14,2) AS total_reembolsado,
       (
           COALESCE(rec.recaudacion_bruta, 0)
           - COALESCE(rec.total_reembolsado, 0)
       )::NUMERIC(14,2) AS recaudacion_neta
FROM funcion f
JOIN pelicula p ON p.id_pelicula = f.id_pelicula
LEFT JOIN recaudacion rec ON rec.id_funcion = f.id_funcion;

-- Las cinco funciones con mas boletos vendidos.
CREATE VIEW vista_top_5_funciones AS
SELECT f.id_funcion,
       p.titulo AS titulo_pelicula,
       f.fecha_inicio,
       COUNT(b.id_boleto)::BIGINT AS boletos_vendidos
FROM funcion f
JOIN pelicula p ON p.id_pelicula = f.id_pelicula
JOIN reserva r ON r.id_funcion = f.id_funcion
JOIN compra c ON c.id_reserva = r.id_reserva
JOIN boleto b ON b.id_compra = c.id_compra
WHERE c.estado = 'Pagada'
  AND b.estado IN ('Emitido', 'Usado')
GROUP BY f.id_funcion, p.titulo, f.fecha_inicio
ORDER BY boletos_vendidos DESC, f.id_funcion ASC
LIMIT 5;

-- Pagos aprobados/rechazados y monto aprobado por metodo.
CREATE VIEW vista_metodos_pago AS
SELECT metodo_pago,
       COUNT(*) FILTER (WHERE estado = 'Aprobado')::BIGINT AS pagos_aprobados,
       COUNT(*) FILTER (WHERE estado = 'Rechazado')::BIGINT AS pagos_rechazados,
       COALESCE(
           SUM(monto) FILTER (WHERE estado = 'Aprobado'), 0
       )::NUMERIC(14,2) AS total_recaudado
FROM pago
GROUP BY metodo_pago;

COMMIT;


