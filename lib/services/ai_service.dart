import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_config.dart';

/// Asistente financiero impulsado por Gemini (capa gratuita).
///
/// El system prompt es deliberadamente estricto: respuestas cortas y
/// enfocadas solo en finanzas personales, para proteger la cuota gratuita
/// de la API.
class AiService {
  static const String _systemPrompt =
      'Eres el asistente financiero de App Bank. Responde siempre de forma '
      'ultra concisa: máximo 2 párrafos cortos, sin listas largas ni rodeos. '
      'Enfócate únicamente en consultas sobre finanzas personales y bancarias '
      'del usuario (ahorros, gastos, inversiones, metas de ahorro, presupuesto). '
      'Si te preguntan algo fuera de ese alcance, indica amablemente que solo '
      'puedes ayudar con temas financieros de la app. Usa los datos financieros '
      'reales del usuario que se te proporcionen como contexto para dar '
      'respuestas concretas y personalizadas, sin inventar cifras.';

  static const String _insightsPrompt =
      'Eres un analista financiero de App Bank. Analiza el perfil financiero '
      'que se te entrega (saldo, metas y transacciones recientes) y genera '
      'entre 2 y 4 sugerencias o alertas breves y concretas (máximo 18 '
      'palabras cada una) sobre el comportamiento financiero del usuario, '
      'basadas únicamente en los datos reales proporcionados, sin inventar '
      'cifras. Responde ESTRICTAMENTE con un arreglo JSON de strings, sin '
      'texto adicional, sin explicaciones y sin bloques de código markdown. '
      'Ejemplo de formato exacto: ["¡Buen trabajo! Has reducido tus gastos en '
      'transporte un 10%", "Alerta: Tu meta \'Casa\' no ha recibido aportes '
      'este mes"]';

  GenerativeModel? _model;
  ChatSession? _chat;
  GenerativeModel? _insightsModel;

  GenerativeModel? get _modelInstance {
    if (geminiApiKey.isEmpty) return null;
    return _model ??= GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: geminiApiKey,
      systemInstruction: Content.system(_systemPrompt),
      generationConfig: GenerationConfig(
        maxOutputTokens: 220,
        temperature: 0.4,
      ),
    );
  }

  GenerativeModel? get _insightsModelInstance {
    if (geminiApiKey.isEmpty) return null;
    return _insightsModel ??= GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: geminiApiKey,
      systemInstruction: Content.system(_insightsPrompt),
      generationConfig: GenerationConfig(
        maxOutputTokens: 500,
        temperature: 0.5,
      ),
    );
  }

  void resetChat() {
    _chat = null;
  }

  Future<String> sendMessage(String message, {String? userContext}) async {
    final model = _modelInstance;
    if (model == null) {
      return "El asistente IA no está configurado: falta la API key de Gemini.";
    }

    _chat ??= model.startChat();

    final prompt = (userContext != null && userContext.isNotEmpty)
        ? "Contexto financiero actual del usuario:\n$userContext\n\nPregunta del usuario: $message"
        : message;

    try {
      final response = await _chat!.sendMessage(Content.text(prompt));
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        return "No pude generar una respuesta. Intenta reformular tu pregunta.";
      }
      return text.trim();
    } catch (e) {
      debugPrint('AiService error: $e');
      final msg = e.toString().toLowerCase();
      if (msg.contains('429') ||
          msg.contains('quota') ||
          msg.contains('resource_exhausted')) {
        return "Se alcanzó el límite gratuito de consultas por ahora. Intenta de nuevo en unos minutos.";
      }
      if (msg.contains('api key') ||
          msg.contains('400') ||
          msg.contains('403') ||
          msg.contains('permission')) {
        return "Hubo un problema con la configuración del asistente. Verifica la API key de Gemini.";
      }
      return "No se pudo contactar al asistente. Revisa tu conexión a internet e intenta de nuevo.";
    }
  }

  /// Genera un diagnóstico financiero a partir del perfil actual del usuario.
  /// Devuelve una lista de sugerencias concisas, o una lista con un único
  /// mensaje de error si algo falla.
  Future<List<String>> generateFinancialInsights(String profileContext) async {
    final model = _insightsModelInstance;
    if (model == null) {
      return ["El asistente IA no está configurado: falta la API key de Gemini."];
    }

    try {
      final response = await model.generateContent(
        [Content.text("Perfil financiero del usuario:\n$profileContext")],
      );
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        return ["No se pudo generar un diagnóstico. Intenta de nuevo más tarde."];
      }

      String cleaned = text.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned
            .replaceAll(RegExp(r'^```(json)?'), '')
            .replaceAll(RegExp(r'```$'), '')
            .trim();
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(cleaned);
      } catch (_) {
        decoded = null;
      }

      if (decoded is List) {
        final items = decoded.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
        if (items.isNotEmpty) return items;
      } else if (decoded is Map) {
        for (final value in decoded.values) {
          if (value is List) {
            final items = value.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
            if (items.isNotEmpty) return items;
          }
        }
      }

      // La respuesta pudo haberse cortado antes de cerrar el JSON (límite de
      // tokens) o no ser un arreglo estricto. Como respaldo, extraemos los
      // strings completos que sí alcanzaron a cerrarse con comillas.
      final matches = RegExp(r'"((?:[^"\\]|\\.)*)"').allMatches(cleaned);
      final extracted = matches
          .map((m) => m.group(1) ?? '')
          .where((s) => s.trim().isNotEmpty)
          .toList();
      if (extracted.isNotEmpty) return extracted;

      debugPrint('AiService insights: respuesta no interpretable: $cleaned');
      return ["No se pudo interpretar el diagnóstico generado."];
    } catch (e) {
      debugPrint('AiService insights error: $e');
      final msg = e.toString().toLowerCase();
      if (msg.contains('429') || msg.contains('quota') || msg.contains('resource_exhausted')) {
        return ["Se alcanzó el límite gratuito de consultas por ahora. Intenta de nuevo en unos minutos."];
      }
      return ["No se pudo generar el diagnóstico financiero. Revisa tu conexión e intenta de nuevo."];
    }
  }
}
