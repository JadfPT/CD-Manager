import 'album_loan.dart';

class ActiveLoanDetails {
  const ActiveLoanDetails({
    required this.loan,
    required this.borrowerDisplayName,
    required this.borrowerUsername,
  });

  final AlbumLoan loan;
  final String? borrowerDisplayName;
  final String? borrowerUsername;

  String get borrowerLabel {
    if (borrowerDisplayName != null && borrowerDisplayName!.trim().isNotEmpty) {
      return borrowerDisplayName!;
    }
    if (borrowerUsername != null && borrowerUsername!.trim().isNotEmpty) {
      return borrowerUsername!;
    }
    return loan.borrowedByUserId;
  }
}
