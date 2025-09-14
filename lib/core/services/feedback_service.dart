import 'package:flutter/material.dart';
import 'package:servus_app/shared/widgets/servus_snackbar.dart';

enum FeedbackType { success, error, warning, info }

class FeedbackService {
  static void showSuccess(BuildContext context, String message) {
    showServusSnack(
      context,
      message: message,
      type: ServusSnackType.success,
    );
  }

  static void showError(BuildContext context, String message) {
    showServusSnack(
      context,
      message: message,
      type: ServusSnackType.error,
    );
  }

  static void showWarning(BuildContext context, String message) {
    showServusSnack(
      context,
      message: message,
      type: ServusSnackType.warning,
    );
  }

  static void showInfo(BuildContext context, String message) {
    showServusSnack(
      context,
      message: message,
      type: ServusSnackType.info,
    );
  }

  // Métodos específicos para operações CRUD
  static void showCreateSuccess(BuildContext context, String itemName) {
    showSuccess(context, '$itemName criado com sucesso!');
  }

  static void showUpdateSuccess(BuildContext context, String itemName) {
    showSuccess(context, '$itemName atualizado com sucesso!');
  }

  static void showDeleteSuccess(BuildContext context, String itemName) {
    showSuccess(context, '$itemName removido com sucesso!');
  }

  static void showCreateError(BuildContext context, String itemName) {
    showError(context, 'Erro ao criar $itemName. Tente novamente.');
  }

  static void showUpdateError(BuildContext context, String itemName) {
    showError(context, 'Erro ao atualizar $itemName. Tente novamente.');
  }

  static void showDeleteError(BuildContext context, String itemName) {
    showError(context, 'Erro ao remover $itemName. Tente novamente.');
  }

  static void showLoadError(BuildContext context, String itemName) {
    showError(context, 'Erro ao carregar $itemName. Tente novamente.');
  }

  static void showNetworkError(BuildContext context) {
    showError(context, 'Erro de conexão. Verifique sua internet.');
  }

  static void showAuthError(BuildContext context) {
    showError(context, 'Erro de autenticação. Faça login novamente.');
  }

  static void showValidationError(BuildContext context, String message) {
    showWarning(context, message);
  }
}
