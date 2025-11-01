import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:servus_app/core/models/block_configuration.dart';
import 'package:servus_app/core/auth/services/token_service.dart';
import 'package:servus_app/core/constants/env.dart';

/// Serviço responsável por gerenciar configurações de bloqueio
class BlockConfigurationService {
  static const String _baseUrl = Env.baseUrl;

  /// Obtém as configurações de bloqueio para um ministério
  static Future<BlockConfiguration?> getConfiguration({
    required String tenantId,
    required String ministryId,
  }) async {
    try {
      print('🔍 [BlockConfigurationService] Obtendo configuração para ministério: $ministryId');
      
      final token = await TokenService.getAccessToken();
      if (token == null) {
        print('❌ [BlockConfigurationService] Token não encontrado');
        return null;
      }

      final headers = {
        'Content-Type': 'application/json',
        'x-tenant-id': tenantId,
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$_baseUrl/scales/$tenantId/block-configuration/$ministryId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null) {
          final config = BlockConfiguration.fromJson(data);
          print('✅ [BlockConfigurationService] Configuração obtida: ${config.maxBlockedDays} dias');
          return config;
        }
      } else if (response.statusCode == 404) {
        print('🔍 [BlockConfigurationService] Configuração não encontrada, usando padrão');
        return null; // Retorna null para usar configuração padrão
      }

      print('❌ [BlockConfigurationService] Erro ao obter configuração: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ [BlockConfigurationService] Erro ao obter configuração: $e');
      return null;
    }
  }

  /// Salva ou atualiza uma configuração de bloqueio
  static Future<bool> saveConfiguration({
    required String tenantId,
    required BlockConfiguration configuration,
  }) async {
    try {
      print('🔍 [BlockConfigurationService] Salvando configuração para ministério: ${configuration.ministryId}');
      print('🔍 [BlockConfigurationService] Limite: ${configuration.maxBlockedDays} dias');
      
      final token = await TokenService.getAccessToken();
      if (token == null) {
        print('❌ [BlockConfigurationService] Token não encontrado');
        return false;
      }

      final headers = {
        'Content-Type': 'application/json',
        'x-tenant-id': tenantId,
        'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/scales/$tenantId/block-configuration'),
        headers: headers,
        body: json.encode(configuration.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [BlockConfigurationService] Configuração salva com sucesso');
        return true;
      }

      print('❌ [BlockConfigurationService] Erro ao salvar configuração: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ [BlockConfigurationService] Erro ao salvar configuração: $e');
      return false;
    }
  }

  /// Obtém todas as configurações de bloqueio para um tenant
  static Future<List<BlockConfiguration>> getAllConfigurations({
    required String tenantId,
  }) async {
    try {
      print('🔍 [BlockConfigurationService] Obtendo todas as configurações para tenant: $tenantId');
      
      final token = await TokenService.getAccessToken();
      if (token == null) {
        print('❌ [BlockConfigurationService] Token não encontrado');
        return [];
      }

      final headers = {
        'Content-Type': 'application/json',
        'x-tenant-id': tenantId,
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$_baseUrl/scales/$tenantId/block-configurations'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) ?? [];
        final configurations = data.map((json) => BlockConfiguration.fromJson(json)).toList();
        print('✅ [BlockConfigurationService] ${configurations.length} configurações obtidas');
        return configurations;
      }

      print('❌ [BlockConfigurationService] Erro ao obter configurações: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ [BlockConfigurationService] Erro ao obter configurações: $e');
      return [];
    }
  }

  /// Obtém o limite de dias bloqueados para um ministério (com fallback para padrão)
  static Future<int> getMaxBlockedDays({
    required String tenantId,
    required String ministryId,
  }) async {
    final config = await getConfiguration(
      tenantId: tenantId,
      ministryId: ministryId,
    );
    
    if (config != null && config.isActive) {
      return config.maxBlockedDays;
    }
    
    // Fallback para configuração padrão
    return DefaultBlockConfiguration.defaultMaxBlockedDays;
  }
}
