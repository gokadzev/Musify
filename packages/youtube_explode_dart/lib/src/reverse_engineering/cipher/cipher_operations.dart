/// Base CipherOperation
abstract class CipherOperation {
  /// Base Cipher initializer.
  const CipherOperation();

  /// Decipher function.
  String decipher(String input);
}

/// Splice Operation
class SpliceCipherOperation extends CipherOperation {
  /// Index where to perform the operation.
  final int index;

  /// Initialize Splice operation.
  const SpliceCipherOperation(this.index);

  @override
  String decipher(String input) => input.substring(index);

  @override
  String toString() => 'Slice: [$index]';
}

/// Swap Operation.
class SwapCipherOperation extends CipherOperation {
  /// Index where to perform the operation.
  final int index;

  /// Initialize swap operation.
  const SwapCipherOperation(this.index);

  @override
  String decipher(String input) {
    final runes = input.runes.toList();
    final first = runes[0];
    runes[0] = runes[index];
    runes[index] = first;
    return String.fromCharCodes(runes);
  }

  @override
  String toString() => 'Swap: [$index]';
}

/// Reverse Operation.
class ReverseCipherOperation extends CipherOperation {
  /// Initialize reverse operation.
  const ReverseCipherOperation();

  @override
  String decipher(String input) {
    final runes = input.runes.toList().reversed;
    return String.fromCharCodes(runes);
  }

  @override
  String toString() => 'Reverse';
}
