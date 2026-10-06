import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  ForbiddenException,
  Get,
  NotFoundException,
  Param,
  Patch,
  Post,
  Req,
  Res,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { Response } from 'express';

import { CreateDocumentDto, CreateDocumentVersionDto, UpdateDocumentDto } from '../dtos/document.dto';
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

  @Get(':id')
  async getOne(@Req() req: { user: { id: string } }, @Param('id') id: string) {
    const document = await this.documents.getDocumentForOwner(id, req.user.id);
    if (!document) throw new NotFoundException('Document not found');
    const versions = await this.documents.listVersions(id);
    return { document, versions };
  }

  @Patch(':id')
  async update(
    @Req() req: { user: { id: string } },
    @Param('id') id: string,
    @Body() dto: UpdateDocumentDto,
  ) {
    const document = await this.documents.getDocumentForOwner(id, req.user.id);
    if (!document) throw new NotFoundException('Document not found');
    return this.documents.updateDocument(id, req.user.id, {
      ...(dto.name !== undefined && { name: dto.name }),
      ...(dto.category !== undefined && { category: dto.category }),
      ...(dto.isExpirable !== undefined && { isExpirable: dto.isExpirable }),
      ...(dto.expiryDate !== undefined && {
        expiryDate: dto.expiryDate ? new Date(dto.expiryDate) : null,
      }),
    });
  }

  @Delete(':id')
  async remove(@Req() req: { user: { id: string } }, @Param('id') id: string) {
    const document = await this.documents.getDocumentForOwner(id, req.user.id);
    if (!document) throw new NotFoundException('Document not found');
    const versions = await this.documents.listVersions(id);
    await this.documents.deleteDocument(id, req.user.id);
    await Promise.all(
      versions.map((version) => this.storage.removeObject(version.objectKey)),
    );
    return { deleted: true };
  }

  @Post(':id/upload')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: 50 * 1024 * 1024 },
    }),
  )
  async uploadFile(
    @Req() req: { user: { id: string } },
    @Param('id') id: string,
    @UploadedFile() file: Express.Multer.File,
    @Body('note') note?: string,
  ) {
    const document = await this.documents.getDocumentForOwner(id, req.user.id);
    if (!document) throw new NotFoundException('Document not found');
    if (!file) throw new BadRequestException('No file provided');
    const objectKey = this.storage.buildObjectKey(req.user.id, id);
    await this.storage.putEncryptedObject(objectKey, file.buffer);
    return this.documents.addVersion(id, objectKey, note ?? null);
  }

  @Get(':id/versions')
  async listVersions(
    @Req() req: { user: { id: string } },
    @Param('id') id: string,
  ) {
    const document = await this.documents.getDocumentForOwner(id, req.user.id);
    if (!document) throw new NotFoundException('Document not found');
    return this.documents.listVersions(id);
  }

  @Post(':id/versions/:versionId/backup')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: 50 * 1024 * 1024 },
    }),
  )
  async uploadBackup(
    @Req() req: { user: { id: string } },
    @Param('id') id: string,
    @Param('versionId') versionId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    const document = await this.documents.getDocumentForOwner(id, req.user.id);
    if (!document) throw new NotFoundException('Document not found');
    const version = await this.documents.getVersionById(versionId, id);
    if (!version) throw new NotFoundException('Version not found');
    if (!file) throw new BadRequestException('No backup provided');
    const objectKey = this.storage.buildBackupObjectKey(
      req.user.id,
      id,
      versionId,
    );
    await this.storage.putEncryptedObject(objectKey, file.buffer);
    return { objectKey };
  }

  @Get(':id/versions/:versionId/backup')
  async downloadBackup(
    @Req() req: { user: { id: string }; query: Record<string, unknown> },
    @Param('id') id: string,
    @Param('versionId') versionId: string,
    @Res() res: Response,
  ) {
    const document = await this.documents.getDocumentForOwner(id, req.user.id);
    if (!document) throw new NotFoundException('Document not found');
    const version = await this.documents.getVersionById(versionId, id);
    if (!version) throw new NotFoundException('Version not found');
    const objectKey = req.query?.objectKey as string | undefined;
    if (
      !objectKey ||
      !this.storage.isOwnedBackupObjectKey(
        req.user.id,
        id,
        versionId,
        objectKey,
      )
    ) {
      throw new NotFoundException('Backup not found');
    }
    const file = await this.storage.getDecryptedObject(objectKey);
    res.type('application/octet-stream').send(file);
  }

  @Get(':id/versions/:versionId/file')
  async serveFile(
    @Req() req: { user: { id: string } },
    @Param('id') id: string,
    @Param('versionId') versionId: string,
    @Res() res: Response,
  ) {
    const document = await this.documents.getDocumentForOwner(id, req.user.id);
    if (!document) throw new NotFoundException('Document not found');

    const version = await this.documents.getVersionById(versionId, id);
    if (!version) throw new NotFoundException('Version not found');

    try {
      const file = await this.storage.getDecryptedObject(version.objectKey);
      res.type('application/octet-stream').send(file);
    } catch {
      throw new ForbiddenException('Unable to read encrypted document');
    }
  }

  @Post(':id/versions')
  async addVersion(
    @Req() req: { user: { id: string } },
    @Param('id') id: string,
    @Body() dto: CreateDocumentVersionDto,
  ) {
    const document = await this.documents.getDocumentForOwner(id, req.user.id);
    if (!document) throw new NotFoundException('Document not found');
    return this.documents.addVersion(id, dto.objectKey, dto.note ?? null);
  }

}
