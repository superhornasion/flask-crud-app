from flask import Flask, request, render_template, redirect
import os
import pyodbc

app = Flask(__name__)

# Obtener la cadena de conexión de una variable de entorno
# Esto es crucial para la seguridad y flexibilidad
DB_CONNECTION_STRING = os.environ.get("DB_CONNECTION_STRING")

if DB_CONNECTION_STRING is None:
    raise ValueError("DB_CONNECTION_STRING environment variable not set.")

# Función para obtener una conexión a la base de datos Azure SQL
def get_db_connection():
    try:
        conn = pyodbc.connect(DB_CONNECTION_STRING)
        return conn
    except pyodbc.Error as ex:
        sqlstate = ex.args[0]
        print(f"Error connecting to DB: {sqlstate}")
        # Aquí podrías manejar el error de manera más robusta
        raise

# Función para inicializar la tabla en Azure SQL Database
def init_db():
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('''
            IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='tasks' and xtype='U')
            BEGIN
                CREATE TABLE dbo.tasks (
                    id INT IDENTITY(1,1) PRIMARY KEY, -- IDENTITY para autoincremento en SQL Server
                    title NVARCHAR(MAX) NOT NULL,     -- NVARCHAR para texto en SQL Server
                    done BIT NOT NULL DEFAULT 0       -- BIT para booleano en SQL Server
                )
            END
        ''')
        conn.commit()
        print("Database initialized successfully.")
    except pyodbc.Error as ex:
        sqlstate = ex.args[0]
        print(f"Error initializing DB: {sqlstate}")
        # Podrías verificar si el error es por tabla ya existente para evitar fallar en cada inicio
    finally:
        if conn:
            conn.close()

init_db() # Llama a la inicialización de la DB al iniciar la app

@app.route('/')
def index():
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('SELECT id, title, done FROM tasks')
        rows = cursor.fetchall()
        return render_template('index.html', tasks=rows)
    finally:
        if conn:
            conn.close()

@app.route('/add', methods=['POST'])
def add_task():
    title = request.form['title']
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('INSERT INTO tasks (title) VALUES (?)', (title,))
        conn.commit()
        return redirect('/')
    finally:
        if conn:
            conn.close()

@app.route('/delete/<int:task_id>', methods=['POST'])
def delete_task(task_id):
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('DELETE FROM tasks WHERE id = ?', (task_id,))
        conn.commit()
        return redirect('/')
    finally:
        if conn:
            conn.close()

@app.route('/toggle/<int:task_id>', methods=['POST'])
def toggle_done(task_id):
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        # Obtener el estado actual de 'done' (BIT se traduce a True/False en Python)
        cursor.execute('SELECT done FROM tasks WHERE id = ?', (task_id,))
        done = cursor.fetchone()[0]
        # Actualizar el estado (BIT 1 para True, 0 para False)
        cursor.execute('UPDATE tasks SET done = ? WHERE id = ?', (int(not done), task_id))
        conn.commit()
        return redirect('/')
    finally:
        if conn:
            conn.close()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)