-- PROYECTO IMAX
-- Roles y cuentas de PostgreSQL
-- Ejecutar como postgres ANTES de restaurar el esquema.
-- No contiene contraseñas.

-- 1. Crear los cinco grupos de permisos

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'imax_administrador'
    ) THEN
        CREATE ROLE imax_administrador NOLOGIN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'imax_cliente'
    ) THEN
        CREATE ROLE imax_cliente NOLOGIN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'imax_contador'
    ) THEN
        CREATE ROLE imax_contador NOLOGIN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'imax_operador_sala'
    ) THEN
        CREATE ROLE imax_operador_sala NOLOGIN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'imax_taquillero'
    ) THEN
        CREATE ROLE imax_taquillero NOLOGIN;
    END IF;
END;
$$;

-- 2. Crear cuentas individuales sin contraseñas

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'imax_ana'
    ) THEN
        CREATE ROLE imax_ana LOGIN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'imax_carlos'
    ) THEN
        CREATE ROLE imax_carlos LOGIN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'imax_operador'
    ) THEN
        CREATE ROLE imax_operador LOGIN;
    END IF;
END;
$$;

-- 3. Asignar cada cuenta a su grupo

GRANT imax_administrador TO imax_ana;

GRANT imax_cliente TO imax_carlos;

GRANT imax_operador_sala TO imax_operador;
