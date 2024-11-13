import 'dart:convert';

import 'package:graphql_flutter/graphql_flutter.dart';

class PokemonService {
  final String apiUrl = 'https://beta.pokeapi.co/graphql/v1beta';
  late GraphQLClient client;

  PokemonService() {
    final HttpLink httpLink = HttpLink(apiUrl);
    client = GraphQLClient(
      cache: GraphQLCache(store: InMemoryStore()),
      link: httpLink,
    );
  }

  Future<Map<String, dynamic>> fetchPokemonDetails(int pokemonId) async {
    const String query = r'''
    query GetPokemonDetails($id: Int!) {
      pokemon_v2_pokemon_by_pk(id: $id) {
        id
        name
        height
        weight
        base_experience
        pokemon_v2_pokemontypes {
          pokemon_v2_type {
            name
          }
        }
        pokemon_v2_pokemonstats {
          base_stat
          pokemon_v2_stat {
            name
          }
        }
        pokemon_v2_pokemonabilities {
          pokemon_v2_ability {
            name
          }
        }
        pokemon_v2_pokemonmoves {
          pokemon_v2_move {
            name
          }
        }
        pokemon_v2_pokemonsprites {
          sprites
        }
      }
    }
  ''';

    final QueryOptions options = QueryOptions(
      document: gql(query),
      variables: {'id': pokemonId},
    );
    final result = await client.query(options);

    if (result.hasException) {
      print("Error en fetchPokemonDetails: ${result.exception.toString()}");
      throw Exception(result.exception.toString());
    }

    return result.data?['pokemon_v2_pokemon_by_pk'] ?? {};
  }

  Future<List<dynamic>> searchPokemonByName(String name) async {
    final String query = '''
    query SearchPokemon(\$name: String!) {
      pokemon_v2_pokemon(
        where: {name: {_ilike: \$name}, is_default: {_eq: true}}
      ) {
        id
        name
        pokemon_v2_pokemontypes {
          pokemon_v2_type {
            name
          }
        }
        pokemon_v2_pokemonsprites {
          sprites
        }
      }
    }
  ''';

    final QueryOptions options = QueryOptions(
      document: gql(query),
      variables: {'name': '%$name%'},
    );

    final result = await client.query(options);

    if (result.hasException) {
      print("Error en searchPokemonByName: ${result.exception.toString()}");
      throw Exception(result.exception.toString());
    }

    return result.data?['pokemon_v2_pokemon'] ?? [];
  }

  Future<List<dynamic>> fetchPokemonList({
    String orderBy = 'name',
    String orderDirection = 'asc',
    int offset = 0,
    int limit = 10,
    String? generation,
    String? type,
  }) async {
    final String query = '''
  query GetPokemonList(\$offset: Int, \$limit: Int, ${generation != null ? '\$generationName: String,' : ''} ${type != null ? '\$typeName: String,' : ''}) {
    pokemon_v2_pokemon(
      where: {
        is_default: {_eq: true}
        ${generation != null ? 'pokemon_v2_pokemonspecies: {pokemon_v2_generation: {name: {_eq: \$generationName}}},' : ''}
        ${type != null ? 'pokemon_v2_pokemontypes: {pokemon_v2_type: {name: {_eq: \$typeName}}},' : ''}
      },
      order_by: {${orderBy}: ${orderDirection}},
      offset: \$offset,
      limit: \$limit
    ) {
      id
      name
      pokemon_v2_pokemontypes {
        pokemon_v2_type {
          name
        }
      }
      pokemon_v2_pokemonsprites {
        sprites
      }
    }
  }
  ''';

    final QueryOptions options = QueryOptions(
      document: gql(query),
      variables: {
        'offset': offset,
        'limit': limit,
        if (generation != null) 'generationName': generation,
        if (type != null) 'typeName': type,
      },
    );

    final result = await client.query(options);

    if (result.hasException) {
      print("Error en fetchPokemonList con orden: ${result.exception.toString()}");
      throw Exception(result.exception.toString());
    }

    return result.data?['pokemon_v2_pokemon'] ?? [];
  }

  Future<List<String>> fetchGenerations() async {
    const String query = '''
    query {
      pokemon_v2_generation {
        name
      }
    }
    ''';

    final result = await client.query(QueryOptions(document: gql(query)));

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return (result.data?['pokemon_v2_generation'] as List)
        .map((gen) => gen['name'] as String)
        .toList();
  }

  Future<List<String>> fetchTypes() async {
    const String query = '''
    query {
      pokemon_v2_type {
        name
      }
    }
    ''';

    final result = await client.query(QueryOptions(document: gql(query)));

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return (result.data?['pokemon_v2_type'] as List)
        .map((type) => type['name'] as String)
        .toList();
  }

}
