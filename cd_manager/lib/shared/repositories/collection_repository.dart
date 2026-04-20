import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/error_handler.dart';
import '../models/collection.dart';
import '../models/collection_entry.dart';
import '../models/item_type.dart';

class CollectionRepository {
  CollectionRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  String _itemTypeToDb(ItemType itemType) =>
      itemType == ItemType.cd ? 'cd' : 'vinyl';

    String _tableByType(ItemType itemType) =>
      itemType == ItemType.cd ? 'cd_albums' : 'vinyl_albums';

  Future<void> _ensureCurrentUserIsAdmin() async {
    try {
      final isAdmin = await _client.rpc('current_user_is_admin');
      if (isAdmin != true) {
        throw AppException(message: 'Apenas administradores podem fazer esta ação');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Falha ao validar permissões de admin: $e');
    }
  }

  /// Lista todas as coleções com contagem de itens
  Future<List<Collection>> listCollections() async {
    try {
      final data = await _client
          .from('item_collections')
          .select('id, name, description, created_at, updated_at')
          .order('name', ascending: true);

      final collections = data.map((row) => Collection.fromMap(row)).toList();

      // Contar itens de cada coleção
      for (int i = 0; i < collections.length; i++) {
        final collection = collections[i];
        try {
          final countData = await _client
              .from('item_collection_entries')
              .select('collection_id')
              .eq('collection_id', collection.id);
          
          final itemCount = countData.length;
          collections[i] = collection.copyWith(itemCount: itemCount);
        } catch (e) {
          // Se falhar a contagem, fica com 0
          continue;
        }
      }

      return collections;
    } catch (e) {
      throw AppException(message: 'Falha ao listar coleções: $e');
    }
  }

  /// Obtém detalhes de uma coleção específica com seus itens
  Future<({Collection collection, List<CollectionEntry> entries})> getCollectionDetails(
    int collectionId,
  ) async {
    try {
      // Fetch collection
      final collData = await _client
          .from('item_collections')
          .select('id, name, description, created_at, updated_at')
          .eq('id', collectionId)
          .maybeSingle();

      if (collData == null) {
        throw AppException(message: 'Coleção não encontrada ou sem permissão de acesso.');
      }

      final collection = Collection.fromMap(collData);

      // Fetch entries, ordenadas por position (se houver) depois por created_at
      final List<Map<String, dynamic>> entriesData =
          await _client
          .from('item_collection_entries')
          .select(
            'collection_id, item_type, item_id, position, label, created_at',
          )
          .eq('collection_id', collectionId)
          .order('position', ascending: true, nullsFirst: false)
          .order('created_at', ascending: true);

      final cdIds = <int>[];
      final vinylIds = <int>[];
      for (final row in entriesData) {
        final itemId = row['item_id'] as int;
        final itemTypeRaw = row['item_type'] as String;
        if (itemTypeRaw == 'cd') {
          cdIds.add(itemId);
        } else {
          vinylIds.add(itemId);
        }
      }

      final itemDetails = <String, ({String title, String artistName, String? coverUrl})>{};

      Future<void> loadItemDetails(ItemType itemType, List<int> itemIds) async {
        if (itemIds.isEmpty) return;

        final rows = await _client
            .from(_tableByType(itemType))
            .select('id, title, artist_id, cover_url')
            .inFilter('id', itemIds.toSet().toList());

        final artistIds = rows.map((r) => r['artist_id'] as int).toSet().toList();
        final artistMap = <int, String>{};

        if (artistIds.isNotEmpty) {
          final artists = await _client
              .from('artists')
              .select('id, name')
              .inFilter('id', artistIds);
          for (final artist in artists) {
            artistMap[artist['id'] as int] = artist['name'] as String;
          }
        }

        for (final row in rows) {
          final id = row['id'] as int;
          final artistId = row['artist_id'] as int;
          final key = '${_itemTypeToDb(itemType)}:$id';
          itemDetails[key] = (
            title: row['title'] as String,
            artistName: artistMap[artistId] ?? 'Artista desconhecido',
            coverUrl: row['cover_url'] as String?,
          );
        }
      }

      await loadItemDetails(ItemType.cd, cdIds);
      await loadItemDetails(ItemType.vinyl, vinylIds);

      final entries = entriesData.map((row) {
        final itemId = row['item_id'] as int;
        final itemTypeRaw = row['item_type'] as String;
        final itemType = itemTypeRaw == 'cd' ? ItemType.cd : ItemType.vinyl;
        final key = '$itemTypeRaw:$itemId';
        final details = itemDetails[key];

        return CollectionEntry(
          collectionId: row['collection_id'] as int,
          itemType: itemType,
          itemId: itemId,
          position: row['position'] as int?,
          label: row['label'] as String?,
          itemTitle: details?.title ?? 'Item #$itemId',
          itemArtistName: details?.artistName ?? 'Artista desconhecido',
          itemCoverUrl: details?.coverUrl,
        );
      }).toList();

      return (collection: collection, entries: entries);
    } catch (e) {
      throw AppException(message: 'Falha ao obter detalhes da coleção: $e');
    }
  }

  /// Cria uma nova coleção (admin apenas)
  Future<int> createCollection({
    required String name,
    String? description,
  }) async {
    await _ensureCurrentUserIsAdmin();

    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw AppException(message: 'Nome da coleção é obrigatório');
    }

    try {
      final result = await _client
          .from('item_collections')
          .insert({
            'name': normalizedName,
            'description': description?.trim().isEmpty == true ? null : description?.trim(),
          })
          .select('id')
          .single();

      return result['id'] as int;
    } catch (e) {
      throw AppException(message: 'Falha ao criar coleção: $e');
    }
  }

  /// Atualiza uma coleção (admin apenas)
  Future<void> updateCollection({
    required int collectionId,
    String? name,
    String? description,
  }) async {
    await _ensureCurrentUserIsAdmin();

    if (name == null && description == null) {
      throw AppException(message: 'Nada para atualizar');
    }

    try {
      final updateData = <String, dynamic>{};
      if (name != null) {
        final normalizedName = name.trim();
        if (normalizedName.isEmpty) {
          throw AppException(message: 'Nome da coleção não pode ser vazio');
        }
        updateData['name'] = normalizedName;
      }
      if (description != null) {
        updateData['description'] =
            description.trim().isEmpty ? null : description.trim();
      }

      await _client
          .from('item_collections')
          .update(updateData)
          .eq('id', collectionId);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Falha ao atualizar coleção: $e');
    }
  }

  /// Deleta uma coleção e todos os seus itens (admin apenas)
  Future<void> deleteCollection(int collectionId) async {
    await _ensureCurrentUserIsAdmin();

    try {
      // Primeiro remove os itens da coleção
      await _client
          .from('item_collection_entries')
          .delete()
          .eq('collection_id', collectionId);

      // Depois remove a coleção
      await _client
          .from('item_collections')
          .delete()
          .eq('id', collectionId);
    } catch (e) {
      throw AppException(message: 'Falha ao deletar coleção: $e');
    }
  }

  /// Adiciona um item a uma coleção
  Future<void> addItemToCollection({
    required int collectionId,
    required int itemId,
    required ItemType itemType,
    int? position,
    String? label,
  }) async {
    await _ensureCurrentUserIsAdmin();

    try {
      await _client.from('item_collection_entries').insert({
        'collection_id': collectionId,
        'item_type': _itemTypeToDb(itemType),
        'item_id': itemId,
        'position': position,
        'label': label?.trim().isEmpty == true ? null : label?.trim(),
      });
    } catch (e) {
      throw AppException(message: 'Falha ao adicionar item à coleção: $e');
    }
  }

  /// Remove um item de uma coleção
  Future<void> removeItemFromCollection({
    required int collectionId,
    required int itemId,
    required ItemType itemType,
  }) async {
    await _ensureCurrentUserIsAdmin();

    try {
      await _client
          .from('item_collection_entries')
          .delete()
          .eq('collection_id', collectionId)
          .eq('item_id', itemId)
          .eq('item_type', _itemTypeToDb(itemType));
    } catch (e) {
      throw AppException(message: 'Falha ao remover item da coleção: $e');
    }
  }

  /// Obtém informações de coleção para um item específico
  /// Retorna a lista de coleções que contem esse item
  Future<List<({int collectionId, String collectionName, int? position, String? label})>>
      getCollectionsForItem({
    required int itemId,
    required ItemType itemType,
  }) async {
    try {
      final collectionsData = await _client
          .from('item_collection_entries')
          .select('collection_id, position, label')
          .eq('item_id', itemId)
          .eq('item_type', _itemTypeToDb(itemType));

      if (collectionsData.isEmpty) return [];

      final collectionIds =
          collectionsData.map((row) => row['collection_id'] as int).toSet().toList();

      // Fetch collection names
      final collectionsInfo = await _client
          .from('item_collections')
          .select('id, name')
          .inFilter('id', collectionIds);

      final collectionMap = <int, String>{};
      for (final coll in collectionsInfo) {
        collectionMap[coll['id'] as int] = coll['name'] as String;
      }

      return collectionsData
          .map((row) => (
                collectionId: row['collection_id'] as int,
                collectionName: collectionMap[row['collection_id']] ?? 'Unknown',
                position: row['position'] as int?,
                label: row['label'] as String?,
              ))
          .toList();
    } catch (e) {
      throw AppException(message: 'Falha ao obter coleções do item: $e');
    }
  }

  /// Atualiza posição e label de um item na coleção
  Future<void> updateCollectionEntry({
    required int collectionId,
    required int itemId,
    required ItemType itemType,
    int? position,
    String? label,
  }) async {
    await _ensureCurrentUserIsAdmin();

    if (position == null && label == null) {
      throw AppException(message: 'Nada para atualizar');
    }

    try {
      final updateData = <String, dynamic>{};
      if (position != null) {
        updateData['position'] = position;
      }
      if (label != null) {
        updateData['label'] = label.trim().isEmpty ? null : label.trim();
      }

      await _client
          .from('item_collection_entries')
          .update(updateData)
          .eq('collection_id', collectionId)
          .eq('item_id', itemId)
          .eq('item_type', _itemTypeToDb(itemType));
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Falha ao atualizar entrada da coleção: $e');
    }
  }
}
