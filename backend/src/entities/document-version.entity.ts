import {
  Column,
  CreateDateColumn,
  Entity,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';

import { DocumentEntity } from './document.entity';

@Entity('document_versions')
export class DocumentVersionEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column()
  documentId!: string;

  @ManyToOne(() => DocumentEntity)
  document!: DocumentEntity;

  @Column()
  objectKey!: string;

  @Column({ type: 'text', nullable: true })
  note?: string | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt!: Date;
}
