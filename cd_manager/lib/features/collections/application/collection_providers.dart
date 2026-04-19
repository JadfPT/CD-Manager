import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_entry.dart';
import '../../../shared/models/item_type.dart';
import '../../../shared/repositories/collection_repository.dart';

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return CollectionRepository();
});

// Listagem de todas as coleções
final collectionsProvider = FutureProvider<List<Collection>>((ref) {
  final repository = ref.watch(collectionRepositoryProvider);
  return repository.listCollections();
});

// Detalhes de uma coleção específica (coleção + itens)
final collectionDetailsProvider = FutureProvider.family<
    ({Collection collection, List<CollectionEntry> entries}),
    int>((ref, collectionId) {
  final repository = ref.watch(collectionRepositoryProvider);
  return repository.getCollectionDetails(collectionId);
});

// Coleções para um item específico (mostrar no detalhe do item)
final itemCollectionsProvider = FutureProvider.family<
    List<({int collectionId, String collectionName, int? position, String? label})>,
    ({int itemId, ItemType itemType})>((ref, params) {
  final repository = ref.watch(collectionRepositoryProvider);
  return repository.getCollectionsForItem(
    itemId: params.itemId,
    itemType: params.itemType,
  );
});

// Actions para coleções
final collectionActionsProvider = Provider<CollectionActions>((ref) {
  return CollectionActions(ref);
});

class CollectionActions {
  const CollectionActions(this._ref);

  final Ref _ref;

  Future<int> createCollection({
    required String name,
    String? description,
  }) async {
    final repository = _ref.read(collectionRepositoryProvider);
    final collectionId = await repository.createCollection(
      name: name,
      description: description,
    );
    _ref.invalidate(collectionsProvider);
    return collectionId;
  }

  Future<void> updateCollection({
    required int collectionId,
    String? name,
    String? description,
  }) async {
    final repository = _ref.read(collectionRepositoryProvider);
    await repository.updateCollection(
      collectionId: collectionId,
      name: name,
      description: description,
    );
    _ref.invalidate(collectionsProvider);
    _ref.invalidate(collectionDetailsProvider(collectionId));
  }

  Future<void> deleteCollection(int collectionId) async {
    final repository = _ref.read(collectionRepositoryProvider);
    await repository.deleteCollection(collectionId);
    _ref.invalidate(collectionsProvider);
  }

  Future<void> addItemToCollection({
    required int collectionId,
    required int itemId,
    required ItemType itemType,
    int? position,
    String? label,
  }) async {
    final repository = _ref.read(collectionRepositoryProvider);
    await repository.addItemToCollection(
      collectionId: collectionId,
      itemId: itemId,
      itemType: itemType,
      position: position,
      label: label,
    );
    _ref.invalidate(collectionsProvider);
    _ref.invalidate(collectionDetailsProvider(collectionId));
    _ref.invalidate(itemCollectionsProvider((itemId: itemId, itemType: itemType)));
  }

  Future<void> removeItemFromCollection({
    required int collectionId,
    required int itemId,
    required ItemType itemType,
  }) async {
    final repository = _ref.read(collectionRepositoryProvider);
    await repository.removeItemFromCollection(
      collectionId: collectionId,
      itemId: itemId,
      itemType: itemType,
    );
    _ref.invalidate(collectionsProvider);
    _ref.invalidate(collectionDetailsProvider(collectionId));
    _ref.invalidate(itemCollectionsProvider((itemId: itemId, itemType: itemType)));
  }

  Future<void> updateCollectionEntry({
    required int collectionId,
    required int itemId,
    required ItemType itemType,
    int? position,
    String? label,
  }) async {
    final repository = _ref.read(collectionRepositoryProvider);
    await repository.updateCollectionEntry(
      collectionId: collectionId,
      itemId: itemId,
      itemType: itemType,
      position: position,
      label: label,
    );
    _ref.invalidate(collectionDetailsProvider(collectionId));
  }
}
