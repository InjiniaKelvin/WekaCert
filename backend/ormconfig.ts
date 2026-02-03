import { DataSource } from 'typeorm';

import { DocumentEntity } from './src/entities/document.entity';
import { DocumentVersionEntity } from './src/entities/document-version.entity';
import { UserEntity } from './src/entities/user.entity';

export default new DataSource({
  type: 'postgres',
  url: process.env.DATABASE_URL,
  entities: [DocumentEntity, DocumentVersionEntity, UserEntity],
  migrations: ['migrations/*.ts'],
});
