enum ItemType {
  cd('cd'),
  vinyl('vinyl');

  const ItemType(this.value);

  final String value;

  factory ItemType.fromString(String value) {
    return ItemType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Unknown ItemType: $value'),
    );
  }

  @override
  String toString() => value;
}
