import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  
  // Instancia de GoogleSignIn configurada para Android/iOS
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get user => _auth.authStateChanges();

  Future<UserCredential?> loginWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Error desconocido al iniciar sesión";
    }
  }

  Future<UserCredential?> registerWithEmail(String email, String password, String name) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );

      if (credential.user != null) {
        await _db.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'currency': 'S/',
        });
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Error desconocido al registrar";
    } catch (e) {
      throw "Fallo en Firestore: $e";
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Iniciar el flujo de autenticación de Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint("Google Sign-In cancelado por el usuario");
        return null;
      }

      // 2. Obtener los detalles de autenticación de la petición
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Crear una nueva credencial
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Iniciar sesión en Firebase con la credencial de Google
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // 5. Crear el perfil en Firestore si es nuevo
      if (userCredential.user != null) {
        final userDoc = await _db.collection('users').doc(userCredential.user!.uid).get();
        if (!userDoc.exists) {
          await _db.collection('users').doc(userCredential.user!.uid).set({
            'uid': userCredential.user!.uid,
            'name': userCredential.user!.displayName ?? 'Usuario',
            'email': userCredential.user!.email,
            'createdAt': FieldValue.serverTimestamp(),
            'currency': 'S/',
          });
        }
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint("Error de Firebase Auth: ${e.code} - ${e.message}");
      throw e.message ?? "Error de autenticación con Google";
    } catch (e) {
      debugPrint("Error general en Google Sign-In: $e");
      throw "Error al iniciar sesión con Google. Asegúrate de tener configurado el SHA-1 en Firebase.";
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint("Error en signOut: $e");
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "No se pudo enviar el correo de recuperación";
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw "No se encontró una sesión activa";
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "No se pudo cambiar la contraseña";
    }
  }
}
