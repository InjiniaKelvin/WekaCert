import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AuthModule } from './auth.module';
import { DocumentsModule } from './documents.module';
import { StorageModule } from './storage.module';
import { UsersModule } from './users.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRoot({
      type: 'postgres',
      url: process.env.DATABASE_URL,
      entities: [__dirname + '/../entities/*.entity.{ts,js}'],
      synchronize: false, // Use migrations in production.
    }),
    AuthModule,
    UsersModule,
    DocumentsModule,
    StorageModule,
  ],
})
export class AppModule {}
