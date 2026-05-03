import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço responsável pelo gerenciamento de arquivos no Supabase Storage.
class MediaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Nome do bucket configurado no Supabase
  static const String _bucketName = 'avatars';

  /// Faz o upload de uma imagem de perfil e retorna a URL pública.
  /// O caminho será: avatars/{uid}/profile_{timestamp}.png
  Future<String?> uploadAvatar({
    required String uid,
    required File imageFile,
  }) async {
    try {
      final String fileExt = imageFile.path.split('.').last.toLowerCase();
      final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      
      // O caminho DEVE começar com o UID para respeitar a política de RLS
      // "Give users access to only their own folder"
      final String path = '$uid/$fileName';

      // 1. Faz o upload para o Storage
      await _supabase.storage.from(_bucketName).upload(
            path,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      // 2. Obtém a URL pública
      final String publicUrl = _supabase.storage.from(_bucketName).getPublicUrl(path);

      debugPrint('>>> [MediaService] Upload concluído: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('>>> [MediaService] Erro no upload: $e');
      return null;
    }
  }

  /// Remove uma imagem antiga do Storage (opcional para manter o bucket limpo)
  Future<void> deleteFile(String url) async {
    try {
      // Extrai o path relativo da URL pública
      // Ex: avatars/uid/file.png -> uid/file.png
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      final int bucketIdx = pathSegments.indexOf(_bucketName);
      
      if (bucketIdx != -1 && bucketIdx < pathSegments.length - 1) {
        final String path = pathSegments.sublist(bucketIdx + 1).join('/');
        await _supabase.storage.from(_bucketName).remove([path]);
        debugPrint('>>> [MediaService] Arquivo removido: $path');
      }
    } catch (e) {
      debugPrint('>>> [MediaService] Erro ao deletar arquivo: $e');
    }
  }
}