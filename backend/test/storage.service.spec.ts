import { StorageService } from '../src/services/storage.service';

describe('StorageService', () => {
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
});
