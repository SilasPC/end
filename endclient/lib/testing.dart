// ignore_for_file: unused_element, dead_code

import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:common/models/glob.dart';
import 'package:common/util.dart';
import 'package:esys_client/equipage/equipage_tile.dart';
import 'package:esys_client/services/local_model.dart';
import 'package:esys_client/util/util.dart';
import 'package:esys_client/v2/dashboard/component/connection_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TestingPage extends StatelessWidget {
  const TestingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ListView.builder(
            itemBuilder: (context, i) => ListTile(
              title: Text("wack $i"),
            ),
          ),
          sheet(),
        ],
      ),
    );
  }

  LayoutBuilder sheet() {
    return LayoutBuilder(builder: (context, constraints) {
      final minSize = kToolbarHeight / constraints.maxHeight;
      const maxSize = 0.4;
      var dsctrl = DraggableScrollableController();
      return DraggableScrollableSheet(
        initialChildSize: minSize,
        minChildSize: minSize,
        maxChildSize: maxSize,
        snap: true,
        controller: dsctrl,
        builder: (context, ctrl) => Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                color: Theme.of(context).colorScheme.surface),
            child: SingleChildScrollView(
                controller: ctrl,
                child: Column(
                  children: [
                    const DragHandle(),
                    CountdownTimer(
                      size: 0.5 * constraints.maxWidth,
                      target: DateTime.now().add(Duration(seconds: 20)),
                      low: Duration(seconds: 10),
                      high: Duration(seconds: 30),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Text("Recovery",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ))),
      );
    });
  }
}

class CountDownThing extends StatefulWidget {
  final double? size;
  final Color primary, secondary;

  static const defaultPrimary = Colors.blue;
  static const defaultSecondary = Color.fromARGB(255, 12, 73, 122);

  const CountDownThing({
    super.key,
    this.size = 70,
    this.primary = defaultPrimary,
    this.secondary = defaultSecondary,
  });

  @override
  State<CountDownThing> createState() => _CountDownThingState();
}

class _CountDownThingState extends State<CountDownThing> {
  Timer? _timer;
  int left = 20;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        left -= 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    const divisions = 60;
    Color fg = widget.primary, bg = widget.secondary;
    if (left % (2 * divisions) >= divisions) {
      (fg, bg) = (bg, fg);
    }
    var val = (left % divisions) / divisions;
    if (val < 0) val += 1;
    return GestureDetector(
      onTap: () {
        setState(() {
          left = 10;
        });
      },
      child: SizedBox.square(
        dimension: widget.size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FittedBox(
                child: Text(
                  formatSeconds(left),
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
            CircularProgressIndicator(
              color: fg,
              backgroundColor: bg,
              value: val,
              strokeCap: StrokeCap.round,
              strokeAlign: -1,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamButton extends StatefulWidget {
  final bool enabled;
  final void Function({required bool pass, required bool retire})? onAccept;

  const _ExamButton({super.key, this.onAccept, this.enabled = true});

  @override
  State<_ExamButton> createState() => _ExamButtonState();
}

class _ExamButtonState extends State<_ExamButton> {
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
            selected: {if (btnState != null) btnState!},
            emptySelectionAllowed: true,
            segments: [
              ButtonSegment(value: (false, false), label: Text("FAIL")),
              ButtonSegment(
                value: (true, false),
                label: Text("PASS"),
              ),
              ButtonSegment(value: (true, true), label: Text("RETIRE")),
            ],
            onSelectionChanged: (val) {
              if (btnState == null && val.isNotEmpty) {
                setState(() {
                  btnState = val.first;
                });
                var (pass, retire) = val.first;
                widget.onAccept?.call(pass: pass, retire: retire);
              }
            },
          ));
    }
  }
}

class _DragSheet extends StatelessWidget {
  const _DragSheet({super.key});

  @override
  Widget build(BuildContext context) {
    var height = 100.0;
    var animTime = 0;
    return Scaffold(
      backgroundColor: Colors.grey,
      body: StatefulBuilder(
        builder: (BuildContext context, setState) {
          return GestureDetector(
            onVerticalDragStart: (drag) {
              animTime = 0;
            },
            onVerticalDragEnd: (drag) {
              setState(() {
                var newHeight = (height / 300).round() * 300.0;
                var dif = (height - newHeight).abs();
                var vel = drag.velocity.pixelsPerSecond.dy.abs();
                animTime = 30 * dif ~/ vel;
                print("$dif $vel $animTime");
                height = newHeight;
              });
            },
            onVerticalDragUpdate: (drag) {
              setState(() {
                height += drag.delta.dy;
              });
            },
            child: AnimatedContainer(
                duration: Duration(milliseconds: animTime),
                curve: Curves.bounceInOut,
                height: height,
                color: Colors.green),
          );
        },
      ),
    );
  }
}

class _ExamLayout extends StatelessWidget {
  const _ExamLayout({super.key});

  @override
  Widget build(BuildContext context) {
    LocalModel model = context.watch();
    Equipage selEq = model.model.equipages[138]!;
    bool open = false;

    return Scaffold(
        appBar: AppBar(
          backgroundColor:
              open ? Color.fromARGB(255, 144, 47, 63) : Colors.transparent,
          elevation: 0,
          actions: [ConnectionIndicator2(iconOnly: true)],
        ),
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                Color.fromARGB(255, 24, 23, 32),
                Color.fromARGB(255, 55, 50, 92),
                Color.fromARGB(255, 24, 23, 32),
              ])),
          child: Stack(children: [
            Column(
              children: [
                SizedBox(
                  height: EquipageTile.height + 18,
                ),
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
                              /* boxShadow: [BoxShadow(
															blurStyle: BlurStyle.inner,
															blurRadius: 10,
															color: Colors.white24,
														)], */
                              borderRadius: BorderRadius.circular(24),
                              color: Color.fromARGB(104, 255, 0, 76),
                            ),
                            alignment: Alignment.center,
                            child: Text("awdw"))
                    ],
                  ),
                )),
                _ExamButton()
              ],
            ),
            if (open)
              ModalBarrier(
                color: Colors.black54,
              ),
            Column(
              children: [
                Container(
                    height: open ? 400 : null,
                    padding: EdgeInsets.only(top: open ? 0 : 30),
                    decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.vertical(bottom: Radius.circular(24)),
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.fromARGB(255, 144, 47, 63),
                              Color.fromARGB(255, 223, 51, 88),
                              Color.fromARGB(255, 185, 36, 61),
                            ]),
                        boxShadow: [
                          BoxShadow(
                              offset: Offset(0, 3),
                              blurRadius: 3,
                              color: Colors.black38)
                        ]),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (open)
                        Expanded(
                          child: ListView(
                            children: [
                              for (var eq in context
                                  .read<LocalModel>()
                                  .model
                                  .equipages
                                  .values)
                                if (eq == selEq)
                                  Transform.scale(
                                      scale: 1.07,
                                      child: Container(
                                        decoration: BoxDecoration(
                                            color:
                                                Color.fromARGB(25, 255, 0, 191),
                                            boxShadow: [
                                              BoxShadow(
                                                  blurStyle: BlurStyle.outer,
                                                  blurRadius: 3),
                                            ]),
                                        child: EquipageTile(eq),
                                      ))
                                else
                                  EquipageTile(eq)
                            ],
                          ),
                        ),
                      if (!open) EquipageTile(selEq),
                      Container(
                          alignment: Alignment.center,
                          decoration: open
                              ? BoxDecoration(
                                  borderRadius: BorderRadius.vertical(
                                      bottom: Radius.circular(24)),
                                  color: Color.fromARGB(255, 144, 47, 63),
                                  /* boxShadow: [
															BoxShadow(
																blurStyle: BlurStyle.outer,
																offset: Offset(0, -1),
																blurRadius: 3
															)
														], */
                                )
                              : null,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8, top: 8),
                            width: 30,
                            height: 5,
                            decoration: BoxDecoration(
                              /* boxShadow: [
																	BoxShadow(
																		blurStyle: BlurStyle.inner,
																		blurRadius: 5,
																	)
																], */
                              backgroundBlendMode: BlendMode.lighten,
                              borderRadius: BorderRadius.circular(5),
                              color: Colors.white54,
                            ),
                          ))
                    ])),
                if (open)
                  Expanded(
                    child: Center(
                      child: CarouselSlider(
                          options: CarouselOptions(
                            height: 200,
                            enlargeCenterPage: true,
                          ),
                          items: List.filled(
                              3,
                              Container(
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color.fromARGB(255, 109, 18, 56),
                                          Color.fromARGB(255, 175, 44, 99),
                                          Color.fromARGB(255, 109, 18, 56),
                                        ]),
                                    borderRadius: BorderRadius.circular(20)),
                                width: 300,
                              ))),
                    ),
                  )
              ],
            ),
          ]),
        ));
  }
}
