import 'package:flutter/material.dart';
import 'package:proyecto_final_pokedex/screens/pokemon_detail_screen.dart';
import 'services/pokemon_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokedex',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PokemonService _pokemonService = PokemonService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _pokemonList = [];
  List<dynamic> _filteredPokemonList = [];
  String _orderBy = 'id';
  String _orderDirection = 'asc';
  int _offset = 0;
  bool _isLoadingMore = false;
  String? _selectedGeneration;
  String? _selectedType;
  List<String> _generationOptions = [];
  List<String> _typeOptions = [];

  @override
  void initState() {
    super.initState();
    _fetchPokemonList();
    _fetchGenerationOptions();
    _fetchTypeOptions();
    _searchController.addListener(_filterPokemonList);
  }

  Future<void> _fetchGenerationOptions() async {
    final generations = await _pokemonService.fetchGenerations();
    setState(() {
      _generationOptions = ['-Ninguno-'] + generations;
    });
  }

  Future<void> _fetchTypeOptions() async {
    final types = await _pokemonService.fetchTypes();
    setState(() {
      _typeOptions = ['-Ninguno-'] + types;
    });
  }

  Future<void> _fetchPokemonList({bool loadMore = false}) async {
    if (loadMore) {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final newPokemonList = await _pokemonService.fetchPokemonList(
        orderBy: _orderBy,
        orderDirection: _orderDirection,
        offset: _offset,
        generation: _selectedGeneration != '-Ninguno-' ? _selectedGeneration : null,
        type: _selectedType != '-Ninguno-' ? _selectedType : null,
      );

      setState(() {
        if (loadMore) {
          _pokemonList.addAll(newPokemonList);
        } else {
          _pokemonList = newPokemonList;
        }
        _filteredPokemonList = _pokemonList;
        _offset += newPokemonList.length;
      });
    } catch (error) {
      print("Error fetching Pokémon list: $error");
    }

    if (loadMore) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _toggleOrderAlphabetical() {
    setState(() {
      _orderBy = 'name';
      _orderDirection = _orderDirection == 'asc' ? 'desc' : 'asc';
      _offset = 0;
      _pokemonList.clear();
      _fetchPokemonList();
    });
  }

  void _toggleOrderById() {
    setState(() {
      _orderBy = 'id';
      _orderDirection = _orderDirection == 'asc' ? 'desc' : 'asc';
      _offset = 0;
      _pokemonList.clear();
      _fetchPokemonList();
    });
  }

  void _loadMorePokemon() {
    _fetchPokemonList(loadMore: true);
  }

  void _filterPokemonList() async {
    final query = _searchController.text.toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _filteredPokemonList = _pokemonList;
      });
      return;
    }

    try {
      final searchResults = await _pokemonService.searchPokemonByName(query);
      setState(() {
        _filteredPokemonList = searchResults;
      });
    } catch (error) {
      print("Error searching Pokémon: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar Pokémon',
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_orderBy == 'name' && _orderDirection == 'asc'
                ? Icons.sort_by_alpha
                : Icons.sort_by_alpha_outlined),
            tooltip: "Ordenar Alfabéticamente (${_orderDirection == 'asc' ? 'Ascendente' : 'Descendente'})",
            onPressed: _toggleOrderAlphabetical,
          ),
          IconButton(
            icon: Icon(_orderBy == 'id' && _orderDirection == 'asc'
                ? Icons.format_list_numbered
                : Icons.format_list_numbered_outlined),
            tooltip: "Ordenar por ID (${_orderDirection == 'asc' ? 'Ascendente' : 'Descendente'})",
            onPressed: _toggleOrderById,
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<String>(
                hint: Text("Generación"),
                value: _selectedGeneration,
                items: _generationOptions.map((gen) {
                  return DropdownMenuItem<String>(
                    value: gen,
                    child: Text(gen),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGeneration = value;
                    _offset = 0;
                    _pokemonList.clear();
                    _fetchPokemonList();
                  });
                },
              ),
              SizedBox(width: 20),
              DropdownButton<String>(
                hint: Text("Tipo"),
                value: _selectedType,
                items: _typeOptions.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                    _offset = 0;
                    _pokemonList.clear();
                    _fetchPokemonList();
                  });
                },
              ),
            ],
          ),
          Expanded(
            child: _filteredPokemonList.isEmpty
                ? Center(child: Text('No se encontraron Pokémon'))
                : ListView.builder(
              itemCount: _filteredPokemonList.length + 1,
              itemBuilder: (context, index) {
                if (index == _filteredPokemonList.length) {
                  return _isLoadingMore
                      ? Center(child: CircularProgressIndicator())
                      : TextButton(
                    onPressed: _loadMorePokemon,
                    child: Text("Cargar más"),
                  );
                }
                final pokemon = _filteredPokemonList[index];
                final name = pokemon['name'] ?? 'Desconocido';
                final types = pokemon['pokemon_v2_pokemontypes'] != null
                    ? pokemon['pokemon_v2_pokemontypes']
                    .map((type) => type['pokemon_v2_type']?['name'] ?? 'Desconocido')
                    .join(', ')
                    : 'Desconocido';
                final spriteUrl = pokemon['pokemon_v2_pokemonsprites'] != null &&
                    pokemon['pokemon_v2_pokemonsprites'].isNotEmpty &&
                    pokemon['pokemon_v2_pokemonsprites'][0]['sprites'] != null
                    ? pokemon['pokemon_v2_pokemonsprites'][0]['sprites']['front_default']
                    : null;

                return ListTile(
                  leading: spriteUrl != null
                      ? Image.network(
                    spriteUrl,
                    width: 50,
                    height: 50,
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
                  )
                      : Icon(Icons.error),
                  title: Text(name),
                  subtitle: Text('Types: $types'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PokemonDetailScreen(
                          pokemonId: pokemon['id'] ?? 0,
                          pokemonName: name,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
