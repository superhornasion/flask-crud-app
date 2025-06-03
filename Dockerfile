FROM python:3.9-slim-bookworm

# Instala el controlador ODBC para SQL Server y las dependencias de pyodbc
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    gnupg \
    unixodbc-dev \
    curl && \
    # Descarga la clave GPG de Microsoft y guárdala en un archivo keyring
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/microsoft.gpg && \
    # Añade el repositorio de Microsoft (asegúrate de que la ruta sea correcta para Debian 12)
    echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] https://packages.microsoft.com/debian/12/prod bookworm main" > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql17 mssql-tools && \
    rm -rf /var/lib/apt/lists/*
# Limpia la cache

# Asegura que el driver esté registrado
RUN echo "[ODBC Driver 17 for SQL Server]\nDescription=Microsoft ODBC Driver 17 for SQL Server\nDriver=/opt/microsoft/msodbcsql17/lib64/libmsodbcsql-17.10.so.6.1\nUsageCount=1" > /etc/odbcinst.ini && \
    odbcinst -i -d -f /etc/odbcinst.ini


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

# Comando para ejecutar la aplicación cuando el contenedor se inicie
CMD ["python", "api.py"]