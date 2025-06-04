FROM python:3.9-slim-bookworm

# Instala las dependencias base de unixODBC y curl
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    gnupg \
    unixodbc-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Descarga e instala el controlador ODBC de Microsoft para SQL Server (versión 18)
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/microsoft.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] https://packages.microsoft.com/debian/12/prod bookworm main" > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql18 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Asegurarse de que el driver tenga la ruta correcta.
RUN echo "[ODBC Driver 18 for SQL Server]\nDescription=Microsoft ODBC Driver 18 for SQL Server\nDriver=/opt/microsoft/msodbcsql18/lib64/libmsodbcsql-18.5.so.1.1\nUsageCount=1" > /etc/odbcinst.ini && \
    odbcinst -i -d -f /etc/odbcinst.ini

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 80
ENV FLASK_APP=api.py
ENV FLASK_RUN_HOST=0.0.0.0
CMD ["flask", "run", "--port=80"]