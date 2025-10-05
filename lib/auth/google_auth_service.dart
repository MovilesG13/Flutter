import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final _googleSignIn = GoogleSignIn();
  static final _auth = FirebaseAuth.instance;

  static Future<UserCredential?> signInWithGoogle() async {
    // Cierra sesiones previas si quedaron corruptas (opcional)
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.disconnect();
      }
    } catch (_) {}

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // usuario canceló

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  static Future<void> signOutGoogle() async {
    try { await _googleSignIn.signOut(); } catch (_) {}
    await _auth.signOut();
  }
}
