
import 'package:common/p2p/protocol.dart';
import 'package:common/util.dart';
import 'package:esys_client/services/identity.dart';
import 'package:esys_client/services/states.dart';
import 'package:esys_client/v2/dashboard/dashboard.dart';
import 'package:esys_client/v2/dashboard/util/util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginDialog extends StatefulWidget {

   const LoginDialog({super.key});

   @override
State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {

   final TextEditingController
      _author = TextEditingController(),
      _password = TextEditingController();

   @override
   Widget build(BuildContext context) {
      return Dialog(
         child: Container(
            padding: const EdgeInsets.all(20),
            width: 400,
           child: Column(
              children: [
                  Text("Login", style: TextStyle(fontSize: 20)),
                 const SizedBox(height: 20,),
                 TextField(
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                       label: Text("Author"),
                    ),
                    controller: _author,
                    onSubmitted: (_) => _submit()
                 ),
                 const SizedBox(height: 20,),
                 TextField(
                    obscureText: true,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                       label: Text("Password"),
                    ),
                    controller: _password,
                    onSubmitted: (_) => _submit()
                 ),
                 const SizedBox(height: 20,),
                 Text("Incorrect password", style: TextStyle(color: Colors.red)),
                 const SizedBox(height:   20,),
                 labelIconButton("Signin", Icons.login, onPressed: _submit),
              ],
           ),
         )
      );
   }

   void _submit() async {
      if (_author.text.isEmpty || _password.text.isEmpty) return;

      var (pubkey, privkey) = genKeyPair();
      var nav = Navigator.of(context);
      IdentityService idService = context.read();
      var sm = ScaffoldMessenger.of(context);

      var id = await context.read<ServerConnection>().auth(
         _password.text,
         pubkey,
         _author.text.trim(),
      );

      if (id case PeerIdentity id) {
         idService.setIdentity(
            PrivatePeerIdentity(privkey, id)
         );
         nav.pushReplacement(MaterialPageRoute(
            builder: (_) => const Dashboard(),
         ));
      } else {
         sm.showSnackBar(SnackBar(
            content: Text("Incorrect"),
         ));
      }

   }
}