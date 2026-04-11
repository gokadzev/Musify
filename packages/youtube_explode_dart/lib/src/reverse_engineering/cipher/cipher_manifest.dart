import '../../extensions/helpers_extension.dart';
import 'cipher_operations.dart';

final _signatureTimestampExp = RegExp(r'(?:signatureTimestamp|sts):(\d{5})');
final _cipherCallSiteExp = RegExp(
  r'''[$_\w]+=function\([$_\w]+\){([$_\w]+)=\1\.split\(['"]{2}\);.*?return \1\.join\(['"]{2}\)}''',
);
final _cipherContainerNameExp = RegExp(r'([$_\w]+)\.[$_\w]+\([$_\w]+,\d+\);');
final _swapFuncNameExp =
    RegExp(r'''([$_\w]+):function\([$_\w]+,[$_\w]+\){+[^}]*?%[^}]*?}''');
final _spliceFuncNameExp =
    RegExp(r'''([$_\w]+):function\([$_\w]+,[$_\w]+\){+[^}]*?splice[^}]*?}''');
final _reverseFuncName =
    RegExp(r'([$_\w]+):function\([$_\w]+\){+[^}]*?reverse[^}]*?}');
final _calledFuncNameExp = RegExp(r'[$_\w]+\.([$_\w]+)\([$_\w]+,\d+\)');
final _funcIndexExp = RegExp(r'\([$_\w]+,(\d+)\)');

final class CipherManifest {
  final String signatureTimestamp;
  final List<CipherOperation> operations;

  const CipherManifest(this.signatureTimestamp, this.operations);

  static CipherManifest? decode(String content) {
    final signatureTimestamp =
        _signatureTimestampExp.firstMatch(content)?.group(1)?.nullIfWhitespace;

    if (signatureTimestamp == null) {
      return null;
    }

    final cipherCallSite =
        _cipherCallSiteExp.firstMatch(content)?.group(0)?.nullIfWhitespace;

    if (cipherCallSite == null) {
      return null;
    }

    final cipherContainerName = _cipherContainerNameExp
        .firstMatch(cipherCallSite)
        ?.group(1)
        ?.nullIfWhitespace;

    if (cipherContainerName == null) {
      return null;
    }

    final cipherDefinition =
        RegExp('var ${RegExp.escape(cipherContainerName)}={.*?};', dotAll: true)
            .firstMatch(content)
            ?.group(0)
            ?.nullIfWhitespace;

    if (cipherDefinition == null) {
      return null;
    }

    final swapFuncName = _swapFuncNameExp
        .firstMatch(cipherDefinition)
        ?.group(1)
        ?.nullIfWhitespace;
    final spliceFuncName = _spliceFuncNameExp
        .firstMatch(cipherDefinition)
        ?.group(1)
        ?.nullIfWhitespace;
    final reverseFuncName = _reverseFuncName
        .firstMatch(cipherDefinition)
        ?.group(1)
        ?.nullIfWhitespace;

    final ops = cipherCallSite
        .split(';')
        .map((e) {
          final calledFuncName =
              _calledFuncNameExp.firstMatch(e)?.group(1)?.nullIfWhitespace;
          if (calledFuncName == null) {
            return null;
          }
          if (calledFuncName == swapFuncName) {
            final index = _funcIndexExp.firstMatch(e)?.group(1).parseInt();
            return SwapCipherOperation(index!);
          }
          if (calledFuncName == spliceFuncName) {
            final index = _funcIndexExp.firstMatch(e)?.group(1).parseInt();
            return SpliceCipherOperation(index!);
          }
          if (calledFuncName == reverseFuncName) {
            return const ReverseCipherOperation();
          }
        })
        .nonNulls
        .toList();
    return CipherManifest(signatureTimestamp, ops);
  }

  String decipher(String input) {
    for (final operation in operations) {
      input = operation.decipher(input);
    }

    return input;
  }
}
