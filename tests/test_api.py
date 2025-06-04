# encoding: utf-8
# tests/test_api.py
import pytest
import os
from unittest.mock import patch, MagicMock

# Mockea la variable de entorno DB_CONNECTION_STRING
with patch.dict(os.environ, {'DB_CONNECTION_STRING': 'mock_connection_string'}):
    from api import app, get_db_connection


@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


@patch('api.get_db_connection')
def test_home_page(mock_get_db_connection, client):
    mock_conn = MagicMock()
    mock_get_db_connection.return_value = mock_conn
    
    response = client.get('/')
    assert response.status_code == 200
    assert b"Gesti\xc3\xb3n de tareas" in response.data
    mock_get_db_connection.assert_called_once()
