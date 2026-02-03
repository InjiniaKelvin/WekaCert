import {
  Body,
  Controller,
  Get,
  NotFoundException,
  Param,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';

import { CreateDocumentDto, CreateDocumentVersionDto } from '../dtos/document.dto';
import { JwtAuthGuard } from '../guards/jwt.guard';
import { DocumentsService } from '../services/documents.service';
import { StorageService } from '../services/storage.service';

@Controller('documents')
@UseGuards(JwtAuthGuard)
export class DocumentsController {
  constructor(
    private readonly documents: DocumentsService,
    private readonly storage: StorageService,
  ) {}

  @Get()
  list(@Req() req: { user: { id: string } }) {
    return this.documents.list(req.user.id);
  }

  @Post()
  create(@Req() req: { user: { id: string } }, @Body() dto: CreateDocumentDto) {
    return this.documents.create(req.user.id, {
      name: dto.name,
      category: dto.category,
      isExpirable: dto.isExpirable,
      expiryDate: dto.expiryDate ? new Date(dto.expiryDate) : null,
    });
  }

  @Post(':id/versions')
  async addVersion(
    @Req() req: { user: { id: string } },
    @Param('id') id: string,
    @Body() dto: CreateDocumentVersionDto,
  ) {
    const document = await this.documents.getDocumentForOwner(id, req.user.id);
    if (!document) {
      throw new NotFoundException('Document not found');
    }
    return this.documents.addVersion(id, dto.objectKey, dto.note ?? null);
  }

  @Get(':id/versions')
  async listVersions(
    @Req() req: { user: { id: string } },
    @Param('id') id: string,
  ) {
    const document = await this.documents.getDocumentForOwner(id, req.user.id);
    if (!document) {
      throw new NotFoundException('Document not found');
    }
    return this.documents.listVersions(id);
  }

  @Post(':id/upload-url')
  async uploadUrl(@Req() req: { user: { id: string } }, @Param('id') id: string) {
    const document = await this.documents.getDocumentForOwner(id, req.user.id);
    if (!document) {
      throw new NotFoundException('Document not found');
    }
    const objectKey = this.storage.buildObjectKey(req.user.id, id);
    const url = await this.storage.getPresignedPutUrl(objectKey);
    return { objectKey, url };
  }

  @Get(':id/download-url/:objectKey')
  async downloadUrl(
    @Req() req: { user: { id: string } },
    @Param('id') id: string,
    @Param('objectKey') objectKey: string,
  ) {
    const document = await this.documents.getDocumentForOwner(id, req.user.id);
    if (!document) {
      throw new NotFoundException('Document not found');
    }
    const url = await this.storage.getPresignedGetUrl(objectKey);
    return { url };
  }
}
