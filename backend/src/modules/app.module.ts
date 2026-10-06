import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Controller, Get } from '@nestjs/common';

import { AuthModule } from './auth.module';
import { DocumentsModule } from './documents.module';
import { StorageModule } from './storage.module';
import { UsersModule } from './users.module';

@Controller()
class HealthController {
  @Get()
  health() {
    return { status: 'ok', service: 'WekaCert API', version: '1.0.0' };
  }
}

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRoot({
      type: 'postgres',
      url: process.env.DATABASE_URL,
      ssl: process.env.DATABASE_URL?.includes('neon.tech')
        ? { rejectUnauthorized: false }
        : false,
      entities: [__dirname + '/../entities/*.entity.{ts,js}'],
      synchronize: process.env.NODE_ENV !== 'production',
      migrationsRun: process.env.NODE_ENV === 'production',
      migrations: [__dirname + '/../../migrations/*.{ts,js}'],
    }),
    AuthModule,
    UsersModule,
    DocumentsModule,
    StorageModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
