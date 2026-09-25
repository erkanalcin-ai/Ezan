enum QiblaNorthReference {
  trueNorth,
  magneticNorth;

  bool get usesTrueNorth => this == QiblaNorthReference.trueNorth;

  String get storageValue => usesTrueNorth ? 'true' : 'magnetic';

  static QiblaNorthReference fromStorage(String? value) => switch (value) {
    'magnetic' => QiblaNorthReference.magneticNorth,
    _ => QiblaNorthReference.trueNorth,
  };
}
