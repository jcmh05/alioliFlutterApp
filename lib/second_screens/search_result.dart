import 'package:alioli/components/components.dart';
import 'package:alioli/models/models.dart';
import 'package:alioli/second_screens/filter_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';

class SearchResults extends StatefulWidget {
  final String title;
  final String? recipeName;
  final List<String>? ingredientsId;
  final String? mealtime;
  final List<String>? tags;
  final String? region;
  final bool? hasVideo;
  final int? minMinutes;
  final int? maxMinutes;

  const SearchResults({
    Key? key,
    required this.title,
    this.recipeName,
    this.ingredientsId,
    this.mealtime,
    this.tags,
    this.region,
    this.hasVideo,
    this.minMinutes,
    this.maxMinutes,
  }) : super(key: key);

  @override
  _SearchResultsState createState() => _SearchResultsState(ingredientsId: ingredientsId);
}

class _SearchResultsState extends State<SearchResults> {
  final Log = logger(SearchResults);
  List<String>? ingredientsId;

  // Constructor que recibe los ingredientes y los limita a 30
  _SearchResultsState({this.ingredientsId}) {
    if (ingredientsId != null && ingredientsId!.length > 30) {
      ingredientsId = ingredientsId!.sublist(0, 30);
    }
  }

  // Variables para el control de recetas y scroll
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 50;
  List<DocumentSnapshot> _recipes = [];
  bool _hasMoreRecipes = true;
  bool _isLoading = false;

  // Variables de estado para los filtros
  String _orderBy = 'likesCount';
  bool _ascending = false;
  String _sortModeText = 'Mejor valoración';
  bool _isVegetarian = false;
  bool _isVegan = false;
  bool _hasVideo = false;
  int? _minMinutes;
  int? _maxMinutes;

  @override
  void initState() {
    super.initState();
    _hasVideo = widget.hasVideo ?? false;
    _minMinutes = widget.minMinutes;
    _maxMinutes = widget.maxMinutes;
    _scrollController.addListener(_onScroll);
    _loadRecipes();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Cargar solo si se alcanza el final y no se está ya cargando más
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading) {
      _loadRecipes();
    }
  }

  Future<void> _loadRecipes() async {
    if (!_hasMoreRecipes || _isLoading) return; // No carga si no hay más recetas o si ya está cargando

    setState(() {
      _isLoading = true;
    });

    Query query = FirebaseFirestore.instance.collection('recipes').orderBy(
        _orderBy, descending: !_ascending).limit(_pageSize);

    if (widget.recipeName != null) {
      String recipeNameSearchTerm = widget.recipeName!.toLowerCase();
      List<String> recipeNameSearchTerms = extractKeywords(recipeNameSearchTerm);

      for (String term in recipeNameSearchTerms) {
        var tempQuery = query.where('keywords', arrayContains: term);

        // Ejecutar esta consulta y verificar si devuelve resultados
        var results = await tempQuery.get();
        if (results.size > 0) {
          query = tempQuery;
          break;
        }
      }
    }

    if (ingredientsId != null && ingredientsId!.isNotEmpty) {
      query = query.where('ingredients', arrayContainsAny: ingredientsId!);
    }
    if (widget.mealtime != null) {
      query = query.where('mealtime', arrayContains: widget.mealtime);
    }
    if (widget.tags != null && widget.tags!.isNotEmpty) {
      query = query.where('tags', arrayContainsAny: widget.tags!);
    }
    if (widget.region != null) {
      query = query.where('region', isEqualTo: widget.region);
    }

    if (_isVegetarian) {
      query = query.where('isVegetarian', isEqualTo: true);
    }
    if (_isVegan) {
      query = query.where('isVegan', isEqualTo: true);
    }

    if (_recipes.isNotEmpty) {
      query = query.startAfterDocument(_recipes.last);
    }

    var snapshot = await query.get();

    // Crear una lista para almacenar las recetas con el número de coincidencias
    List<Map<String, dynamic>> recipesWithMatches = [];

    List<String>? recipeNameSearchTerms;
    if (widget.recipeName != null) {
      String recipeNameSearchTerm = widget.recipeName!.toLowerCase();
      recipeNameSearchTerms = extractKeywords(recipeNameSearchTerm);
    }

    for (var doc in snapshot.docs) {
      int matches = 0;
      if (ingredientsId != null) {
        for (var ingredient in doc['ingredients']) {
          if (ingredientsId!.contains(ingredient)) {
            matches++;
          }
        }
      } else if (recipeNameSearchTerms != null) {
        for (var keyword in doc['keywords']) {
          if (recipeNameSearchTerms!.contains(keyword)) {
            matches++;
          }
        }
      }
      recipesWithMatches.add({
        'doc': doc,
        'matches': matches,
      });
    }

    // Ordenar por coincidencias y luego por el parámetro de ordenación seleccionado
    recipesWithMatches.sort((a, b) {
      int compare = b['matches'].compareTo(a['matches']);
      if (compare != 0) {
        return compare;
      } else {
        return _ascending
            ? a['doc'][_orderBy].compareTo(b['doc'][_orderBy])
            : b['doc'][_orderBy].compareTo(a['doc'][_orderBy]);
      }
    });

    // Extraer solo los documentos de Firestore para usar en la interfaz de usuario
    List<DocumentSnapshot<Object?>> orderedRecipes = recipesWithMatches
        .map((item) => item['doc'] as DocumentSnapshot<Object?>)
        .toList();
    if (orderedRecipes.length < _pageSize) {
      _hasMoreRecipes = false; // No hay más recetas para cargar
    }

    setState(() {
      _recipes.addAll(orderedRecipes);
      _isLoading = false; // Desactiva el indicador de carga
    });
  }

  Widget buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Chips para ordenar y filtrar
          PopupMenuButton<String>(
            onSelected: (String value) {
              updateQuery(value);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'createdAt',
                child: Text('Más recientes'),
              ),
              const PopupMenuItem<String>(
                value: 'likesCount',
                child: Text('Mejor valoración'),
              ),
              const PopupMenuItem<String>(
                value: 'minutes',
                child: Text('Más rápidas'),
              ),
            ],
            child: Chip(
              label: Text(_sortModeText),
              avatar: Icon(Icons.sort),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
          ),
          SizedBox(width: 8),
          // Chips para filtros vegetarianos y veganos
          ChoiceChip(
            label: Text('Vegetariana'),
            avatar: Icon(AppTheme.categoryIcons['vegetarian']),
            selected: _isVegetarian,
            onSelected: (bool selected) {
              updateFilter('isVegetarian', selected);
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
          ),
          SizedBox(width: 8),
          ChoiceChip(
            label: Text('Vegana'),
            avatar: Icon(AppTheme.categoryIcons['vegan']),
            selected: _isVegan,
            onSelected: (bool selected) {
              updateFilter('isVegan', selected);
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
          ),
        ],
      ),
    );
  }

  void updateFilter(String filterType, bool selected) {
    setState(() {
      switch (filterType) {
        case 'isVegetarian':
          _isVegetarian = selected;
          if (selected) _isVegan = false;
          break;
        case 'isVegan':
          _isVegan = selected;
          if (selected) _isVegetarian = false;
          break;
      }
      _recipes.clear(); // Limpiar la lista de recetas actual
      _hasMoreRecipes = true; // Resetear paginación
      _loadRecipes(); // Recargar recetas con nuevos filtros
    });
  }

  void updateQuery(String orderType) {
    setState(() {
      if (orderType == 'likesCount') {
        _orderBy = 'likesCount'; // Asegúrate de que este campo esté correctamente indexado
        _ascending = false; // Descendente para mejor valoración
        _sortModeText = 'Mejor valoración'; // Actualizar el texto del modo de ordenación
      } else if (orderType == 'createdAt') {
        _orderBy = 'createdAt';
        _ascending = false;
        _sortModeText = 'Más recientes'; // Actualizar el texto del modo de ordenación
      } else if (orderType == 'minutes') {
        _orderBy = 'minutes';
        _ascending = true;
        _sortModeText = 'Más rápidas'; // Actualizar el texto del modo de ordenación
      }
      _recipes.clear();
      _hasMoreRecipes = true;
      _loadRecipes();
    });
  }

  void applyFilters(String orderBy, int? maxMinutes, bool isVegan,
      bool isVegetarian, bool hasVideo) {
    setState(() {
      _orderBy = orderBy;
      _isVegan = isVegan;
      _isVegetarian = isVegetarian;
      _hasVideo = hasVideo;

      if (_orderBy == "minutes") {
        _ascending = true;
      } else {
        _ascending = false;
      }

      _maxMinutes = maxMinutes;

      _recipes.clear();
      _hasMoreRecipes = true;
      _loadRecipes();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Aplicar filtros menores de forma local
    var filteredRecipes =
    _recipes.where((doc) => doc['visible'] != false).toList();

    // Si _hasVideo está activado, filtrar las recetas que no tienen ningún video
    if (_hasVideo) {
      filteredRecipes = filteredRecipes.where((doc) {
        var youtubeUrl = doc['youtubeUrl'];
        var tiktokUrl = doc['tiktokUrl'];
        var instagramUrl = doc['instagramUrl'];
        var otherUrl = doc['otherUrl'];
        return (youtubeUrl != null && youtubeUrl.isNotEmpty) ||
            (tiktokUrl != null && tiktokUrl.isNotEmpty) ||
            (instagramUrl != null && instagramUrl.isNotEmpty) ||
            (otherUrl != null && otherUrl.isNotEmpty);
      }).toList();
    }

    // Si _maxMinutes no es nulo, filtrar las recetas cuyo tiempo de preparación es mayor que _maxMinutes
    if (_maxMinutes != null) {
      filteredRecipes = filteredRecipes.where((doc) {
        var minutes = doc['minutes'];
        return minutes <= _maxMinutes;
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt),
            onPressed: () {
              // Navegar a la pantalla de filtros
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => FiltersScreen(
                        _orderBy,
                        _isVegetarian,
                        _isVegan,
                        _hasVideo,
                        applyFilters,
                        maxMinutes: _maxMinutes,
                      )));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            buildFilterChips(),
            if (filteredRecipes.isEmpty && !_isLoading)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 20.0,
                    ),
                    placeholderIconText(
                        context,
                        MediaQuery.of(context).platformBrightness ==
                            Brightness.dark
                            ? 'assets/noresult2.svg'
                            : 'assets/noresults.svg',
                        'No se han encontrado recetas',
                        'Prueba a cambiar los filtros o buscar otras recetas',
                        0.8),
                  ],
                ),
              ),
            if (filteredRecipes.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: filteredRecipes.length,
                  itemBuilder: (context, index) {
                    return FutureBuilder<Recipe>(
                      future: convertDocToRecipe(filteredRecipes[index]),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.hasData) {
                          return Padding(
                            padding:
                            const EdgeInsets.symmetric(vertical: 10.0),
                            child: RecipeCard(
                              recipe: snapshot.data!,
                              mode: 1,
                              ingredientsSearch: widget.ingredientsId,
                            ),
                          );
                        } else {
                          return Transform.scale(
                            scale: 0.5,
                            child: LoadingIndicator(
                              indicatorType:
                              Indicator.ballClipRotateMultiple,
                              colors:
                              MediaQuery.of(context).platformBrightness ==
                                  Brightness.dark
                                  ? const [Colors.white]
                                  : const [Colors.black],
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            if (_isLoading && _recipes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: LoadingIndicator(
                  indicatorType: Indicator.ballClipRotateMultiple,
                  colors: MediaQuery.of(context).platformBrightness ==
                      Brightness.dark
                      ? const [Colors.white]
                      : const [Colors.black],
                ),
              )
          ],
        ),
      ),
      bottomNavigationBar: const AdBanner(),
    );
  }
}
