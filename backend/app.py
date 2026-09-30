"""Backend da atividade. Flutter nunca consulta diretamente a PokéAPI."""
from concurrent.futures import ThreadPoolExecutor
from functools import lru_cache
import random
import re

import requests
from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Desenvolvimento local: permite o Flutter Web.
POKEAPI = 'https://pokeapi.co/api/v2'


class ApiError(Exception):
    def __init__(self, message, status):
        self.message = message
        self.status = status


@app.errorhandler(ApiError)
def handle_api_error(error):
    return jsonify({'erro': error.message}), error.status


@lru_cache(maxsize=2048)
def consultar(caminho):
    try:
        response = requests.get(f'{POKEAPI}/{caminho}', timeout=15)
        if response.status_code == 404:
            raise ApiError('Pokémon não encontrado.', 404)
        response.raise_for_status()
        return response.json()
    except requests.Timeout as error:
        raise ApiError('A PokéAPI demorou para responder.', 504) from error
    except (requests.RequestException, ValueError) as error:
        raise ApiError('Não foi possível consultar a PokéAPI.', 502) from error


def converter(dados):
    sprites = dados.get('sprites') or {}
    artwork = ((sprites.get('other') or {}).get('official-artwork') or {})
    tipos = [item['type']['name'] for item in dados['types']]
    return {
        'id': dados['id'],
        'nome': dados['name'],
        'imagem': artwork.get('front_default') or sprites.get('front_default'),
        'tipo': tipos[0] if tipos else '',
        'tipos': tipos,
        # Mantém as unidades da PokéAPI. O model Flutter converte para m e kg.
        'altura': dados['height'],
        'peso': dados['weight'],
        'experiencia': dados.get('base_experience') or 0,
        'habilidades': [item['ability']['name'] for item in dados['abilities']],
        'atributos': {item['stat']['name']: item['base_stat'] for item in dados['stats']},
    }


def obter_pokemon(identificador):
    return converter(consultar(f'pokemon/{identificador}'))


@app.get('/pokemons')
def listar():
    try:
        limit = int(request.args.get('limit', 20))
        offset = int(request.args.get('offset', 0))
    except ValueError as error:
        raise ApiError('limit e offset devem ser números inteiros.', 400) from error
    if not 1 <= limit <= 50 or offset < 0:
        raise ApiError('Use limit entre 1 e 50 e offset maior ou igual a zero.', 400)
    pagina = consultar(f'pokemon?limit={limit}&offset={offset}')
    nomes = [item['name'] for item in pagina['results']]
    # Requisições em paralelo, com cache, para não buscar 20 detalhes em sequência.
    with ThreadPoolExecutor(max_workers=8) as pool:
        pokemons = list(pool.map(obter_pokemon, nomes))
    return jsonify({'pokemons': pokemons, 'total': pagina['count']})


@app.get('/pokemons/nome/<nome>')
def buscar_nome(nome):
    nome = nome.strip().lower()
    if not re.fullmatch(r'[a-z0-9-]+', nome):
        raise ApiError('Informe um nome válido.', 400)
    return jsonify(obter_pokemon(nome))


@app.get('/pokemons/aleatorio')
def aleatorio():
    # Sorteia qualquer espécie listada, inclusive IDs não sequenciais de formas.
    lista = consultar('pokemon?limit=100000&offset=0')['results']
    if not lista:
        raise ApiError('Nenhum Pokémon disponível para sorteio.', 502)
    return jsonify(obter_pokemon(random.choice(lista)['name']))


@app.get('/pokemons/<int:pokemon_id>')
def buscar_id(pokemon_id):
    if pokemon_id < 1:
        raise ApiError('Pokémon não encontrado.', 404)
    return jsonify(obter_pokemon(pokemon_id))


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
