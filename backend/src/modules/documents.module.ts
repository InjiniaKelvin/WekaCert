import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { DocumentsController } from '../controllers/documents.controller';
import { DocumentEntity } from '../entities/document.entity';
import { DocumentVersionEntity } from '../entities/document-version.entity';
import { DocumentsService } from '../services/documents.service';
import { StorageModule } from './storage.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([DocumentEntity, DocumentVersionEntity]),
    StorageModule,
  ],
  providers: [DocumentsService],
  controllers: [DocumentsController],
})
export class DocumentsModule {}
