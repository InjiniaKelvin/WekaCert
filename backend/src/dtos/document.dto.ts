import { IsBoolean, IsDateString, IsOptional, IsString } from 'class-validator';

export class CreateDocumentDto {
  @IsString()
  name!: string;

  @IsString()
  category!: string;

  @IsBoolean()
  isExpirable!: boolean;

  @IsOptional()
  @IsDateString()
  expiryDate?: string;
}

export class CreateDocumentVersionDto {
  @IsString()
  objectKey!: string;

  @IsOptional()
  @IsString()
  note?: string;
}
