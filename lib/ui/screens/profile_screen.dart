import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/colors.dart';
import '../../services/auth_service.dart';
import '../../services/settings_provider.dart';
import 'welcome_screen.dart';
import 'edit_profile_screen.dart';
import 'security_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showFeatureUnderDevelopment(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("La función '$feature' estará disponible próximamente")),
    );
  }

  void _showThemeDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tema de la app"),
        backgroundColor: Theme.of(context).colorScheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogItem(context, "Claro", Icons.light_mode_outlined, () => settings.setThemeMode(ThemeMode.light)),
            _buildDialogItem(context, "Oscuro", Icons.dark_mode_outlined, () => settings.setThemeMode(ThemeMode.dark)),
            _buildDialogItem(context, "Sistema", Icons.settings_suggest_outlined, () => settings.setThemeMode(ThemeMode.system)),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      onTap: () {
        onTap();
        Navigator.pop(context);
      },
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Seleccionar Idioma"),
        backgroundColor: Theme.of(context).colorScheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogItem(context, "Español", Icons.language, () => settings.setLanguage("Español")),
            _buildDialogItem(context, "English", Icons.language, () => settings.setLanguage("English")),
          ],
        ),
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Seleccionar Moneda"),
        backgroundColor: Theme.of(context).colorScheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogItem(context, "Soles (S/)", Icons.monetization_on_outlined, () => settings.setCurrency("Soles (S/)")),
            _buildDialogItem(context, "Dólares (\$)", Icons.attach_money_outlined, () => settings.setCurrency("Dólares (\$)")),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context);
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("No se encontró sesión activa")));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "Mi cuenta",
          style: theme.appBarTheme.titleTextStyle,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.settings_outlined, color: theme.iconTheme.color),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.hasData && snapshot.data!.exists 
              ? snapshot.data!.data() as Map<String, dynamic> 
              : <String, dynamic>{};
          
          final String name = userData['name'] ?? "Usuario";
          final String email = userData['email'] ?? currentUser.email ?? "Sin correo";
          
          // Fix for initials logic to handle short names and avoid RangeError
          String initials = "??";
          if (name.isNotEmpty) {
            if (name.length >= 2) {
              initials = name.substring(0, 2).toUpperCase();
            } else {
              initials = name[0].toUpperCase();
            }
          }
          
          String memberSince = "Mar 2024";
          if (userData['createdAt'] != null) {
            Timestamp t = userData['createdAt'];
            DateTime date = t.toDate();
            List<String> months = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"];
            memberSince = "${months[date.month - 1]} ${date.year}";
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserHeader(context, name, email, initials),
                const SizedBox(height: 24),
                _buildStatusCards(context, memberSince),
                const SizedBox(height: 32),
                Text(
                  "Cuenta",
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                _buildSectionContainer(context, [
                  _buildMenuItem(
                    context, 
                    Icons.person_outline, 
                    "Información personal", 
                    "Edita tus datos personales", 
                    Colors.green,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
                  ),
                  _buildMenuItem(
                    context,
                    Icons.lock_outline,
                    "Seguridad",
                    "Cambia tu contraseña y más",
                    Colors.blue,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SecurityScreen())),
                  ),
                  _buildMenuItem(
                    context,
                    Icons.notifications_none,
                    "Notificaciones",
                    "Gestiona tus alertas y preferencias",
                    Colors.purple,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())),
                  ),
                  _buildMenuItem(
                    context, 
                    Icons.credit_card, 
                    "Métodos de pago", 
                    "Administra tus tarjetas y cuentas", 
                    Colors.orange,
                    onTap: () => _showFeatureUnderDevelopment(context, "Métodos de pago"),
                  ),
                  _buildMenuItem(
                    context, 
                    Icons.cloud_download_outlined, 
                    "Exportar datos", 
                    "Descarga tu información financiera", 
                    Colors.cyan,
                    onTap: () => _showFeatureUnderDevelopment(context, "Exportar datos"),
                  ),
                ]),
                const SizedBox(height: 32),
                Text(
                  "Preferencias",
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                _buildSectionContainer(context, [
                  _buildPreferenceItem(
                    context, 
                    Icons.dark_mode_outlined, 
                    "Tema de la app", 
                    settings.themeName, 
                    Colors.deepPurpleAccent,
                    onTap: () => _showThemeDialog(context, settings),
                  ),
                  _buildPreferenceItem(
                    context, 
                    Icons.language, 
                    "Idioma", 
                    settings.language, 
                    Colors.teal,
                    onTap: () => _showLanguageDialog(context, settings),
                  ),
                  _buildPreferenceItem(
                    context, 
                    Icons.monetization_on_outlined, 
                    "Moneda", 
                    settings.currency, 
                    Colors.green,
                    onTap: () => _showCurrencyDialog(context, settings),
                  ),
                ]),
                const SizedBox(height: 32),
                _buildSectionContainer(context, [
                  ListTile(
                    onTap: () async {
                      await authService.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                          (route) => false,
                        );
                      }
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.logout, color: Colors.orange),
                    ),
                    title: const Text("Cerrar sesión", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    trailing: Icon(Icons.arrow_forward_ios, color: theme.textTheme.bodyMedium?.color, size: 14),
                  ),
                ]),
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      Text("Versión 1.2.0", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Hecho con ", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
                          const Icon(Icons.favorite, color: Colors.greenAccent, size: 14),
                          Text(" para tu bienestar financiero.", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionContainer(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildUserHeader(BuildContext context, String name, String email, String initials) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.accentGreen.withValues(alpha: 0.2),
                child: Text(
                  initials,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.accentGreen),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: theme.colorScheme.secondary, shape: BoxShape.circle),
                  child: Icon(Icons.camera_alt, size: 16, color: theme.iconTheme.color),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(email, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium, size: 16, color: AppColors.accentGreen),
                      SizedBox(width: 6),
                      Text("Plan Premium", style: TextStyle(color: AppColors.accentGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: theme.textTheme.bodyMedium?.color, size: 16),
        ],
      ),
    );
  }

  Widget _buildStatusCards(BuildContext context, String memberSince) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatusItem(context, Icons.account_balance_wallet_outlined, "Miembro desde", memberSince),
          _buildDivider(context),
          _buildStatusItem(context, Icons.verified_user_outlined, "Seguridad", "Activa", valueColor: AppColors.accentGreen),
          _buildDivider(context),
          _buildStatusItem(context, Icons.star_outline, "Puntos", "1,250"),
        ],
      ),
    );
  }

  Widget _buildStatusItem(BuildContext context, IconData icon, String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accentGreen, size: 24),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(height: 40, width: 1, color: Theme.of(context).dividerColor);
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String subtitle, Color iconColor, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
      trailing: Icon(Icons.arrow_forward_ios, color: theme.textTheme.bodyMedium?.color, size: 14),
      onTap: onTap,
    );
  }

  Widget _buildPreferenceItem(BuildContext context, IconData icon, String title, String currentVal, Color iconColor, {required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(currentVal, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14)),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios, color: theme.textTheme.bodyMedium?.color, size: 14),
        ],
      ),
      onTap: onTap,
    );
  }
}
