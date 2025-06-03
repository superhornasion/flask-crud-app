from api import app
import pytest


@pytest.fixture
def client():
    app.config['TESTING'] = True  # Activa el modo de prueba de Flask
    with app.test_client() as client:
        yield client  # Retorna el cliente de prueba para que los tests lo usen


def test_home_page(client):
    # Hace una solicitud GET a la ruta raíz
    response = client.get('/')
    assert response.status_code == 200
    assert b"Hola mundo" in response.data
