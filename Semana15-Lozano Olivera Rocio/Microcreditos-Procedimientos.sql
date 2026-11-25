/* =====================================================================
   Modelo ER v3 - Esquema para SQL Server (T-SQL)
   ===================================================================== */
IF DB_ID(N'microcreditos') IS NULL
    CREATE DATABASE microcreditos;
GO
USE microcreditos;
GO

/* ---------- SEGURIDAD Y USUARIOS ---------- */

CREATE TABLE PERMISO (
    permiso_id   INT IDENTITY(1,1) PRIMARY KEY,
    nombre       NVARCHAR(100) NOT NULL,
    descripcion  NVARCHAR(255) NULL,
    modulo       NVARCHAR(100) NULL
);

CREATE TABLE ROL (
    rol_id       INT IDENTITY(1,1) PRIMARY KEY,
    nombre       NVARCHAR(100) NOT NULL CONSTRAINT UQ_ROL_nombre UNIQUE,
    descripcion  NVARCHAR(255) NULL
);

CREATE TABLE ROL_PERMISO (
    rol_id      INT NOT NULL REFERENCES ROL(rol_id),
    permiso_id  INT NOT NULL REFERENCES PERMISO(permiso_id),
    CONSTRAINT PK_ROL_PERMISO PRIMARY KEY (rol_id, permiso_id)
);

CREATE TABLE USUARIO (
    usuario_id      INT IDENTITY(1,1) PRIMARY KEY,
    rol_id          INT NOT NULL REFERENCES ROL(rol_id),
    nombre          NVARCHAR(100) NOT NULL,
    apellido        NVARCHAR(100) NOT NULL,
    correo          NVARCHAR(150) NOT NULL CONSTRAINT UQ_USUARIO_correo UNIQUE,
    telefono        NVARCHAR(20)  NULL,
    password_hash   NVARCHAR(256) NOT NULL,
    fecha_registro  DATETIME2(0)  NOT NULL CONSTRAINT DF_USUARIO_fecha DEFAULT SYSDATETIME(),
    estado          NVARCHAR(20)  NOT NULL CONSTRAINT DF_USUARIO_estado DEFAULT N'ACTIVO',
    gestionado_por  INT NULL  
);

/* ---------- SUBTIPOS DE USUARIO (ISA) ---------- */

CREATE TABLE ADMINISTRADOR_ORGANIZACION (
    usuario_id  INT NOT NULL PRIMARY KEY REFERENCES USUARIO(usuario_id),
    estado      NVARCHAR(20) NOT NULL DEFAULT N'ACTIVO'
);

ALTER TABLE USUARIO
    ADD CONSTRAINT FK_USUARIO_GESTIONADO
    FOREIGN KEY (gestionado_por) REFERENCES ADMINISTRADOR_ORGANIZACION(usuario_id);

CREATE TABLE COORDINADOR_PROGRAMAS (
    usuario_id  INT NOT NULL PRIMARY KEY REFERENCES USUARIO(usuario_id)
);

CREATE TABLE SOLICITANTE (
    usuario_id           INT NOT NULL PRIMARY KEY REFERENCES USUARIO(usuario_id),
    tipo_documento       NVARCHAR(20)  NOT NULL,
    numero_documento     NVARCHAR(20)  NOT NULL CONSTRAINT UQ_SOLICITANTE_doc UNIQUE,
    fecha_nacimiento     DATE          NULL,
    direccion            NVARCHAR(255) NULL,
    nivel_educativo      NVARCHAR(50)  NULL,
    situacion_laboral    NVARCHAR(50)  NULL,
    ingreso_referencial  DECIMAL(12,2) NULL,
    numero_dependientes  INT           NULL CONSTRAINT DF_SOLIC_dep DEFAULT 0
);

CREATE TABLE BENEFICIARIO (
    usuario_id    INT NOT NULL PRIMARY KEY REFERENCES SOLICITANTE(usuario_id),
    estado        NVARCHAR(20)  NOT NULL DEFAULT N'ACTIVO',
    fecha_retiro  DATE          NULL,
    motivo_retiro NVARCHAR(255) NULL
);

CREATE TABLE FINANCIADOR (
    usuario_id      INT NOT NULL PRIMARY KEY REFERENCES USUARIO(usuario_id),
    nombre_entidad  NVARCHAR(150) NOT NULL,
    contacto        NVARCHAR(150) NULL,
    tipo            NVARCHAR(50)  NULL
);

CREATE TABLE DIRECTIVO_ONG (
    usuario_id  INT NOT NULL PRIMARY KEY REFERENCES USUARIO(usuario_id),
    cargo       NVARCHAR(100) NULL
);

CREATE TABLE TECNICO_CAPACITADOR (
    usuario_id    INT NOT NULL PRIMARY KEY REFERENCES USUARIO(usuario_id),
    especialidad  NVARCHAR(100) NULL,
    disponibilidad NVARCHAR(50) NULL
);

CREATE TABLE ASESOR_TECNICO (
    usuario_id     INT NOT NULL PRIMARY KEY REFERENCES USUARIO(usuario_id),
    especialidad   NVARCHAR(100) NULL,
    disponibilidad NVARCHAR(50)  NULL
);

CREATE TABLE AREA_FINANCIERA (
    usuario_id  INT NOT NULL PRIMARY KEY REFERENCES USUARIO(usuario_id),
    cargo       NVARCHAR(100) NULL
);

/* ---------- AUDITORÍA, IMPORTACIÓN, REGLAS ---------- */

CREATE TABLE BITACORA_AUDITORIA (
    bitacora_id        BIGINT IDENTITY(1,1) PRIMARY KEY,
    usuario_id         INT NOT NULL REFERENCES USUARIO(usuario_id),
    fecha_hora         DATETIME2(0) NOT NULL CONSTRAINT DF_BIT_fecha DEFAULT SYSDATETIME(),
    accion             NVARCHAR(50)  NOT NULL,
    tabla_afectada     NVARCHAR(100) NULL,
    registro_afectado  NVARCHAR(100) NULL
);

CREATE TABLE IMPORTACION (
    importacion_id        INT IDENTITY(1,1) PRIMARY KEY,
    admin_id              INT NOT NULL REFERENCES ADMINISTRADOR_ORGANIZACION(usuario_id),
    nombre_archivo        NVARCHAR(255) NOT NULL,
    fuente                NVARCHAR(150) NULL,
    fecha_importacion     DATETIME2(0)  NOT NULL CONSTRAINT DF_IMP_fecha DEFAULT SYSDATETIME(),
    registros_importados  INT           NOT NULL CONSTRAINT DF_IMP_reg DEFAULT 0,
    estado                NVARCHAR(20)  NOT NULL CONSTRAINT DF_IMP_estado DEFAULT N'PENDIENTE'
);

CREATE TABLE REGLA_ALERTA (
    regla_id      INT IDENTITY(1,1) PRIMARY KEY,
    admin_id      INT NOT NULL REFERENCES ADMINISTRADOR_ORGANIZACION(usuario_id),
    tipo          NVARCHAR(50)  NOT NULL,
    condicion     NVARCHAR(255) NOT NULL,
    valor_umbral  DECIMAL(18,4) NULL,
    estado        NVARCHAR(20)  NOT NULL DEFAULT N'ACTIVA'
);

/* ---------- SOLICITUDES DE INGRESO Y PROGRAMA ---------- */

CREATE TABLE SOLICITUD_INGRESO (
    solicitud_ingreso_id  INT IDENTITY(1,1) PRIMARY KEY,
    solicitante_id        INT NOT NULL REFERENCES SOLICITANTE(usuario_id),
    coordinador_id        INT NULL REFERENCES COORDINADOR_PROGRAMAS(usuario_id),
    fecha_solicitud       DATETIME2(0) NOT NULL CONSTRAINT DF_SI_fecha DEFAULT SYSDATETIME(),
    estado                NVARCHAR(20) NOT NULL CONSTRAINT DF_SI_estado DEFAULT N'PENDIENTE',
    fecha_evaluacion      DATETIME2(0) NULL,
    documentacion         NVARCHAR(MAX) NULL,
    observaciones         NVARCHAR(MAX) NULL
);

CREATE TABLE EMPRENDIMIENTO (
    emprendimiento_id   INT IDENTITY(1,1) PRIMARY KEY,
    beneficiario_id     INT NOT NULL REFERENCES BENEFICIARIO(usuario_id),
    nombre_negocio      NVARCHAR(150) NOT NULL,
    sector              NVARCHAR(100) NULL,
    descripcion         NVARCHAR(MAX) NULL,
    estado_actual       NVARCHAR(50)  NULL,
    fecha_inicio        DATE          NULL,
    empleos_iniciales   INT           NULL CONSTRAINT DF_EMP_ei DEFAULT 0,
    empleos_actuales    INT           NULL,
    estado              NVARCHAR(20)  NOT NULL CONSTRAINT DF_EMP_estado DEFAULT N'ACTIVO'
);

CREATE TABLE CAPACITACION (
    capacitacion_id    INT IDENTITY(1,1) PRIMARY KEY,
    nombre             NVARCHAR(150) NOT NULL,
    tipo               NVARCHAR(50)  NULL,
    fecha_programada   DATETIME2(0)  NULL,
    estado             NVARCHAR(20)  NULL,
    es_obligatoria     BIT           NOT NULL CONSTRAINT DF_CAP_obl DEFAULT 0,
    observaciones      NVARCHAR(MAX) NULL
);

CREATE TABLE ASIGNACION_CAPACITACION (
    asignacion_cap_id  INT IDENTITY(1,1) PRIMARY KEY,
    coordinador_id     INT NOT NULL REFERENCES COORDINADOR_PROGRAMAS(usuario_id),
    tecnico_id         INT NOT NULL REFERENCES TECNICO_CAPACITADOR(usuario_id),
    capacitacion_id    INT NOT NULL REFERENCES CAPACITACION(capacitacion_id),
    fecha_asignacion   DATE NOT NULL CONSTRAINT DF_ASGC_fecha DEFAULT CAST(SYSDATETIME() AS DATE),
    estado             NVARCHAR(20) NULL
);

CREATE TABLE ASIGNACION_ASESOR (
    asignacion_ase_id  INT IDENTITY(1,1) PRIMARY KEY,
    coordinador_id     INT NOT NULL REFERENCES COORDINADOR_PROGRAMAS(usuario_id),
    asesor_id          INT NOT NULL REFERENCES ASESOR_TECNICO(usuario_id),
    beneficiario_id    INT NOT NULL REFERENCES BENEFICIARIO(usuario_id),
    fecha_asignacion   DATE NOT NULL CONSTRAINT DF_ASGA_fecha DEFAULT CAST(SYSDATETIME() AS DATE),
    estado             NVARCHAR(20) NULL
);

/* ---------- MICROCRÉDITO ---------- */

CREATE TABLE SOLICITUD_MICROCREDITO (
    solicitud_mc_id       INT IDENTITY(1,1) PRIMARY KEY,
    emprendimiento_id     INT NOT NULL REFERENCES EMPRENDIMIENTO(emprendimiento_id),
    coordinador_id        INT NULL REFERENCES COORDINADOR_PROGRAMAS(usuario_id),
    area_financiera_id    INT NULL REFERENCES AREA_FINANCIERA(usuario_id),
    fecha_solicitud       DATETIME2(0) NOT NULL CONSTRAINT DF_SMC_fecha DEFAULT SYSDATETIME(),
    monto_solicitado      DECIMAL(12,2) NOT NULL CONSTRAINT CK_SMC_monto CHECK (monto_solicitado > 0),
    finalidad             NVARCHAR(255) NULL,
    fecha_verificacion    DATETIME2(0)  NULL,
    resultado_evaluacion  NVARCHAR(50)  NULL,
    fecha_evaluacion      DATETIME2(0)  NULL,
    observaciones         NVARCHAR(MAX) NULL,
    estado                NVARCHAR(20)  NOT NULL CONSTRAINT DF_SMC_estado DEFAULT N'REGISTRADA'
);

CREATE TABLE MICROCREDITO (
    microcredito_id       INT IDENTITY(1,1) PRIMARY KEY,
    solicitud_mc_id       INT NOT NULL CONSTRAINT UQ_MICRO_solicitud UNIQUE
                          REFERENCES SOLICITUD_MICROCREDITO(solicitud_mc_id),
    admin_id              INT NOT NULL REFERENCES ADMINISTRADOR_ORGANIZACION(usuario_id),
    codigo_credito        NVARCHAR(30)  NOT NULL CONSTRAINT UQ_MICRO_codigo UNIQUE,
    monto_otorgado        DECIMAL(12,2) NOT NULL,
    fecha_otorgamiento    DATE          NULL,
    estado_credito        NVARCHAR(20)  NOT NULL,
    fecha_registro        DATETIME2(0)  NOT NULL CONSTRAINT DF_MICRO_reg DEFAULT SYSDATETIME(),
    fecha_actualizacion   DATETIME2(0)  NULL
);

/* ---------- ALERTAS, VISITAS, ASISTENCIA TÉCNICA, HITOS ---------- */

CREATE TABLE ALERTA_RIESGO (
    alerta_id            INT IDENTITY(1,1) PRIMARY KEY,
    regla_id             INT NOT NULL REFERENCES REGLA_ALERTA(regla_id),
    emprendimiento_id    INT NOT NULL REFERENCES EMPRENDIMIENTO(emprendimiento_id),
    asesor_id            INT NULL REFERENCES ASESOR_TECNICO(usuario_id),
    coordinador_id       INT NULL REFERENCES COORDINADOR_PROGRAMAS(usuario_id),
    tipo                 NVARCHAR(50)  NULL,
    descripcion          NVARCHAR(MAX) NULL,
    estado               NVARCHAR(20)  NULL,
    nivel_riesgo         NVARCHAR(20)  NULL,
    fecha_generacion     DATETIME2(0)  NOT NULL CONSTRAINT DF_ALERTA_fecha DEFAULT SYSDATETIME(),
    fecha_atencion       DATETIME2(0)  NULL,
    acciones_realizadas  NVARCHAR(MAX) NULL,
    observaciones        NVARCHAR(MAX) NULL
);

CREATE TABLE VISITA_MONITOREO (
    visita_id                INT IDENTITY(1,1) PRIMARY KEY,
    asesor_id                INT NOT NULL REFERENCES ASESOR_TECNICO(usuario_id),
    emprendimiento_id        INT NOT NULL REFERENCES EMPRENDIMIENTO(emprendimiento_id),
    microcredito_id          INT NULL REFERENCES MICROCREDITO(microcredito_id),
    fecha_programada         DATETIME2(0) NULL,
    fecha_visita             DATETIME2(0) NULL,
    hallazgos                NVARCHAR(MAX) NULL,
    dificultades             NVARCHAR(MAX) NULL,
    acuerdos                 NVARCHAR(MAX) NULL,
    observaciones            NVARCHAR(MAX) NULL,
    estado                   NVARCHAR(20)  NULL,
    estado_sincronizacion    NVARCHAR(20)  NULL,
    fecha_sincronizacion     DATETIME2(0)  NULL
);

CREATE TABLE ASISTENCIA_TECNICA (
    asistencia_tec_id          INT IDENTITY(1,1) PRIMARY KEY,
    asesor_id                  INT NOT NULL REFERENCES ASESOR_TECNICO(usuario_id),
    emprendimiento_id          INT NOT NULL REFERENCES EMPRENDIMIENTO(emprendimiento_id),
    microcredito_id            INT NULL REFERENCES MICROCREDITO(microcredito_id),
    fecha                      DATE NOT NULL,
    tema                       NVARCHAR(150) NULL,
    recomendaciones            NVARCHAR(MAX) NULL,
    compromisos                NVARCHAR(MAX) NULL,
    proximos_pasos             NVARCHAR(MAX) NULL,
    fecha_proximo_seguimiento  DATE NULL,
    estado                     NVARCHAR(20) NULL
);

CREATE TABLE HITO_NEGOCIO (
    hito_id              INT IDENTITY(1,1) PRIMARY KEY,
    asesor_id            INT NOT NULL REFERENCES ASESOR_TECNICO(usuario_id),
    emprendimiento_id    INT NOT NULL REFERENCES EMPRENDIMIENTO(emprendimiento_id),
    titulo               NVARCHAR(150) NOT NULL,
    tipo                 NVARCHAR(50)  NULL,
    descripcion          NVARCHAR(MAX) NULL,
    fecha_limite         DATE          NULL,
    fecha_cumplimiento   DATE          NULL,
    estado               NVARCHAR(20)  NULL,
    observaciones        NVARCHAR(MAX) NULL
);

/* ---------- ATENCIÓN, EVIDENCIAS, ASISTENCIA A CAPACITACIÓN ---------- */

CREATE TABLE SOLICITUD_ATENCION (
    atencion_id      INT IDENTITY(1,1) PRIMARY KEY,
    beneficiario_id  INT NOT NULL REFERENCES BENEFICIARIO(usuario_id),
    asesor_id        INT NULL REFERENCES ASESOR_TECNICO(usuario_id),
    tipo             NVARCHAR(50)  NULL,
    detalle          NVARCHAR(MAX) NULL,
    fecha            DATETIME2(0)  NOT NULL CONSTRAINT DF_SATN_fecha DEFAULT SYSDATETIME(),
    estado           NVARCHAR(20)  NULL,
    respuesta        NVARCHAR(MAX) NULL,
    fecha_cierre     DATETIME2(0)  NULL
);

CREATE TABLE EVIDENCIA (
    evidencia_id     INT IDENTITY(1,1) PRIMARY KEY,
    visita_id        INT NULL REFERENCES VISITA_MONITOREO(visita_id),
    capacitacion_id  INT NULL REFERENCES CAPACITACION(capacitacion_id),
    tipo             NVARCHAR(50)  NULL,
    nombre_archivo   NVARCHAR(255) NOT NULL,
    ruta             NVARCHAR(500) NOT NULL,
    fecha_subida     DATETIME2(0)  NOT NULL CONSTRAINT DF_EVID_fecha DEFAULT SYSDATETIME(),
    descripcion      NVARCHAR(MAX) NULL
);

CREATE TABLE ASISTENCIA_CAPACITACION (
    asistencia_cap_id  INT IDENTITY(1,1) PRIMARY KEY,
    capacitacion_id    INT NOT NULL REFERENCES CAPACITACION(capacitacion_id),
    tecnico_id         INT NOT NULL REFERENCES TECNICO_CAPACITADOR(usuario_id),
    beneficiario_id    INT NOT NULL REFERENCES BENEFICIARIO(usuario_id),
    microcredito_id    INT NULL REFERENCES MICROCREDITO(microcredito_id),
    asistencia         BIT NOT NULL,
    fecha              DATE NOT NULL,
    resultado          NVARCHAR(50)  NULL,
    observaciones      NVARCHAR(MAX) NULL
);

/* ---------- REPORTES E INDICADORES ---------- */

CREATE TABLE REPORTE (
    reporte_id        INT IDENTITY(1,1) PRIMARY KEY,
    admin_id          INT NOT NULL REFERENCES ADMINISTRADOR_ORGANIZACION(usuario_id),
    tipo              NVARCHAR(50)  NULL,
    periodo           NVARCHAR(30)  NULL,
    formato           NVARCHAR(20)  NULL,
    fecha_generacion  DATETIME2(0)  NOT NULL CONSTRAINT DF_REP_fecha DEFAULT SYSDATETIME()
);

CREATE TABLE INDICADOR_IMPACTO (
    indicador_id  INT IDENTITY(1,1) PRIMARY KEY,
    nombre        NVARCHAR(150) NOT NULL,
    descripcion   NVARCHAR(MAX) NULL,
    valor         DECIMAL(18,4) NULL,
    periodo       NVARCHAR(30)  NULL,
    fuente        NVARCHAR(150) NULL
);

CREATE TABLE REPORTE_INDICADOR (
    reporte_id    INT NOT NULL REFERENCES REPORTE(reporte_id),
    indicador_id  INT NOT NULL REFERENCES INDICADOR_IMPACTO(indicador_id),
    CONSTRAINT PK_REPORTE_INDICADOR PRIMARY KEY (reporte_id, indicador_id)
);

-- Consulta de reportes por usuarios (Directivo, Financiador, Admin, Coordinador)
CREATE TABLE CONSULTA_REPORTE (
    usuario_id     INT NOT NULL REFERENCES USUARIO(usuario_id),
    reporte_id     INT NOT NULL REFERENCES REPORTE(reporte_id),
    fecha_consulta DATETIME2(0) NOT NULL CONSTRAINT DF_CONS_fecha DEFAULT SYSDATETIME(),
    CONSTRAINT PK_CONSULTA_REPORTE PRIMARY KEY (usuario_id, reporte_id, fecha_consulta)
);
GO

/* ===================================================================
   CREACION DE INDICES NONCLUSTERED - microcreditos
   Ejecutar DESPUES de crear todas las tablas
   =================================================================== */
USE microcreditos;
GO

/* Seguridad y usuarios */
CREATE NONCLUSTERED INDEX IX_USUARIO_ROL ON USUARIO(rol_id);
GO
CREATE NONCLUSTERED INDEX IX_USUARIO_GESTIONADO ON USUARIO(gestionado_por);
GO
CREATE NONCLUSTERED INDEX IX_ROL_PERMISO_PERMISO ON ROL_PERMISO(permiso_id);
GO

/* Auditoria, importacion y reglas */
CREATE NONCLUSTERED INDEX IX_BITACORA_USUARIO ON BITACORA_AUDITORIA(usuario_id);
GO
CREATE NONCLUSTERED INDEX IX_BITACORA_FECHA ON BITACORA_AUDITORIA(fecha_hora);
GO
CREATE NONCLUSTERED INDEX IX_IMPORTACION_ADMIN ON IMPORTACION(admin_id);
GO
CREATE NONCLUSTERED INDEX IX_REGLA_ADMIN ON REGLA_ALERTA(admin_id);
GO

/* Solicitudes de ingreso y programa */
CREATE NONCLUSTERED INDEX IX_SOLIC_ING_SOLICITANTE ON SOLICITUD_INGRESO(solicitante_id);
GO
CREATE NONCLUSTERED INDEX IX_SOLIC_ING_COORD ON SOLICITUD_INGRESO(coordinador_id);
GO
CREATE NONCLUSTERED INDEX IX_SOLIC_ING_ESTADO ON SOLICITUD_INGRESO(estado);
GO
CREATE NONCLUSTERED INDEX IX_EMP_BENEFICIARIO ON EMPRENDIMIENTO(beneficiario_id);
GO
CREATE NONCLUSTERED INDEX IX_ASIGCAP_COORD ON ASIGNACION_CAPACITACION(coordinador_id);
GO
CREATE NONCLUSTERED INDEX IX_ASIGCAP_TECNICO ON ASIGNACION_CAPACITACION(tecnico_id);
GO
CREATE NONCLUSTERED INDEX IX_ASIGCAP_CAPACITACION ON ASIGNACION_CAPACITACION(capacitacion_id);
GO
CREATE NONCLUSTERED INDEX IX_ASIGASE_COORD ON ASIGNACION_ASESOR(coordinador_id);
GO
CREATE NONCLUSTERED INDEX IX_ASIGASE_ASESOR ON ASIGNACION_ASESOR(asesor_id);
GO
CREATE NONCLUSTERED INDEX IX_ASIGASE_BENEFICIARIO ON ASIGNACION_ASESOR(beneficiario_id);
GO

/* Microcredito */
CREATE NONCLUSTERED INDEX IX_SOLMC_EMPRENDIMIENTO ON SOLICITUD_MICROCREDITO(emprendimiento_id);
GO
CREATE NONCLUSTERED INDEX IX_SOLMC_COORD ON SOLICITUD_MICROCREDITO(coordinador_id);
GO
CREATE NONCLUSTERED INDEX IX_SOLMC_AREA ON SOLICITUD_MICROCREDITO(area_financiera_id);
GO
CREATE NONCLUSTERED INDEX IX_SOLMC_FECHA ON SOLICITUD_MICROCREDITO(fecha_solicitud);
GO
CREATE NONCLUSTERED INDEX IX_MICRO_ADMIN ON MICROCREDITO(admin_id);
GO
CREATE NONCLUSTERED INDEX IX_MICRO_ESTADO ON MICROCREDITO(estado_credito);
GO

/* Alertas, visitas, asistencia tecnica e hitos */
CREATE NONCLUSTERED INDEX IX_ALERTA_REGLA ON ALERTA_RIESGO(regla_id);
GO
CREATE NONCLUSTERED INDEX IX_ALERTA_EMPRENDIMIENTO ON ALERTA_RIESGO(emprendimiento_id);
GO
CREATE NONCLUSTERED INDEX IX_ALERTA_ASESOR ON ALERTA_RIESGO(asesor_id);
GO
CREATE NONCLUSTERED INDEX IX_ALERTA_COORD ON ALERTA_RIESGO(coordinador_id);
GO
CREATE NONCLUSTERED INDEX IX_ALERTA_ESTADO ON ALERTA_RIESGO(estado);
GO
CREATE NONCLUSTERED INDEX IX_VISITA_ASESOR ON VISITA_MONITOREO(asesor_id);
GO
CREATE NONCLUSTERED INDEX IX_VISITA_EMPRENDIMIENTO ON VISITA_MONITOREO(emprendimiento_id);
GO
CREATE NONCLUSTERED INDEX IX_VISITA_MICROCREDITO ON VISITA_MONITOREO(microcredito_id);
GO
CREATE NONCLUSTERED INDEX IX_VISITA_FECHA ON VISITA_MONITOREO(fecha_programada);
GO
CREATE NONCLUSTERED INDEX IX_ASTEC_ASESOR ON ASISTENCIA_TECNICA(asesor_id);
GO
CREATE NONCLUSTERED INDEX IX_ASTEC_EMPRENDIMIENTO ON ASISTENCIA_TECNICA(emprendimiento_id);
GO
CREATE NONCLUSTERED INDEX IX_ASTEC_MICROCREDITO ON ASISTENCIA_TECNICA(microcredito_id);
GO
CREATE NONCLUSTERED INDEX IX_ASTEC_FECHA ON ASISTENCIA_TECNICA(fecha);
GO
CREATE NONCLUSTERED INDEX IX_HITO_ASESOR ON HITO_NEGOCIO(asesor_id);
GO
CREATE NONCLUSTERED INDEX IX_HITO_EMPRENDIMIENTO ON HITO_NEGOCIO(emprendimiento_id);
GO

/* Atencion, evidencias y asistencia a capacitacion */
CREATE NONCLUSTERED INDEX IX_SATN_BENEFICIARIO ON SOLICITUD_ATENCION(beneficiario_id);
GO
CREATE NONCLUSTERED INDEX IX_SATN_ASESOR ON SOLICITUD_ATENCION(asesor_id);
GO
CREATE NONCLUSTERED INDEX IX_SATN_ESTADO ON SOLICITUD_ATENCION(estado);
GO
CREATE NONCLUSTERED INDEX IX_EVID_VISITA ON EVIDENCIA(visita_id);
GO
CREATE NONCLUSTERED INDEX IX_EVID_CAPACITACION ON EVIDENCIA(capacitacion_id);
GO
CREATE NONCLUSTERED INDEX IX_ASISTCAP_CAPACITACION ON ASISTENCIA_CAPACITACION(capacitacion_id);
GO
CREATE NONCLUSTERED INDEX IX_ASISTCAP_TECNICO ON ASISTENCIA_CAPACITACION(tecnico_id);
GO
CREATE NONCLUSTERED INDEX IX_ASISTCAP_BENEFICIARIO ON ASISTENCIA_CAPACITACION(beneficiario_id);
GO
CREATE NONCLUSTERED INDEX IX_ASISTCAP_MICROCREDITO ON ASISTENCIA_CAPACITACION(microcredito_id);
GO

/* Reportes e indicadores */
CREATE NONCLUSTERED INDEX IX_REPORTE_ADMIN ON REPORTE(admin_id);
GO
CREATE NONCLUSTERED INDEX IX_REPINDIC_INDICADOR ON REPORTE_INDICADOR(indicador_id);
GO
CREATE NONCLUSTERED INDEX IX_CONSREP_REPORTE ON CONSULTA_REPORTE(reporte_id);
GO

USE microcreditos;
GO
SET NOCOUNT ON;

-- 1. Roles y usuarios base (10)
INSERT INTO ROL (nombre, descripcion)
VALUES ('Administrador','Gestion del sistema'),('Coordinador','Coordinacion de programas'),
       ('Asesor','Asesoria tecnica'),('Tecnico','Capacitacion'),('Beneficiario','Emprendedor'),
       ('Financiador','Entidad financiadora'),('Directivo','Directivo ONG'),
       ('Solicitante','Solicitante de ingreso'),('Area financiera','Evaluacion de creditos'),
       ('Supervisor','Supervision');

INSERT INTO USUARIO (rol_id, nombre, apellido, correo, telefono, password_hash)
SELECT i, CONCAT('Nombre', i), CONCAT('Apellido', i), CONCAT('usuario', i, '@mail.com'),
       CONCAT('9000000', i), CONCAT('hash', i)
FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10)) AS v(i);

INSERT INTO ADMINISTRADOR_ORGANIZACION (usuario_id) VALUES (1);
INSERT INTO COORDINADOR_PROGRAMAS (usuario_id) VALUES (2);
INSERT INTO ASESOR_TECNICO (usuario_id, especialidad, disponibilidad) VALUES (3,'Negocios','Disponible');
INSERT INTO TECNICO_CAPACITADOR (usuario_id, especialidad, disponibilidad) VALUES (4,'Contabilidad','Disponible');
INSERT INTO FINANCIADOR (usuario_id, nombre_entidad, contacto, tipo) VALUES (5,'Fondo Demo','fondo@mail.com','Privado');
INSERT INTO DIRECTIVO_ONG (usuario_id, cargo) VALUES (6,'Director');
INSERT INTO AREA_FINANCIERA (usuario_id, cargo) VALUES (7,'Analista');

INSERT INTO REGLA_ALERTA (admin_id, tipo, condicion, valor_umbral, estado)
VALUES (1,'Mora','Dias de atraso > 30',30,'ACTIVA'),
       (1,'Ventas','Caida > 20%',20,'ACTIVA'),
       (1,'Empleo','Sin empleos nuevos',0,'ACTIVA');

-- 2. 500 beneficiarios adicionales (usuario_id 11..510)
;WITH N AS (SELECT TOP (500) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
            FROM sys.all_objects a CROSS JOIN sys.all_objects b)
INSERT INTO USUARIO (rol_id, nombre, apellido, correo, telefono, password_hash)
SELECT 5, CONCAT('Benef', i), CONCAT('Apel', i), CONCAT('benef', i, '@mail.com'),
       CONCAT('9', RIGHT(CONCAT('0000000', i), 7)), CONCAT('hash', i)
FROM N;

INSERT INTO SOLICITANTE (usuario_id, tipo_documento, numero_documento, fecha_nacimiento,
                         direccion, nivel_educativo, situacion_laboral, ingreso_referencial, numero_dependientes)
SELECT usuario_id, 'DNI', RIGHT(CONCAT('00000000', usuario_id), 8), '1990-01-01',
       'Direccion demo', 'Secundaria', 'Independiente', 1200.00, 2
FROM USUARIO WHERE usuario_id > 10;

INSERT INTO BENEFICIARIO (usuario_id, estado)
SELECT usuario_id, 'ACTIVO' FROM USUARIO WHERE usuario_id > 10;

-- 3. 10,000 emprendimientos
;WITH N AS (SELECT TOP (10000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
            FROM sys.all_objects a CROSS JOIN sys.all_objects b)
INSERT INTO EMPRENDIMIENTO (beneficiario_id, nombre_negocio, sector, descripcion, estado_actual,
                            fecha_inicio, empleos_iniciales, empleos_actuales, estado)
SELECT 11 + (i % 500), CONCAT('Negocio ', i), CHOOSE(i % 4 + 1,'Comercio','Servicios','Agro','Manufactura'),
       'Descripcion demo', 'EN_OPERACION', DATEADD(DAY, -(i % 1500), '2026-11-01'),
       1 + i % 5, 1 + i % 8, 'ACTIVO'
FROM N;

-- 4. 10,000 solicitudes de microcredito
;WITH N AS (SELECT TOP (10000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
            FROM sys.all_objects a CROSS JOIN sys.all_objects b)
INSERT INTO SOLICITUD_MICROCREDITO (emprendimiento_id, coordinador_id, area_financiera_id,
                                    fecha_solicitud, monto_solicitado, finalidad,
                                    resultado_evaluacion, estado)
SELECT i, 2, 7, DATEADD(DAY, -(i % 1000), SYSDATETIME()), 500 + (i % 50) * 100, 'Capital de trabajo',
       CASE WHEN i % 3 = 0 THEN 'RECHAZADA' ELSE 'APROBADA' END,
       CASE WHEN i % 3 = 0 THEN 'RECHAZADA' ELSE 'APROBADA' END
FROM N;

-- 5. 5,000 microcreditos (a partir de solicitudes aprobadas)
INSERT INTO MICROCREDITO (solicitud_mc_id, admin_id, codigo_credito, monto_otorgado,
                          fecha_otorgamiento, estado_credito)
SELECT TOP (5000) s.solicitud_mc_id, 1,
       CONCAT('MC-', RIGHT(CONCAT('000000', s.solicitud_mc_id), 6)),
       s.monto_solicitado, CAST(SYSDATETIME() AS DATE), 'VIGENTE'
FROM SOLICITUD_MICROCREDITO s
WHERE s.estado = 'APROBADA'
ORDER BY s.solicitud_mc_id;

-- 6. 10,000 alertas de riesgo
;WITH N AS (SELECT TOP (10000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
            FROM sys.all_objects a CROSS JOIN sys.all_objects b)
INSERT INTO ALERTA_RIESGO (regla_id, emprendimiento_id, asesor_id, coordinador_id, tipo,
                           descripcion, estado, nivel_riesgo, fecha_generacion)
SELECT 1 + i % 3, 1 + i % 10000, 3, 2, 'Riesgo', 'Alerta demo',
       CASE WHEN i % 2 = 0 THEN 'ABIERTA' ELSE 'ATENDIDA' END,
       CHOOSE(i % 3 + 1,'BAJO','MEDIO','ALTO'), DATEADD(MINUTE, -i, SYSDATETIME())
FROM N;

-- 7. 10,000 visitas de monitoreo
;WITH N AS (SELECT TOP (10000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
            FROM sys.all_objects a CROSS JOIN sys.all_objects b)
INSERT INTO VISITA_MONITOREO (asesor_id, emprendimiento_id, fecha_programada, estado,
                              estado_sincronizacion)
SELECT 3, 1 + i % 10000, DATEADD(DAY, i % 365, '2026-01-01'),
       CASE WHEN i % 2 = 0 THEN 'PROGRAMADA' ELSE 'REALIZADA' END, 'SINCRONIZADO'
FROM N;
GO


SELECT t.name AS Tabla, SUM(p.rows) AS Total
FROM sys.tables t
JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
GROUP BY t.name
ORDER BY t.name;



SET STATISTICS TIME ON;
SET STATISTICS IO ON;

-- Q1: filtro por estado
SELECT * FROM SOLICITUD_MICROCREDITO WHERE estado = 'APROBADA';

-- Q2: JOIN de cuatro tablas
SELECT sm.solicitud_mc_id, e.nombre_negocio, u.nombre, u.apellido, sm.monto_solicitado
FROM SOLICITUD_MICROCREDITO sm
JOIN EMPRENDIMIENTO e ON e.emprendimiento_id = sm.emprendimiento_id
JOIN BENEFICIARIO b   ON b.usuario_id = e.beneficiario_id
JOIN USUARIO u        ON u.usuario_id = b.usuario_id
WHERE sm.estado = 'APROBADA';

-- Q3: agregacion por mes
SELECT YEAR(fecha_solicitud) AS anio, MONTH(fecha_solicitud) AS mes,
       COUNT(*) AS total, SUM(monto_solicitado) AS monto_total
FROM SOLICITUD_MICROCREDITO
GROUP BY YEAR(fecha_solicitud), MONTH(fecha_solicitud);

-- Q4: rango de fechas
SELECT * FROM SOLICITUD_MICROCREDITO
WHERE fecha_solicitud >= DATEADD(DAY, -30, SYSDATETIME());

-- Q5: microcreditos con sector del emprendimiento
SELECT m.codigo_credito, m.monto_otorgado, e.sector
FROM MICROCREDITO m
JOIN SOLICITUD_MICROCREDITO sm ON sm.solicitud_mc_id = m.solicitud_mc_id
JOIN EMPRENDIMIENTO e          ON e.emprendimiento_id = sm.emprendimiento_id
WHERE e.sector = 'Comercio';

-- Q6: visitas por asesor
SELECT a.usuario_id, COUNT(v.visita_id) AS visitas
FROM ASESOR_TECNICO a
LEFT JOIN VISITA_MONITOREO v ON v.asesor_id = a.usuario_id
GROUP BY a.usuario_id;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;





USE microcreditos;
GO

/* 1. PERMISO */
INSERT INTO PERMISO (nombre, descripcion, modulo) VALUES
('Registrar solicitud','Registrar solicitud de ingreso','Solicitudes'),
('Evaluar solicitud','Evaluar solicitud de ingreso','Solicitudes'),
('Gestionar usuarios','Crear y editar usuarios','Seguridad'),
('Registrar visita','Registrar visita de monitoreo','Visitas'),
('Generar reportes','Generar reportes e indicadores','Reportes');

/* 2. ROL */
INSERT INTO ROL (nombre, descripcion) VALUES
('Administrador','Gestion general de la organizacion'),
('Coordinador','Coordinacion de programas'),
('Asesor tecnico','Asesoria a emprendimientos'),
('Tecnico capacitador','Dictado de capacitaciones'),
('Beneficiario','Emprendedor beneficiario');

/* 3. ROL_PERMISO */
INSERT INTO ROL_PERMISO (rol_id, permiso_id) VALUES
(1,1),(1,3),(2,2),(3,4),(5,1);

/* 4. USUARIO (40 filas: 1-5 admin, 6-10 coord, 11-15 asesor, 16-20 tecnico,
      21-25 financiador, 26-30 directivo, 31-35 area financiera, 36-40 beneficiario) */
INSERT INTO USUARIO (rol_id, nombre, apellido, correo, telefono, password_hash) VALUES
(1,'Carlos','Perez','admin01@mc.pe','900000001','hash001'),
(1,'Maria','Quispe','admin02@mc.pe','900000002','hash002'),
(1,'Jose','Huaman','admin03@mc.pe','900000003','hash003'),
(1,'Rosa','Mendoza','admin04@mc.pe','900000004','hash004'),
(1,'Luis','Torres','admin05@mc.pe','900000005','hash005'),
(2,'Juan','Lopez','coord01@mc.pe','900000006','hash006'),
(2,'Carmen','Vega','coord02@mc.pe','900000007','hash007'),
(2,'Ricardo','Quispe','coord03@mc.pe','900000008','hash008'),
(2,'Patricia','Ramos','coord04@mc.pe','900000009','hash009'),
(2,'Andres','Flores','coord05@mc.pe','900000010','hash010'),
(3,'Raul','Castillo','asesor01@mc.pe','900000011','hash011'),
(3,'Monica','Ponce','asesor02@mc.pe','900000012','hash012'),
(3,'Fernando','Huanca','asesor03@mc.pe','900000013','hash013'),
(3,'Teresa','Lazo','asesor04@mc.pe','900000014','hash014'),
(3,'Victor','Ccama','asesor05@mc.pe','900000015','hash015'),
(4,'Javier','Rios','tecnico01@mc.pe','900000016','hash016'),
(4,'Claudia','Paredes','tecnico02@mc.pe','900000017','hash017'),
(4,'Ernesto','Vilca','tecnico03@mc.pe','900000018','hash018'),
(4,'Lourdes','Mamani','tecnico04@mc.pe','900000019','hash019'),
(4,'Kevin','Ayala','tecnico05@mc.pe','900000020','hash020'),
(6,'Walter','Aguirre','fin01@mc.pe','900000021','hash021'),
(6,'Sandra','Benavides','fin02@mc.pe','900000022','hash022'),
(6,'Hector','Pinto','fin03@mc.pe','900000023','hash023'),
(6,'Julia','Ancajima','fin04@mc.pe','900000024','hash024'),
(6,'Pablo','Zegarra','fin05@mc.pe','900000025','hash025'),
(7,'Alfredo','Chirinos','dir01@mc.pe','900000026','hash026'),
(7,'Beatriz','Salinas','dir02@mc.pe','900000027','hash027'),
(7,'Gustavo','Ruiz','dir03@mc.pe','900000028','hash028'),
(7,'Norma','Gutierrez','dir04@mc.pe','900000029','hash029'),
(7,'Hernan','Pacheco','dir05@mc.pe','900000030','hash030'),
(9,'Jorge','Calderon','area01@mc.pe','900000031','hash031'),
(9,'Vanessa','Ticona','area02@mc.pe','900000032','hash032'),
(9,'Nelson','Zapata','area03@mc.pe','900000033','hash033'),
(9,'Mirella','Huanca','area04@mc.pe','900000034','hash034'),
(9,'Rolando','Cahuana','area05@mc.pe','900000035','hash035'),
(5,'Edgar','Gomez','benef01@mc.pe','900000036','hash036'),
(5,'Milagros','Vargas','benef02@mc.pe','900000037','hash037'),
(5,'Wilber','Taipe','benef03@mc.pe','900000038','hash038'),
(5,'Liz','Huaman','benef04@mc.pe','900000039','hash039'),
(5,'Renato','Alvarez','benef05@mc.pe','900000040','hash040');

/* 5. SUBTIPOS DE USUARIO */
INSERT INTO ADMINISTRADOR_ORGANIZACION (usuario_id, estado) VALUES
(1,'ACTIVO'),(2,'ACTIVO'),(3,'ACTIVO'),(4,'ACTIVO'),(5,'ACTIVO');

UPDATE USUARIO SET gestionado_por = 1 WHERE usuario_id > 5;

INSERT INTO COORDINADOR_PROGRAMAS (usuario_id) VALUES (6),(7),(8),(9),(10);

INSERT INTO ASESOR_TECNICO (usuario_id, especialidad, disponibilidad) VALUES
(11,'Negocios','Disponible'),(12,'Contabilidad','Disponible'),(13,'Marketing','Parcial'),
(14,'Agronegocios','Disponible'),(15,'Finanzas','Disponible');

INSERT INTO TECNICO_CAPACITADOR (usuario_id, especialidad, disponibilidad) VALUES
(16,'Contabilidad','Disponible'),(17,'Marketing digital','Disponible'),(18,'Gestion de caja','Parcial'),
(19,'Costos y precios','Disponible'),(20,'Tributacion','Disponible');

INSERT INTO FINANCIADOR (usuario_id, nombre_entidad, contacto, tipo) VALUES
(21,'Fondo Emprender Peru','contacto21@fondo.pe','Publico'),
(22,'Cooperativa Sol Andino','contacto22@solandino.pe','Cooperativa'),
(23,'ONG Desarrollo Local','contacto23@ongdl.org','ONG'),
(24,'Banco Comunal Huancayo','contacto24@bcomunal.pe','Privado'),
(25,'Fundacion Mujer Activa','contacto25@mujeractiva.org','ONG');

INSERT INTO DIRECTIVO_ONG (usuario_id, cargo) VALUES
(26,'Presidente'),(27,'Director Ejecutivo'),(28,'Gerente General'),(29,'Director de Programas'),(30,'Director Financiero');

INSERT INTO AREA_FINANCIERA (usuario_id, cargo) VALUES
(31,'Analista de credito'),(32,'Jefe de finanzas'),(33,'Analista de riesgo'),(34,'Contador'),(35,'Supervisor de cobranzas');

INSERT INTO SOLICITANTE (usuario_id, tipo_documento, numero_documento, fecha_nacimiento, direccion,
                         nivel_educativo, situacion_laboral, ingreso_referencial, numero_dependientes) VALUES
(36,'DNI','71000001','1985-03-12','Av. Huancavelica 245, Huancayo','Secundaria completa','Independiente',1200.00,3),
(37,'DNI','71000002','1990-07-25','Jr. Lima 310, El Tambo','Tecnico','Comerciante',1500.00,2),
(38,'DNI','71000003','1978-11-02','Calle Real 120, Chilca','Primaria completa','Agricultor',900.00,4),
(39,'DNI','71000004','1992-05-18','Av. Ferrocarril 88, Pilcomayo','Superior','Independiente',1800.00,1),
(40,'DNI','71000005','1988-09-30','Jr. Puno 402, Huancayo','Secundaria completa','Artesano',1100.00,2);

INSERT INTO BENEFICIARIO (usuario_id, estado, fecha_retiro, motivo_retiro) VALUES
(36,'ACTIVO',NULL,NULL),(37,'ACTIVO',NULL,NULL),(38,'ACTIVO',NULL,NULL),
(39,'ACTIVO',NULL,NULL),(40,'RETIRADO','2026-10-15','Culmino el programa');

/* 6. AUDITORIA, IMPORTACION, REGLAS */
INSERT INTO BITACORA_AUDITORIA (usuario_id, fecha_hora, accion, tabla_afectada, registro_afectado) VALUES
(1,'2026-11-20 08:15:00','LOGIN',NULL,NULL),
(6,'2026-11-20 09:05:00','UPDATE','SOLICITUD_INGRESO','1'),
(11,'2026-11-20 10:10:00','INSERT','VISITA_MONITOREO','1'),
(16,'2026-11-21 14:00:00','INSERT','ASISTENCIA_CAPACITACION','1'),
(1,'2026-11-23 17:45:00','DELETE','REGLA_ALERTA','3');

INSERT INTO IMPORTACION (admin_id, nombre_archivo, fuente, fecha_importacion, registros_importados, estado) VALUES
(1,'solicitudes_octubre.xlsx','Excel','2026-11-01 09:00:00',120,'COMPLETADA'),
(2,'beneficiarios_lote1.csv','CSV','2026-11-02 10:00:00',85,'COMPLETADA'),
(3,'emprendimientos_q4.xlsx','Excel','2026-11-03 11:00:00',60,'COMPLETADA'),
(4,'pagos_microcreditos.csv','CSV','2026-11-04 08:30:00',200,'ERROR'),
(5,'visitas_campo.xlsx','Excel','2026-11-05 15:20:00',45,'PENDIENTE');

INSERT INTO REGLA_ALERTA (admin_id, tipo, condicion, valor_umbral, estado) VALUES
(1,'Mora','Dias de atraso mayor a 30',30,'ACTIVA'),
(2,'Ventas','Caida de ventas mayor al 20%',20,'ACTIVA'),
(3,'Empleo','Sin empleos nuevos en 6 meses',6,'ACTIVA'),
(4,'Asistencia','Inasistencia a capacitacion mayor a 2',2,'ACTIVA'),
(5,'Financiera','Saldo de caja menor a 500',500,'INACTIVA');

/* 7. SOLICITUD DE INGRESO */
INSERT INTO SOLICITUD_INGRESO (solicitante_id, coordinador_id, fecha_solicitud, estado,
                               fecha_evaluacion, documentacion, observaciones) VALUES
(36,6,'2026-10-05 09:00:00','APROBADA','2026-10-07 15:00:00','DNI, recibo de luz','Cumple requisitos'),
(37,7,'2026-10-06 10:00:00','APROBADA','2026-10-08 11:00:00','DNI, constancia de ingresos','Cumple requisitos'),
(38,8,'2026-10-10 09:30:00','APROBADA','2026-10-12 10:00:00','DNI, declaracion jurada','Sin observaciones'),
(39,9,'2026-10-12 14:00:00','RECHAZADA','2026-10-14 09:00:00','DNI','Ingresos insuficientes'),
(40,10,'2026-10-15 08:20:00','PENDIENTE',NULL,'DNI, contrato de alquiler','En revision');

/* 8. EMPRENDIMIENTO */
INSERT INTO EMPRENDIMIENTO (beneficiario_id, nombre_negocio, sector, descripcion, estado_actual,
                            fecha_inicio, empleos_iniciales, empleos_actuales, estado) VALUES
(36,'Bodega Don Carlos','Comercio','Venta de abarrotes','EN_OPERACION','2024-03-10',1,2,'ACTIVO'),
(37,'Polleria La Esquina','Servicios','Venta de pollo a la brasa','EN_OPERACION','2023-08-15',2,3,'ACTIVO'),
(38,'Granja Los Andes','Agro','Crianza de cuyes','EN_OPERACION','2024-01-20',1,2,'ACTIVO'),
(39,'Taller Textil Ruth','Manufactura','Confeccion de prendas','EN_OPERACION','2023-11-05',2,4,'ACTIVO'),
(40,'Panaderia Santa Rosa','Comercio','Venta de pan artesanal','CERRADO','2022-06-01',2,0,'INACTIVO');

/* 9. CAPACITACION Y ASIGNACIONES */
INSERT INTO CAPACITACION (nombre, tipo, fecha_programada, estado, es_obligatoria, observaciones) VALUES
('Educacion financiera basica','Presencial','2026-10-15 09:00:00','REALIZADA',1,'Asistencia obligatoria'),
('Contabilidad para emprendedores','Presencial','2026-10-22 09:00:00','REALIZADA',1,NULL),
('Marketing digital','Virtual','2026-11-05 15:00:00','REALIZADA',0,NULL),
('Gestion de costos y precios','Presencial','2026-12-03 09:00:00','PROGRAMADA',1,NULL),
('Atencion al cliente','Presencial','2026-12-10 09:00:00','PROGRAMADA',0,NULL);

INSERT INTO ASIGNACION_CAPACITACION (coordinador_id, tecnico_id, capacitacion_id, fecha_asignacion, estado) VALUES
(6,16,1,'2026-10-01','COMPLETADA'),(7,17,2,'2026-10-05','COMPLETADA'),
(8,18,3,'2026-10-20','COMPLETADA'),(9,19,4,'2026-11-20','ASIGNADA'),
(10,20,5,'2026-11-22','ASIGNADA');

INSERT INTO ASIGNACION_ASESOR (coordinador_id, asesor_id, beneficiario_id, fecha_asignacion, estado) VALUES
(6,11,36,'2026-10-08','ACTIVA'),(7,12,37,'2026-10-09','ACTIVA'),
(8,13,38,'2026-10-12','ACTIVA'),(9,14,39,'2026-10-14','ACTIVA'),
(10,15,40,'2026-10-16','FINALIZADA');

/* 10. MICROCREDITO */
INSERT INTO SOLICITUD_MICROCREDITO (emprendimiento_id, coordinador_id, area_financiera_id, fecha_solicitud,
                                    monto_solicitado, finalidad, fecha_verificacion, resultado_evaluacion,
                                    fecha_evaluacion, observaciones, estado) VALUES
(1,6,31,'2026-10-10 09:00:00',1500.00,'Compra de mercaderia','2026-10-11 10:00:00','APROBADA','2026-10-12 15:00:00','Sin observaciones','APROBADA'),
(2,7,32,'2026-10-12 09:00:00',2000.00,'Compra de insumos','2026-10-13 10:00:00','APROBADA','2026-10-14 15:00:00','Sin observaciones','APROBADA'),
(3,8,33,'2026-10-14 09:00:00',2500.00,'Compra de cuyes','2026-10-15 10:00:00','APROBADA','2026-10-16 15:00:00','Sin observaciones','APROBADA'),
(4,9,34,'2026-10-16 09:00:00',3000.00,'Compra de telas','2026-10-17 10:00:00','APROBADA','2026-10-18 15:00:00','Sin observaciones','APROBADA'),
(5,10,35,'2026-10-18 09:00:00',1200.00,'Capital de trabajo','2026-10-19 10:00:00','APROBADA','2026-10-20 15:00:00','Requiere control de caja','APROBADA');

INSERT INTO MICROCREDITO (solicitud_mc_id, admin_id, codigo_credito, monto_otorgado,
                          fecha_otorgamiento, estado_credito, fecha_actualizacion) VALUES
(1,1,'MC-000001',1500.00,'2026-10-15','VIGENTE','2026-11-20 10:00:00'),
(2,2,'MC-000002',2000.00,'2026-10-17','VIGENTE','2026-11-20 10:00:00'),
(3,3,'MC-000003',2500.00,'2026-10-19','VIGENTE','2026-11-20 10:00:00'),
(4,4,'MC-000004',3000.00,'2026-10-21','VENCIDO','2026-11-20 10:00:00'),
(5,5,'MC-000005',1200.00,'2026-10-23','CANCELADO','2026-11-20 10:00:00');

/* 11. ALERTAS, VISITAS, ASISTENCIA TECNICA, HITOS */
INSERT INTO ALERTA_RIESGO (regla_id, emprendimiento_id, asesor_id, coordinador_id, tipo, descripcion,
                           estado, nivel_riesgo, fecha_generacion, fecha_atencion, acciones_realizadas, observaciones) VALUES
(1,1,11,6,'Mora','Pago atrasado 35 dias','ATENDIDA','ALTO','2026-11-10 09:00:00','2026-11-11 10:00:00','Visita de cobranza','Se acordo plan de pago'),
(2,2,12,7,'Ventas','Caida de ventas del 25%','ATENDIDA','MEDIO','2026-11-11 09:00:00','2026-11-12 11:00:00','Asesoria en marketing','Seguimiento programado'),
(3,3,13,8,'Empleo','Sin contratacion en 6 meses','ABIERTA','BAJO','2026-11-12 09:00:00',NULL,NULL,NULL),
(4,4,14,9,'Asistencia','Faltas a capacitacion','ATENDIDA','BAJO','2026-11-13 09:00:00','2026-11-14 09:00:00','Llamada de recordatorio','Asistio a la siguiente'),
(1,5,15,10,'Mora','Saldo de caja bajo','EN_PROCESO','ALTO','2026-11-14 09:00:00',NULL,'Revision de caja',NULL);

INSERT INTO VISITA_MONITOREO (asesor_id, emprendimiento_id, microcredito_id, fecha_programada, fecha_visita,
                              hallazgos, dificultades, acuerdos, observaciones, estado,
                              estado_sincronizacion, fecha_sincronizacion) VALUES
(11,1,1,'2026-11-02 09:00:00','2026-11-02 09:30:00','Inventario ordenado','Falta de capital de trabajo','Plan de compras semanal','Buen avance','REALIZADA','SINCRONIZADO','2026-11-02 18:00:00'),
(12,2,2,'2026-11-03 10:00:00','2026-11-03 10:20:00','Registro de ventas al dia','Ventas bajas en temporada','Promocion en redes','Seguimiento mensual','REALIZADA','SINCRONIZADO','2026-11-03 19:00:00'),
(13,3,3,'2026-11-04 08:00:00','2026-11-04 08:40:00','Crianza adecuada de cuyes','Falta de alimento','Compra de balanceado','Revisar en 15 dias','REALIZADA','SINCRONIZADO','2026-11-04 17:30:00'),
(14,4,4,'2026-11-05 14:00:00',NULL,NULL,NULL,NULL,'Visita reprogramada','PROGRAMADA','PENDIENTE',NULL),
(15,5,5,'2026-11-06 09:00:00','2026-11-06 09:50:00','Caja sin control','Falta de registro contable','Llevar cuaderno de caja','Requiere apoyo','REALIZADA','SINCRONIZADO','2026-11-06 18:10:00');

INSERT INTO ASISTENCIA_TECNICA (asesor_id, emprendimiento_id, microcredito_id, fecha, tema, recomendaciones,
                                compromisos, proximos_pasos, fecha_proximo_seguimiento, estado) VALUES
(11,1,1,'2026-11-03','Control de inventario','Registrar compras diarias','Llevar cuaderno de ventas','Revisar stock','2026-11-17','REALIZADA'),
(12,2,2,'2026-11-04','Marketing digital','Usar redes sociales','Publicar 3 veces por semana','Medir alcance','2026-11-18','REALIZADA'),
(13,3,3,'2026-11-05','Manejo de alimentacion','Dieta balanceada para cuyes','Comprar balanceado','Verificar peso','2026-11-19','REALIZADA'),
(14,4,4,'2026-11-06','Costos de produccion','Calcular costo por prenda','Registrar costos','Ajustar precios','2026-11-20','EN_PROCESO'),
(15,5,5,'2026-11-07','Contabilidad basica','Separar gastos personales','Usar cuaderno de caja','Revisar caja semanal','2026-11-21','PENDIENTE');

INSERT INTO HITO_NEGOCIO (asesor_id, emprendimiento_id, titulo, tipo, descripcion, fecha_limite,
                          fecha_cumplimiento, estado, observaciones) VALUES
(11,1,'Registrar ventas diarias','Operativo','Llevar registro diario de ventas','2026-11-15','2026-11-14','CUMPLIDO','Cumplido antes de tiempo'),
(12,2,'Abrir cuenta en redes sociales','Comercial','Crear perfil de negocio','2026-11-10','2026-11-12','CUMPLIDO',NULL),
(13,3,'Comprar primer lote de cuyes','Produccion','Adquirir 20 cuyes reproductores','2026-11-20',NULL,'EN_PROCESO',NULL),
(14,4,'Calcular costo por prenda','Financiero','Definir costo unitario','2026-11-18',NULL,'EN_PROCESO',NULL),
(15,5,'Abrir libro de caja','Financiero','Implementar libro de caja','2026-11-12','2026-11-11','CUMPLIDO',NULL);

/* 12. ATENCION, EVIDENCIAS, ASISTENCIA A CAPACITACION */
INSERT INTO SOLICITUD_ATENCION (beneficiario_id, asesor_id, tipo, detalle, fecha, estado, respuesta, fecha_cierre) VALUES
(36,11,'Consulta','Duda sobre cuota mensual','2026-11-05 10:00:00','CERRADA','Se explico el calendario de pagos','2026-11-05 11:00:00'),
(37,12,'Asesoria','Quiero ampliar mi tienda','2026-11-06 09:30:00','EN_PROCESO',NULL,NULL),
(38,13,'Reclamo','Retraso en entrega de insumos','2026-11-07 14:00:00','CERRADA','Se coordino con proveedor','2026-11-08 09:00:00'),
(39,14,'Consulta','Requisitos para nuevo credito','2026-11-08 11:15:00','CERRADA','Se entregaron requisitos','2026-11-08 12:00:00'),
(40,15,'Consulta','Solicitud de cierre de cuenta','2026-11-09 16:00:00','CERRADA','Cierre procesado','2026-11-10 10:00:00');

INSERT INTO EVIDENCIA (visita_id, capacitacion_id, tipo, nombre_archivo, ruta, fecha_subida, descripcion) VALUES
(1,NULL,'FOTO','visita_01.jpg','/evidencias/visitas/visita_01.jpg','2026-11-02 18:00:00','Foto del inventario'),
(2,NULL,'PDF','visita_02.pdf','/evidencias/visitas/visita_02.pdf','2026-11-03 19:00:00','Acta de visita'),
(3,NULL,'PDF','visita_03.pdf','/evidencias/visitas/visita_03.pdf','2026-11-04 17:30:00','Acta de visita'),
(NULL,1,'LISTA','asistencia_cap01.pdf','/evidencias/capacitacion/asistencia_cap01.pdf','2026-10-15 12:00:00','Lista de asistencia'),
(NULL,2,'LISTA','asistencia_cap02.pdf','/evidencias/capacitacion/asistencia_cap02.pdf','2026-10-22 12:00:00','Lista de asistencia');

INSERT INTO ASISTENCIA_CAPACITACION (capacitacion_id, tecnico_id, beneficiario_id, microcredito_id,
                                     asistencia, fecha, resultado, observaciones) VALUES
(1,16,36,1,1,'2026-10-15','APROBADO','Participo activamente'),
(2,17,37,2,1,'2026-10-22','APROBADO',NULL),
(3,18,38,3,0,'2026-11-05','NO_APROBADO','Falto a la sesion'),
(4,19,39,NULL,1,'2026-12-03','PENDIENTE',NULL),
(5,20,40,NULL,0,'2026-12-10','PENDIENTE','Justifico inasistencia');

/* 13. REPORTES E INDICADORES */
INSERT INTO REPORTE (admin_id, tipo, periodo, formato, fecha_generacion) VALUES
(1,'Impacto mensual','2026-10','PDF','2026-11-01 09:00:00'),
(2,'Colocaciones','2026-10','XLSX','2026-11-01 10:00:00'),
(3,'Asistencia tecnica','2026-10','PDF','2026-11-02 09:00:00'),
(4,'Capacitaciones','2026-10','PDF','2026-11-02 11:00:00'),
(5,'Morosidad','2026-10','XLSX','2026-11-03 09:30:00');

INSERT INTO INDICADOR_IMPACTO (nombre, descripcion, valor, periodo, fuente) VALUES
('Emprendimientos activos','Numero de emprendimientos en operacion',4,'2026-10','Sistema'),
('Empleos generados','Empleos creados por los emprendimientos',10,'2026-10','Sistema'),
('Monto colocado','Monto total de microcreditos otorgados',10200,'2026-10','Sistema'),
('Tasa de morosidad','Porcentaje de creditos con mora',20,'2026-10','Area financiera'),
('Asistencia a capacitaciones','Porcentaje de asistencia',60,'2026-10','Capacitaciones');

INSERT INTO REPORTE_INDICADOR (reporte_id, indicador_id) VALUES
(1,1),(2,2),(3,3),(4,4),(5,5);

INSERT INTO CONSULTA_REPORTE (usuario_id, reporte_id, fecha_consulta) VALUES
(26,1,'2026-11-21 09:00:00'),(27,2,'2026-11-21 09:30:00'),(28,3,'2026-11-21 10:00:00'),
(29,4,'2026-11-21 10:30:00'),(30,5,'2026-11-22 09:00:00');
GO


/*Procedimientos almacenados*/

/*Evaluar una solicitud de ingreso*/
USE microcreditos;
GO

CREATE OR ALTER PROCEDURE sp_EvaluarSolicitudIngreso
    @SolicitudIngresoID INT,
    @CoordinadorID INT,
    @Estado NVARCHAR(20),
    @Observaciones NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Estado NOT IN ('APROBADA', 'RECHAZADA')
    BEGIN
        THROW 50001, 'El estado debe ser APROBADA o RECHAZADA.', 1;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM SOLICITUD_INGRESO
            WHERE solicitud_ingreso_id = @SolicitudIngresoID
        )
            THROW 50002, 'La solicitud de ingreso no existe.', 1;

        UPDATE SOLICITUD_INGRESO
        SET coordinador_id = @CoordinadorID,
            estado = @Estado,
            fecha_evaluacion = SYSDATETIME(),
            observaciones = @Observaciones
        WHERE solicitud_ingreso_id = @SolicitudIngresoID;

        IF @Estado = 'APROBADA'
        BEGIN
            INSERT INTO BENEFICIARIO (usuario_id, estado)
            SELECT s.solicitante_id, 'ACTIVO'
            FROM SOLICITUD_INGRESO s
            WHERE s.solicitud_ingreso_id = @SolicitudIngresoID
              AND NOT EXISTS (
                  SELECT 1
                  FROM BENEFICIARIO b
                  WHERE b.usuario_id = s.solicitante_id
              );
        END;

        COMMIT TRANSACTION;

        SELECT 'Solicitud evaluada correctamente' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/*Registrar una solicitud de microcrédito*/
CREATE OR ALTER PROCEDURE sp_RegistrarSolicitudMicrocredito
    @EmprendimientoID INT,
    @CoordinadorID INT,
    @AreaFinancieraID INT,
    @MontoSolicitado DECIMAL(12,2),
    @Finalidad NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    IF @MontoSolicitado <= 0
        THROW 50003, 'El monto solicitado debe ser mayor que cero.', 1;

    IF NOT EXISTS (
        SELECT 1
        FROM EMPRENDIMIENTO
        WHERE emprendimiento_id = @EmprendimientoID
          AND estado = 'ACTIVO'
    )
        THROW 50004, 'El emprendimiento no existe o no está activo.', 1;

    INSERT INTO SOLICITUD_MICROCREDITO (
        emprendimiento_id,
        coordinador_id,
        area_financiera_id,
        monto_solicitado,
        finalidad,
        estado
    )
    VALUES (
        @EmprendimientoID,
        @CoordinadorID,
        @AreaFinancieraID,
        @MontoSolicitado,
        @Finalidad,
        'REGISTRADA'
    );

    SELECT SCOPE_IDENTITY() AS solicitud_mc_id,
           'Solicitud de microcrédito registrada correctamente' AS mensaje;
END;
GO


/*Evaluar una solicitud de microcrédito*/
CREATE OR ALTER PROCEDURE sp_EvaluarMicrocredito
    @SolicitudMCID INT,
    @AreaFinancieraID INT,
    @Resultado NVARCHAR(50),
    @Observaciones NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Resultado NOT IN ('APROBADA', 'RECHAZADA')
        THROW 50005, 'El resultado debe ser APROBADA o RECHAZADA.', 1;

    IF NOT EXISTS (
        SELECT 1
        FROM SOLICITUD_MICROCREDITO
        WHERE solicitud_mc_id = @SolicitudMCID
    )
        THROW 50006, 'La solicitud de microcrédito no existe.', 1;

    UPDATE SOLICITUD_MICROCREDITO
    SET area_financiera_id = @AreaFinancieraID,
        resultado_evaluacion = @Resultado,
        fecha_verificacion = SYSDATETIME(),
        fecha_evaluacion = SYSDATETIME(),
        observaciones = @Observaciones,
        estado = @Resultado
    WHERE solicitud_mc_id = @SolicitudMCID;

    SELECT 'Evaluación financiera registrada correctamente' AS mensaje;
END;
GO


/*Otorgar un microcrédito*/
CREATE OR ALTER PROCEDURE sp_OtorgarMicrocredito
    @SolicitudMCID INT,
    @AdministradorID INT,
    @CodigoCredito NVARCHAR(30),
    @MontoOtorgado DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;

    IF @MontoOtorgado <= 0
        THROW 50007, 'El monto otorgado debe ser mayor que cero.', 1;

    IF NOT EXISTS (
        SELECT 1
        FROM SOLICITUD_MICROCREDITO
        WHERE solicitud_mc_id = @SolicitudMCID
          AND estado = 'APROBADA'
    )
        THROW 50008, 'Solo se pueden otorgar créditos con solicitud aprobada.', 1;

    IF EXISTS (
        SELECT 1
        FROM MICROCREDITO
        WHERE solicitud_mc_id = @SolicitudMCID
    )
        THROW 50009, 'Esta solicitud ya tiene un microcrédito registrado.', 1;

    INSERT INTO MICROCREDITO (
        solicitud_mc_id,
        admin_id,
        codigo_credito,
        monto_otorgado,
        fecha_otorgamiento,
        estado_credito
    )
    VALUES (
        @SolicitudMCID,
        @AdministradorID,
        @CodigoCredito,
        @MontoOtorgado,
        CAST(SYSDATETIME() AS DATE),
        'VIGENTE'
    );

    SELECT SCOPE_IDENTITY() AS microcredito_id,
           'Microcrédito otorgado correctamente' AS mensaje;
END;
GO


/*Registrar una visita de monitoreo*/
CREATE OR ALTER PROCEDURE sp_RegistrarVisitaMonitoreo
    @AsesorID INT,
    @EmprendimientoID INT,
    @MicrocreditoID INT = NULL,
    @Hallazgos NVARCHAR(MAX) = NULL,
    @Dificultades NVARCHAR(MAX) = NULL,
    @Acuerdos NVARCHAR(MAX) = NULL,
    @Observaciones NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO VISITA_MONITOREO (
        asesor_id,
        emprendimiento_id,
        microcredito_id,
        fecha_visita,
        hallazgos,
        dificultades,
        acuerdos,
        observaciones,
        estado,
        estado_sincronizacion
    )
    VALUES (
        @AsesorID,
        @EmprendimientoID,
        @MicrocreditoID,
        SYSDATETIME(),
        @Hallazgos,
        @Dificultades,
        @Acuerdos,
        @Observaciones,
        'REALIZADA',
        'PENDIENTE'
    );

    SELECT SCOPE_IDENTITY() AS visita_id,
           'Visita de monitoreo registrada correctamente' AS mensaje;
END;
GO



/* CREACION DE VISTAS */
/*Vista general de beneficiarios y emprendimientos*/
CREATE OR ALTER VIEW vw_BeneficiariosEmprendimientos
AS
SELECT
    b.usuario_id AS beneficiario_id,
    u.nombre,
    u.apellido,
    u.correo,
    s.numero_documento,
    b.estado AS estado_beneficiario,
    e.emprendimiento_id,
    e.nombre_negocio,
    e.sector,
    e.estado AS estado_emprendimiento,
    e.empleos_iniciales,
    e.empleos_actuales
FROM BENEFICIARIO b
INNER JOIN USUARIO u
    ON b.usuario_id = u.usuario_id
INNER JOIN SOLICITANTE s
    ON b.usuario_id = s.usuario_id
LEFT JOIN EMPRENDIMIENTO e
    ON b.usuario_id = e.beneficiario_id;
GO

/*Vista de microcréditos otorgados*/
CREATE OR ALTER VIEW vw_MicrocreditosOtorgados
AS
SELECT
    m.microcredito_id,
    m.codigo_credito,
    m.monto_otorgado,
    m.fecha_otorgamiento,
    m.estado_credito,
    sm.solicitud_mc_id,
    sm.monto_solicitado,
    e.nombre_negocio,
    e.sector,
    u.nombre,
    u.apellido
FROM MICROCREDITO m
INNER JOIN SOLICITUD_MICROCREDITO sm
    ON m.solicitud_mc_id = sm.solicitud_mc_id
INNER JOIN EMPRENDIMIENTO e
    ON sm.emprendimiento_id = e.emprendimiento_id
INNER JOIN BENEFICIARIO b
    ON e.beneficiario_id = b.usuario_id
INNER JOIN USUARIO u
    ON b.usuario_id = u.usuario_id;
GO


/*Vista de seguimiento técnico*/
CREATE OR ALTER VIEW vw_SeguimientoTecnico
AS
SELECT
    v.visita_id,
    v.fecha_programada,
    v.fecha_visita,
    v.estado AS estado_visita,
    v.hallazgos,
    v.dificultades,
    v.acuerdos,
    e.nombre_negocio,
    e.sector,
    u.nombre AS nombre_asesor,
    u.apellido AS apellido_asesor
FROM VISITA_MONITOREO v
INNER JOIN EMPRENDIMIENTO e
    ON v.emprendimiento_id = e.emprendimiento_id
INNER JOIN ASESOR_TECNICO a
    ON v.asesor_id = a.usuario_id
INNER JOIN USUARIO u
    ON a.usuario_id = u.usuario_id;
GO

/*Vista de asistencia a capacitaciones*/
CREATE OR ALTER VIEW vw_AsistenciaCapacitaciones
AS
SELECT
    ac.asistencia_cap_id,
    c.nombre AS capacitacion,
    c.es_obligatoria,
    ac.fecha,
    ac.asistencia,
    ac.resultado,
    u.nombre,
    u.apellido,
    ac.observaciones
FROM ASISTENCIA_CAPACITACION ac
INNER JOIN CAPACITACION c
    ON ac.capacitacion_id = c.capacitacion_id
INNER JOIN BENEFICIARIO b
    ON ac.beneficiario_id = b.usuario_id
INNER JOIN USUARIO u
    ON b.usuario_id = u.usuario_id;
GO

/**/
SELECT * FROM vw_BeneficiariosEmprendimientos;
SELECT * FROM vw_MicrocreditosOtorgados;
SELECT * FROM vw_SeguimientoTecnico;
SELECT * FROM vw_AsistenciaCapacitaciones;



/*CREACION DE TRIGGERS */
/*Trigger para actualizar la fecha de modificación del microcrédito*/
CREATE OR ALTER TRIGGER trg_ActualizarFechaMicrocredito
ON MICROCREDITO
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    UPDATE m
    SET fecha_actualizacion = SYSDATETIME()
    FROM MICROCREDITO m
    INNER JOIN inserted i
        ON m.microcredito_id = i.microcredito_id;
END;
GO


/*Trigger para registrar cambios de estado del microcrédito en la bitácora*/
CREATE OR ALTER TRIGGER trg_AuditoriaEstadoMicrocredito
ON MICROCREDITO
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    DECLARE @UsuarioID INT =
        TRY_CONVERT(INT, SESSION_CONTEXT(N'usuario_id'));

    IF @UsuarioID IS NULL
        RETURN;

    IF NOT EXISTS (
        SELECT 1
        FROM USUARIO
        WHERE usuario_id = @UsuarioID
    )
        RETURN;

    INSERT INTO BITACORA_AUDITORIA (
        usuario_id,
        fecha_hora,
        accion,
        tabla_afectada,
        registro_afectado
    )
    SELECT
        @UsuarioID,
        SYSDATETIME(),
        'UPDATE',
        'MICROCREDITO',
        CONVERT(NVARCHAR(100), i.microcredito_id)
    FROM inserted i
    INNER JOIN deleted d
        ON i.microcredito_id = d.microcredito_id
    WHERE ISNULL(i.estado_credito, '') <>
          ISNULL(d.estado_credito, '');
END;
GO

EXEC sys.sp_set_session_context
    @key = N'usuario_id',
    @value = 1;


/*Trigger para registrar cambios de estado de las solicitudes de microcrédito*/
CREATE OR ALTER TRIGGER trg_AuditoriaSolicitudMicrocredito
ON SOLICITUD_MICROCREDITO
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UsuarioID INT =
        TRY_CONVERT(INT, SESSION_CONTEXT(N'usuario_id'));

    IF @UsuarioID IS NULL
        RETURN;

    IF NOT EXISTS (
        SELECT 1
        FROM USUARIO
        WHERE usuario_id = @UsuarioID
    )
        RETURN;

    INSERT INTO BITACORA_AUDITORIA (
        usuario_id,
        fecha_hora,
        accion,
        tabla_afectada,
        registro_afectado
    )
    SELECT
        @UsuarioID,
        SYSDATETIME(),
        'UPDATE',
        'SOLICITUD_MICROCREDITO',
        CONVERT(NVARCHAR(100), i.solicitud_mc_id)
    FROM inserted i
    INNER JOIN deleted d
        ON i.solicitud_mc_id = d.solicitud_mc_id
    WHERE ISNULL(i.estado, '') <> ISNULL(d.estado, '');
END;
GO

/*CREAR ROLES DE SEGURIDAD */
USE microcreditos;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals
               WHERE name = 'rol_sigam_administrador')
    CREATE ROLE rol_sigam_administrador;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals
               WHERE name = 'rol_sigam_coordinador')
    CREATE ROLE rol_sigam_coordinador;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals
               WHERE name = 'rol_sigam_financiero')
    CREATE ROLE rol_sigam_financiero;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals
               WHERE name = 'rol_sigam_asesor')
    CREATE ROLE rol_sigam_asesor;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals
               WHERE name = 'rol_sigam_tecnico')
    CREATE ROLE rol_sigam_tecnico;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals
               WHERE name = 'rol_sigam_consulta')
    CREATE ROLE rol_sigam_consulta;
GO


GRANT CONTROL ON DATABASE::microcreditos
TO rol_sigam_administrador;
GO

/*COORDINADOR DE PROGRAMAS */
GRANT EXECUTE ON OBJECT::dbo.sp_EvaluarSolicitudIngreso
TO rol_sigam_coordinador;

GRANT EXECUTE ON OBJECT::dbo.sp_RegistrarSolicitudMicrocredito
TO rol_sigam_coordinador;

GRANT SELECT ON OBJECT::dbo.vw_BeneficiariosEmprendimientos
TO rol_sigam_coordinador;

GRANT SELECT ON OBJECT::dbo.vw_MicrocreditosOtorgados
TO rol_sigam_coordinador;
GO

/*ÁREA FINANCIERA */

GRANT EXECUTE ON OBJECT::dbo.sp_EvaluarMicrocredito
TO rol_sigam_financiero;

GRANT SELECT ON OBJECT::dbo.vw_MicrocreditosOtorgados
TO rol_sigam_financiero;
GO


/*ASESOR TENICO */
GRANT EXECUTE ON OBJECT::dbo.sp_RegistrarVisitaMonitoreo
TO rol_sigam_asesor;

GRANT SELECT ON OBJECT::dbo.vw_SeguimientoTecnico
TO rol_sigam_asesor;

GRANT SELECT ON OBJECT::dbo.vw_BeneficiariosEmprendimientos
TO rol_sigam_asesor;
GO


/*TECNICO CAPACITADOR */
GRANT SELECT ON OBJECT::dbo.vw_AsistenciaCapacitaciones
TO rol_sigam_tecnico;
GO


/*Rol de consulta: permite consultar información consolidada mediante las vistas.*/
GRANT SELECT ON OBJECT::dbo.vw_BeneficiariosEmprendimientos
TO rol_sigam_consulta;

GRANT SELECT ON OBJECT::dbo.vw_MicrocreditosOtorgados
TO rol_sigam_consulta;

GRANT SELECT ON OBJECT::dbo.vw_SeguimientoTecnico
TO rol_sigam_consulta;

GRANT SELECT ON OBJECT::dbo.vw_AsistenciaCapacitaciones
TO rol_sigam_consulta;
GO


/*Crear usuarios de base de datos y asociarlos a roles*/
-- Crear usuarios dentro de la base de datos
CREATE USER usuario_admin FOR LOGIN login_admin;
CREATE USER usuario_coordinador FOR LOGIN login_coordinador;
CREATE USER usuario_financiero FOR LOGIN login_financiero;
CREATE USER usuario_asesor FOR LOGIN login_asesor;
CREATE USER usuario_tecnico FOR LOGIN login_tecnico;

-- Asignar usuarios a sus respectivos roles
ALTER ROLE rol_sigam_administrador
ADD MEMBER usuario_admin;

ALTER ROLE rol_sigam_coordinador
ADD MEMBER usuario_coordinador;

ALTER ROLE rol_sigam_financiero
ADD MEMBER usuario_financiero;

ALTER ROLE rol_sigam_asesor
ADD MEMBER usuario_asesor;

ALTER ROLE rol_sigam_tecnico
ADD MEMBER usuario_tecnico;
GO



/*Respaldo y recuperación de la base de datos*/
/*Crear una copia de seguridad completa*/
BACKUP DATABASE microcreditos
TO DISK = 'C:\Respaldos\microcreditos_full.bak'
WITH
    FORMAT,
    INIT,
    NAME = 'Respaldo completo SIGAM',
    DESCRIPTION = 'Copia de seguridad completa de la base de datos microcreditos',
    STATS = 10;
GO

/*Crear una copia de seguridad diferencial*/
BACKUP DATABASE microcreditos
TO DISK = 'C:\Respaldos\microcreditos_diferencial.bak'
WITH
    DIFFERENTIAL,
    INIT,
    NAME = 'Respaldo diferencial SIGAM',
    STATS = 10;
GO

/*Restaurar la base de datos*/
USE master;
GO

ALTER DATABASE microcreditos
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;
GO

RESTORE DATABASE microcreditos
FROM DISK = 'C:\Respaldos\microcreditos_full.bak'
WITH REPLACE,
     RECOVERY,
     STATS = 10;
GO

ALTER DATABASE microcreditos
SET MULTI_USER;
GO


/*Verificar los respaldos*/
RESTORE VERIFYONLY
FROM DISK = 'C:\Respaldos\microcreditos_full.bak';
GO




/*Pruebas de funcionamiento*/
/*Prueba 1. Consultar beneficiarios y emprendimientos*/
SELECT * FROM vw_BeneficiariosEmprendimientos;

/*Prueba 2. Consultar microcréditos otorgados*/
SELECT * FROM vw_MicrocreditosOtorgados;

/*Prueba 3. Registrar una visita de monitoreo*/
EXEC sp_RegistrarVisitaMonitoreo
    @AsesorID = 11,
    @EmprendimientoID = 1,
    @MicrocreditoID = 1,
    @Hallazgos = 'Se verificó el avance del emprendimiento',
    @Dificultades = 'Falta de capital de trabajo',
    @Acuerdos = 'Mejorar el control de inventario',
    @Observaciones = 'Seguimiento satisfactorio';


/*Prueba 4. Verificar la actualización automática de la fecha*/
UPDATE MICROCREDITO
SET estado_credito = 'VENCIDO'
WHERE microcredito_id = 1;

SELECT
    microcredito_id,
    codigo_credito,
    estado_credito,
    fecha_actualizacion
FROM MICROCREDITO
WHERE microcredito_id = 1;


/*Prueba 5. Consultar la bitácora de auditoría*/
SELECT * FROM BITACORA_AUDITORIA
ORDER BY fecha_hora DESC;


USE microcreditos;
GO

SELECT * FROM USUARIO;
SELECT * FROM ASESOR_TECNICO;
SELECT * FROM EMPRENDIMIENTO;
SELECT * FROM MICROCREDITO;
SELECT * FROM SOLICITUD_MICROCREDITO;
SELECT * FROM BITACORA_AUDITORIA;


UPDATE MICROCREDITO
SET estado_credito = 'VENCIDO'
WHERE microcredito_id = 1;


SELECT name
FROM sys.views
WHERE name IN (
    'vw_BeneficiariosEmprendimientos',
    'vw_MicrocreditosOtorgados'
);
SELECT * FROM vw_BeneficiariosEmprendimientos;
SELECT * FROM vw_MicrocreditosOtorgados;


USE microcreditos;
GO

-- Comprobar procedimientos almacenados
SELECT name AS procedimiento
FROM sys.procedures
WHERE name IN (
    'sp_EvaluarSolicitudIngreso',
    'sp_RegistrarSolicitudMicrocredito',
    'sp_EvaluarMicrocredito',
    'sp_OtorgarMicrocredito',
    'sp_RegistrarVisitaMonitoreo'
);

-- Comprobar vistas
SELECT name AS vista
FROM sys.views
WHERE name IN (
    'vw_BeneficiariosEmprendimientos',
    'vw_MicrocreditosOtorgados',
    'vw_SeguimientoTecnico',
    'vw_AsistenciaCapacitaciones'
);

-- Comprobar triggers
SELECT
    name AS nombre_trigger,
    OBJECT_NAME(parent_id) AS tabla
FROM sys.triggers
WHERE name IN (
    'trg_ActualizarFechaMicrocredito',
    'trg_AuditoriaEstadoMicrocredito',
    'trg_AuditoriaSolicitudMicrocredito'
);
GO



SELECT usuario_id, nombre, apellido
FROM USUARIO;

SELECT usuario_id
FROM COORDINADOR_PROGRAMAS;

SELECT usuario_id
FROM AREA_FINANCIERA;

SELECT usuario_id
FROM ADMINISTRADOR_ORGANIZACION;

SELECT usuario_id
FROM ASESOR_TECNICO;

SELECT emprendimiento_id, beneficiario_id,
       nombre_negocio, estado
FROM EMPRENDIMIENTO;

SELECT solicitud_ingreso_id, solicitante_id, estado
FROM SOLICITUD_INGRESO;

SELECT solicitud_mc_id, emprendimiento_id, estado
FROM SOLICITUD_MICROCREDITO;

SELECT microcredito_id, solicitud_mc_id, estado_credito
FROM MICROCREDITO;


EXEC sp_RegistrarSolicitudMicrocredito
    @EmprendimientoID = 1,
    @CoordinadorID = 1,
    @AreaFinancieraID = 1,
    @MontoSolicitado = 5000.00,
    @Finalidad = 'Adquisición de materiales y capital de trabajo';

SELECT * FROM SOLICITUD_MICROCREDITO
ORDER BY solicitud_mc_id DESC;

EXEC sp_EvaluarMicrocredito
    @SolicitudMCID = 1,
    @AreaFinancieraID = 1,
    @Resultado = 'APROBADA',
    @Observaciones = 'El emprendimiento cumple con los criterios financieros.';

SELECT * FROM SOLICITUD_MICROCREDITO
WHERE solicitud_mc_id = 1;


EXEC sp_RegistrarVisitaMonitoreo
    @AsesorID = 11,
    @EmprendimientoID = 1,
    @MicrocreditoID = 1,
    @Hallazgos = 'Se verificó el avance del emprendimiento.',
    @Dificultades = 'Falta de capital de trabajo.',
    @Acuerdos = 'Mejorar el control de inventario.',
    @Observaciones = 'Seguimiento satisfactorio.';

SELECT * FROM VISITA_MONITOREO
ORDER BY visita_id DESC;

/*PROBAR VISTAS */
-- Vista de beneficiarios y emprendimientos
SELECT * FROM vw_BeneficiariosEmprendimientos;

-- Vista de microcréditos otorgados
SELECT * FROM vw_MicrocreditosOtorgados;

-- Vista de seguimiento técnico
SELECT * FROM vw_SeguimientoTecnico;

-- Vista de asistencia a capacitaciones
SELECT * FROM vw_AsistenciaCapacitaciones;


/*PROBAR LOS TRIGGERS*/
-- Consultar fecha antes de actualizar
SELECT microcredito_id,
       estado_credito,
       fecha_actualizacion
FROM MICROCREDITO
WHERE microcredito_id = 1;

-- Actualizar el estado
UPDATE MICROCREDITO
SET estado_credito = 'VENCIDO'
WHERE microcredito_id = 1;

-- Consultar fecha después de actualizar
SELECT microcredito_id,
       estado_credito,
       fecha_actualizacion
FROM MICROCREDITO
WHERE microcredito_id = 1;

/*Comprobar usuarios y asignación de roles*/
SELECT
    usuario.name AS usuario,
    rol.name AS rol_asignado
FROM sys.database_role_members AS miembros
INNER JOIN sys.database_principals AS rol
    ON miembros.role_principal_id = rol.principal_id
INNER JOIN sys.database_principals AS usuario
    ON miembros.member_principal_id = usuario.principal_id
WHERE rol.name LIKE 'rol_sigam_%'
ORDER BY rol.name;



USE microcreditos;
GO

-- Crear usuario administrador
IF NOT EXISTS (
    SELECT 1 FROM sys.database_principals
    WHERE name = 'usuario_admin'
)
    CREATE USER usuario_admin WITHOUT LOGIN;
GO

-- Crear usuario coordinador
IF NOT EXISTS (
    SELECT 1 FROM sys.database_principals
    WHERE name = 'usuario_coordinador'
)
    CREATE USER usuario_coordinador WITHOUT LOGIN;
GO

-- Crear usuario financiero
IF NOT EXISTS (
    SELECT 1 FROM sys.database_principals
    WHERE name = 'usuario_financiero'
)
    CREATE USER usuario_financiero WITHOUT LOGIN;
GO

-- Crear usuario asesor
IF NOT EXISTS (
    SELECT 1 FROM sys.database_principals
    WHERE name = 'usuario_asesor'
)
    CREATE USER usuario_asesor WITHOUT LOGIN;
GO

-- Crear usuario técnico
IF NOT EXISTS (
    SELECT 1 FROM sys.database_principals
    WHERE name = 'usuario_tecnico'
)
    CREATE USER usuario_tecnico WITHOUT LOGIN;
GO

/*ASIGNAR ROLES*/
USE microcreditos;
GO

ALTER ROLE rol_sigam_administrador
ADD MEMBER usuario_admin;

ALTER ROLE rol_sigam_coordinador
ADD MEMBER usuario_coordinador;

ALTER ROLE rol_sigam_financiero
ADD MEMBER usuario_financiero;

ALTER ROLE rol_sigam_asesor
ADD MEMBER usuario_asesor;

ALTER ROLE rol_sigam_tecnico
ADD MEMBER usuario_tecnico;
GO

SELECT
    name AS usuario,
    type_desc AS tipo
FROM sys.database_principals
WHERE name IN (
    'usuario_admin',
    'usuario_coordinador',
    'usuario_financiero',
    'usuario_asesor',
    'usuario_tecnico'
);

/*ACCESO A COORDINADOR */
USE microcreditos;
GO

EXECUTE AS USER = 'usuario_coordinador';

SELECT USER_NAME() AS usuario_actual;
SELECT *FROM vw_BeneficiariosEmprendimientos;
SELECT *FROM vw_MicrocreditosOtorgados;

REVERT;
GO

/*Probar que el coordinador no puede acceder a información restringida */
USE microcreditos;
GO

EXECUTE AS USER = 'usuario_coordinador';
SELECT * FROM BITACORA_AUDITORIA;

REVERT;
GO


/*Área financiera:*/
EXECUTE AS USER = 'usuario_financiero';

SELECT USER_NAME() AS usuario_actual;
SELECT * FROM vw_MicrocreditosOtorgados;

REVERT;
GO

/*Asesor Técnico*/
EXECUTE AS USER = 'usuario_asesor';

SELECT USER_NAME() AS usuario_actual;
SELECT * FROM vw_SeguimientoTecnico;

REVERT;
GO


/*Técnico capacitador*/
EXECUTE AS USER = 'usuario_tecnico';

SELECT USER_NAME() AS usuario_actual;
SELECT * FROM vw_AsistenciaCapacitaciones;

REVERT;
GO

/*Realizar el respaldo completo*/
USE master;
GO

BACKUP DATABASE microcreditos
TO DISK = 'C:\Respaldos\microcreditos_full.bak'
WITH
    INIT,
    NAME = 'Respaldo completo SIGAM',
    DESCRIPTION = 'Respaldo completo de la base de datos microcreditos',
    STATS = 10;
GO

/*Comprobar que el respaldo existe*/
RESTORE VERIFYONLY
FROM DISK = 'C:\Respaldos\microcreditos_full.bak';
GO

/*Crear el respaldo diferencial*/
BACKUP DATABASE microcreditos
TO DISK = 'C:\Respaldos\microcreditos_diferencial.bak'
WITH
    DIFFERENTIAL,
    INIT,
    NAME = 'Respaldo diferencial SIGAM',
    STATS = 10;
GO

/*Verificar el respaldo diferencial*/
RESTORE VERIFYONLY
FROM DISK = 'C:\Respaldos\microcreditos_diferencial.bak';
GO

/*Consultar el historial de respaldos*/
SELECT
    database_name,
    backup_start_date,
    backup_finish_date,
    type AS tipo,
    backup_size / 1024 / 1024 AS tamano_MB
FROM msdb.dbo.backupset
WHERE database_name = 'microcreditos'
ORDER BY backup_finish_date DESC;
GO

/*PROCEDIMIENTO ALMACENADO 1 - EvaluarSolicitudIngreso*/
CREATE OR ALTER PROCEDURE sp_EvaluarSolicitudIngreso
    @SolicitudIngresoID INT,
    @CoordinadorID INT,
    @Estado NVARCHAR(20),
    @Observaciones NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Estado NOT IN ('APROBADA', 'RECHAZADA')
        THROW 50001, 'Estado no válido.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE SOLICITUD_INGRESO
        SET coordinador_id = @CoordinadorID,
            estado = @Estado,
            fecha_evaluacion = SYSDATETIME(),
            observaciones = @Observaciones
        WHERE solicitud_ingreso_id = @SolicitudIngresoID;

        IF @Estado = 'APROBADA'
        BEGIN
            INSERT INTO BENEFICIARIO (usuario_id, estado)
            SELECT s.solicitante_id, 'ACTIVO'
            FROM SOLICITUD_INGRESO s
            WHERE s.solicitud_ingreso_id = @SolicitudIngresoID
              AND NOT EXISTS (
                  SELECT 1 FROM BENEFICIARIO b
                  WHERE b.usuario_id = s.solicitante_id
              );
        END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;

/*PROCEDIMIENTO ALMACENADO 2 - sp_RegistrarSolicitudMicrocredito*/
CREATE OR ALTER PROCEDURE sp_RegistrarSolicitudMicrocredito
    @EmprendimientoID INT,
    @CoordinadorID INT,
    @AreaFinancieraID INT,
    @MontoSolicitado DECIMAL(12,2),
    @Finalidad NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    IF @MontoSolicitado <= 0
        THROW 50003, 'El monto debe ser mayor a cero.', 1;

    INSERT INTO SOLICITUD_MICROCREDITO (
        emprendimiento_id,
        coordinador_id,
        area_financiera_id,
        monto_solicitado,
        finalidad,
        estado
    )
    VALUES (
        @EmprendimientoID,
        @CoordinadorID,
        @AreaFinancieraID,
        @MontoSolicitado,
        @Finalidad,
        'REGISTRADA'
    );

    SELECT SCOPE_IDENTITY() AS solicitud_mc_id;
END;

/*PROCEDIMIENTO ALMACENADO 3. sp_EvaluarMicrocredito*/
CREATE OR ALTER PROCEDURE sp_EvaluarMicrocredito
    @SolicitudMCID INT,
    @AreaFinancieraID INT,
    @Resultado NVARCHAR(50),
    @Observaciones NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Resultado NOT IN ('APROBADA', 'RECHAZADA')
        THROW 50005, 'Resultado no válido.', 1;

    UPDATE SOLICITUD_MICROCREDITO
    SET area_financiera_id = @AreaFinancieraID,
        resultado_evaluacion = @Resultado,
        fecha_verificacion = SYSDATETIME(),
        fecha_evaluacion = SYSDATETIME(),
        observaciones = @Observaciones,
        estado = @Resultado
    WHERE solicitud_mc_id = @SolicitudMCID;

    SELECT 'Evaluación registrada correctamente' AS mensaje;
END;

/*PROCEDIMIENTO ALMACENADO 4. sp_OtorgarMicrocredito*/
CREATE OR ALTER PROCEDURE sp_OtorgarMicrocredito
    @SolicitudMCID INT,
    @AdministradorID INT,
    @CodigoCredito NVARCHAR(30),
    @MontoOtorgado DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;

    IF @MontoOtorgado <= 0
        THROW 50007, 'El monto debe ser mayor a cero.', 1;

    IF NOT EXISTS (
        SELECT 1
        FROM SOLICITUD_MICROCREDITO
        WHERE solicitud_mc_id = @SolicitudMCID
          AND estado = 'APROBADA'
    )
        THROW 50008, 'La solicitud debe estar aprobada.', 1;

    INSERT INTO MICROCREDITO (
        solicitud_mc_id,
        admin_id,
        codigo_credito,
        monto_otorgado,
        fecha_otorgamiento,
        estado_credito
    )
    VALUES (
        @SolicitudMCID,
        @AdministradorID,
        @CodigoCredito,
        @MontoOtorgado,
        CAST(SYSDATETIME() AS DATE),
        'VIGENTE'
    );

    SELECT SCOPE_IDENTITY() AS microcredito_id;
END;

/*PROCEDIMIENTO ALMACENADO 5. sp_RegistrarVisitaMonitoreo*/
CREATE OR ALTER PROCEDURE sp_RegistrarVisitaMonitoreo
    @AsesorID INT,
    @EmprendimientoID INT,
    @MicrocreditoID INT = NULL,
    @Hallazgos NVARCHAR(MAX) = NULL,
    @Dificultades NVARCHAR(MAX) = NULL,
    @Acuerdos NVARCHAR(MAX) = NULL,
    @Observaciones NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO VISITA_MONITOREO (
        asesor_id,
        emprendimiento_id,
        microcredito_id,
        fecha_visita,
        hallazgos,
        dificultades,
        acuerdos,
        observaciones,
        estado,
        estado_sincronizacion
    )
    VALUES (
        @AsesorID,
        @EmprendimientoID,
        @MicrocreditoID,
        SYSDATETIME(),
        @Hallazgos,
        @Dificultades,
        @Acuerdos,
        @Observaciones,
        'REALIZADA',
        'PENDIENTE'
    );

    SELECT SCOPE_IDENTITY() AS visita_id;
END;

/*-----------------------------------------*/
USE microcreditos;
GO

SELECT * FROM SOLICITUD_INGRESO;
SELECT * FROM SOLICITANTE;
SELECT * FROM BENEFICIARIO;
SELECT * FROM EMPRENDIMIENTO;
SELECT * FROM SOLICITUD_MICROCREDITO;
SELECT * FROM MICROCREDITO;
SELECT * FROM COORDINADORES_PROGRAMAS;
SELECT * FROM AREA_FINANCIERA;
SELECT * FROM ADMINISTRADOR_ORGANIZACION;
SELECT * FROM ASESOR_TECNICO;


SELECT *FROM SOLICITUD_INGRESO
WHERE estado = 'PENDIENTE';

/*2. Probar sp_EvaluarSolicitudIngreso*/
SELECT * FROM SOLICITUD_INGRESO
WHERE estado = 'PENDIENTE';
/*3. Probar sp_RegistrarSolicitudMicrocredito*/
SELECT * FROM EMPRENDIMIENTO;

EXEC sp_RegistrarSolicitudMicrocredito
    @EmprendimientoID = 1,
    @CoordinadorID = 1,
    @AreaFinancieraID = 1,
    @MontoSolicitado = 5000.00,
    @Finalidad = 'Compra de materiales para el emprendimiento';

SELECT * FROM SOLICITUD_MICROCREDITO
ORDER BY solicitud_mc_id DESC;

/*Procedimiento 4 - Probar sp_EvaluarMicrocredito*/
SELECT * FROM SOLICITUD_MICROCREDITO;
EXEC sp_EvaluarMicrocredito
    @SolicitudMCID = 1,
    @AreaFinancieraID = 1,
    @Resultado = 'APROBADA',
    @Observaciones = 'Evaluación financiera favorable.';

SELECT * FROM SOLICITUD_MICROCREDITO
WHERE solicitud_mc_id = 1;



/*Probar sp_OtorgarMicrocredito*/
SELECT * FROM SOLICITUD_MICROCREDITO
WHERE estado = 'APROBADA';

EXEC sp_OtorgarMicrocredito
    @SolicitudMCID = 1,
    @AdministradorID = 1,
    @CodigoCredito = 'SIGAM-TEST-001',
    @MontoOtorgado = 5000.00;

    SELECT * FROM MICROCREDITO
ORDER BY microcredito_id DESC;

/*TRIGGERS */
USE microcreditos;
GO

SELECT
    name AS nombre_trigger,
    parent_id,
    OBJECT_NAME(parent_id) AS tabla_asociada,
    is_disabled AS deshabilitado
FROM sys.triggers
WHERE is_ms_shipped = 0;


/*Probar trg_ActualizarFechaMicrocredito*/
/*Paso 1. Buscar un microcrédito*/

SELECT
    microcredito_id,
    codigo_credito,
    estado_credito,
    fecha_actualizacion
FROM MICROCREDITO;

/*Paso 2. Observar la fecha antes del cambio*/
SELECT
    microcredito_id,
    fecha_actualizacion
FROM MICROCREDITO
WHERE microcredito_id = 1;

/*Paso 3. Modificar un dato del registro*/
UPDATE MICROCREDITO
SET monto_otorgado = monto_otorgado
WHERE microcredito_id = 1;

/*Paso 4. Verificar la fecha*/
SELECT
    microcredito_id,
    fecha_actualizacion
FROM MICROCREDITO
WHERE microcredito_id = 1;







/**/
/**/

/**/
/**/
/**/
/**/

/**/