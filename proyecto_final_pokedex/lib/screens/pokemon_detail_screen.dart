import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/pokemon_service.dart';
import '../widgets/stat_card.dart';

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
  List<Color> _palette = [];
  bool _isLoading = true;
  String? _selectedGeneration;

  @override
  void initState() {
    super.initState();
    final flavorTextEntries = _pokemonDetails['flavor_text_entries'] as List<dynamic>?;
    final generations = flavorTextEntries
        ?.where((entry) => entry['language']['name'] == 'en')
        .map((entry) => entry['version']['name'] as String)
        .toSet()
        .toList() ?? [];

    _selectedGeneration ??= generations.isNotEmpty ? generations.last : null;

    _fetchPokemonDetails();
    _fetchPokemonPalette();
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

  Future<void> _fetchPokemonPalette() async {
    try {
      final response = await http.get(Uri.parse('https://pokemonpalette.com/api/palette/${widget.pokemonName.toLowerCase()}'));
      if (response.statusCode == 200) {
        final List<dynamic> colorsHex = json.decode(response.body);
        setState(() {
          _palette = colorsHex.map((hex) => Color(int.parse(hex.replaceFirst('#', '0xff')))).toList();
        });
      }
    } catch (error) {
      print("Error fetching palette: $error");
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

    // Datos principales
    final flavorTextEntries = _pokemonDetails['flavor_text_entries'] as List<dynamic>?;
    final generations = flavorTextEntries
        ?.where((entry) => entry['language']['name'] == 'en') // Solo en inglés
        .map((entry) => entry['version']['name'] as String)
        .toSet() // Evitar duplicados
        .toList() ??
        [];


    final imageUrl = _pokemonDetails['sprites']?['front_default'] ?? null;
    final stats = (_pokemonDetails['stats'] as List<dynamic>?)
        ?.map((stat) => {
      'name': stat['stat']['name'] as String,
      'value': stat['base_stat'] as int,
    })
        .toList() ??
        [];
    final types = (_pokemonDetails['types'] as List<dynamic>?)
        ?.map((type) => type['type']['name'] as String)
        .toList() ??
        [];
    final moves = (_pokemonDetails['moves'] as List<dynamic>?)
        ?.where((move) =>
    move['version_group_details']?.any((detail) =>
    detail['move_learn_method']['name'] == 'level-up') ??
        false) // Solo movimientos aprendidos por nivel
        ?.map((move) => move['move']['name'] as String)
        ?.toList() ??
        [];
    final abilities = (_pokemonDetails['abilities'] as List<dynamic>?)
        ?.map((ability) => ability['ability']['name'] as String)
        ?.toList() ??
        [];



    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pokemonName),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del Pokémon
              Center(
                child: Image.network(
                  imageUrl ?? '',
                  width: 150,
                  height: 150,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.error, size: 150),
                ),
              ),

              SizedBox(height: 16),

              // SECCIÓN: Descripción
              Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título para Generaciones
                      Text(
                        "Generaciones:",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),

                      // Botones dinámicos de generaciones
                      Wrap(
                        spacing: 8,
                        children: generations.map((generation) {
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: _selectedGeneration == generation ? Colors.blue : Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedGeneration = generation;
                              });
                            },
                            child: Text(
                              generation,
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                      ),

                      // Espaciado entre botones y descripción
                      SizedBox(height: 16),

                      // Texto de la descripción basado en la generación seleccionada
                      Text(
                        flavorText,
                        style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // SECCIÓN: Tipos
              Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Tipos:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      buildTypeTags(types),
                    ],
                  ),
                ),
              ),

              Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Habilidades:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: abilities.map((ability) {
                          return Chip(
                            label: Text(ability, style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.purple,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // SECCIÓN: Estadísticas Base
              Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Estadísticas Base", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      buildStatsChart(stats),
                    ],
                  ),
                ),
              ),

              // SECCIÓN: Movimientos
              Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Movimientos:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      buildMovesList(moves),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTypeTags(List<String> types) {
    final typeColors = {
      'grass': Colors.green,
      'poison': Colors.purple,
      'fire': Colors.red,
      'water': Colors.blue,
      // Agrega más colores aquí...
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: types.map((type) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: typeColors[type] ?? Colors.grey,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            type,
            style: TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
    );
  }

  Widget buildStatsChart(List<Map<String, dynamic>> stats) {
    final statColors = {
      'hp': Colors.red,
      'attack': Colors.orange,
      'defense': Colors.blue,
      'special-attack': Colors.purple,
      'special-defense': Colors.green,
      'speed': Colors.yellow,
    };

    return Column(
      children: stats.map((stat) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(stat['name'], style: TextStyle(fontSize: 16)),
              Expanded(
                child: LinearProgressIndicator(
                  value: stat['value'] / 100,
                  backgroundColor: Colors.grey[300],
                  color: statColors[stat['name']] ?? Colors.grey,
                ),
              ),
              SizedBox(width: 10),
              Text(stat['value'].toString(), style: TextStyle(fontSize: 16)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget buildMovesList(List<String> moves) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: moves.map((move) {
        return Chip(
          label: Text(move, style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blueAccent,
        );
      }).toList(),
    );
  }


}
