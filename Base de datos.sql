drop database if exists clinica_db;
Create database clinica_db;
use clinica_db;

-- Tabla de Persona
CREATE TABLE Persona (
    ID_Persona INT PRIMARY KEY,
    Nombre VARCHAR(20),
    Apellido VARCHAR(50),
    Fecha_nacimiento INTEGER,
    Telefono INTEGER
);

-- Tabla Doctores
CREATE TABLE Doctores (
	ID_Doctor INT PRIMARY KEY,
    Especialidad VARCHAR(90),
    ID_Persona INT,
    FOREIGN KEY (ID_Persona) REFERENCES Persona(ID_Persona)
);

-- Tabla Ficha_Consulta
CREATE TABLE Ficha_Consulta (
    ID_Ficha_Consulta INTEGER PRIMARY KEY,
    Nombre VARCHAR(20),
    Apellido VARCHAR(30),
    Medicamento VARCHAR(100),
    Fecha_nacimiento INTEGER,
    Telefono INTEGER
);
ALTER TABLE Ficha_Consulta ADD COLUMN ID_Paciente INTEGER;
ALTER TABLE Ficha_Consulta MODIFY COLUMN ID_Ficha_Consulta INTEGER AUTO_INCREMENT;



-- Tabla ID_Cita
CREATE TABLE Cita (
    ID_Cita INTEGER PRIMARY KEY,
    Fecha INTEGER,
    Motivo VARCHAR(250),
    Estado VARCHAR(100),
    ID_Doctor INTEGER,
    ID_Ficha_Consulta INTEGER,
    FOREIGN KEY (ID_Doctor) REFERENCES Doctores(ID_Doctor),
    FOREIGN KEY (ID_Ficha_Consulta) REFERENCES Ficha_Consulta(ID_Ficha_Consulta)
);

-- Tabla Paciente
CREATE TABLE Paciente (
    ID_Paciente INTEGER PRIMARY KEY,
    Rut INTEGER,
    Direccion VARCHAR(100),
    ID_Cita INTEGER,
    ID_Persona INTEGER,
    FOREIGN KEY (ID_Cita) REFERENCES Cita(ID_Cita),
    FOREIGN KEY (ID_Persona) REFERENCES Persona(ID_Persona)
);

 select * from cita;
 

-- Tabla Facturas
CREATE TABLE Facturas (
    ID_Factura INTEGER PRIMARY KEY,
    Monto INTEGER,
    Fecha_Emision INTEGER,
    Estado VARCHAR(200),
    Doctores_ID_Doctor INTEGER,
    CONSTRAINT Facturas_Doctores_FK FOREIGN KEY (Doctores_ID_Doctor) REFERENCES Doctores(ID_Doctor)
);

-- Tabla Tratamientos
CREATE TABLE Tratamientos (
    ID_Tratamientos INTEGER PRIMARY KEY,
    Descripcion VARCHAR(250),
    Medicamentos_Recetados VARCHAR(80),
    Doctores_ID_Doctor INTEGER,
    CONSTRAINT Tratamientos_Doctores_FK FOREIGN KEY (Doctores_ID_Doctor) REFERENCES Doctores(ID_Doctor)
);

-- Tabla Tratamiento_Medicamento
CREATE TABLE Tratamiento_Medicamento (
    ID INTEGER PRIMARY KEY,
    Dosis_indica VARCHAR(70),
    Frecuencia VARCHAR(80),
    Tratamientos_ID_Tratamientos INTEGER,
    CONSTRAINT Tratamiento_Medicamento_Tratamientos_FK FOREIGN KEY (Tratamientos_ID_Tratamientos) REFERENCES Tratamientos(ID_Tratamientos)
);

-- Tabla Medicamentos
CREATE TABLE Medicamentos (
    ID_Medicamento INTEGER PRIMARY KEY,
    Nombre_medicamento VARCHAR(70),
    Fecha_Caducidad INTEGER,
    Fecha_Elaboracion INTEGER,
    Ficha_Consulta_ID_Ficha_Consulta INTEGER,
    Tratamiento_Medicamento_ID INTEGER,
    CONSTRAINT Medicamentos_Ficha_Consulta_FK FOREIGN KEY (Ficha_Consulta_ID_Ficha_Consulta) REFERENCES Ficha_Consulta(ID_Ficha_Consulta),
    CONSTRAINT Medicamentos_Tratamiento_Medicamento_FK FOREIGN KEY (Tratamiento_Medicamento_ID) REFERENCES Tratamiento_Medicamento(ID)
);

CREATE TABLE Hechos_Citas (
    cita_id INT PRIMARY KEY,
    paciente_id INT NOT NULL,
    doctor_id INT NOT NULL,
    fecha_id INT NOT NULL,
    ficha_id INT,
    tratamiento_id INT,
    duracion_min INT,
    costo DECIMAL(10,2),
    estado ENUM('agendada', 'completada', 'cancelada', 'no_asistio'),
    motivo VARCHAR(255),
    FOREIGN KEY (fecha_id) REFERENCES Cita(ID_Cita), -- Suponiendo que 'fecha_id' apunta a 'Cita'
    FOREIGN KEY (paciente_id) REFERENCES Paciente(ID_Paciente),
    FOREIGN KEY (doctor_id) REFERENCES Doctores(ID_Doctor),
    FOREIGN KEY (ficha_id) REFERENCES Ficha_Consulta(ID_Ficha_Consulta),
    FOREIGN KEY (tratamiento_id) REFERENCES Tratamientos(ID_Tratamientos)
);


-- Persona
INSERT INTO Persona (ID_Persona, Nombre, Apellido, Fecha_nacimiento, Telefono)
VALUES 
(1, 'Carlos', 'Pérez', 19850115, 987654321),
(2, 'Laura', 'Gómez', 19900220, 912345678),
(3, 'Dr. Ana', 'Ramírez', 19751210, 999888777),
(5, 'Dr. Esteban', 'Vasquez', 21342134, 999933312),
(6, 'Marco', 'López', 19881111, 933223344),
(7, 'Isabel', 'Soto', 19790730, 966778899),
(8, 'Dr. Carla', 'Navarro', 19830520, 988877766),
(9, 'Dr. Jorge', 'Leiva', 19670615, 911122233),
(10, 'Camila', 'Rojas', 19951123, 911233344),
(11, 'Fernando', 'Garrido', 19800602, 922114455),
(12, 'Lucía', 'Mendoza', 19790505, 955667788);

-- Doctores
INSERT INTO Doctores (ID_Doctor, Especialidad, ID_Persona)
VALUES
(1, 'Pediatría', 3),
(2, 'Neurologo', 5),
(3, 'Cardiología', 8),
(4, 'Traumatología', 9);

-- Ficha_Consulta
INSERT INTO Ficha_Consulta (ID_Ficha_Consulta, Nombre, Apellido, Medicamento, Fecha_nacimiento, Telefono)
VALUES
(1, 'Carlos', 'Pérez', 'Paracetamol', 19850115, 987654321),
(2, 'Laura', 'Gómez', 'Ibuprofeno', 19900220, 912345678),
(3, 'Marco', 'López', 'Losartán', 19881111, 933223344),
(4, 'Isabel', 'Soto', 'Ketoprofeno', 19790730, 966778899),
(5, 'Camila', 'Rojas', 'Amoxicilina', 19951123, 911233344),
(6, 'Fernando', 'Garrido', 'Omeprazol', 19800602, 922114455),
(7, 'Lucía', 'Mendoza', 'Metformina', 19790505, 955667788);

-- Cita
INSERT INTO Cita (ID_Cita, Fecha, Motivo, Estado, ID_Doctor, ID_Ficha_Consulta)
VALUES
(1, 20240501, 'Dolor de cabeza', 'Atendida', 1, 1),
(2, 20240502, 'Fiebre', 'Pendiente', 1, 2),
(3, 20240503, 'Chequeo corazón', 'Atendida', 3, 3),
(4, 20240504, 'Dolor de rodilla', 'Cancelada', 4, 4),
(5, 20240415, 'Dolor de garganta', 'Completada', 1, 5),
(6, 20240610, 'Reflujo', 'Atendida', 2, 6),
(7, 20240705, 'Chequeo de diabetes', 'Completada', 3, 7);


-- Paciente
INSERT INTO Paciente (ID_Paciente, Rut, Direccion, ID_Cita, ID_Persona)
VALUES
(1, 12345678, 'Av. Siempre Viva 123', 1, 1),
(2, 87654321, 'Calle Falsa 456', 2, 2),
(3, 11223344, 'Calle Los Robles 789', 3, 6),
(4, 55667788, 'Pje. Las Lilas 321', 4, 7),
(5, 13456789, 'Av. Pacifico 123', 5, 10),
(6, 98765432, 'Los Almendros 456', 6, 11),
(7, 99887766, 'Camino Real 789', 7, 12);

-- Facturas
INSERT INTO Facturas (ID_Factura, Monto, Fecha_Emision, Estado, Doctores_ID_Doctor)
VALUES
(1, 25000, 20240501, 'Pagada', 1),
(2, 18000, 20240502, 'Pendiente', 2),
(3, 45000, 20240503, 'Pagada', 3),
(4, 0, 20240504, 'Cancelada', 4),
(5, 30000, 20240415, 'Pagada', 1),
(6, 22000, 20240610, 'Pagada', 2),
(7, 41000, 20240705, 'Pendiente', 3);

-- Tratamientos
INSERT INTO Tratamientos (ID_Tratamientos, Descripcion, Medicamentos_Recetados, Doctores_ID_Doctor)
VALUES
(1, 'Reposo y analgésico', 'Paracetamol', 1),
(2, 'Hidratación y antiinflamatorio', 'Ibuprofeno', 2),
(3, 'Tratamiento neurológico básico', 'Clonazepam', 2),
(4, 'Control de presión arterial', 'Losartán', 3),
(5, 'Rehabilitación leve', 'Ketoprofeno', 4),
(6, 'Antibiótico para infección', 'Amoxicilina', 1),
(7, 'Tratamiento gástrico', 'Omeprazol', 2),
(8, 'Control de glucosa', 'Metformina', 3);


-- Tratamiento_Medicamento
INSERT INTO Tratamiento_Medicamento (ID, Dosis_indica, Frecuencia, Tratamientos_ID_Tratamientos)
VALUES
(1, '500mg', 'Cada 8 horas', 1),
(2, '400mg', 'Cada 12 horas', 2),
(3, '50mg', 'Cada mañana', 4),
(4, '200mg', 'Cada 8 horas', 5),
(5, '250mg', 'Cada 12 horas', 6),
(6, '20mg', 'Antes del desayuno', 7),
(7, '850mg', 'Cada 8 horas', 8);

-- Medicamentos
INSERT INTO Medicamentos (ID_Medicamento, Nombre_medicamento, Fecha_Caducidad, Fecha_Elaboracion, Ficha_Consulta_ID_Ficha_Consulta, Tratamiento_Medicamento_ID)
VALUES
(1, 'Paracetamol', 20251231, 20240101, 1, 1),
(2, 'Ibuprofeno', 20251130, 20240215, 2, 2),
(3, 'Losartán', 20261231, 20240310, 3, 3),
(4, 'Ketoprofeno', 20251115, 20240301, 4, 4),
(5, 'Amoxicilina', 20251230, 20240401, 5, 5),
(6, 'Omeprazol', 20251201, 20240601, 6, 6),
(7, 'Metformina', 20260115, 20240701, 7, 7);


-- Scripts

-- Consulta de datos del paciente, cita y el doctor asociado
SELECT 
    p.Nombre AS Nombre_Paciente,
    p.Apellido AS Apellido_Paciente,
    c.Fecha AS Fecha_Cita,
    c.Motivo,
    d.Especialidad AS Especialidad_Doctor,
    per.Nombre AS Nombre_Doctor
FROM 
    Paciente pa
JOIN Persona p ON pa.ID_Persona = p.ID_Persona
JOIN Cita c ON pa.ID_Cita = c.ID_Cita
JOIN Doctores d ON c.ID_Doctor = d.ID_Doctor
JOIN Persona per ON d.ID_Persona = per.ID_Persona;

-- Ficha de consulta, medicamentos recetados y tratamiento aplicado
SELECT 
    fc.Nombre AS Nombre_Paciente,
    fc.Medicamento,
    m.Nombre_medicamento,
    tm.Dosis_indica,
    tm.Frecuencia
FROM 
    Ficha_Consulta fc
JOIN Medicamentos m ON fc.ID_Ficha_Consulta = m.Ficha_Consulta_ID_Ficha_Consulta
JOIN Tratamiento_Medicamento tm ON m.Tratamiento_Medicamento_ID = tm.ID;


-- Doctores, sus facturas emitidas y tratamientos que han recetado
SELECT 
    per.Nombre AS Nombre_Doctor,
    d.Especialidad,
    f.Monto AS Monto_Factura,
    t.Descripcion AS Tratamiento
FROM 
    Doctores d
JOIN Persona per ON d.ID_Persona = per.ID_Persona
JOIN Facturas f ON d.ID_Doctor = f.Doctores_ID_Doctor
JOIN Tratamientos t ON d.ID_Doctor = t.Doctores_ID_Doctor;

-- Paciente, tratamiento y medicamento final recibido
SELECT 
    pe.Nombre AS Nombre_Paciente,
    t.Descripcion AS Tratamiento,
    m.Nombre_medicamento
FROM 
    Paciente pa
JOIN Persona pe ON pa.ID_Persona = pe.ID_Persona
JOIN Cita c ON pa.ID_Cita = c.ID_Cita
JOIN Ficha_Consulta fc ON c.ID_Ficha_Consulta = fc.ID_Ficha_Consulta
JOIN Medicamentos m ON fc.ID_Ficha_Consulta = m.Ficha_Consulta_ID_Ficha_Consulta
JOIN Tratamiento_Medicamento tm ON m.Tratamiento_Medicamento_ID = tm.ID
JOIN Tratamientos t ON tm.Tratamientos_ID_Tratamientos = t.ID_Tratamientos;



