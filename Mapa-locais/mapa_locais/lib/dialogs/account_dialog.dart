import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/local_service.dart';

Future<bool?> showAccount(BuildContext context, Session session) =>
    showDialog<bool>(
      context: context,
      builder: (_) => AccountDialog(session: session),
    );

class AccountDialog extends StatefulWidget {
  const AccountDialog({super.key, required this.session});
  final Session session;
  @override
  State<AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<AccountDialog> {
  final email = TextEditingController(), password = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login(bool create) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final auth = FirebaseAuth.instance;
      if (create && auth.currentUser?.isAnonymous == true) {
        await auth.currentUser!.linkWithCredential(
          EmailAuthProvider.credential(
            email: email.text.trim(),
            password: password.text,
          ),
        );
      } else {
        await auth.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = mensagemErro(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: const Text('Conta e permissões'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.session.admin
                    ? 'Administrador: cadastro, edição e exclusão habilitados.'
                    : 'Visitante autenticado: consulte e favorite locais.',
              ),
              const SizedBox(height: 12),
              const Text(
                'O responsável pelo projeto pode liberar este UID pelo Console Firebase. O app não concede acesso administrativo.',
              ),
              const SizedBox(height: 8),
              SelectableText(
                widget.session.uid,
                style: const TextStyle(fontSize: 12),
              ),
              TextButton.icon(
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: widget.session.uid)),
                icon: const Icon(Icons.copy),
                label: const Text('Copiar UID'),
              ),
              const Divider(),
              const Text(
                'Para manter o acesso em outro celular, vincule uma conta antes de desinstalar.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: email,
                enabled: !busy,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: password,
                enabled: !busy,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha'),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed: busy ? null : () => login(false),
                    child: const Text('Entrar'),
                  ),
                  if (FirebaseAuth.instance.currentUser?.isAnonymous == true)
                    TextButton(
                      onPressed: busy ? null : () => login(true),
                      child: const Text('Vincular conta'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context, true),
          child: const Text('Atualizar permissões'),
        ),
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context, false),
          child: const Text('Fechar'),
        ),
      ],
    ),
  );
}
