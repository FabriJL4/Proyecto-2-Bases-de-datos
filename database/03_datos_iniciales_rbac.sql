-- =========================================================
-- PROYECTO IMAX
-- DATOS INICIALES DEL SISTEMA RBAC
-- =========================================================
-- Ejecutar después de restaurar la estructura de la BD.
-- Las cuentas de PostgreSQL deben existir previamente.
-- No incluye contraseñas ni correos personales.
-- =========================================================

BEGIN;

-- 1. ROLES DEL SISTEMA

INSERT INTO public.rol (id_rol, nombre)
VALUES
    (1, 'Operador de sala'),
    (2, 'Administrador'),
    (3, 'Taquillero'),
    (4, 'Contador'),
    (5, 'Cliente')
ON CONFLICT (id_rol) DO NOTHING;


-- 2. PERMISOS DEL SISTEMA

INSERT INTO public.permiso (nombre, descripcion)
SELECT v.nombre, NULL
FROM (
    VALUES
        ('roles_gestionar'),
        ('salas_funciones_gestionar'),
        ('boletos_comprar'),
        ('venta_presencial'),
        ('qr_ver_propio'),
        ('cartelera_gestionar'),
        ('qr_validar'),
        ('cartelera_ver'),
        ('caja_propia_consultar'),
        ('reportes_financieros'),
        ('qr_emitir'),
        ('reportes_globales'),
        ('qr_incidencias'),
        ('auditoria_consultar'),
        ('tarifas_gestionar')
) AS v(nombre)
WHERE NOT EXISTS (
    SELECT 1
    FROM public.permiso p
    WHERE p.nombre = v.nombre
);


-- 3. USUARIOS INICIALES
-- Correos ficticios, únicamente para restauración.

INSERT INTO public.usuario (
    id_usuario,
    nombre,
    apellido,
    correo
)
VALUES
    (1, 'Carlos', 'Ramírez', 'carlos@imax-pruebas.invalid'),
    (4, 'Ana', 'Prueba', 'ana@imax-pruebas.invalid'),
    (5, 'Luis', 'Prueba', 'luis@imax-pruebas.invalid'),
    (8, 'Contador', 'Prueba', 'contador@imax-pruebas.invalid'),
    (9, 'Operador', 'Prueba', 'operador@imax-pruebas.invalid')
ON CONFLICT (id_usuario) DO NOTHING;


-- 4. ASIGNACIÓN DE PERMISOS A ROLES

WITH asignaciones(nombre_rol, nombre_permiso) AS (
    VALUES

    -- Administrador: 9 permisos
    ('Administrador', 'auditoria_consultar'),
    ('Administrador', 'cartelera_gestionar'),
    ('Administrador', 'cartelera_ver'),
    ('Administrador', 'qr_incidencias'),
    ('Administrador', 'reportes_financieros'),
    ('Administrador', 'reportes_globales'),
    ('Administrador', 'roles_gestionar'),
    ('Administrador', 'salas_funciones_gestionar'),
    ('Administrador', 'tarifas_gestionar'),

    -- Cliente: 3 permisos
    ('Cliente', 'boletos_comprar'),
    ('Cliente', 'cartelera_ver'),
    ('Cliente', 'qr_ver_propio'),

    -- Contador: 2 permisos
    ('Contador', 'cartelera_ver'),
    ('Contador', 'reportes_financieros'),

    -- Operador de sala: 2 permisos
    ('Operador de sala', 'cartelera_ver'),
    ('Operador de sala', 'qr_validar'),

    -- Taquillero: 4 permisos
    ('Taquillero', 'caja_propia_consultar'),
    ('Taquillero', 'cartelera_ver'),
    ('Taquillero', 'qr_emitir'),
    ('Taquillero', 'venta_presencial')
)
INSERT INTO public.rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM asignaciones a
JOIN public.rol r
    ON r.nombre = a.nombre_rol
JOIN public.permiso p
    ON p.nombre = a.nombre_permiso
WHERE NOT EXISTS (
    SELECT 1
    FROM public.rol_permiso rp
    WHERE rp.id_rol = r.id_rol
      AND rp.id_permiso = p.id_permiso
);


-- 5. ASIGNACIÓN DE ROLES A USUARIOS

WITH asignaciones(id_usuario, nombre_rol) AS (
    VALUES
        (1, 'Cliente'),
        (4, 'Administrador'),
        (5, 'Taquillero'),
        (8, 'Contador'),
        (9, 'Operador de sala')
)
INSERT INTO public.usuario_rol (id_usuario, id_rol)
SELECT a.id_usuario, r.id_rol
FROM asignaciones a
JOIN public.rol r
    ON r.nombre = a.nombre_rol
WHERE NOT EXISTS (
    SELECT 1
    FROM public.usuario_rol ur
    WHERE ur.id_usuario = a.id_usuario
      AND ur.id_rol = r.id_rol
);


-- 6. VINCULAR CUENTAS POSTGRESQL CON USUARIOS IMAX

INSERT INTO public.cuenta_postgres_usuario (
    nombre_cuenta,
    id_usuario
)
VALUES
    ('imax_ana', 4),
    ('imax_carlos', 1),
    ('imax_operador', 9)
ON CONFLICT (nombre_cuenta) DO NOTHING;


-- 7. AJUSTAR SECUENCIAS PARA FUTUROS REGISTROS

SELECT setval(
    pg_get_serial_sequence('public.rol', 'id_rol'),
    GREATEST((SELECT MAX(id_rol) FROM public.rol), 1),
    TRUE
);

SELECT setval(
    pg_get_serial_sequence('public.permiso', 'id_permiso'),
    GREATEST((SELECT MAX(id_permiso) FROM public.permiso), 1),
    TRUE
);

SELECT setval(
    pg_get_serial_sequence('public.usuario', 'id_usuario'),
    GREATEST((SELECT MAX(id_usuario) FROM public.usuario), 1),
    TRUE
);

COMMIT;
