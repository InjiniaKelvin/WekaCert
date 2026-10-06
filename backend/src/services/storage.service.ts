import { Injectable } from '@nestjs/common';
import {
  createCipheriv,
  createDecipheriv,
  createHash,
  randomBytes,
  randomUUID,
} from 'crypto';
import { Client } from 'minio';

@Injectable()
export class StorageService {
  private client: Client;
  private bucket = process.env.MINIO_BUCKET ?? 'weka-cert';
  private readonly encryptionKey: Buffer;

  constructor() {
    const keyMaterial = process.env.BACKUP_ENCRYPTION_KEY ?? process.env.JWT_SECRET;
    if (!keyMaterial) {
      throw new Error('BACKUP_ENCRYPTION_KEY is required');
    }
    this.encryptionKey = createHash('sha256').update(keyMaterial).digest();
    this.client = new Client({
      endPoint: process.env.MINIO_ENDPOINT ?? 'localhost',
      port: Number(process.env.MINIO_PORT ?? 9000),
      useSSL: process.env.MINIO_USE_SSL === 'true',
      accessKey: process.env.MINIO_ACCESS_KEY ?? 'minioadmin',
      secretKey: process.env.MINIO_SECRET_KEY ?? 'minioadmin',
    });
  }

  async ensureBucket() {
    const exists = await this.client.bucketExists(this.bucket);
    if (!exists) {
      await this.client.makeBucket(this.bucket, 'us-east-1');
    }
  }

  async getPresignedPutUrl(objectKey: string, expirySeconds = 900) {
    await this.ensureBucket();
    return this.client.presignedPutObject(this.bucket, objectKey, expirySeconds);
  }

  async getPresignedGetUrl(objectKey: string, expirySeconds = 900) {
    await this.ensureBucket();
    return this.client.presignedGetObject(this.bucket, objectKey, expirySeconds);
  }

  async putEncryptedObject(objectKey: string, data: Buffer) {
    await this.ensureBucket();
    const payload = this.encrypt(data);
    await this.client.putObject(this.bucket, objectKey, payload, payload.length, {
      'Content-Type': 'application/octet-stream',
    });
  }

  async getDecryptedObject(objectKey: string): Promise<Buffer> {
    await this.ensureBucket();
    const stream = await this.client.getObject(this.bucket, objectKey);
    const chunks: Buffer[] = [];
    for await (const chunk of stream) {
      chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
    }
    const payload = Buffer.concat(chunks);
    if (payload.length < 28) {
      throw new Error('Encrypted object is invalid');
    }
    return this.decrypt(payload);
  }

  encrypt(data: Buffer) {
    const nonce = randomBytes(12);
    const cipher = createCipheriv('aes-256-gcm', this.encryptionKey, nonce);
    const ciphertext = Buffer.concat([cipher.update(data), cipher.final()]);
    return Buffer.concat([nonce, cipher.getAuthTag(), ciphertext]);
  }

  decrypt(payload: Buffer) {
    if (payload.length < 28) {
      throw new Error('Encrypted object is invalid');
    }
    const decipher = createDecipheriv(
      'aes-256-gcm',
      this.encryptionKey,
      payload.subarray(0, 12),
    );
    decipher.setAuthTag(payload.subarray(12, 28));
    return Buffer.concat([
      decipher.update(payload.subarray(28)),
      decipher.final(),
    ]);
  }

  async removeObject(objectKey: string) {
    await this.ensureBucket();
    await this.client.removeObject(this.bucket, objectKey);
  }

  buildObjectKey(ownerId: string, documentId: string) {
    return `${ownerId}/${documentId}/${randomUUID()}.enc`;
  }

  buildBackupObjectKey(ownerId: string, documentId: string, versionId: string) {
    return `${ownerId}/${documentId}/backups/${versionId}-${randomUUID()}.enc`;
  }

  isOwnedObjectKey(ownerId: string, objectKey: string) {
    return objectKey.startsWith(`${ownerId}/`);
  }

  isOwnedBackupObjectKey(
    ownerId: string,
    documentId: string,
    versionId: string,
    objectKey: string,
  ) {
    return (
      this.isOwnedObjectKey(ownerId, objectKey) &&
      objectKey.startsWith(`${ownerId}/${documentId}/backups/${versionId}-`)
    );
  }
}
