FROM python:3.9-slim-bookworm

# Instala el controlador ODBC para SQL Server (versión 18) y las dependencias de pyodbc
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    gnupg \
    unixodbc-dev \
    curl && \
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/microsoft.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] https://packages.microsoft.com/debian/12/prod bookworm main" > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql18 mssql-tools # <--- CAMBIADO DE msodbcsql17 A msodbcsql18
    rm -rf /var/lib/apt/lists/*

# Asegura que el driver esté registrado (para Driver 18)
RUN echo "[ODBC Driver 18 for SQL Server]\nDescription=Microsoft ODBC Driver 18 for SQL Server\nDriver=/opt/microsoft/msodbcsql18/lib64/libmsodbcsql-18.so.1.1\nUsageCount=1" > /etc/odbcinst.ini && \
    odbcinst -i -d -f /etc/odbcinst.ini
# NOTA: La versión específica de la librería (.so) puede variar, libmsodbcsql-18.so.1.1 es común para la v18.

# Establece el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copia el archivo requirements.txt al directorio de trabajo
COPY requirements.txt .

# Instala las dependencias de Python
RUN pip install --no-cache-dir -r requirements.txt

# Copia el resto de tu aplicación al directorio de trabajo
COPY . .

# Expone el puerto 80
EXPOSE 80

ENV FLASK_APP=api.py
ENV FLASK_RUN_HOST=0.0.0.0

CMD ["flask", "run", "--port=80"]