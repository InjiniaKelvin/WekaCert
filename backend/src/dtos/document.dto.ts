import { IsBoolean, IsDateString, IsIn, IsOptional, IsString } from 'class-validator';

const documentCategories = ['id', 'certificate', 'license', 'property', 'other'];

export class CreateDocumentDto {
  @IsString()
  name!: string;

  @IsString()
  @IsIn(documentCategories)
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

export class UpdateDocumentDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  @IsIn(documentCategories)
  category?: string;

  @IsOptional()
  @IsBoolean()
  isExpirable?: boolean;

  @IsOptional()
  @IsDateString()
  expiryDate?: string | null;
}
