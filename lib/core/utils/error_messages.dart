/// Traduce errores comunes de Firebase/Firestore a mensajes claros en
/// español para mostrar al usuario en un SnackBar.
String friendlyFirestoreError(Object error) {
  final msg = error.toString().toLowerCase();
  if (msg.contains('permission-denied') || msg.contains('permission_denied')) {
    return "No tienes permiso para guardar esto. Verifica las reglas de seguridad "
        "de Firestore en Firebase Console (deben permitir leer/escribir en "
        "subcolecciones del usuario autenticado).";
  }
  if (msg.contains('unavailable') || msg.contains('network')) {
    return "No se pudo conectar. Revisa tu conexión a internet e inténtalo de nuevo.";
  }
  return "Ocurrió un error: $error";
}
