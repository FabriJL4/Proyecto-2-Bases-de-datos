# Proyecto-2-Bases-de-datos Ecosistema Digital de Cines IMAX
Avances del proyecto

Funcionalidades implementadas

- Gestión de películas y funciones.
- Reserva de asientos con control de concurrencia.
- Procesamiento simulado de compras y pagos.
- Emisión y validación de boletos con códigos QR.
- Control de acceso basado en roles (RBAC).
- Auditoría de operaciones mediante triggers.
- Reportes de ocupación, recaudación y métodos de pago.
- Carga de datos sintéticos para pruebas.

Archivos principales

- database/00_roles_postgres.sql: creación de roles y cuentas PostgreSQL.
- database/01_estructura_base.sql: estructura inicial de la base de datos.
- database/02_IMAX_estructura_final.sql: estructura final con procedimientos, triggers, vistas y permisos.
- database/03_datos_iniciales_rbac.sql: usuarios, roles y permisos iniciales.

Orden de restauración

1. Crear una base de datos llamada `IMAX`.
2. Ejecutar `00_roles_postgres.sql` con una cuenta administradora de PostgreSQL.
3. Restaurar `02_IMAX_estructura_final.sql` en la base de datos IMAX.
4. Ejecutar `03_datos_iniciales_rbac.sql`.
5. Configurar contraseñas para las cuentas PostgreSQL de prueba.

Nota: el archivo de estructura final es un respaldo independiente, no debe ejecutarse encima de la estructura inicial. Los archivos publicados de esquema y RBAC no incluyen todas las películas, salas, funciones y ventas sintéticas utilizadas en las pruebas.

Resultados de pruebas

- 415 reservas registradas.
- 412 compras registradas.
- 377 pagos aprobados.
- 35 pagos rechazados.
- 377 boletos generados.
- ₡2.262.000 en compras pagadas.
- 1.422 eventos de auditoría observados.

Evidencias

Las capturas incluidas en la carpeta `evidencias` muestran los resultados de ventas, auditoría, permisos RBAC y reportes analíticos.

Herramientas

- PostgreSQL
- pgAdmin
- SQL y PL/pgSQL

El proyecto se desarrolla a nivel de base de datos; no requiere una interfaz gráfica.
