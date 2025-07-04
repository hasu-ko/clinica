import mysql.connector
from mysql.connector import Error
import re
from datetime import datetime



def ejecutar_query(cursor, query, descripcion=""):
    try:
        cursor.execute(query)
        print(f"{descripcion} ejecutado correctamente.")
    except Error as e:
        print(f"Error al ejecutar {descripcion}: {e}")

def carga_fact_citas(dw_cursor, dw_conn):
    try:
        query = """
        INSERT INTO Hechos_Citas (
            cita_id, paciente_id, doctor_id, fecha_id, tratamiento_id, costo, estado, motivo
        )
        SELECT
            c.ID_Cita,
            fc.ID_Paciente,
            c.ID_Doctor,
            c.Fecha,
            t.ID_Tratamientos,
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
        LEFT JOIN clinica_db.Facturas f ON f.Doctores_ID_Doctor = c.ID_Doctor
        LEFT JOIN clinica_db.Tratamientos t ON t.Doctores_ID_Doctor = c.ID_Doctor
        GROUP BY c.ID_Cita, fc.ID_Paciente, c.ID_Doctor, c.Fecha, t.ID_Tratamientos, c.Estado, c.Motivo
        ON DUPLICATE KEY UPDATE
            costo = VALUES(costo),
            estado = VALUES(estado),
            tratamiento_id = VALUES(tratamiento_id),
            motivo = VALUES(motivo);
        """
        dw_cursor.execute(query)
        dw_conn.commit()
        print("✅ Hechos_Citas cargadas correctamente.")
    except Error as err:
        print(f"❌ Error en Hechos_Citas: {err}")

def insertar_nuevo_paciente(source_cursor, source_conn):
    try:
        print("=== Insertar Nuevo Paciente ===")

        # Validar RUT único en la tabla Paciente
        while True:
            rut = input("RUT (sin puntos, con guion): ").strip()
            source_cursor.execute("SELECT 1 FROM Paciente WHERE Rut = %s", (rut,))
            if source_cursor.fetchone():
                print("⚠️ Ya existe un paciente con ese RUT.")
            else:
                break

        # Validar nombre y apellido como texto
        def validar_texto(label):
            while True:
                texto = input(f"{label}: ").strip()
                if not texto.isalpha():
                    print(f"{label} debe contener solo letras.")
                else:
                    return texto

        nombre = validar_texto("Nombre")
        apellido = validar_texto("Apellido")

        # Validar fecha de nacimiento
        while True:
            fecha_nac = input("Fecha de nacimiento (YYYY-MM-DD o YYYY/MM/DD): ")
            try:
                fecha_nac = fecha_nac.replace("-", "/")
                fecha_obj = datetime.strptime(fecha_nac, '%Y/%m/%d')
                fecha_nac_final = fecha_obj.strftime('%Y%m%d')  # formato INT
                break
            except ValueError:
                print("❌ Fecha inválida.")

        # Validar teléfono numérico
        while True:
            telefono = input("Teléfono (sólo números): ").strip()
            if not telefono.isdigit():
                print("❌ Teléfono inválido.")
            else:
                break

        # Dirección libre
        direccion = input("Dirección: ").strip()

        # Insertar en Persona
        source_cursor.execute("""
            INSERT INTO Persona (Nombre, Apellido, Fecha_nacimiento, Telefono)
            VALUES (%s, %s, %s, %s)
        """, (nombre, apellido, fecha_nac_final, telefono))
        source_conn.commit()

        # Obtener ID_Persona recién creada
        source_cursor.execute("SELECT LAST_INSERT_ID()")
        id_persona = source_cursor.fetchone()[0]

        # Insertar en Paciente con el RUT
        source_cursor.execute("""
            INSERT INTO Paciente (Direccion, ID_Persona, Rut)
            VALUES (%s, %s, %s)
        """, (direccion, id_persona, rut))
        source_conn.commit()

        print("✅ Paciente insertado correctamente.")

    except Error as e:
        print(f"❌ Error al insertar paciente: {e}")

def insertar_nueva_cita(source_cursor, source_conn):
    while True:
        print("\n==============================")
        print("🆕 Insertar Nueva Cita")
        print("==============================")

        # Validar ID_Cita único
        while True:
            id_cita = input("🔢 ID de la cita (número): ").strip()
            if not id_cita.isdigit():
                print("❌ El ID debe ser un número.")
                continue

            source_cursor.execute("SELECT 1 FROM Cita WHERE ID_Cita = %s", (id_cita,))
            if source_cursor.fetchone():
                print("⚠️ Esa ID de cita ya existe.")
            else:
                break

        # Validar ID_Paciente existente
        while True:
            id_paciente = input("👤 ID del paciente: ").strip()
            if not id_paciente.isdigit():
                print("❌ El ID del paciente debe ser numérico.")
                continue
            source_cursor.execute("SELECT 1 FROM Paciente WHERE ID_Paciente = %s", (id_paciente,))
            if not source_cursor.fetchone():
                print("⚠️ No se encontró ese paciente.")
            else:
                break

        # Validar ID_Doctor existente
        while True:
            id_doctor = input("🩺 ID del doctor: ").strip()
            if not id_doctor.isdigit():
                print("❌ El ID del doctor debe ser numérico.")
                continue
            source_cursor.execute("SELECT 1 FROM Doctores WHERE ID_Doctor = %s", (id_doctor,))
            if not source_cursor.fetchone():
                print("⚠️ No se encontró ese doctor.")
            else:
                break

        try:
            # Validar Fecha
            while True:
                fecha_input = input("📅 Fecha (YYYY/MM/DD o YYYY-MM-DD): ").strip()
                try:
                    fecha_input = fecha_input.replace("-", "/")
                    fecha_obj = datetime.strptime(fecha_input, '%Y/%m/%d')

                    if not (1900 <= fecha_obj.year <= 2100):
                        raise ValueError("⚠️ Año fuera del rango permitido (1900–2100)")

                    fecha = fecha_obj.strftime('%Y%m%d')  # Para la DB
                    fecha_mostrada = fecha_obj.strftime('%d/%m/%Y')  # Para mostrar
                    print(f"\n✅ Fecha válida: {fecha_mostrada}\n")
                    break

                except ValueError as e:
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    print("❌ Fecha inválida.")
                    print(f"📌 Detalle: {e}")
                    print("📌 Usa formato: 2024/07/04 o 2024-07-04")
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            # Validar Estado
            estados_validos = ['atendida', 'pendiente', 'cancelada', 'no_asistio']
            while True:
                estado = input("📌 Estado (atendida/pendiente/cancelada/no_asistio): ").lower().strip()
                if estado not in estados_validos:
                    print("❌ Estado no válido. Opciones: atendida, pendiente, cancelada, no_asistio.")
                else:
                    break

            # Motivo
            motivo = input("📝 Motivo de la cita: ").strip()

            # Insertar Ficha_Consulta
            source_cursor.execute("""
                INSERT INTO Ficha_Consulta (ID_Paciente)
                VALUES (%s)
            """, (id_paciente,))
            source_conn.commit()

            # Obtener ID_Ficha_Consulta generado
            source_cursor.execute("SELECT LAST_INSERT_ID();")
            id_ficha = source_cursor.fetchone()[0]

            # Insertar Cita
            source_cursor.execute("""
                INSERT INTO Cita (ID_Cita, Fecha, Motivo, Estado, ID_Doctor, ID_Ficha_Consulta)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (id_cita, fecha, motivo, estado, id_doctor, id_ficha))
            source_conn.commit()

            print("\n✅ Cita insertada correctamente con ficha asociada.")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            # ¿Desea continuar?
            while True:
                continuar = input("🔁 ¿Deseas insertar otra cita? (sí/no): ").strip().lower()
                if continuar in ['sí', 'si', 's']:
                    break  # vuelve al inicio del while True principal
                elif continuar in ['no', 'n']:
                    print("\n👋 Saliendo del sistema. ¡Hasta luego!\n")
                    return
                else:
                    print("❌ Opción no válida. Escribe 'sí' o 'no'.")

        except Error as e:
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print(f"❌ Error al insertar la cita: {e}")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

def main():
    source_conn = None
    source_cursor = None
    dw_conn = None
    dw_cursor = None

    try:
        # Conexión a base de datos original (operacional)
        source_conn = mysql.connector.connect(
            host="localhost",
            user="root",
            password="",
            database="clinica_db"
        )
        source_cursor = source_conn.cursor()

        # Conexión a base de datos DW
        dw_conn = mysql.connector.connect(
            host="localhost",
            user="root",
            password="",
            database="clinica_dw_test"
        )
        dw_cursor = dw_conn.cursor()

        # Menú interactivo
        print(f"Conectado a la base: {source_conn.database}")
        print("=== Menú de Opciones ===")
        print("1. Insertar nueva cita")
        print("2. Insertar nuevo paciente")
        print("3. Solo actualizar DW")
        opcion = input("Elige una opción (1/2): ")

        if opcion == "1":
            insertar_nueva_cita(source_cursor, source_conn)
        elif opcion == "2":
            insertar_nuevo_paciente(source_cursor, source_conn)

        # Carga de dimensiones y hechos
        ejecutar_query(dw_cursor, """
            INSERT INTO Dim_Paciente (paciente_id, rut, nombre, apellido, direccion, fecha_nacimiento, telefono)
            SELECT 
                p.ID_Paciente,
                p.Rut,
                per.Nombre,
                per.Apellido,
                p.Direccion,
                per.Fecha_nacimiento,
                per.Telefono
            FROM clinica_db.Paciente p
            JOIN clinica_db.Persona per ON p.ID_Persona = per.ID_Persona
            ON DUPLICATE KEY UPDATE
                rut = VALUES(rut),
                nombre = VALUES(nombre),
                apellido = VALUES(apellido),
                direccion = VALUES(direccion),
                fecha_nacimiento = VALUES(fecha_nacimiento),
                telefono = VALUES(telefono);
        """, "Carga Dim_Paciente")

        ejecutar_query(dw_cursor, """
            INSERT INTO Dim_Doctor (doctor_id, nombre, apellido, especialidad)
            SELECT 
                d.ID_Doctor,
                p.Nombre,
                p.Apellido,
                d.Especialidad
            FROM clinica_db.Doctores d
            JOIN clinica_db.Persona p ON d.ID_Persona = p.ID_Persona
            ON DUPLICATE KEY UPDATE
                nombre = VALUES(nombre),
                apellido = VALUES(apellido),
                especialidad = VALUES(especialidad);
        """, "Carga Dim_Doctor")

        ejecutar_query(dw_cursor, """
            INSERT INTO Dim_Tratamiento (tratamiento_id, descripcion, medicamentos_recetados)
            SELECT 
                ID_Tratamientos,
                Descripcion,
                Medicamentos_Recetados
            FROM clinica_db.Tratamientos
            ON DUPLICATE KEY UPDATE
                descripcion = VALUES(descripcion),
                medicamentos_recetados = VALUES(medicamentos_recetados);
        """, "Carga Dim_Tratamiento")

        ejecutar_query(dw_cursor, """
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
        """, "Carga Dim_Tiempo")

        # Cargar hechos
        carga_fact_citas(dw_cursor, dw_conn)

        dw_conn.commit()

    except Error as e:
        print(f"Error generaldo: {e}")

    finally:
        if source_cursor:
            source_cursor.close()
        if source_conn:
            source_conn.close()
        if dw_cursor:
            dw_cursor.close()
        if dw_conn:
            dw_conn.close()
        print("Conexiones cerradas.")

if __name__ == "__main__":






    ###este es el verdadero
    main()
