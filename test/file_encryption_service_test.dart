import 'dart:io';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:weka_cert/services/file_encryption_service.dart';

void main() {
  test('encrypts document bytes and rejects tampering', () async {
    final directory = await Directory.systemTemp.createTemp('weka-cert-crypto-');
    addTearDown(() => directory.delete(recursive: true));

    final source = File('${directory.path}/source.pdf');
    final encrypted = File('${directory.path}/document.enc');
    final restored = File('${directory.path}/restored.pdf');
    const content = 'sensitive certificate contents';
    await source.writeAsString(content);

    final service = FileEncryptionService(keyMaterial: 'test-key-material');
    await service.encryptFile(
      sourcePath: source.path,
      destinationPath: encrypted.path,
    );

    expect(await encrypted.readAsBytes(), isNot(utf8.encode(content)));
    await service.decryptToFile(
      sourcePath: encrypted.path,
      destinationPath: restored.path,
    );
    expect(await restored.readAsString(), content);

    final bytes = await encrypted.readAsBytes();
    bytes[bytes.length - 1] ^= 1;
    await encrypted.writeAsBytes(bytes);
    expect(
      () => service.decryptToFile(
        sourcePath: encrypted.path,
        destinationPath: restored.path,
      ),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });
}
