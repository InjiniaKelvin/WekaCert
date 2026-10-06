import { StorageService } from '../src/services/storage.service';

describe('StorageService', () => {
  beforeAll(() => {
    process.env.BACKUP_ENCRYPTION_KEY = 'test-backup-key';
  });

  it('builds a unique object key per call', () => {
    const service = new StorageService();
    const first = service.buildObjectKey('user', 'doc');
    const second = service.buildObjectKey('user', 'doc');
    expect(first).not.toEqual(second);
    expect(first).toContain('user/doc/');
    expect(first).toContain('.enc');
  });

  it('validates owned object keys', () => {
    const service = new StorageService();
    const key = service.buildObjectKey('owner', 'doc');
    expect(service.isOwnedObjectKey('owner', key)).toBe(true);
    expect(service.isOwnedObjectKey('other', key)).toBe(false);
  });

  it('limits backup keys to the owner, document, and version', () => {
    const service = new StorageService();
    const key = 'owner/doc/backups/version-random.enc';
    expect(service.isOwnedBackupObjectKey('owner', 'doc', 'version', key)).toBe(
      true,
    );
    expect(service.isOwnedBackupObjectKey('owner', 'other', 'version', key)).toBe(
      false,
    );
  });

  it('round-trips encrypted content and rejects tampering', () => {
    const service = new StorageService();
    const encrypted = service.encrypt(Buffer.from('private document'));

    expect(encrypted.toString()).not.toContain('private document');
    expect(service.decrypt(encrypted).toString()).toBe('private document');

    encrypted[encrypted.length - 1] ^= 1;
    expect(() => service.decrypt(encrypted)).toThrow();
  });
});
