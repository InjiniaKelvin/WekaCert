import { Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { Client } from 'minio';

@Injectable()
export class StorageService {
  private client: Client;
  private bucket = process.env.MINIO_BUCKET ?? 'weka-cert';

  constructor() {
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

  buildObjectKey(ownerId: string, documentId: string) {
    return `${ownerId}/${documentId}/${randomUUID()}.enc`;
  }
}
