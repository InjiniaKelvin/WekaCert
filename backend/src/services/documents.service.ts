import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { DocumentEntity } from '../entities/document.entity';
import { DocumentVersionEntity } from '../entities/document-version.entity';

@Injectable()
export class DocumentsService {
  constructor(
    @InjectRepository(DocumentEntity)
    private readonly documents: Repository<DocumentEntity>,
    @InjectRepository(DocumentVersionEntity)
    private readonly versions: Repository<DocumentVersionEntity>,
  ) {}

  async list(ownerId: string) {
    return this.documents.find({ where: { ownerId } });
  }

  async create(ownerId: string, data: Partial<DocumentEntity>) {
    const document = this.documents.create({ ...data, ownerId });
    return this.documents.save(document);
  }

  async addVersion(documentId: string, objectKey: string, note?: string | null) {
    const doc = await this.documents.findOne({ where: { id: documentId } });
    if (!doc) {
      throw new NotFoundException('Document not found');
    }
    const version = this.versions.create({
      documentId,
      objectKey,
      note: note ?? null,
    });
    return this.versions.save(version);
  }

  async listVersions(documentId: string) {
    return this.versions.find({
      where: { documentId },
      order: { createdAt: 'DESC' },
    });
  }
}
