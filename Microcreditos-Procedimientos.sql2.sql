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
SELECT *
FROM BITACORA_AUDITORIA
ORDER BY fecha_hora DESC;


/**/








/**/
/**/
/**/
/**/




