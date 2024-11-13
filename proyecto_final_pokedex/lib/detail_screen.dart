import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/pokemon_service.dart';

class PokemonDetailScreen extends StatefulWidget {
  final int pokemonId;
  final String pokemonName;

  const PokemonDetailScreen({Key? key, required this.pokemonId, required this.pokemonName})
      : super(key: key);

  @override
  _PokemonDetailScreenState createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  final PokemonService _pokemonService = PokemonService();
  Map<String, dynamic> _pokemonDetails = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPokemonDetails();
  }

  Future<void> _fetchPokemonDetails() async {
    try {
      final details = await _pokemonService.fetchPokemonDetails(widget.pokemonId);
      setState(() {
        _pokemonDetails = details;
        _isLoading = false;
      });
    } catch (error) {
      print("Error fetching Pokémon details: $error");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.pokemonName),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Acceder a los datos de _pokemonDetails para construir la interfaz
    final imageUrl = jsonDecode(_pokemonDetails['pokemon_v2_pokemonsprites'][0]['sprites'])['front_default'];
    final types = _pokemonDetails['pokemon_v2_pokemontypes']
        .map((type) => type['pokemon_v2_type']['name'])
        .join(', ');
    final stats = _pokemonDetails['pokemon_v2_pokemonstats']
        .map((stat) => "${stat['pokemon_v2_stat']['name']}: ${stat['base_stat']}")
        .join(', ');
    final abilities = _pokemonDetails['pokemon_v2_pokemonabilities']
        .map((ability) => ability['pokemon_v2_ability']['name'])
        .join(', ');
    final moves = _pokemonDetails['pokemon_v2_pokemonmoves']
        .map((move) => move['pokemon_v2_move']['name'])
        .take(10) // Limitar a 10 movimientos para no sobrecargar la interfaz
        .join(', ');
    final evolutions = _pokemonDetails['pokemon_v2_pokemonevolutions']
        .map((evolution) => evolution['pokemon_v2_pokemonspecies']['name'])
        .join(', ');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pokemonName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.network(imageUrl, width: 150, height: 150),
              ),
              SizedBox(height: 16),
              Text("Tipos: $types", style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              Text("Estadísticas:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(stats, style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              Text("Habilidades:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(abilities, style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              Text("Movimientos (10 primeros):", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(moves, style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              Text("Evoluciones:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(evolutions, style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
