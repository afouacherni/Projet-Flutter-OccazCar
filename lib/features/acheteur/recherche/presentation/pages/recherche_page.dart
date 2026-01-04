import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../data/models/annonce_model.dart';
import '../providers/recherche_provider.dart';
import '../providers/filtres_provider.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/vehicle_list_item.dart';
import '../../domain/usecases/search_vehicles.dart';
import 'filtres_avances_page.dart';
import '../../../favoris/presentation/providers/favoris_provider.dart';
import '../../../alertes/presentation/pages/creer_alerte_page.dart';

class RecherchePage extends ConsumerStatefulWidget {
  const RecherchePage({super.key});

  @override
  ConsumerState<RecherchePage> createState() => _RecherchePageState();
}

class _RecherchePageState extends ConsumerState<RecherchePage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    // Lance une recherche initiale au chargement de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rechercheProvider.notifier).search();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rechercheState = ref.watch(rechercheProvider);
    final filters = ref.watch(filtresProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechercher'),
        elevation: 0,
        actions: [
          // Bouton pour changer le mode d'affichage
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView ? 'Vue liste' : 'Vue grille',
          ),
        ],
      ),

      body: Column(
        children: [
          _buildSearchSection(filters),
          _buildInfoBar(rechercheState, filters),
          Expanded(child: _buildResultsList(rechercheState)),
        ],
      ),
    );
  }

  Widget _buildSearchSection(SearchFilters filters) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SearchBarWidget(
            controller: _searchController,
            hintText: 'Marque, mod\u00e8le, mot-cl\u00e9...',
            hasActiveFilters: filters.hasActiveFilters,
            onChanged: (value) {
              ref.read(filtresProvider.notifier).updateQuery(value);
            },
            onSubmitted: (value) {
              ref.read(filtresProvider.notifier).updateQuery(value);
              ref.read(rechercheProvider.notifier).search();
            },
            onFilterTap: () => _openFiltersPage(),
            onClear: () {
              ref.read(filtresProvider.notifier).updateQuery(null);
              ref.read(rechercheProvider.notifier).search();
            },
          ),

          if (filters.hasActiveFilters)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: FilterChipsRow(
                filters: _getActiveFilterChips(filters),
                onRemoveFilter: (key) => _removeFilter(key),
                onClearAll: () {
                  ref.read(filtresProvider.notifier).clearAllFilters();
                  ref.read(rechercheProvider.notifier).search();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoBar(RechercheState state, SearchFilters filters) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Text(
            '${state.totalCount} r\u00e9sultat${state.totalCount > 1 ? 's' : ''}',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          if (filters.hasActiveFilters) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _createAlertFromFilters(filters),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      size: 14,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Créer alerte',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const Spacer(),
          _buildSortDropdown(filters),
        ],
      ),
    );
  }

  void _createAlertFromFilters(SearchFilters filters) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreerAlertePage()),
    );
  }

  Widget _buildSortDropdown(SearchFilters filters) {
    return PopupMenuButton<SortOption>(
      initialValue: filters.sortBy,
      onSelected: (SortOption option) {
        // Met à jour le tri dans le provider
        ref.read(filtresProvider.notifier).updateSortBy(option);
        // Relance la recherche avec le nouveau tri (passé directement pour éviter le délai)
        ref.read(rechercheProvider.notifier).search(sortOverride: option);
      },
      itemBuilder:
          (context) =>
              SortOption.values.map((option) {
                return PopupMenuItem(
                  value: option,
                  child: Row(
                    children: [
                      Icon(
                        _getSortIcon(option),
                        size: 18,
                        color:
                            filters.sortBy == option
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        option.label,
                        style: TextStyle(
                          color:
                              filters.sortBy == option
                                  ? Theme.of(context).primaryColor
                                  : Colors.black87,
                          fontWeight:
                              filters.sortBy == option
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getSortIcon(filters.sortBy),
            size: 18,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            filters.sortBy.label,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 13,
            ),
          ),
          const Icon(Icons.arrow_drop_down, size: 20),
        ],
      ),
    );
  }

  Widget _buildResultsList(RechercheState state) {
    if (state.isLoading) {
      return _buildLoadingState();
    }

    if (state.error != null) {
      return _buildErrorState(state.error!);
    }

    if (state.results.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(rechercheProvider.notifier).refresh(),
      child: _isGridView ? _buildGridView(state) : _buildListView(state),
    );
  }

  Widget _buildListView(RechercheState state) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: state.results.length,
      itemBuilder: (context, index) {
        final annonce = state.results[index];
        final isFavorite = ref.watch(isFavoriteProvider(annonce.vehicle.id));
        return VehicleListItem(
          annonce: annonce,
          isCompact: false,
          onTap: () => _navigateToDetails(annonce.id),
          onFavoriteTap: () => _toggleFavorite(annonce),
          isFavorite: isFavorite,
        );
      },
    );
  }

  Widget _buildGridView(RechercheState state) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: state.results.length,
      itemBuilder: (context, index) {
        final annonce = state.results[index];
        final isFavorite = ref.watch(isFavoriteProvider(annonce.vehicle.id));
        return VehicleListItem(
          annonce: annonce,
          isCompact: true,
          onTap: () => _navigateToDetails(annonce.id),
          onFavoriteTap: () => _toggleFavorite(annonce),
          isFavorite: isFavorite,
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return const VehicleListItemSkeleton(isCompact: false);
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Oups ! Une erreur est survenue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(rechercheProvider.notifier).search(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucun véhicule trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez de modifier vos critères de recherche',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(filtresProvider.notifier).clearAllFilters();
                _searchController.clear();
                ref.read(rechercheProvider.notifier).search();
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Effacer les filtres'),
            ),
          ],
        ),
      ),
    );
  }

  List<FilterChipData> _getActiveFilterChips(SearchFilters filters) {
    final chips = <FilterChipData>[];

    if (filters.make != null) {
      chips.add(
        FilterChipData(
          key: 'make',
          label: 'Marque',
          value: filters.make,
          icon: Icons.directions_car,
        ),
      );
    }

    if (filters.minPrice != null || filters.maxPrice != null) {
      String value = '';
      if (filters.minPrice != null && filters.maxPrice != null) {
        value = '${filters.minPrice!.toInt()}€ - ${filters.maxPrice!.toInt()}€';
      } else if (filters.minPrice != null) {
        value = 'Min ${filters.minPrice!.toInt()}€';
      } else {
        value = 'Max ${filters.maxPrice!.toInt()}€';
      }
      chips.add(
        FilterChipData(
          key: 'price',
          label: 'Prix',
          value: value,
          icon: Icons.euro,
        ),
      );
    }

    if (filters.minYear != null || filters.maxYear != null) {
      String value = '';
      if (filters.minYear != null && filters.maxYear != null) {
        value = '${filters.minYear} - ${filters.maxYear}';
      } else if (filters.minYear != null) {
        value = 'Dès ${filters.minYear}';
      } else {
        value = 'Jusqu\'à ${filters.maxYear}';
      }
      chips.add(
        FilterChipData(
          key: 'year',
          label: 'Année',
          value: value,
          icon: Icons.calendar_today,
        ),
      );
    }

    if (filters.maxMileage != null) {
      chips.add(
        FilterChipData(
          key: 'mileage',
          label: 'Kilométrage',
          value: '< ${filters.maxMileage} km',
          icon: Icons.speed,
        ),
      );
    }

    return chips;
  }

  /// Supprime un filtre spécifique
  void _removeFilter(String key) {
    switch (key) {
      case 'make':
        ref.read(filtresProvider.notifier).clearFilter(FilterType.make);
        break;
      case 'price':
        ref.read(filtresProvider.notifier).clearFilter(FilterType.price);
        break;
      case 'year':
        ref.read(filtresProvider.notifier).clearFilter(FilterType.year);
        break;
      case 'mileage':
        ref.read(filtresProvider.notifier).clearFilter(FilterType.mileage);
        break;
    }
    ref.read(rechercheProvider.notifier).search();
  }

  /// Ouvre la page des filtres avancés
  void _openFiltersPage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const FiltresAvancesPage()),
    );

    // Si des filtres ont été appliqués, relance la recherche
    if (result == true) {
      ref.read(rechercheProvider.notifier).search();
    }
  }

  void _navigateToDetails(String annonceId) {
    Navigator.pushNamed(context, '/details/$annonceId');
  }

  void _toggleFavorite(AnnonceModel annonce) async {
    final wasFavorite = ref
        .read(favorisProvider)
        .isFavorite(annonce.vehicle.id);

    final success = await ref
        .read(favorisProvider.notifier)
        .toggleFavorite(annonce);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (wasFavorite ? 'Retiré des favoris' : 'Ajouté aux favoris')
                : 'Erreur lors de la mise à jour',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: success ? null : Colors.red,
        ),
      );
    }
  }

  /// Retourne l'icône appropriée pour une option de tri
  IconData _getSortIcon(SortOption option) {
    switch (option) {
      case SortOption.dateDesc:
      case SortOption.dateAsc:
        return Icons.calendar_today;
      case SortOption.priceAsc:
        return Icons.arrow_upward;
      case SortOption.priceDesc:
        return Icons.arrow_downward;
      case SortOption.mileageAsc:
        return Icons.speed;
      case SortOption.yearDesc:
        return Icons.date_range;
    }
  }
}
