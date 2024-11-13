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

  void _navigateToPokemon(int newPokemonId, String newPokemonName) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PokemonDetailScreen(
          pokemonId: newPokemonId,
          pokemonName: newPokemonName,
        ),
      ),
    );
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

    final imageUrl = _pokemonDetails['pokemon_v2_pokemonsprites']?[0]?['sprites']?['front_default'] ?? null;
    final types = _pokemonDetails['pokemon_v2_pokemontypes']?.map((type) => type['pokemon_v2_type']['name']).join(', ') ?? 'N/A';

    final stats = _pokemonDetails['pokemon_v2_pokemonstats']?.map((stat) {
      return {
        'name': stat['pokemon_v2_stat']['name'],
        'value': stat['base_stat']
      };
    }).toList() ?? [];

    final abilities = _pokemonDetails['pokemon_v2_pokemonabilities']?.map((ability) => ability['pokemon_v2_ability']['name']).join(', ') ?? 'N/A';

    final evolutions = _pokemonDetails['evolutions'] ?? []; // Suponiendo que la API devuelva evoluciones en una clave 'evolutions'

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
              if (imageUrl != null)
                Center(
                  child: Image.network(imageUrl, width: 150, height: 150),
                )
              else
                Center(child: Icon(Icons.error, size: 150)),
              SizedBox(height: 16),
              Text("Tipos: $types", style: TextStyle(fontSize: 18)),
              SizedBox(height: 16),
              Text("Estadísticas:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              GridView.builder(
                shrinkWrap: true,
                itemCount: stats.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(stats[index]['name']),
                      subtitle: Text(stats[index]['value'].toString()),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              Text("Habilidades: $abilities", style: TextStyle(fontSize: 18)),
              SizedBox(height: 16),
              Text("Evoluciones:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (evolutions.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: evolutions.map<Widget>((evolution) {
                    final evolutionImage = evolution['sprites']['front_default'];
                    return Column(
                      children: [
                        Image.network(evolutionImage, width: 80, height: 80),
                        Text(evolution['name']),
                      ],
                    );
                  }).toList(),
                )
              else
                Text("N/A", style: TextStyle(fontSize: 16)),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.pokemonId > 1)
                    ElevatedButton(
                      onPressed: () => _navigateToPokemon(widget.pokemonId - 1, "Anterior Pokemon"),
                      child: Text("Anterior"),
                    ),
                  ElevatedButton(
                    onPressed: () => _navigateToPokemon(widget.pokemonId + 1, "Siguiente Pokemon"),
                    child: Text("Siguiente"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
