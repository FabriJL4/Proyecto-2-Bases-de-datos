--
-- PostgreSQL database dump
--

\restrict KbmQc0t3DUXTKF00FbKkc2YpFfLZQ6VH6p8oDdTmr6YMLDmnLUmhNyGndBVQIRg

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

-- Started on 2026-10-24 02:16:36

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 283 (class 1255 OID 26116)
-- Name: auditar_cambios_imax(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.auditar_cambios_imax() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $$
DECLARE
    v_id_usuario INTEGER;
    v_detalle TEXT;
BEGIN

    -- Identificar la cuenta que inició sesión realmente
    SELECT c.id_usuario
    INTO v_id_usuario
    FROM public.cuenta_postgres_usuario AS c
    WHERE c.nombre_cuenta = SESSION_USER;

    -- No aceptar acciones sin responsable identificado
    IF v_id_usuario IS NULL THEN
        RAISE EXCEPTION
            'La cuenta % no está vinculada a un usuario IMAX.',
            SESSION_USER;
    END IF;

    -- Guardar los datos según el tipo de operación
    IF TG_OP = 'INSERT' THEN

        v_detalle = jsonb_build_object(
            'nuevo', to_jsonb(NEW)
        )::TEXT;

    ELSIF TG_OP = 'UPDATE' THEN

        v_detalle = jsonb_build_object(
            'anterior', to_jsonb(OLD),
            'nuevo', to_jsonb(NEW)
        )::TEXT;

    ELSIF TG_OP = 'DELETE' THEN

        v_detalle = jsonb_build_object(
            'anterior', to_jsonb(OLD)
        )::TEXT;

    END IF;

    -- Registrar la operación en la tabla auditoria
    INSERT INTO public.auditoria (
        accion,
        entidad_afectada,
        detalle,
        id_usuario
    )
    VALUES (
        TG_OP,
        TG_TABLE_NAME,
        v_detalle,
        v_id_usuario
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;

END;
$$;


ALTER FUNCTION public.auditar_cambios_imax() OWNER TO postgres;

--
-- TOC entry 281 (class 1255 OID 26143)
-- Name: cargar_ventas_prueba(integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.cargar_ventas_prueba(IN p_max_funciones integer, IN p_boletos_por_funcion integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public', 'pg_temp'
    AS $$
DECLARE
    v_funcion RECORD;
    v_asiento RECORD;
    v_id_reserva INTEGER;
    v_id_compra INTEGER;
    v_contador INTEGER;
    v_funciones_cargadas INTEGER := 0;
    v_boletos_creados INTEGER := 0;
    v_rechazados INTEGER := 0;
    v_metodo VARCHAR;
BEGIN

    -- Límites para evitar una carga accidental demasiado grande
    IF p_max_funciones IS NULL
       OR p_max_funciones < 1
       OR p_max_funciones > 180 THEN
        RAISE EXCEPTION
            'La cantidad de funciones debe estar entre 1 y 180.';
    END IF;

    IF p_boletos_por_funcion IS NULL
       OR p_boletos_por_funcion < 1
       OR p_boletos_por_funcion > 30 THEN
        RAISE EXCEPTION
            'Los boletos por función deben estar entre 1 y 30.';
    END IF;

    -- Solo las funciones de las nueve salas de prueba
    FOR v_funcion IN
        SELECT f.id_funcion, f.id_sala
        FROM public.funcion f
        JOIN public.sala s
          ON s.id_sala = f.id_sala
        WHERE s.nombre LIKE 'IMAX PRUEBA - Sala %'
          AND f.fecha_inicio >= '2026-11-01 00:00:00-06'
          AND f.fecha_inicio < '2026-11-21 00:00:00-06'
          AND NOT EXISTS (
              SELECT 1
              FROM public.reserva r
              JOIN public.compra c
                ON c.id_reserva = r.id_reserva
              WHERE r.id_funcion = f.id_funcion
                AND c.estado = 'Pagada'
          )
        ORDER BY f.id_funcion
        LIMIT p_max_funciones
    LOOP

        v_contador := 0;

        -- Asientos diferentes dentro de cada función
        FOR v_asiento IN
            SELECT a.id_asiento
            FROM public.asiento a
            WHERE a.id_sala = v_funcion.id_sala
            ORDER BY a.fila, a.numero
            LIMIT p_boletos_por_funcion + 1
        LOOP

            v_contador := v_contador + 1;

            -- Crear la reserva
            INSERT INTO public.reserva (
                fecha_creacion,
                fecha_vencimiento,
                estado,
                id_usuario,
                id_funcion
            )
            VALUES (
                clock_timestamp(),
                clock_timestamp() + INTERVAL '10 minutes',
                'Activa',
                1,
                v_funcion.id_funcion
            )
            RETURNING id_reserva INTO v_id_reserva;

            -- Asociar un asiento distinto
            INSERT INTO public.reserva_asiento (
                id_reserva,
                id_asiento
            )
            VALUES (
                v_id_reserva,
                v_asiento.id_asiento
            );

            -- Variar métodos de pago para el reporte
            v_metodo := CASE MOD(v_contador, 3)
                WHEN 0 THEN 'Tarjeta'
                WHEN 1 THEN 'SINPE Movil'
                ELSE 'Efectivo'
            END;

            -- La última operación de cada función será rechazada
            IF v_contador > p_boletos_por_funcion THEN

                INSERT INTO public.compra (
                    total, estado, id_reserva, id_tarifa
                )
                VALUES (
                    6000, 'Cancelada', v_id_reserva, 1
                );

                UPDATE public.reserva
                SET estado = 'Cancelada'
                WHERE id_reserva = v_id_reserva;

                SELECT id_compra
                INTO v_id_compra
                FROM public.compra
                WHERE id_reserva = v_id_reserva;

                INSERT INTO public.pago (
                    monto, metodo_pago, estado, id_compra
                )
                VALUES (
                    6000, v_metodo, 'Rechazado', v_id_compra
                );

                v_rechazados := v_rechazados + 1;

            ELSE

                -- Compra pagada de prueba
                INSERT INTO public.compra (
                    total, estado, id_reserva, id_tarifa
                )
                VALUES (
                    6000, 'Pagada', v_id_reserva, 1
                )
                RETURNING id_compra INTO v_id_compra;

                INSERT INTO public.pago (
                    monto, metodo_pago, estado, id_compra
                )
                VALUES (
                    6000, v_metodo, 'Aprobado', v_id_compra
                );

                UPDATE public.reserva
                SET estado = 'Confirmada'
                WHERE id_reserva = v_id_reserva;

                -- Boleto con identificador QR único
                INSERT INTO public.boleto (
                    codigo_qr,
                    precio_final,
                    estado,
                    id_compra,
                    id_asiento,
                    id_tarifa
                )
                VALUES (
                    'IMAX-PRUEBA-' ||
                        REPLACE(gen_random_uuid()::TEXT, '-', ''),
                    6000,
                    'Emitido',
                    v_id_compra,
                    v_asiento.id_asiento,
                    1
                );

                v_boletos_creados := v_boletos_creados + 1;

            END IF;

        END LOOP;

        v_funciones_cargadas := v_funciones_cargadas + 1;

    END LOOP;

    RAISE NOTICE
        'Carga finalizada. Funciones: %, boletos: %, pagos rechazados: %.',
        v_funciones_cargadas,
        v_boletos_creados,
        v_rechazados;

END;
$$;


ALTER PROCEDURE public.cargar_ventas_prueba(IN p_max_funciones integer, IN p_boletos_por_funcion integer) OWNER TO postgres;

--
-- TOC entry 275 (class 1255 OID 26061)
-- Name: impedir_cambio_funcion_reserva(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.impedir_cambio_funcion_reserva() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.id_funcion IS DISTINCT FROM OLD.id_funcion
       AND EXISTS (
           SELECT 1
           FROM reserva_asiento ra
           WHERE ra.id_reserva = OLD.id_reserva
       )
    THEN
        RAISE EXCEPTION
            'No se puede cambiar la funcion de una reserva con asientos asignados';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.impedir_cambio_funcion_reserva() OWNER TO postgres;

--
-- TOC entry 274 (class 1255 OID 26059)
-- Name: impedir_cambio_reserva_asiento(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.impedir_cambio_reserva_asiento() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.id_reserva IS DISTINCT FROM OLD.id_reserva
       OR NEW.id_asiento IS DISTINCT FROM OLD.id_asiento
    THEN
        RAISE EXCEPTION
            'No se permite modificar directamente una asignacion de asiento';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.impedir_cambio_reserva_asiento() OWNER TO postgres;

--
-- TOC entry 286 (class 1255 OID 26122)
-- Name: iniciar_compra(integer, integer, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.iniciar_compra(IN p_id_reserva integer, IN p_id_tarifa integer, IN p_metodo_pago character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $$
DECLARE
    v_id_usuario INTEGER;
    v_dueno_reserva INTEGER;
    v_estado_reserva VARCHAR;
    v_fecha_vencimiento TIMESTAMPTZ;
    v_fecha_funcion TIMESTAMPTZ;
    v_cantidad_asientos INTEGER;
    v_precio NUMERIC;
    v_total NUMERIC;
    v_id_compra INTEGER;
    v_id_pago INTEGER;
BEGIN

    -- 1. Identificar al cliente conectado
    SELECT c.id_usuario
    INTO v_id_usuario
    FROM public.cuenta_postgres_usuario c
    WHERE c.nombre_cuenta = SESSION_USER;

    IF v_id_usuario IS NULL THEN
        RAISE EXCEPTION
            'La cuenta no está vinculada a un usuario IMAX.';
    END IF;

    -- 2. Obtener y bloquear la reserva
    SELECT
        r.id_usuario,
        r.estado,
        r.fecha_vencimiento,
        f.fecha_inicio
    INTO
        v_dueno_reserva,
        v_estado_reserva,
        v_fecha_vencimiento,
        v_fecha_funcion
    FROM public.reserva r
    JOIN public.funcion f
        ON f.id_funcion = r.id_funcion
    WHERE r.id_reserva = p_id_reserva
    FOR UPDATE OF r;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La reserva indicada no existe.';
    END IF;

    -- 3. Verificar que pertenece al cliente
    IF v_dueno_reserva <> v_id_usuario THEN
        RAISE EXCEPTION
            'No puede comprar una reserva de otro usuario.';
    END IF;

    -- 4. Comprobar vigencia
    IF v_estado_reserva <> 'Activa'
       OR v_fecha_vencimiento <= CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION
            'La reserva no está activa o ya venció.';
    END IF;

    IF v_fecha_funcion <= CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'La función ya comenzó.';
    END IF;

    -- 5. Impedir compras duplicadas
    IF EXISTS (
        SELECT 1
        FROM public.compra
        WHERE id_reserva = p_id_reserva
    ) THEN
        RAISE EXCEPTION
            'Esta reserva ya tiene una compra registrada.';
    END IF;

    -- 6. Obtener tarifa activa
    SELECT t.precio_base
    INTO v_precio
    FROM public.tarifa t
    WHERE t.id_tarifa = p_id_tarifa
      AND t.estado = 'Activa';

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'La tarifa no existe o está inactiva.';
    END IF;

    IF v_precio <= 0 THEN
        RAISE EXCEPTION
            'La tarifa debe tener un precio mayor que cero.';
    END IF;

    -- 7. Contar asientos
    SELECT COUNT(*)
    INTO v_cantidad_asientos
    FROM public.reserva_asiento
    WHERE id_reserva = p_id_reserva;

    IF v_cantidad_asientos = 0 THEN
        RAISE EXCEPTION
            'La reserva no tiene asientos asignados.';
    END IF;

    -- 8. Calcular total
    v_total := v_cantidad_asientos * v_precio;

    -- 9. Validar método de pago
    IF p_metodo_pago IS NULL
       OR TRIM(p_metodo_pago) = '' THEN
        RAISE EXCEPTION
            'Debe indicar un método de pago.';
    END IF;

    -- 10. Registrar compra CON SU TARIFA
    INSERT INTO public.compra (
        total,
        estado,
        id_reserva,
        id_promocion,
        id_tarifa
    )
    VALUES (
        v_total,
        'Pendiente',
        p_id_reserva,
        NULL,
        p_id_tarifa
    )
    RETURNING id_compra INTO v_id_compra;

    -- 11. Registrar pago pendiente
    INSERT INTO public.pago (
        monto,
        metodo_pago,
        estado,
        id_compra
    )
    VALUES (
        v_total,
        TRIM(p_metodo_pago),
        'Pendiente',
        v_id_compra
    )
    RETURNING id_pago INTO v_id_pago;

    RAISE NOTICE
        'Compra ID: %, pago ID: %, tarifa: %, asientos: %, total: ₡%. Estado: Pendiente.',
        v_id_compra,
        v_id_pago,
        p_id_tarifa,
        v_cantidad_asientos,
        v_total;

END;
$$;


ALTER PROCEDURE public.iniciar_compra(IN p_id_reserva integer, IN p_id_tarifa integer, IN p_metodo_pago character varying) OWNER TO postgres;

--
-- TOC entry 288 (class 1255 OID 26128)
-- Name: procesar_pago_simulado(integer, boolean); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.procesar_pago_simulado(IN p_id_pago integer, IN p_aprobado boolean)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $$
DECLARE
    v_id_compra INTEGER;
    v_id_reserva INTEGER;
    v_id_tarifa INTEGER;
    v_estado_pago VARCHAR;
    v_estado_compra VARCHAR;
    v_estado_reserva VARCHAR;
    v_vencimiento TIMESTAMPTZ;
    v_inicio_funcion TIMESTAMPTZ;
    v_monto NUMERIC;
    v_total NUMERIC;
    v_cantidad INTEGER;
    v_emitidos INTEGER;
BEGIN

    IF p_aprobado IS NULL THEN
        RAISE EXCEPTION
            'Debe indicar si el pago fue aprobado o rechazado.';
    END IF;

    -- Buscar y bloquear el pago, la compra y la reserva
    SELECT
        p.id_compra,
        c.id_reserva,
        c.id_tarifa,
        p.estado,
        c.estado,
        r.estado,
        r.fecha_vencimiento,
        f.fecha_inicio,
        p.monto,
        c.total
    INTO
        v_id_compra,
        v_id_reserva,
        v_id_tarifa,
        v_estado_pago,
        v_estado_compra,
        v_estado_reserva,
        v_vencimiento,
        v_inicio_funcion,
        v_monto,
        v_total
    FROM public.pago p
    JOIN public.compra c
        ON c.id_compra = p.id_compra
    JOIN public.reserva r
        ON r.id_reserva = c.id_reserva
    JOIN public.funcion f
        ON f.id_funcion = r.id_funcion
    WHERE p.id_pago = p_id_pago
    FOR UPDATE OF p, c, r;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El pago indicado no existe.';
    END IF;

    -- Impedir procesar dos veces el mismo pago
    IF v_estado_pago <> 'Pendiente'
       OR v_estado_compra <> 'Pendiente' THEN

        RAISE EXCEPTION
            'Este pago o su compra ya fueron procesados.';
    END IF;

    -- Caso 1: pago rechazado
    IF p_aprobado = FALSE THEN

        UPDATE public.pago
        SET estado = 'Rechazado'
        WHERE id_pago = p_id_pago;

        UPDATE public.compra
        SET estado = 'Cancelada'
        WHERE id_compra = v_id_compra;

        UPDATE public.reserva
        SET estado = 'Cancelada'
        WHERE id_reserva = v_id_reserva
          AND estado = 'Activa';

        RAISE NOTICE
            'Pago % rechazado. Compra % cancelada. No se emitieron boletos.',
            p_id_pago,
            v_id_compra;

        RETURN;
    END IF;

    -- Caso 2: pago aprobado

    -- La reserva debe seguir vigente
    IF v_estado_reserva <> 'Activa'
       OR v_vencimiento <= clock_timestamp() THEN

        RAISE EXCEPTION
            'No se puede aprobar: la reserva ya no está vigente.';
    END IF;

    IF v_inicio_funcion <= clock_timestamp() THEN
        RAISE EXCEPTION
            'No se puede aprobar: la función ya comenzó.';
    END IF;

    -- Comprobar tarifa y montos
    IF v_id_tarifa IS NULL THEN
        RAISE EXCEPTION
            'La compra no tiene una tarifa asociada.';
    END IF;

    IF v_total <= 0 OR v_monto <> v_total THEN
        RAISE EXCEPTION
            'El monto del pago no coincide con el total.';
    END IF;

    -- Contar los asientos reservados
    SELECT COUNT(*)
    INTO v_cantidad
    FROM public.reserva_asiento
    WHERE id_reserva = v_id_reserva;

    IF v_cantidad = 0 THEN
        RAISE EXCEPTION
            'La reserva no tiene asientos.';
    END IF;

    -- No emitir boletos duplicados
    IF EXISTS (
        SELECT 1
        FROM public.boleto
        WHERE id_compra = v_id_compra
    ) THEN
        RAISE EXCEPTION
            'Esta compra ya tiene boletos emitidos.';
    END IF;

    -- Aprobar pago
    UPDATE public.pago
    SET estado = 'Aprobado'
    WHERE id_pago = p_id_pago;

    -- Confirmar compra
    UPDATE public.compra
    SET estado = 'Pagada'
    WHERE id_compra = v_id_compra;

    -- Confirmar reserva
    UPDATE public.reserva
    SET estado = 'Confirmada'
    WHERE id_reserva = v_id_reserva;

    -- Emitir un boleto por asiento reservado
    INSERT INTO public.boleto (
        codigo_qr,
        precio_final,
        estado,
        id_compra,
        id_asiento,
        id_tarifa
    )
    SELECT
        'IMAX-' || REPLACE(
            pg_catalog.gen_random_uuid()::TEXT,
            '-',
            ''
        ),
        v_total / v_cantidad,
        'Emitido',
        v_id_compra,
        ra.id_asiento,
        v_id_tarifa
    FROM public.reserva_asiento ra
    WHERE ra.id_reserva = v_id_reserva;

    GET DIAGNOSTICS v_emitidos = ROW_COUNT;

    IF v_emitidos <> v_cantidad THEN
        RAISE EXCEPTION
            'No se emitieron todos los boletos esperados.';
    END IF;

    RAISE NOTICE
        'Pago % aprobado. Compra % pagada. Boletos emitidos: %.',
        p_id_pago,
        v_id_compra,
        v_emitidos;

END;
$$;


ALTER PROCEDURE public.procesar_pago_simulado(IN p_id_pago integer, IN p_aprobado boolean) OWNER TO postgres;

--
-- TOC entry 284 (class 1255 OID 26099)
-- Name: programar_funcion(integer, integer, timestamp with time zone, timestamp with time zone); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.programar_funcion(IN p_id_pelicula integer, IN p_id_sala integer, IN p_fecha_inicio timestamp with time zone, IN p_fecha_fin timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $$
DECLARE
    v_id_funcion INTEGER;
BEGIN

    -- 1. Verificar las fechas
    IF p_fecha_inicio IS NULL
       OR p_fecha_fin IS NULL
       OR p_fecha_fin <= p_fecha_inicio THEN

        RAISE EXCEPTION
            'La fecha de finalización debe ser posterior al inicio.';
    END IF;

    -- 2. Comprobar que la película existe
    IF NOT EXISTS (
        SELECT 1
        FROM public.pelicula
        WHERE id_pelicula = p_id_pelicula
    ) THEN

        RAISE EXCEPTION 'La película indicada no existe.';
    END IF;

    -- 3. Verificar y bloquear temporalmente la sala
    -- para evitar programaciones simultáneas incompatibles
    PERFORM 1
    FROM public.sala
    WHERE id_sala = p_id_sala
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La sala indicada no existe.';
    END IF;

    -- 4. Buscar funciones con horarios traslapados
    IF EXISTS (
        SELECT 1
        FROM public.funcion
        WHERE id_sala = p_id_sala
          AND fecha_inicio < p_fecha_fin
          AND fecha_fin > p_fecha_inicio
    ) THEN

        RAISE EXCEPTION
            'La sala ya tiene una función programada en ese horario.';
    END IF;

    -- 5. Registrar la función
    INSERT INTO public.funcion (
        fecha_inicio,
        fecha_fin,
        estado,
        id_pelicula,
        id_sala
    )
    VALUES (
        p_fecha_inicio,
        p_fecha_fin,
        'programada',
        p_id_pelicula,
        p_id_sala
    )
    RETURNING id_funcion INTO v_id_funcion;

    RAISE NOTICE
        'Función programada correctamente. ID: %',
        v_id_funcion;

END;
$$;


ALTER PROCEDURE public.programar_funcion(IN p_id_pelicula integer, IN p_id_sala integer, IN p_fecha_inicio timestamp with time zone, IN p_fecha_fin timestamp with time zone) OWNER TO postgres;

--
-- TOC entry 287 (class 1255 OID 26072)
-- Name: proteger_cancelacion_con_boleto(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.proteger_cancelacion_con_boleto() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $$
BEGIN

    IF NEW.estado = 'Cancelada'
       AND OLD.estado IS DISTINCT FROM NEW.estado
       AND EXISTS (
           SELECT 1
           FROM public.compra c
           JOIN public.boleto b
               ON b.id_compra = c.id_compra
           WHERE c.id_reserva = OLD.id_reserva
             AND b.estado IN ('Emitido', 'Usado')
       )
    THEN
        RAISE EXCEPTION
            'No se puede cancelar directamente una reserva con boletos vigentes';
    END IF;

    RETURN NEW;

END;
$$;


ALTER FUNCTION public.proteger_cancelacion_con_boleto() OWNER TO postgres;

--
-- TOC entry 279 (class 1255 OID 26070)
-- Name: proteger_eliminacion_reserva_asiento(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.proteger_eliminacion_reserva_asiento() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Impedir eliminar un asiento de una
    -- reserva confirmada.
    IF EXISTS (
        SELECT 1
        FROM reserva r
        WHERE r.id_reserva = OLD.id_reserva
          AND r.estado = 'Confirmada'
    ) THEN
        RAISE EXCEPTION
            'No se puede eliminar un asiento de una reserva confirmada';
    END IF;

    -- Impedir eliminar la asignacion si
    -- ya existe un boleto para ese asiento.
    IF EXISTS (
        SELECT 1
        FROM compra c
        JOIN boleto b
            ON b.id_compra = c.id_compra
        WHERE c.id_reserva = OLD.id_reserva
          AND b.id_asiento = OLD.id_asiento
    ) THEN
        RAISE EXCEPTION
            'No se puede eliminar un asiento con boleto emitido';
    END IF;

    RETURN OLD;
END;
$$;


ALTER FUNCTION public.proteger_eliminacion_reserva_asiento() OWNER TO postgres;

--
-- TOC entry 276 (class 1255 OID 26064)
-- Name: proteger_estado_reserva(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.proteger_estado_reserva() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Una reserva cancelada o vencida no se reactiva.
    IF OLD.estado IN ('Cancelada', 'Vencida')
       AND NEW.estado IS DISTINCT FROM OLD.estado
    THEN
        RAISE EXCEPTION
            'No se puede reactivar una reserva cancelada o vencida';
    END IF;

    -- Una reserva confirmada no vuelve a estar activa.
    IF OLD.estado = 'Confirmada'
       AND NEW.estado NOT IN ('Confirmada', 'Cancelada')
    THEN
        RAISE EXCEPTION
            'Una reserva confirmada no puede volver a estar activa';
    END IF;

    -- No confirmar una reserva cuya fecha ya vencio.
    IF OLD.estado = 'Activa'
       AND NEW.estado = 'Confirmada'
       AND OLD.fecha_vencimiento <= CURRENT_TIMESTAMP
    THEN
        RAISE EXCEPTION
            'No se puede confirmar una reserva vencida';
    END IF;

    -- No extender una reserva activa que ya vencio.
    IF OLD.estado = 'Activa'
       AND OLD.fecha_vencimiento <= CURRENT_TIMESTAMP
       AND NEW.fecha_vencimiento > OLD.fecha_vencimiento
    THEN
        RAISE EXCEPTION
            'No se puede extender una reserva que ya vencio';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.proteger_estado_reserva() OWNER TO postgres;

--
-- TOC entry 273 (class 1255 OID 26057)
-- Name: proteger_reserva_asiento(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.proteger_reserva_asiento() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_funcion INTEGER;
    v_id_sala INTEGER;
BEGIN
    -- Obtener la funcion y su sala
    SELECT r.id_funcion, f.id_sala
    INTO v_id_funcion, v_id_sala
    FROM reserva r
    JOIN funcion f
        ON f.id_funcion = r.id_funcion
    WHERE r.id_reserva = NEW.id_reserva;

    -- Comprobar que el asiento pertenezca
    -- a la sala de la funcion
    IF NOT EXISTS (
        SELECT 1
        FROM asiento a
        WHERE a.id_asiento = NEW.id_asiento
          AND a.id_sala = v_id_sala
    ) THEN
        RAISE EXCEPTION
            'El asiento no pertenece a la sala de la funcion';
    END IF;

    -- Bloquear esta combinacion de funcion y asiento
    -- durante la transaccion
    PERFORM pg_advisory_xact_lock(
        v_id_funcion,
        NEW.id_asiento
    );

    -- Comprobar si el asiento esta ocupado
    IF EXISTS (
        SELECT 1
        FROM reserva_asiento ra
        JOIN reserva r
            ON r.id_reserva = ra.id_reserva
        WHERE r.id_funcion = v_id_funcion
          AND ra.id_asiento = NEW.id_asiento
          AND (
              r.estado = 'Confirmada'
              OR (
                  r.estado = 'Activa'
                  AND r.fecha_vencimiento > CURRENT_TIMESTAMP
              )
          )
    ) THEN
        RAISE EXCEPTION
            'El asiento ya esta reservado para esta funcion';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.proteger_reserva_asiento() OWNER TO postgres;

--
-- TOC entry 277 (class 1255 OID 26066)
-- Name: proteger_sala_asiento(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.proteger_sala_asiento() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.id_sala IS DISTINCT FROM OLD.id_sala
       AND (
           EXISTS (
               SELECT 1
               FROM reserva_asiento ra
               WHERE ra.id_asiento = OLD.id_asiento
           )
           OR EXISTS (
               SELECT 1
               FROM boleto b
               WHERE b.id_asiento = OLD.id_asiento
           )
       )
    THEN
        RAISE EXCEPTION
            'No se puede cambiar de sala un asiento asociado a reservas o boletos';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.proteger_sala_asiento() OWNER TO postgres;

--
-- TOC entry 278 (class 1255 OID 26068)
-- Name: proteger_sala_funcion(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.proteger_sala_funcion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.id_sala IS DISTINCT FROM OLD.id_sala
       AND EXISTS (
           SELECT 1
           FROM reserva r
           JOIN reserva_asiento ra
               ON ra.id_reserva = r.id_reserva
           WHERE r.id_funcion = OLD.id_funcion
       )
    THEN
        RAISE EXCEPTION
            'No se puede cambiar la sala de una funcion con asientos reservados';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.proteger_sala_funcion() OWNER TO postgres;

--
-- TOC entry 280 (class 1255 OID 26098)
-- Name: registrar_pelicula(character varying, text, integer, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.registrar_pelicula(IN p_titulo character varying, IN p_sinopsis text, IN p_duracion integer, IN p_clasificacion character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $$
DECLARE
    nuevo_id INTEGER;
BEGIN

    -- Validar el título
    IF p_titulo IS NULL OR TRIM(p_titulo) = '' THEN
        RAISE EXCEPTION 'El título de la película es obligatorio.';
    END IF;

    -- Validar la duración
    IF p_duracion IS NULL OR p_duracion <= 0 THEN
        RAISE EXCEPTION 'La duración debe ser mayor que cero.';
    END IF;

    -- Validar la clasificación
    IF p_clasificacion IS NULL OR TRIM(p_clasificacion) = '' THEN
        RAISE EXCEPTION 'La clasificación es obligatoria.';
    END IF;

    -- Registrar la película
    INSERT INTO public.pelicula (
        titulo,
        sinopsis,
        duracion,
        clasificacion
    )
    VALUES (
        TRIM(p_titulo),
        p_sinopsis,
        p_duracion,
        TRIM(p_clasificacion)
    )
    RETURNING id_pelicula INTO nuevo_id;

    RAISE NOTICE 'Película registrada con ID: %', nuevo_id;

END;
$$;


ALTER PROCEDURE public.registrar_pelicula(IN p_titulo character varying, IN p_sinopsis text, IN p_duracion integer, IN p_clasificacion character varying) OWNER TO postgres;

--
-- TOC entry 285 (class 1255 OID 26119)
-- Name: reservar_asiento(integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.reservar_asiento(IN p_id_funcion integer, IN p_id_asiento integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public', 'pg_temp'
    AS $$
DECLARE
    v_id_usuario INTEGER;
    v_id_sala INTEGER;
    v_fecha_inicio TIMESTAMPTZ;
    v_estado_funcion VARCHAR;
    v_id_reserva INTEGER;
BEGIN

    -- 1. Identificar al cliente conectado
    SELECT c.id_usuario
    INTO v_id_usuario
    FROM public.cuenta_postgres_usuario c
    WHERE c.nombre_cuenta = SESSION_USER;

    IF v_id_usuario IS NULL THEN
        RAISE EXCEPTION
            'La cuenta % no está vinculada a un usuario IMAX.',
            SESSION_USER;
    END IF;

    -- 2. Comprobar que la función existe
    SELECT
        f.id_sala,
        f.fecha_inicio,
        f.estado
    INTO
        v_id_sala,
        v_fecha_inicio,
        v_estado_funcion
    FROM public.funcion f
    WHERE f.id_funcion = p_id_funcion;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La función indicada no existe.';
    END IF;

    -- 3. Comprobar el estado y el horario
    IF LOWER(TRIM(v_estado_funcion)) <> 'programada' THEN
        RAISE EXCEPTION
            'La función no está disponible para reservas.';
    END IF;

    IF v_fecha_inicio <= CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION
            'No se puede reservar para una función que ya comenzó.';
    END IF;

    -- 4. Comprobar que el asiento sea válido
    IF NOT EXISTS (
        SELECT 1
        FROM public.asiento a
        WHERE a.id_asiento = p_id_asiento
          AND a.id_sala = v_id_sala
          AND LOWER(TRIM(a.estado)) = 'disponible'
    ) THEN
        RAISE EXCEPTION
            'El asiento no existe, no pertenece a la sala o no está disponible.';
    END IF;

    -- 5. Crear reserva temporal
    INSERT INTO public.reserva (
        id_usuario,
        id_funcion,
        fecha_creacion,
        fecha_vencimiento,
        estado
    )
    VALUES (
        v_id_usuario,
        p_id_funcion,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP + INTERVAL '10 minutes',
        'Activa'
    )
    RETURNING id_reserva INTO v_id_reserva;

    -- 6. Asignar el asiento
    -- El trigger existente impide las reservas duplicadas
    INSERT INTO public.reserva_asiento (
        id_reserva,
        id_asiento
    )
    VALUES (
        v_id_reserva,
        p_id_asiento
    );

    RAISE NOTICE
        'Reserva creada. ID: %, usuario: %, asiento: %. Vence en 10 minutos.',
        v_id_reserva,
        v_id_usuario,
        p_id_asiento;

END;
$$;


ALTER PROCEDURE public.reservar_asiento(IN p_id_funcion integer, IN p_id_asiento integer) OWNER TO postgres;

--
-- TOC entry 282 (class 1255 OID 26134)
-- Name: validar_boleto_qr(character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.validar_boleto_qr(IN p_codigo_qr character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $$
DECLARE
    v_id_boleto INTEGER;
    v_id_compra INTEGER;
    v_estado_boleto VARCHAR;
    v_estado_compra VARCHAR;
    v_estado_reserva VARCHAR;
    v_inicio TIMESTAMPTZ;
    v_fin TIMESTAMPTZ;
    v_motivo TEXT;
BEGIN

    -- 1. Buscar el boleto y bloquearlo durante la validación
    SELECT
        b.id_boleto,
        c.id_compra,
        b.estado,
        c.estado,
        r.estado,
        f.fecha_inicio,
        f.fecha_fin
    INTO
        v_id_boleto,
        v_id_compra,
        v_estado_boleto,
        v_estado_compra,
        v_estado_reserva,
        v_inicio,
        v_fin
    FROM public.boleto b
    JOIN public.compra c
        ON c.id_compra = b.id_compra
    JOIN public.reserva r
        ON r.id_reserva = c.id_reserva
    JOIN public.funcion f
        ON f.id_funcion = r.id_funcion
    WHERE b.codigo_qr = p_codigo_qr
    FOR UPDATE OF b;

    -- No podemos registrar un QR desconocido en validacion_qr
    -- porque esa tabla exige un id_boleto existente.
    IF NOT FOUND THEN
        RAISE NOTICE 'QR rechazado: código no reconocido.';
        RETURN;
    END IF;

    -- 2. Comprobar las condiciones de ingreso
    IF v_estado_boleto <> 'Emitido' THEN

        v_motivo := 'El boleto ya fue utilizado o está anulado.';

    ELSIF v_estado_compra <> 'Pagada' THEN

        v_motivo := 'La compra no está pagada.';

    ELSIF v_estado_reserva <> 'Confirmada' THEN

        v_motivo := 'La reserva no está confirmada.';

    ELSIF NOT EXISTS (
        SELECT 1
        FROM public.pago p
        WHERE p.id_compra = v_id_compra
          AND p.estado = 'Aprobado'
    ) THEN

        v_motivo := 'No existe un pago aprobado.';

    ELSIF clock_timestamp() < v_inicio - INTERVAL '1 hour'
       OR clock_timestamp() > v_fin THEN

        v_motivo := 'El boleto está fuera del horario de ingreso.';

    END IF;

    -- 3. Registrar un intento rechazado
    IF v_motivo IS NOT NULL THEN

        INSERT INTO public.validacion_qr (
            resultado,
            motivo_rechazo,
            id_boleto
        )
        VALUES (
            'Rechazado',
            v_motivo,
            v_id_boleto
        );

        RAISE NOTICE 'QR rechazado: %', v_motivo;
        RETURN;

    END IF;

    -- 4. Registrar el ingreso aprobado
    -- El índice único impide dos aprobaciones del mismo boleto.
    INSERT INTO public.validacion_qr (
        resultado,
        motivo_rechazo,
        id_boleto
    )
    VALUES (
        'Aprobado',
        NULL,
        v_id_boleto
    );

    -- 5. Marcar el boleto como utilizado
    UPDATE public.boleto
    SET estado = 'Usado'
    WHERE id_boleto = v_id_boleto;

    RAISE NOTICE
        'QR aprobado. Boleto % validado correctamente.',
        v_id_boleto;

END;
$$;


ALTER PROCEDURE public.validar_boleto_qr(IN p_codigo_qr character varying) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 226 (class 1259 OID 25708)
-- Name: asiento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.asiento (
    id_asiento integer NOT NULL,
    fila character varying(5) NOT NULL,
    numero integer NOT NULL,
    estado character varying(20) NOT NULL,
    id_sala integer NOT NULL,
    CONSTRAINT chk_asiento_numero CHECK ((numero > 0))
);


ALTER TABLE public.asiento OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 25707)
-- Name: asiento_id_asiento_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.asiento_id_asiento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.asiento_id_asiento_seq OWNER TO postgres;

--
-- TOC entry 5204 (class 0 OID 0)
-- Dependencies: 225
-- Name: asiento_id_asiento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.asiento_id_asiento_seq OWNED BY public.asiento.id_asiento;


--
-- TOC entry 255 (class 1259 OID 26037)
-- Name: auditoria; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auditoria (
    id_auditoria integer NOT NULL,
    accion character varying(100) NOT NULL,
    fecha_hora timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    entidad_afectada character varying(100) NOT NULL,
    detalle text,
    id_usuario integer NOT NULL
);


ALTER TABLE public.auditoria OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 26036)
-- Name: auditoria_id_auditoria_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auditoria_id_auditoria_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.auditoria_id_auditoria_seq OWNER TO postgres;

--
-- TOC entry 5206 (class 0 OID 0)
-- Dependencies: 254
-- Name: auditoria_id_auditoria_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auditoria_id_auditoria_seq OWNED BY public.auditoria.id_auditoria;


--
-- TOC entry 243 (class 1259 OID 25894)
-- Name: boleto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.boleto (
    id_boleto integer NOT NULL,
    codigo_qr character varying(255) NOT NULL,
    fecha_emision timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    precio_final numeric(12,2) NOT NULL,
    estado character varying(20) NOT NULL,
    id_compra integer NOT NULL,
    id_asiento integer NOT NULL,
    id_tarifa integer NOT NULL,
    CONSTRAINT chk_boleto_estado CHECK (((estado)::text = ANY ((ARRAY['Emitido'::character varying, 'Usado'::character varying, 'Anulado'::character varying])::text[]))),
    CONSTRAINT chk_boleto_precio CHECK ((precio_final >= (0)::numeric))
);


ALTER TABLE public.boleto OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 25893)
-- Name: boleto_id_boleto_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.boleto_id_boleto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.boleto_id_boleto_seq OWNER TO postgres;

--
-- TOC entry 5207 (class 0 OID 0)
-- Dependencies: 242
-- Name: boleto_id_boleto_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.boleto_id_boleto_seq OWNED BY public.boleto.id_boleto;


--
-- TOC entry 222 (class 1259 OID 25675)
-- Name: cine; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cine (
    id_cine integer NOT NULL,
    nombre character varying(100) NOT NULL,
    direccion character varying(200) NOT NULL,
    ciudad character varying(100) NOT NULL,
    pais character varying(100) NOT NULL
);


ALTER TABLE public.cine OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 25674)
-- Name: cine_id_cine_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cine_id_cine_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cine_id_cine_seq OWNER TO postgres;

--
-- TOC entry 5208 (class 0 OID 0)
-- Dependencies: 221
-- Name: cine_id_cine_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cine_id_cine_seq OWNED BY public.cine.id_cine;


--
-- TOC entry 239 (class 1259 OID 25846)
-- Name: compra; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.compra (
    id_compra integer NOT NULL,
    fecha_compra timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    total numeric(12,2) NOT NULL,
    estado character varying(20) NOT NULL,
    id_reserva integer NOT NULL,
    id_promocion integer,
    id_tarifa integer,
    CONSTRAINT chk_compra_estado CHECK (((estado)::text = ANY ((ARRAY['Pendiente'::character varying, 'Pagada'::character varying, 'Cancelada'::character varying])::text[]))),
    CONSTRAINT chk_compra_total CHECK ((total >= (0)::numeric))
);


ALTER TABLE public.compra OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 25845)
-- Name: compra_id_compra_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.compra_id_compra_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.compra_id_compra_seq OWNER TO postgres;

--
-- TOC entry 5209 (class 0 OID 0)
-- Dependencies: 238
-- Name: compra_id_compra_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.compra_id_compra_seq OWNED BY public.compra.id_compra;


--
-- TOC entry 260 (class 1259 OID 26102)
-- Name: cuenta_postgres_usuario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cuenta_postgres_usuario (
    nombre_cuenta name NOT NULL,
    id_usuario integer NOT NULL
);


ALTER TABLE public.cuenta_postgres_usuario OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 25728)
-- Name: funcion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.funcion (
    id_funcion integer NOT NULL,
    fecha_inicio timestamp with time zone NOT NULL,
    fecha_fin timestamp with time zone NOT NULL,
    estado character varying(20) NOT NULL,
    id_pelicula integer NOT NULL,
    id_sala integer NOT NULL,
    CONSTRAINT chk_funcion_fechas CHECK ((fecha_fin > fecha_inicio))
);


ALTER TABLE public.funcion OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 25727)
-- Name: funcion_id_funcion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.funcion_id_funcion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.funcion_id_funcion_seq OWNER TO postgres;

--
-- TOC entry 5210 (class 0 OID 0)
-- Dependencies: 227
-- Name: funcion_id_funcion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.funcion_id_funcion_seq OWNED BY public.funcion.id_funcion;


--
-- TOC entry 241 (class 1259 OID 25873)
-- Name: pago; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pago (
    id_pago integer NOT NULL,
    monto numeric(12,2) NOT NULL,
    metodo_pago character varying(30) NOT NULL,
    fecha_intento timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    estado character varying(20) NOT NULL,
    id_compra integer NOT NULL,
    CONSTRAINT chk_pago_estado CHECK (((estado)::text = ANY ((ARRAY['Pendiente'::character varying, 'Aprobado'::character varying, 'Rechazado'::character varying])::text[]))),
    CONSTRAINT chk_pago_monto CHECK ((monto > (0)::numeric))
);


ALTER TABLE public.pago OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 25872)
-- Name: pago_id_pago_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pago_id_pago_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pago_id_pago_seq OWNER TO postgres;

--
-- TOC entry 5211 (class 0 OID 0)
-- Dependencies: 240
-- Name: pago_id_pago_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pago_id_pago_seq OWNED BY public.pago.id_pago;


--
-- TOC entry 220 (class 1259 OID 25661)
-- Name: pelicula; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pelicula (
    id_pelicula integer NOT NULL,
    titulo character varying(150) NOT NULL,
    sinopsis text,
    duracion integer NOT NULL,
    clasificacion character varying(20) NOT NULL,
    CONSTRAINT chk_pelicula_duracion CHECK ((duracion > 0))
);


ALTER TABLE public.pelicula OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 25660)
-- Name: pelicula_id_pelicula_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pelicula_id_pelicula_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pelicula_id_pelicula_seq OWNER TO postgres;

--
-- TOC entry 5212 (class 0 OID 0)
-- Dependencies: 219
-- Name: pelicula_id_pelicula_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pelicula_id_pelicula_seq OWNED BY public.pelicula.id_pelicula;


--
-- TOC entry 251 (class 1259 OID 25990)
-- Name: permiso; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.permiso (
    id_permiso integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text
);


ALTER TABLE public.permiso OWNER TO postgres;

--
-- TOC entry 250 (class 1259 OID 25989)
-- Name: permiso_id_permiso_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.permiso_id_permiso_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.permiso_id_permiso_seq OWNER TO postgres;

--
-- TOC entry 5213 (class 0 OID 0)
-- Dependencies: 250
-- Name: permiso_id_permiso_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.permiso_id_permiso_seq OWNED BY public.permiso.id_permiso;


--
-- TOC entry 237 (class 1259 OID 25825)
-- Name: promocion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.promocion (
    id_promocion integer NOT NULL,
    codigo character varying(50) NOT NULL,
    tipo_descuento character varying(20) NOT NULL,
    valor_descuento numeric(12,2) NOT NULL,
    fecha_inicio timestamp with time zone NOT NULL,
    fecha_fin timestamp with time zone NOT NULL,
    estado character varying(20) NOT NULL,
    CONSTRAINT chk_promocion_estado CHECK (((estado)::text = ANY ((ARRAY['Activa'::character varying, 'Inactiva'::character varying])::text[]))),
    CONSTRAINT chk_promocion_fechas CHECK ((fecha_fin > fecha_inicio)),
    CONSTRAINT chk_promocion_porcentaje CHECK ((((tipo_descuento)::text <> 'Porcentaje'::text) OR (valor_descuento <= (100)::numeric))),
    CONSTRAINT chk_promocion_tipo CHECK (((tipo_descuento)::text = ANY ((ARRAY['Porcentaje'::character varying, 'Monto fijo'::character varying])::text[]))),
    CONSTRAINT chk_promocion_valor CHECK ((valor_descuento > (0)::numeric))
);


ALTER TABLE public.promocion OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 25824)
-- Name: promocion_id_promocion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.promocion_id_promocion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.promocion_id_promocion_seq OWNER TO postgres;

--
-- TOC entry 5214 (class 0 OID 0)
-- Dependencies: 236
-- Name: promocion_id_promocion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.promocion_id_promocion_seq OWNED BY public.promocion.id_promocion;


--
-- TOC entry 245 (class 1259 OID 25931)
-- Name: reembolso; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reembolso (
    id_reembolso integer NOT NULL,
    monto numeric(12,2) NOT NULL,
    motivo text NOT NULL,
    fecha_solicitud timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_resolucion timestamp with time zone,
    estado character varying(20) NOT NULL,
    id_compra integer NOT NULL,
    CONSTRAINT chk_reembolso_estado CHECK (((estado)::text = ANY ((ARRAY['Solicitado'::character varying, 'Aprobado'::character varying, 'Rechazado'::character varying, 'Procesado'::character varying])::text[]))),
    CONSTRAINT chk_reembolso_fechas CHECK (((fecha_resolucion IS NULL) OR (fecha_resolucion >= fecha_solicitud))),
    CONSTRAINT chk_reembolso_monto CHECK ((monto > (0)::numeric))
);


ALTER TABLE public.reembolso OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 25930)
-- Name: reembolso_id_reembolso_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reembolso_id_reembolso_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reembolso_id_reembolso_seq OWNER TO postgres;

--
-- TOC entry 5215 (class 0 OID 0)
-- Dependencies: 244
-- Name: reembolso_id_reembolso_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reembolso_id_reembolso_seq OWNED BY public.reembolso.id_reembolso;


--
-- TOC entry 232 (class 1259 OID 25767)
-- Name: reserva; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reserva (
    id_reserva integer NOT NULL,
    fecha_creacion timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_vencimiento timestamp with time zone NOT NULL,
    estado character varying(20) NOT NULL,
    id_usuario integer NOT NULL,
    id_funcion integer NOT NULL,
    CONSTRAINT chk_reserva_estado CHECK (((estado)::text = ANY ((ARRAY['Activa'::character varying, 'Confirmada'::character varying, 'Vencida'::character varying, 'Cancelada'::character varying])::text[]))),
    CONSTRAINT chk_reserva_fechas CHECK ((fecha_vencimiento > fecha_creacion))
);


ALTER TABLE public.reserva OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 25792)
-- Name: reserva_asiento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reserva_asiento (
    id_reserva integer NOT NULL,
    id_asiento integer NOT NULL
);


ALTER TABLE public.reserva_asiento OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 25766)
-- Name: reserva_id_reserva_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reserva_id_reserva_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reserva_id_reserva_seq OWNER TO postgres;

--
-- TOC entry 5216 (class 0 OID 0)
-- Dependencies: 231
-- Name: reserva_id_reserva_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reserva_id_reserva_seq OWNED BY public.reserva.id_reserva;


--
-- TOC entry 249 (class 1259 OID 25977)
-- Name: rol; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rol (
    id_rol integer NOT NULL,
    nombre character varying(50) NOT NULL,
    descripcion text
);


ALTER TABLE public.rol OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 25976)
-- Name: rol_id_rol_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rol_id_rol_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rol_id_rol_seq OWNER TO postgres;

--
-- TOC entry 5217 (class 0 OID 0)
-- Dependencies: 248
-- Name: rol_id_rol_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rol_id_rol_seq OWNED BY public.rol.id_rol;


--
-- TOC entry 253 (class 1259 OID 26019)
-- Name: rol_permiso; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rol_permiso (
    id_rol integer NOT NULL,
    id_permiso integer NOT NULL
);


ALTER TABLE public.rol_permiso OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 25689)
-- Name: sala; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sala (
    id_sala integer NOT NULL,
    nombre character varying(50) NOT NULL,
    tipo_proyeccion character varying(30) NOT NULL,
    estado character varying(20) NOT NULL,
    id_cine integer NOT NULL
);


ALTER TABLE public.sala OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 25688)
-- Name: sala_id_sala_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sala_id_sala_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sala_id_sala_seq OWNER TO postgres;

--
-- TOC entry 5218 (class 0 OID 0)
-- Dependencies: 223
-- Name: sala_id_sala_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sala_id_sala_seq OWNED BY public.sala.id_sala;


--
-- TOC entry 235 (class 1259 OID 25810)
-- Name: tarifa; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tarifa (
    id_tarifa integer NOT NULL,
    nombre character varying(50) NOT NULL,
    descripcion text,
    precio_base numeric(12,2) NOT NULL,
    estado character varying(20) NOT NULL,
    CONSTRAINT chk_tarifa_estado CHECK (((estado)::text = ANY ((ARRAY['Activa'::character varying, 'Inactiva'::character varying])::text[]))),
    CONSTRAINT chk_tarifa_precio CHECK ((precio_base >= (0)::numeric))
);


ALTER TABLE public.tarifa OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 25809)
-- Name: tarifa_id_tarifa_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tarifa_id_tarifa_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tarifa_id_tarifa_seq OWNER TO postgres;

--
-- TOC entry 5219 (class 0 OID 0)
-- Dependencies: 234
-- Name: tarifa_id_tarifa_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tarifa_id_tarifa_seq OWNED BY public.tarifa.id_tarifa;


--
-- TOC entry 230 (class 1259 OID 25752)
-- Name: usuario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuario (
    id_usuario integer NOT NULL,
    nombre character varying(50) NOT NULL,
    apellido character varying(50) NOT NULL,
    correo character varying(150) NOT NULL,
    fecha_registro timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.usuario OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 25751)
-- Name: usuario_id_usuario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.usuario_id_usuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.usuario_id_usuario_seq OWNER TO postgres;

--
-- TOC entry 5220 (class 0 OID 0)
-- Dependencies: 229
-- Name: usuario_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.usuario_id_usuario_seq OWNED BY public.usuario.id_usuario;


--
-- TOC entry 252 (class 1259 OID 26002)
-- Name: usuario_rol; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuario_rol (
    id_usuario integer NOT NULL,
    id_rol integer NOT NULL
);


ALTER TABLE public.usuario_rol OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 25957)
-- Name: validacion_qr; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.validacion_qr (
    id_validacion integer NOT NULL,
    fecha_hora timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    resultado character varying(20) NOT NULL,
    motivo_rechazo text,
    id_boleto integer NOT NULL,
    CONSTRAINT chk_validacion_qr_resultado CHECK (((resultado)::text = ANY ((ARRAY['Aprobado'::character varying, 'Rechazado'::character varying])::text[])))
);


ALTER TABLE public.validacion_qr OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 25956)
-- Name: validacion_qr_id_validacion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.validacion_qr_id_validacion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.validacion_qr_id_validacion_seq OWNER TO postgres;

--
-- TOC entry 5221 (class 0 OID 0)
-- Dependencies: 246
-- Name: validacion_qr_id_validacion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.validacion_qr_id_validacion_seq OWNED BY public.validacion_qr.id_validacion;


--
-- TOC entry 261 (class 1259 OID 26129)
-- Name: vista_control_boletos; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vista_control_boletos AS
 SELECT b.id_boleto,
    b.codigo_qr,
    b.estado AS estado_boleto,
    b.precio_final,
    b.id_asiento,
    c.id_compra,
    c.estado AS estado_compra,
    p.id_pago,
    p.estado AS estado_pago,
    r.id_reserva,
    r.id_usuario
   FROM (((public.boleto b
     JOIN public.compra c ON ((c.id_compra = b.id_compra)))
     JOIN public.reserva r ON ((r.id_reserva = c.id_reserva)))
     JOIN public.pago p ON ((p.id_compra = c.id_compra)))
  WHERE ((p.estado)::text = 'Aprobado'::text);


ALTER VIEW public.vista_control_boletos OWNER TO postgres;

--
-- TOC entry 259 (class 1259 OID 26089)
-- Name: vista_metodos_pago; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vista_metodos_pago AS
 SELECT metodo_pago,
    count(*) FILTER (WHERE ((estado)::text = 'Aprobado'::text)) AS pagos_aprobados,
    count(*) FILTER (WHERE ((estado)::text = 'Rechazado'::text)) AS pagos_rechazados,
    (COALESCE(sum(monto) FILTER (WHERE ((estado)::text = 'Aprobado'::text)), (0)::numeric))::numeric(14,2) AS total_recaudado
   FROM public.pago
  GROUP BY metodo_pago;


ALTER VIEW public.vista_metodos_pago OWNER TO postgres;

--
-- TOC entry 256 (class 1259 OID 26074)
-- Name: vista_ocupacion_funciones; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vista_ocupacion_funciones AS
 SELECT f.id_funcion,
    p.titulo AS titulo_pelicula,
    f.id_sala,
    COALESCE(cap.total_asientos, (0)::bigint) AS total_asientos,
    COALESCE(ven.boletos_vendidos, (0)::bigint) AS boletos_vendidos,
    (COALESCE(round((((COALESCE(ven.boletos_vendidos, (0)::bigint))::numeric * 100.0) / (NULLIF(cap.total_asientos, 0))::numeric), 2), (0)::numeric))::numeric(5,2) AS porcentaje_ocupacion
   FROM (((public.funcion f
     JOIN public.pelicula p ON ((p.id_pelicula = f.id_pelicula)))
     LEFT JOIN ( SELECT asiento.id_sala,
            count(*) AS total_asientos
           FROM public.asiento
          GROUP BY asiento.id_sala) cap ON ((cap.id_sala = f.id_sala)))
     LEFT JOIN ( SELECT r.id_funcion,
            count(*) AS boletos_vendidos
           FROM ((public.boleto b
             JOIN public.compra c ON ((c.id_compra = b.id_compra)))
             JOIN public.reserva r ON ((r.id_reserva = c.id_reserva)))
          WHERE (((c.estado)::text = 'Pagada'::text) AND ((b.estado)::text = ANY ((ARRAY['Emitido'::character varying, 'Usado'::character varying])::text[])))
          GROUP BY r.id_funcion) ven ON ((ven.id_funcion = f.id_funcion)));


ALTER VIEW public.vista_ocupacion_funciones OWNER TO postgres;

--
-- TOC entry 257 (class 1259 OID 26079)
-- Name: vista_recaudacion_funciones; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vista_recaudacion_funciones AS
 WITH boletos_por_compra AS (
         SELECT boleto.id_compra,
            count(*) AS cantidad_boletos,
            sum(boleto.precio_final) AS total_boletos
           FROM public.boleto
          WHERE ((boleto.estado)::text = ANY ((ARRAY['Emitido'::character varying, 'Usado'::character varying])::text[]))
          GROUP BY boleto.id_compra
        ), reembolsos_por_compra AS (
         SELECT reembolso.id_compra,
            sum(reembolso.monto) AS total_reembolsado
           FROM public.reembolso
          WHERE ((reembolso.estado)::text = 'Procesado'::text)
          GROUP BY reembolso.id_compra
        ), recaudacion AS (
         SELECT r.id_funcion,
            sum(COALESCE(b.cantidad_boletos, (0)::bigint)) AS cantidad_boletos,
            sum(COALESCE(b.total_boletos, (0)::numeric)) AS recaudacion_bruta,
            sum(COALESCE(re.total_reembolsado, (0)::numeric)) AS total_reembolsado
           FROM (((public.compra c
             JOIN public.reserva r ON ((r.id_reserva = c.id_reserva)))
             LEFT JOIN boletos_por_compra b ON ((b.id_compra = c.id_compra)))
             LEFT JOIN reembolsos_por_compra re ON ((re.id_compra = c.id_compra)))
          WHERE ((c.estado)::text = 'Pagada'::text)
          GROUP BY r.id_funcion
        )
 SELECT f.id_funcion,
    p.titulo AS titulo_pelicula,
    (COALESCE(rec.cantidad_boletos, (0)::numeric))::bigint AS cantidad_boletos,
    (COALESCE(rec.recaudacion_bruta, (0)::numeric))::numeric(14,2) AS recaudacion_bruta,
    (COALESCE(rec.total_reembolsado, (0)::numeric))::numeric(14,2) AS total_reembolsado,
    ((COALESCE(rec.recaudacion_bruta, (0)::numeric) - COALESCE(rec.total_reembolsado, (0)::numeric)))::numeric(14,2) AS recaudacion_neta
   FROM ((public.funcion f
     JOIN public.pelicula p ON ((p.id_pelicula = f.id_pelicula)))
     LEFT JOIN recaudacion rec ON ((rec.id_funcion = f.id_funcion)));


ALTER VIEW public.vista_recaudacion_funciones OWNER TO postgres;

--
-- TOC entry 258 (class 1259 OID 26084)
-- Name: vista_top_5_funciones; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vista_top_5_funciones AS
 SELECT f.id_funcion,
    p.titulo AS titulo_pelicula,
    f.fecha_inicio,
    count(b.id_boleto) AS boletos_vendidos
   FROM ((((public.funcion f
     JOIN public.pelicula p ON ((p.id_pelicula = f.id_pelicula)))
     JOIN public.reserva r ON ((r.id_funcion = f.id_funcion)))
     JOIN public.compra c ON ((c.id_reserva = r.id_reserva)))
     JOIN public.boleto b ON ((b.id_compra = c.id_compra)))
  WHERE (((c.estado)::text = 'Pagada'::text) AND ((b.estado)::text = ANY ((ARRAY['Emitido'::character varying, 'Usado'::character varying])::text[])))
  GROUP BY f.id_funcion, p.titulo, f.fecha_inicio
  ORDER BY (count(b.id_boleto)) DESC, f.id_funcion
 LIMIT 5;


ALTER VIEW public.vista_top_5_funciones OWNER TO postgres;

--
-- TOC entry 4890 (class 2604 OID 25711)
-- Name: asiento id_asiento; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asiento ALTER COLUMN id_asiento SET DEFAULT nextval('public.asiento_id_asiento_seq'::regclass);


--
-- TOC entry 4910 (class 2604 OID 26040)
-- Name: auditoria id_auditoria; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auditoria ALTER COLUMN id_auditoria SET DEFAULT nextval('public.auditoria_id_auditoria_seq'::regclass);


--
-- TOC entry 4902 (class 2604 OID 25897)
-- Name: boleto id_boleto; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.boleto ALTER COLUMN id_boleto SET DEFAULT nextval('public.boleto_id_boleto_seq'::regclass);


--
-- TOC entry 4888 (class 2604 OID 25678)
-- Name: cine id_cine; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cine ALTER COLUMN id_cine SET DEFAULT nextval('public.cine_id_cine_seq'::regclass);


--
-- TOC entry 4898 (class 2604 OID 25849)
-- Name: compra id_compra; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compra ALTER COLUMN id_compra SET DEFAULT nextval('public.compra_id_compra_seq'::regclass);


--
-- TOC entry 4891 (class 2604 OID 25731)
-- Name: funcion id_funcion; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.funcion ALTER COLUMN id_funcion SET DEFAULT nextval('public.funcion_id_funcion_seq'::regclass);


--
-- TOC entry 4900 (class 2604 OID 25876)
-- Name: pago id_pago; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pago ALTER COLUMN id_pago SET DEFAULT nextval('public.pago_id_pago_seq'::regclass);


--
-- TOC entry 4887 (class 2604 OID 25664)
-- Name: pelicula id_pelicula; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pelicula ALTER COLUMN id_pelicula SET DEFAULT nextval('public.pelicula_id_pelicula_seq'::regclass);


--
-- TOC entry 4909 (class 2604 OID 25993)
-- Name: permiso id_permiso; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permiso ALTER COLUMN id_permiso SET DEFAULT nextval('public.permiso_id_permiso_seq'::regclass);


--
-- TOC entry 4897 (class 2604 OID 25828)
-- Name: promocion id_promocion; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.promocion ALTER COLUMN id_promocion SET DEFAULT nextval('public.promocion_id_promocion_seq'::regclass);


--
-- TOC entry 4904 (class 2604 OID 25934)
-- Name: reembolso id_reembolso; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reembolso ALTER COLUMN id_reembolso SET DEFAULT nextval('public.reembolso_id_reembolso_seq'::regclass);


--
-- TOC entry 4894 (class 2604 OID 25770)
-- Name: reserva id_reserva; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserva ALTER COLUMN id_reserva SET DEFAULT nextval('public.reserva_id_reserva_seq'::regclass);


--
-- TOC entry 4908 (class 2604 OID 25980)
-- Name: rol id_rol; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rol ALTER COLUMN id_rol SET DEFAULT nextval('public.rol_id_rol_seq'::regclass);


--
-- TOC entry 4889 (class 2604 OID 25692)
-- Name: sala id_sala; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sala ALTER COLUMN id_sala SET DEFAULT nextval('public.sala_id_sala_seq'::regclass);


--
-- TOC entry 4896 (class 2604 OID 25813)
-- Name: tarifa id_tarifa; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tarifa ALTER COLUMN id_tarifa SET DEFAULT nextval('public.tarifa_id_tarifa_seq'::regclass);


--
-- TOC entry 4892 (class 2604 OID 25755)
-- Name: usuario id_usuario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario ALTER COLUMN id_usuario SET DEFAULT nextval('public.usuario_id_usuario_seq'::regclass);


--
-- TOC entry 4906 (class 2604 OID 25960)
-- Name: validacion_qr id_validacion; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.validacion_qr ALTER COLUMN id_validacion SET DEFAULT nextval('public.validacion_qr_id_validacion_seq'::regclass);


--
-- TOC entry 4943 (class 2606 OID 25719)
-- Name: asiento asiento_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asiento
    ADD CONSTRAINT asiento_pkey PRIMARY KEY (id_asiento);


--
-- TOC entry 4996 (class 2606 OID 26050)
-- Name: auditoria auditoria_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auditoria
    ADD CONSTRAINT auditoria_pkey PRIMARY KEY (id_auditoria);


--
-- TOC entry 4972 (class 2606 OID 25910)
-- Name: boleto boleto_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.boleto
    ADD CONSTRAINT boleto_pkey PRIMARY KEY (id_boleto);


--
-- TOC entry 4937 (class 2606 OID 25687)
-- Name: cine cine_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cine
    ADD CONSTRAINT cine_pkey PRIMARY KEY (id_cine);


--
-- TOC entry 4965 (class 2606 OID 25859)
-- Name: compra compra_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compra
    ADD CONSTRAINT compra_pkey PRIMARY KEY (id_compra);


--
-- TOC entry 4998 (class 2606 OID 26110)
-- Name: cuenta_postgres_usuario cuenta_postgres_usuario_id_usuario_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuenta_postgres_usuario
    ADD CONSTRAINT cuenta_postgres_usuario_id_usuario_key UNIQUE (id_usuario);


--
-- TOC entry 5000 (class 2606 OID 26108)
-- Name: cuenta_postgres_usuario cuenta_postgres_usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuenta_postgres_usuario
    ADD CONSTRAINT cuenta_postgres_usuario_pkey PRIMARY KEY (nombre_cuenta);


--
-- TOC entry 4947 (class 2606 OID 25740)
-- Name: funcion funcion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.funcion
    ADD CONSTRAINT funcion_pkey PRIMARY KEY (id_funcion);


--
-- TOC entry 4970 (class 2606 OID 25887)
-- Name: pago pago_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pago
    ADD CONSTRAINT pago_pkey PRIMARY KEY (id_pago);


--
-- TOC entry 4935 (class 2606 OID 25673)
-- Name: pelicula pelicula_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pelicula
    ADD CONSTRAINT pelicula_pkey PRIMARY KEY (id_pelicula);


--
-- TOC entry 4988 (class 2606 OID 25999)
-- Name: permiso permiso_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permiso
    ADD CONSTRAINT permiso_pkey PRIMARY KEY (id_permiso);


--
-- TOC entry 4957 (class 2606 OID 25798)
-- Name: reserva_asiento pk_reserva_asiento; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserva_asiento
    ADD CONSTRAINT pk_reserva_asiento PRIMARY KEY (id_reserva, id_asiento);


--
-- TOC entry 4994 (class 2606 OID 26025)
-- Name: rol_permiso pk_rol_permiso; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rol_permiso
    ADD CONSTRAINT pk_rol_permiso PRIMARY KEY (id_rol, id_permiso);


--
-- TOC entry 4992 (class 2606 OID 26008)
-- Name: usuario_rol pk_usuario_rol; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario_rol
    ADD CONSTRAINT pk_usuario_rol PRIMARY KEY (id_usuario, id_rol);


--
-- TOC entry 4961 (class 2606 OID 25842)
-- Name: promocion promocion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.promocion
    ADD CONSTRAINT promocion_pkey PRIMARY KEY (id_promocion);


--
-- TOC entry 4979 (class 2606 OID 25948)
-- Name: reembolso reembolso_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reembolso
    ADD CONSTRAINT reembolso_pkey PRIMARY KEY (id_reembolso);


--
-- TOC entry 4954 (class 2606 OID 25781)
-- Name: reserva reserva_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserva
    ADD CONSTRAINT reserva_pkey PRIMARY KEY (id_reserva);


--
-- TOC entry 4984 (class 2606 OID 25986)
-- Name: rol rol_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id_rol);


--
-- TOC entry 4939 (class 2606 OID 25699)
-- Name: sala sala_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sala
    ADD CONSTRAINT sala_pkey PRIMARY KEY (id_sala);


--
-- TOC entry 4959 (class 2606 OID 25823)
-- Name: tarifa tarifa_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tarifa
    ADD CONSTRAINT tarifa_pkey PRIMARY KEY (id_tarifa);


--
-- TOC entry 4945 (class 2606 OID 25721)
-- Name: asiento uq_asiento_sala_fila_numero; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asiento
    ADD CONSTRAINT uq_asiento_sala_fila_numero UNIQUE (id_sala, fila, numero);


--
-- TOC entry 4974 (class 2606 OID 25912)
-- Name: boleto uq_boleto_codigo_qr; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.boleto
    ADD CONSTRAINT uq_boleto_codigo_qr UNIQUE (codigo_qr);


--
-- TOC entry 4976 (class 2606 OID 25914)
-- Name: boleto uq_boleto_compra_asiento; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.boleto
    ADD CONSTRAINT uq_boleto_compra_asiento UNIQUE (id_compra, id_asiento);


--
-- TOC entry 4967 (class 2606 OID 25861)
-- Name: compra uq_compra_reserva; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compra
    ADD CONSTRAINT uq_compra_reserva UNIQUE (id_reserva);


--
-- TOC entry 4990 (class 2606 OID 26001)
-- Name: permiso uq_permiso_nombre; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permiso
    ADD CONSTRAINT uq_permiso_nombre UNIQUE (nombre);


--
-- TOC entry 4963 (class 2606 OID 25844)
-- Name: promocion uq_promocion_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.promocion
    ADD CONSTRAINT uq_promocion_codigo UNIQUE (codigo);


--
-- TOC entry 4986 (class 2606 OID 25988)
-- Name: rol uq_rol_nombre; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rol
    ADD CONSTRAINT uq_rol_nombre UNIQUE (nombre);


--
-- TOC entry 4941 (class 2606 OID 25701)
-- Name: sala uq_sala_cine_nombre; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sala
    ADD CONSTRAINT uq_sala_cine_nombre UNIQUE (id_cine, nombre);


--
-- TOC entry 4949 (class 2606 OID 25765)
-- Name: usuario uq_usuario_correo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT uq_usuario_correo UNIQUE (correo);


--
-- TOC entry 4951 (class 2606 OID 25763)
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id_usuario);


--
-- TOC entry 4982 (class 2606 OID 25970)
-- Name: validacion_qr validacion_qr_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.validacion_qr
    ADD CONSTRAINT validacion_qr_pkey PRIMARY KEY (id_validacion);


--
-- TOC entry 4968 (class 1259 OID 26150)
-- Name: idx_pago_compra; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pago_compra ON public.pago USING btree (id_compra);


--
-- TOC entry 4977 (class 1259 OID 26151)
-- Name: idx_reembolso_compra; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reembolso_compra ON public.reembolso USING btree (id_compra);


--
-- TOC entry 4955 (class 1259 OID 26152)
-- Name: idx_reserva_asiento_asiento; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reserva_asiento_asiento ON public.reserva_asiento USING btree (id_asiento);


--
-- TOC entry 4952 (class 1259 OID 26149)
-- Name: idx_reserva_funcion; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reserva_funcion ON public.reserva USING btree (id_funcion);


--
-- TOC entry 4980 (class 1259 OID 26056)
-- Name: uq_validacion_qr_aprobada; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_validacion_qr_aprobada ON public.validacion_qr USING btree (id_boleto) WHERE ((resultado)::text = 'Aprobado'::text);


--
-- TOC entry 5036 (class 2620 OID 26140)
-- Name: boleto trg_auditoria_boleto; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_auditoria_boleto AFTER INSERT OR DELETE OR UPDATE ON public.boleto FOR EACH ROW EXECUTE FUNCTION public.auditar_cambios_imax();


--
-- TOC entry 5034 (class 2620 OID 26138)
-- Name: compra trg_auditoria_compra; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_auditoria_compra AFTER INSERT OR DELETE OR UPDATE ON public.compra FOR EACH ROW EXECUTE FUNCTION public.auditar_cambios_imax();


--
-- TOC entry 5026 (class 2620 OID 26118)
-- Name: funcion trg_auditoria_funcion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_auditoria_funcion AFTER INSERT OR DELETE OR UPDATE ON public.funcion FOR EACH ROW EXECUTE FUNCTION public.auditar_cambios_imax();


--
-- TOC entry 5035 (class 2620 OID 26139)
-- Name: pago trg_auditoria_pago; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_auditoria_pago AFTER INSERT OR DELETE OR UPDATE ON public.pago FOR EACH ROW EXECUTE FUNCTION public.auditar_cambios_imax();


--
-- TOC entry 5024 (class 2620 OID 26117)
-- Name: pelicula trg_auditoria_pelicula; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_auditoria_pelicula AFTER INSERT OR DELETE OR UPDATE ON public.pelicula FOR EACH ROW EXECUTE FUNCTION public.auditar_cambios_imax();


--
-- TOC entry 5037 (class 2620 OID 26141)
-- Name: validacion_qr trg_auditoria_validacion_qr; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_auditoria_validacion_qr AFTER INSERT OR DELETE OR UPDATE ON public.validacion_qr FOR EACH ROW EXECUTE FUNCTION public.auditar_cambios_imax();


--
-- TOC entry 5028 (class 2620 OID 26063)
-- Name: reserva trg_impedir_cambio_funcion_reserva; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_impedir_cambio_funcion_reserva BEFORE UPDATE OF id_funcion ON public.reserva FOR EACH ROW EXECUTE FUNCTION public.impedir_cambio_funcion_reserva();


--
-- TOC entry 5031 (class 2620 OID 26060)
-- Name: reserva_asiento trg_impedir_cambio_reserva_asiento; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_impedir_cambio_reserva_asiento BEFORE UPDATE ON public.reserva_asiento FOR EACH ROW EXECUTE FUNCTION public.impedir_cambio_reserva_asiento();


--
-- TOC entry 5029 (class 2620 OID 26073)
-- Name: reserva trg_proteger_cancelacion_con_boleto; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_proteger_cancelacion_con_boleto BEFORE UPDATE OF estado ON public.reserva FOR EACH ROW EXECUTE FUNCTION public.proteger_cancelacion_con_boleto();


--
-- TOC entry 5032 (class 2620 OID 26071)
-- Name: reserva_asiento trg_proteger_eliminacion_reserva_asiento; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_proteger_eliminacion_reserva_asiento BEFORE DELETE ON public.reserva_asiento FOR EACH ROW EXECUTE FUNCTION public.proteger_eliminacion_reserva_asiento();


--
-- TOC entry 5030 (class 2620 OID 26065)
-- Name: reserva trg_proteger_estado_reserva; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_proteger_estado_reserva BEFORE UPDATE OF estado, fecha_vencimiento ON public.reserva FOR EACH ROW EXECUTE FUNCTION public.proteger_estado_reserva();


--
-- TOC entry 5033 (class 2620 OID 26058)
-- Name: reserva_asiento trg_proteger_reserva_asiento; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_proteger_reserva_asiento BEFORE INSERT ON public.reserva_asiento FOR EACH ROW EXECUTE FUNCTION public.proteger_reserva_asiento();


--
-- TOC entry 5025 (class 2620 OID 26067)
-- Name: asiento trg_proteger_sala_asiento; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_proteger_sala_asiento BEFORE UPDATE OF id_sala ON public.asiento FOR EACH ROW EXECUTE FUNCTION public.proteger_sala_asiento();


--
-- TOC entry 5027 (class 2620 OID 26069)
-- Name: funcion trg_proteger_sala_funcion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_proteger_sala_funcion BEFORE UPDATE OF id_sala ON public.funcion FOR EACH ROW EXECUTE FUNCTION public.proteger_sala_funcion();


--
-- TOC entry 5023 (class 2606 OID 26111)
-- Name: cuenta_postgres_usuario cuenta_postgres_usuario_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuenta_postgres_usuario
    ADD CONSTRAINT cuenta_postgres_usuario_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario);


--
-- TOC entry 5002 (class 2606 OID 25722)
-- Name: asiento fk_asiento_sala; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.asiento
    ADD CONSTRAINT fk_asiento_sala FOREIGN KEY (id_sala) REFERENCES public.sala(id_sala);


--
-- TOC entry 5022 (class 2606 OID 26051)
-- Name: auditoria fk_auditoria_usuario; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auditoria
    ADD CONSTRAINT fk_auditoria_usuario FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario);


--
-- TOC entry 5013 (class 2606 OID 25920)
-- Name: boleto fk_boleto_asiento; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.boleto
    ADD CONSTRAINT fk_boleto_asiento FOREIGN KEY (id_asiento) REFERENCES public.asiento(id_asiento);


--
-- TOC entry 5014 (class 2606 OID 25915)
-- Name: boleto fk_boleto_compra; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.boleto
    ADD CONSTRAINT fk_boleto_compra FOREIGN KEY (id_compra) REFERENCES public.compra(id_compra);


--
-- TOC entry 5015 (class 2606 OID 25925)
-- Name: boleto fk_boleto_tarifa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.boleto
    ADD CONSTRAINT fk_boleto_tarifa FOREIGN KEY (id_tarifa) REFERENCES public.tarifa(id_tarifa);


--
-- TOC entry 5009 (class 2606 OID 25867)
-- Name: compra fk_compra_promocion; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compra
    ADD CONSTRAINT fk_compra_promocion FOREIGN KEY (id_promocion) REFERENCES public.promocion(id_promocion);


--
-- TOC entry 5010 (class 2606 OID 25862)
-- Name: compra fk_compra_reserva; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compra
    ADD CONSTRAINT fk_compra_reserva FOREIGN KEY (id_reserva) REFERENCES public.reserva(id_reserva);


--
-- TOC entry 5011 (class 2606 OID 26123)
-- Name: compra fk_compra_tarifa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compra
    ADD CONSTRAINT fk_compra_tarifa FOREIGN KEY (id_tarifa) REFERENCES public.tarifa(id_tarifa);


--
-- TOC entry 5003 (class 2606 OID 25741)
-- Name: funcion fk_funcion_pelicula; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.funcion
    ADD CONSTRAINT fk_funcion_pelicula FOREIGN KEY (id_pelicula) REFERENCES public.pelicula(id_pelicula);


--
-- TOC entry 5004 (class 2606 OID 25746)
-- Name: funcion fk_funcion_sala; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.funcion
    ADD CONSTRAINT fk_funcion_sala FOREIGN KEY (id_sala) REFERENCES public.sala(id_sala);


--
-- TOC entry 5012 (class 2606 OID 25888)
-- Name: pago fk_pago_compra; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pago
    ADD CONSTRAINT fk_pago_compra FOREIGN KEY (id_compra) REFERENCES public.compra(id_compra);


--
-- TOC entry 5016 (class 2606 OID 25949)
-- Name: reembolso fk_reembolso_compra; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reembolso
    ADD CONSTRAINT fk_reembolso_compra FOREIGN KEY (id_compra) REFERENCES public.compra(id_compra);


--
-- TOC entry 5007 (class 2606 OID 25804)
-- Name: reserva_asiento fk_reserva_asiento_asiento; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserva_asiento
    ADD CONSTRAINT fk_reserva_asiento_asiento FOREIGN KEY (id_asiento) REFERENCES public.asiento(id_asiento);


--
-- TOC entry 5008 (class 2606 OID 25799)
-- Name: reserva_asiento fk_reserva_asiento_reserva; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserva_asiento
    ADD CONSTRAINT fk_reserva_asiento_reserva FOREIGN KEY (id_reserva) REFERENCES public.reserva(id_reserva);


--
-- TOC entry 5005 (class 2606 OID 25787)
-- Name: reserva fk_reserva_funcion; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserva
    ADD CONSTRAINT fk_reserva_funcion FOREIGN KEY (id_funcion) REFERENCES public.funcion(id_funcion);


--
-- TOC entry 5006 (class 2606 OID 25782)
-- Name: reserva fk_reserva_usuario; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserva
    ADD CONSTRAINT fk_reserva_usuario FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario);


--
-- TOC entry 5020 (class 2606 OID 26031)
-- Name: rol_permiso fk_rol_permiso_permiso; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rol_permiso
    ADD CONSTRAINT fk_rol_permiso_permiso FOREIGN KEY (id_permiso) REFERENCES public.permiso(id_permiso);


--
-- TOC entry 5021 (class 2606 OID 26026)
-- Name: rol_permiso fk_rol_permiso_rol; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rol_permiso
    ADD CONSTRAINT fk_rol_permiso_rol FOREIGN KEY (id_rol) REFERENCES public.rol(id_rol);


--
-- TOC entry 5001 (class 2606 OID 25702)
-- Name: sala fk_sala_cine; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sala
    ADD CONSTRAINT fk_sala_cine FOREIGN KEY (id_cine) REFERENCES public.cine(id_cine);


--
-- TOC entry 5018 (class 2606 OID 26014)
-- Name: usuario_rol fk_usuario_rol_rol; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario_rol
    ADD CONSTRAINT fk_usuario_rol_rol FOREIGN KEY (id_rol) REFERENCES public.rol(id_rol);


--
-- TOC entry 5019 (class 2606 OID 26009)
-- Name: usuario_rol fk_usuario_rol_usuario; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario_rol
    ADD CONSTRAINT fk_usuario_rol_usuario FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario);


--
-- TOC entry 5017 (class 2606 OID 25971)
-- Name: validacion_qr fk_validacion_qr_boleto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.validacion_qr
    ADD CONSTRAINT fk_validacion_qr_boleto FOREIGN KEY (id_boleto) REFERENCES public.boleto(id_boleto);


--
-- TOC entry 5195 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO imax_contador;
GRANT USAGE ON SCHEMA public TO imax_administrador;
GRANT USAGE ON SCHEMA public TO imax_cliente;
GRANT USAGE ON SCHEMA public TO imax_operador_sala;


--
-- TOC entry 5196 (class 0 OID 0)
-- Dependencies: 283
-- Name: FUNCTION auditar_cambios_imax(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.auditar_cambios_imax() FROM PUBLIC;


--
-- TOC entry 5197 (class 0 OID 0)
-- Dependencies: 281
-- Name: PROCEDURE cargar_ventas_prueba(IN p_max_funciones integer, IN p_boletos_por_funcion integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.cargar_ventas_prueba(IN p_max_funciones integer, IN p_boletos_por_funcion integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.cargar_ventas_prueba(IN p_max_funciones integer, IN p_boletos_por_funcion integer) TO imax_administrador;


--
-- TOC entry 5198 (class 0 OID 0)
-- Dependencies: 286
-- Name: PROCEDURE iniciar_compra(IN p_id_reserva integer, IN p_id_tarifa integer, IN p_metodo_pago character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.iniciar_compra(IN p_id_reserva integer, IN p_id_tarifa integer, IN p_metodo_pago character varying) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.iniciar_compra(IN p_id_reserva integer, IN p_id_tarifa integer, IN p_metodo_pago character varying) TO imax_cliente;


--
-- TOC entry 5199 (class 0 OID 0)
-- Dependencies: 288
-- Name: PROCEDURE procesar_pago_simulado(IN p_id_pago integer, IN p_aprobado boolean); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.procesar_pago_simulado(IN p_id_pago integer, IN p_aprobado boolean) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.procesar_pago_simulado(IN p_id_pago integer, IN p_aprobado boolean) TO imax_administrador;


--
-- TOC entry 5200 (class 0 OID 0)
-- Dependencies: 284
-- Name: PROCEDURE programar_funcion(IN p_id_pelicula integer, IN p_id_sala integer, IN p_fecha_inicio timestamp with time zone, IN p_fecha_fin timestamp with time zone); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.programar_funcion(IN p_id_pelicula integer, IN p_id_sala integer, IN p_fecha_inicio timestamp with time zone, IN p_fecha_fin timestamp with time zone) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.programar_funcion(IN p_id_pelicula integer, IN p_id_sala integer, IN p_fecha_inicio timestamp with time zone, IN p_fecha_fin timestamp with time zone) TO imax_administrador;


--
-- TOC entry 5201 (class 0 OID 0)
-- Dependencies: 280
-- Name: PROCEDURE registrar_pelicula(IN p_titulo character varying, IN p_sinopsis text, IN p_duracion integer, IN p_clasificacion character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.registrar_pelicula(IN p_titulo character varying, IN p_sinopsis text, IN p_duracion integer, IN p_clasificacion character varying) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.registrar_pelicula(IN p_titulo character varying, IN p_sinopsis text, IN p_duracion integer, IN p_clasificacion character varying) TO imax_administrador;


--
-- TOC entry 5202 (class 0 OID 0)
-- Dependencies: 285
-- Name: PROCEDURE reservar_asiento(IN p_id_funcion integer, IN p_id_asiento integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.reservar_asiento(IN p_id_funcion integer, IN p_id_asiento integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.reservar_asiento(IN p_id_funcion integer, IN p_id_asiento integer) TO imax_cliente;


--
-- TOC entry 5203 (class 0 OID 0)
-- Dependencies: 282
-- Name: PROCEDURE validar_boleto_qr(IN p_codigo_qr character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON PROCEDURE public.validar_boleto_qr(IN p_codigo_qr character varying) FROM PUBLIC;
GRANT ALL ON PROCEDURE public.validar_boleto_qr(IN p_codigo_qr character varying) TO imax_operador_sala;


--
-- TOC entry 5205 (class 0 OID 0)
-- Dependencies: 255
-- Name: TABLE auditoria; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.auditoria TO imax_administrador;


--
-- TOC entry 5222 (class 0 OID 0)
-- Dependencies: 261
-- Name: TABLE vista_control_boletos; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vista_control_boletos TO imax_administrador;


--
-- TOC entry 5223 (class 0 OID 0)
-- Dependencies: 259
-- Name: TABLE vista_metodos_pago; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vista_metodos_pago TO imax_contador;
GRANT SELECT ON TABLE public.vista_metodos_pago TO imax_administrador;


--
-- TOC entry 5224 (class 0 OID 0)
-- Dependencies: 256
-- Name: TABLE vista_ocupacion_funciones; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vista_ocupacion_funciones TO imax_contador;
GRANT SELECT ON TABLE public.vista_ocupacion_funciones TO imax_administrador;


--
-- TOC entry 5225 (class 0 OID 0)
-- Dependencies: 257
-- Name: TABLE vista_recaudacion_funciones; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vista_recaudacion_funciones TO imax_contador;
GRANT SELECT ON TABLE public.vista_recaudacion_funciones TO imax_administrador;


--
-- TOC entry 5226 (class 0 OID 0)
-- Dependencies: 258
-- Name: TABLE vista_top_5_funciones; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.vista_top_5_funciones TO imax_contador;
GRANT SELECT ON TABLE public.vista_top_5_funciones TO imax_administrador;


-- Completed on 2026-10-24 02:16:36

--
-- PostgreSQL database dump complete
--

\unrestrict KbmQc0t3DUXTKF00FbKkc2YpFfLZQ6VH6p8oDdTmr6YMLDmnLUmhNyGndBVQIRg

