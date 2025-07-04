drop database if exists clinica_dw_test;
CREATE DATABASE clinica_dw_test;
USE clinica_dw_test;

CREATE TABLE Dim_Tiempo (
    fecha_id INT PRIMARY KEY,
    fecha DATE,
    anio INT,
    mes INT,
    dia INT,
    trimestre INT,
    nombre_mes VARCHAR(20)
);

CREATE TABLE Dim_Paciente (
    paciente_id INT PRIMARY KEY,
    rut VARCHAR(20),
    nombre VARCHAR(50),
    apellido VARCHAR(50),
    direccion VARCHAR(100),
    fecha_nacimiento DATE,
    telefono VARCHAR(20)
);

CREATE TABLE Dim_Doctor (
    doctor_id INT PRIMARY KEY,
    nombre VARCHAR(50),
    apellido VARCHAR(50),
    especialidad VARCHAR(100)
);

CREATE TABLE Dim_Tratamiento (
    tratamiento_id INT PRIMARY KEY,
    descripcion VARCHAR(250),
    medicamentos_recetados VARCHAR(100)
);
CREATE TABLE Hechos_Citas (
    cita_id INT PRIMARY KEY,
    paciente_id INT,
    doctor_id INT,
    ficha_id INT,
    fecha_id INT,
    tratamiento_id INT,
    costo INT,
    estado ENUM('agendada', 'completada', 'cancelada', 'no_asistio'),
    motivo VARCHAR(255),
    FOREIGN KEY (paciente_id) REFERENCES Dim_Paciente(paciente_id),
    FOREIGN KEY (doctor_id) REFERENCES Dim_Doctor(doctor_id),
    FOREIGN KEY (fecha_id) REFERENCES Dim_Tiempo(fecha_id),
    FOREIGN KEY (tratamiento_id) REFERENCES Dim_Tratamiento(tratamiento_id)
);




USE clinica_db;
SELECT * FROM Paciente;

-- Combinar datos de persona y paciente
SELECT 
    pa.ID_Paciente,
    per.Nombre,
    per.Apellido,
    per.Fecha_nacimiento,
    pa.Direccion,
    per.Telefono,
    pa.Rut
FROM Paciente pa
JOIN Persona per ON pa.ID_Persona = per.ID_Persona;



USE clinica_dw_test;

INSERT INTO Dim_Paciente (paciente_id, nombre, apellido, fecha_nacimiento, direccion, telefono, rut)
SELECT 
    p.ID_Paciente,
    per.Nombre,
    per.Apellido,
    per.Fecha_nacimiento,
    p.Direccion,
    per.Telefono,
    p.Rut
FROM clinica_db.Paciente p
JOIN clinica_db.Persona per ON p.ID_Persona = per.ID_Persona;

INSERT INTO Dim_Doctor (doctor_id, nombre, apellido, especialidad)
SELECT 
    d.ID_Doctor,
    p.Nombre,
    p.Apellido,
    d.Especialidad
FROM clinica_db.Doctores d
JOIN clinica_db.Persona p ON d.ID_Persona = p.ID_Persona;

INSERT INTO Dim_Tratamiento (tratamiento_id, descripcion, medicamentos_recetados)
SELECT 
    ID_Tratamientos,
    Descripcion,
    Medicamentos_Recetados
FROM clinica_db.Tratamientos;

SELECT DISTINCT c.Fecha AS fecha_id
FROM clinica_db.Cita c
LEFT JOIN clinica_dw_test.Dim_Tiempo dt ON c.Fecha = dt.fecha_id
WHERE dt.fecha_id IS NULL;



INSERT IGNORE INTO Dim_Tiempo (
    fecha_id, fecha, anio, mes, dia, trimestre, nombre_mes
)
SELECT DISTINCT
    Fecha AS fecha_id,
    STR_TO_DATE(Fecha, '%Y%m%d') AS fecha,
    YEAR(STR_TO_DATE(Fecha, '%Y%m%d')),
    MONTH(STR_TO_DATE(Fecha, '%Y%m%d')),
    DAY(STR_TO_DATE(Fecha, '%Y%m%d')),
    QUARTER(STR_TO_DATE(Fecha, '%Y%m%d')),
    MONTHNAME(STR_TO_DATE(Fecha, '%Y%m%d'))
FROM clinica_db.Cita;

SELECT DISTINCT Estado FROM clinica_db.Cita;


INSERT INTO Hechos_Citas (
    cita_id, paciente_id, doctor_id, fecha_id, ficha_id, tratamiento_id,
    costo, estado, motivo
)
SELECT
    c.ID_Cita,
    fc.ID_Paciente,
    c.ID_Doctor,
    c.Fecha AS fecha_id,
    c.ID_Ficha_Consulta,
    MIN(t.ID_Tratamientos),
    COALESCE(SUM(f.Monto), 0),
    CASE
        WHEN LOWER(c.Estado) = 'atendida' THEN 'completada'
        WHEN LOWER(c.Estado) = 'pendiente' THEN 'agendada'
        WHEN LOWER(c.Estado) IN ('cancelada', 'no_asistio') THEN LOWER(c.Estado)
        ELSE 'agendada'
    END,
    c.Motivo
FROM clinica_db.Cita c
JOIN clinica_db.Ficha_Consulta fc ON fc.ID_Ficha_Consulta = c.ID_Ficha_Consulta
JOIN clinica_db.Paciente p ON p.ID_Paciente = fc.ID_Paciente
LEFT JOIN clinica_db.Facturas f ON f.Doctores_ID_Doctor = c.ID_Doctor
LEFT JOIN clinica_db.Tratamientos t ON t.Doctores_ID_Doctor = c.ID_Doctor
WHERE c.ID_Cita <> 0  -- Excluir ID 0
GROUP BY 
    c.ID_Cita, 
    fc.ID_Paciente, 
    c.ID_Doctor, 
    c.Fecha, 
    c.ID_Ficha_Consulta, 
    c.Estado, 
    c.Motivo
ON DUPLICATE KEY UPDATE
    costo = VALUES(costo),
    estado = VALUES(estado),
    motivo = VALUES(motivo),
    tratamiento_id = VALUES(tratamiento_id);


-- Ver cuántas citas hay por estado:
SELECT estado, COUNT(*) AS cantidad FROM Hechos_Citas GROUP BY estado;


-- Ver citas por doctor:
SELECT d.nombre, d.apellido, COUNT(h.cita_id) AS total_citas
FROM Hechos_Citas h
JOIN Dim_Doctor d ON h.doctor_id = d.doctor_id
GROUP BY d.doctor_id;


-- Ver ingresos (monto) por mes:
SELECT t.anio, t.mes, SUM(h.costo) AS ingresos
FROM Hechos_Citas h
JOIN Dim_Tiempo t ON h.fecha_id = t.fecha_id
GROUP BY t.anio, t.mes
ORDER BY t.anio, t.mes;


CREATE VIEW resumen_citas AS
SELECT 
    dt.nombre_mes,
    dd.nombre AS doctor,
    dd.especialidad,
    COUNT(*) AS total_citas
FROM Hechos_Citas hc
JOIN Dim_Tiempo dt ON hc.fecha_id = dt.fecha_id
JOIN Dim_Doctor dd ON hc.doctor_id = dd.doctor_id
GROUP BY dt.nombre_mes, dd.nombre, dd.especialidad;

select * from resumen_citas;

CREATE VIEW resumen_citas AS
SELECT 
    dt.nombre_mes,
    dd.nombre AS doctor,
    dd.especialidad,
    COUNT(*) AS total_citas
FROM Hechos_Citas hc
JOIN Dim_Tiempo dt ON hc.fecha_id = dt.fecha_id
JOIN Dim_Doctor dd ON hc.doctor_id = dd.doctor_id
GROUP BY dt.nombre_mes, dd.nombre, dd.especialidad;


CREATE VIEW resumen_eficiencia_medica AS
SELECT
    dt.anio,
    dt.nombre_mes,
    dd.especialidad,
    hc.estado,
    COUNT(hc.cita_id) AS total_citas,
    SUM(hc.costo) AS ingresos_generados,
    ROUND(SUM(CASE WHEN hc.estado = 'completada' THEN hc.costo ELSE 0 END) / NULLIF(SUM(hc.costo), 0) * 100, 2) AS porcentaje_efectividad,
    AVG(hc.duracion_min) AS duracion_promedio_min
FROM
    Hechos_Citas hc
    JOIN Dim_Tiempo dt ON hc.fecha_id = dt.fecha_id
    JOIN Dim_Doctor dd ON hc.doctor_id = dd.doctor_id
GROUP BY
    dt.anio, dt.nombre_mes, dd.especialidad, hc.estado
ORDER BY
    dt.anio, dt.mes, dd.especialidad, hc.estado;
    
-- Consulta básica de todas las citas con información de pacientes y doctores
SELECT 
    hc.cita_id AS 'ID Cita',
    CONCAT(dp.nombre, ' ', dp.apellido) AS 'Paciente',
    dp.rut AS 'RUT Paciente',
    CONCAT(dd.nombre, ' ', dd.apellido) AS 'Doctor',
    dd.especialidad AS 'Especialidad',
    dt.fecha AS 'Fecha Cita',
    hc.costo AS 'Costo',
    hc.estado AS 'Estado',
    hc.motivo AS 'Motivo',
    dtr.descripcion AS 'Tratamiento'
FROM 
    Hechos_Citas hc
JOIN 
    Dim_Paciente dp ON hc.paciente_id = dp.paciente_id
JOIN 
    Dim_Doctor dd ON hc.doctor_id = dd.doctor_id
JOIN 
    Dim_Tiempo dt ON hc.fecha_id = dt.fecha_id
LEFT JOIN 
    Dim_Tratamiento dtr ON hc.tratamiento_id = dtr.tratamiento_id
ORDER BY 
    dt.fecha DESC
LIMIT 0, 1000;

select * from resumen_eficiencia_medica;

SELECT 
    paciente_id AS 'ID Paciente',
    rut AS 'RUT',
    nombre AS 'Nombre',
    apellido AS 'Apellido',
    fecha_nacimiento AS 'Fecha de Nacimiento',
    direccion AS 'Dirección',
    telefono AS 'Teléfono'
FROM clinica_dw_test.Dim_Paciente;


SELECT * FROM clinica_db.Cita WHERE ID_Cita = 0;

