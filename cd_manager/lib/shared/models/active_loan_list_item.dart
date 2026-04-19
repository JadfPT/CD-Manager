import 'item_type.dart';

class ActiveLoanListItem {
  const ActiveLoanListItem({
    required this.loanId,
    required this.albumId,
    required this.title,
    required this.artistName,
    required this.borrowedByUserId,
    required this.borrowedAt,
    this.coverUrl,
    this.borrowerDisplayName,
    this.borrowerUsername,
    this.itemType = ItemType.cd,
  });

  final int loanId;
  final int albumId;
  final String title;
  final String artistName;
  final String borrowedByUserId;
  final DateTime borrowedAt;
  final String? coverUrl;
  final String? borrowerDisplayName;
  final String? borrowerUsername;
  final ItemType itemType;

  String get borrowerLabel {
    if (borrowerDisplayName != null && borrowerDisplayName!.trim().isNotEmpty) {
      return borrowerDisplayName!;
    }
    if (borrowerUsername != null && borrowerUsername!.trim().isNotEmpty) {
      return borrowerUsername!;
    }
    return borrowedByUserId;
  }
}
