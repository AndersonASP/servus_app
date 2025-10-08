# Ajustes no Backend para Campo maxBlockedDays

## 📋 **Resumo**
Adicionar o campo `maxBlockedDays` na tabela `ministerios` para armazenar o limite de dias bloqueados por ministério.

## 🗄️ **Alterações no Banco de Dados**

### **1. Adicionar Coluna na Tabela `ministerios`**
```sql
ALTER TABLE ministries ADD COLUMN max_blocked_days INT DEFAULT 10;
```

### **2. Atualizar Registros Existentes (Opcional)**
```sql
UPDATE ministries SET max_blocked_days = 10 WHERE max_blocked_days IS NULL;
```

## 🔧 **Alterações no Backend (Node.js/TypeScript)**

### **1. Schema do Ministério**
```typescript
// src/modules/ministries/schemas/ministry.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class Ministry extends Document {
  @Prop({ required: true })
  name: string;

  @Prop()
  description?: string;

  @Prop({ type: [String], default: [] })
  ministryFunctions: string[];

  @Prop({ default: true })
  isActive: boolean;

  @Prop({ default: 10 })
  maxBlockedDays: number; // ← NOVO CAMPO

  @Prop({ required: true })
  tenantId: string;

  @Prop()
  branchId?: string;
}

export const MinistrySchema = SchemaFactory.createForClass(Ministry);
```

### **2. DTOs de Criação e Atualização**
```typescript
// src/modules/ministries/dto/create-ministry.dto.ts
import { IsString, IsOptional, IsBoolean, IsArray, IsInt, Min, Max } from 'class-validator';

export class CreateMinistryDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  ministryFunctions?: string[];

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(50)
  maxBlockedDays?: number; // ← NOVO CAMPO
}
```

```typescript
// src/modules/ministries/dto/update-ministry.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateMinistryDto } from './create-ministry.dto';

export class UpdateMinistryDto extends PartialType(CreateMinistryDto) {
  // Herda todos os campos de CreateMinistryDto, incluindo maxBlockedDays
}
```

### **3. Service do Ministério**
```typescript
// src/modules/ministries/ministries.service.ts
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Ministry } from './schemas/ministry.schema';
import { CreateMinistryDto } from './dto/create-ministry.dto';
import { UpdateMinistryDto } from './dto/update-ministry.dto';

@Injectable()
export class MinistriesService {
  constructor(
    @InjectModel(Ministry.name) private ministryModel: Model<Ministry>,
  ) {}

  async create(createMinistryDto: CreateMinistryDto): Promise<Ministry> {
    const ministry = new this.ministryModel({
      ...createMinistryDto,
      maxBlockedDays: createMinistryDto.maxBlockedDays ?? 10, // ← VALOR PADRÃO
    });
    return ministry.save();
  }

  async update(id: string, updateMinistryDto: UpdateMinistryDto): Promise<Ministry> {
    return this.ministryModel.findByIdAndUpdate(
      id,
      updateMinistryDto,
      { new: true }
    ).exec();
  }

  async findOne(id: string): Promise<Ministry> {
    return this.ministryModel.findById(id).exec();
  }

  // ... outros métodos
}
```

### **4. Controller do Ministério**
```typescript
// src/modules/ministries/ministries.controller.ts
import { Controller, Get, Post, Put, Delete, Body, Param, Query } from '@nestjs/common';
import { MinistriesService } from './ministries.service';
import { CreateMinistryDto } from './dto/create-ministry.dto';
import { UpdateMinistryDto } from './dto/update-ministry.dto';

@Controller('ministries')
export class MinistriesController {
  constructor(private readonly ministriesService: MinistriesService) {}

  @Post()
  create(@Body() createMinistryDto: CreateMinistryDto) {
    return this.ministriesService.create(createMinistryDto);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() updateMinistryDto: UpdateMinistryDto) {
    return this.ministriesService.update(id, updateMinistryDto);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.ministriesService.findOne(id);
  }

  // ... outros endpoints
}
```

## 🧪 **Testes**

### **1. Teste de Criação**
```typescript
// test/ministries.e2e-spec.ts
describe('Ministries (e2e)', () => {
  it('should create a ministry with maxBlockedDays', async () => {
    const createMinistryDto = {
      name: 'Test Ministry',
      description: 'Test Description',
      ministryFunctions: ['Vocal', 'Instrumentos'],
      isActive: true,
      maxBlockedDays: 15, // ← NOVO CAMPO
    };

    const response = await request(app.getHttpServer())
      .post('/ministries')
      .send(createMinistryDto)
      .expect(201);

    expect(response.body.maxBlockedDays).toBe(15);
  });
});
```

## 📝 **Validações**

### **1. Validação de Range**
- **Mínimo**: 1 dia
- **Máximo**: 50 dias
- **Padrão**: 10 dias

### **2. Validação de Tipo**
- **Tipo**: Integer
- **Obrigatório**: Não (opcional)
- **Fallback**: 10 dias se não informado

## 🚀 **Deploy**

### **1. Migração do Banco**
```bash
# Executar no banco de dados
ALTER TABLE ministries ADD COLUMN max_blocked_days INT DEFAULT 10;
```

### **2. Deploy do Backend**
```bash
# Build e deploy
npm run build
npm run start:prod
```

## ✅ **Verificação**

### **1. Teste via API**
```bash
# Criar ministério com limite
curl -X POST http://localhost:3000/ministries \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Ministry",
    "maxBlockedDays": 15
  }'

# Verificar resposta
# Deve incluir: "maxBlockedDays": 15
```

### **2. Teste via Frontend**
1. Criar novo ministério
2. Definir limite de bloqueios (ex: 15 dias)
3. Salvar ministério
4. Verificar na tela de detalhes se o limite aparece

## 🎯 **Resultado Esperado**

Após implementar essas alterações:
- ✅ Campo `maxBlockedDays` será salvo na tabela `ministerios`
- ✅ Frontend conseguirá criar/editar ministérios com limite
- ✅ Tela de detalhes mostrará o limite correto
- ✅ Sistema de bloqueios usará o limite do ministério
