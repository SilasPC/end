
import 'package:common/models/glob.dart';
import 'package:esys_client/equipage/equipage_tile.dart';
import 'package:flutter/material.dart';

class TestingPage extends StatefulWidget {
   const TestingPage({super.key});

  @override
  State<TestingPage> createState() => _TestingPageState();
}

class _TestingPageState extends State<TestingPage> {
   @override
   Widget build(BuildContext context) {
      return Scaffold(
         backgroundColor: Colors.red[300],
         appBar: AppBar(
            backgroundColor: Colors.red[600],
            elevation: 0,

         ),
         body: Container(
            decoration: BoxDecoration(
               gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                     Colors.redAccent,
                     Colors.red[200]!,
                     Colors.redAccent,
                  ]
               )
            ),
           child: Stack(

              children: [
                 Column(
                    children: [
                       SizedBox(height: 70,),
                       Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GridView.count(
                              clipBehavior: Clip.none,
                               mainAxisSpacing: 8,
                               crossAxisSpacing: 8,
                               crossAxisCount: 3,
                               children: [
                                  for (var _ in List.filled(12, 0))
                                  Container(
                                    decoration: BoxDecoration(
                                       boxShadow: [BoxShadow(
                                          offset: Offset(3, 3),
                                          blurRadius: 3,
                                          color: Colors.black26,
                                       )],
                                       borderRadius: BorderRadius.circular(24),
                                     color: Color.fromARGB(140, 190, 60, 51),
                                    ),
                                     alignment: Alignment.center,
                                     child: Text("awdw")
                                  )
                               ],
                            ),
                          )
                       ),
                       ExamButton()
                    ],
                 ),
                 Container(
                    decoration: BoxDecoration(
                       borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                       color: Colors.red[600],
                       boxShadow: [
                          BoxShadow(
                             offset: Offset(0, 3),
                             blurRadius: 3,
                             color: Colors.black38
                          )
                       ]
                    ),
                    child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                          EquipageTile(Equipage(
                           207, "Silas Pockendahl", "Aidah", Category(null, "MA", [], 0)
                          ))
                       ]
                    )
                 ),
              ]
           ),
         )
      );

   }
}

class ExamButton extends StatefulWidget {

   final bool enabled;
  final void Function({required bool pass, required bool retire})? onAccept;

  const ExamButton({super.key, this.onAccept, this.enabled = true});


  @override
  State<ExamButton> createState() => _ExamButtonState();
}

class _ExamButtonState extends State<ExamButton> {

   bool open = false;
   (bool, bool)? btnState = (false, false);

   @override
   Widget build(BuildContext context) {

      if (!widget.enabled) {
         open = false;
         btnState = null;
      }

      if (!open) {
         return ElevatedButton(
            child: Text("CONTINUE"),
            onPressed: () => setState(() {
              open = true;
            }),
         );
      } else {
         return TapRegion(
            onTapOutside: (_) {
               setState(() {
                 open = false;
                 btnState = null;
               });
            },
            child: SegmentedButton(
               showSelectedIcon: false,
               selected: { if (btnState != null) btnState! },
               emptySelectionAllowed: true,
               segments: [
                  ButtonSegment(
                     value: (false, false),
                     label: Text("FAIL")
                  ),
                  ButtonSegment(
                     value: (true, false),
                     label: Text("PASS"),
                  ),
                  ButtonSegment(
                     value: (true, true),
                     label: Text("RETIRE")
                  ),
               ],
               onSelectionChanged: (val) {
                  if (btnState == null && val.isNotEmpty) {
                     setState(() {
                       btnState = val.first;
                     });
                     var (pass, retire) = val.first;
                     widget.onAccept?.call(
                        pass: pass,
                        retire: retire
                     );
                  }
               },
            )
         );
      }

   }
}