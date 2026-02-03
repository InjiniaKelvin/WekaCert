import {
  Column,
  CreateDateColumn,
  Entity,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import { UserEntity } from './user.entity';

@Entity('documents')
export class DocumentEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column()
  ownerId!: string;

  @ManyToOne(() => UserEntity)
  owner!: UserEntity;

  @Column()
  name!: string;

  @Column()
  category!: string;

  @Column({ default: false })
  isExpirable!: boolean;

  @Column({ type: 'date', nullable: true })
  expiryDate?: Date | null;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt!: Date;
}
