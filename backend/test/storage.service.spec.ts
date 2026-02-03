import { StorageService } from '../src/services/storage.service';

jest.mock('minio', () => {
  return {
    Client: jest.fn().mockImplementation(() => ({
      bucketExists: jest.fn().mockResolvedValue(true),
      makeBucket: jest.fn(),
      presignedPutObject: jest.fn().mockResolvedValue('put-url'),
      presignedGetObject: jest.fn().mockResolvedValue('get-url'),
    })),
  };
});

describe('StorageService', () => {
  it('builds a unique object key per call', () => {
    const service = new StorageService();
    const first = service.buildObjectKey('user', 'doc');
    const second = service.buildObjectKey('user', 'doc');
    expect(first).not.toEqual(second);
    expect(first).toContain('user/doc/');
    expect(first).toContain('.enc');
  });

  it('generates presigned URLs', async () => {
    const service = new StorageService();
    await expect(service.getPresignedPutUrl('key')).resolves.toBe('put-url');
    await expect(service.getPresignedGetUrl('key')).resolves.toBe('get-url');
  });
});
