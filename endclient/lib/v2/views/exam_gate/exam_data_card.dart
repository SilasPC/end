import 'package:common/models/glob.dart';
import 'package:esys_client/util/input/int_picker.dart';
import 'package:flutter/material.dart';

class ExamDataCard extends StatefulWidget {
  final void Function(VetData, bool, {bool retire}) submit;

  const ExamDataCard({super.key, required this.submit});

  @override
  State<ExamDataCard> createState() => _ExamDataCardState();
}

class _ExamDataCardState extends State<ExamDataCard> {
  VetData data = VetData.empty();

  void submit(bool passed, {bool retire = false}) {
    widget.submit(data, passed, retire: retire);
    setState(() {
      data = VetData.empty();
    });
  }

  @override
  Widget build(BuildContext context) => Card(
          child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          verticalDirection: VerticalDirection.up,
          children: [
            Row(
              children: [
                Flexible(
                  fit: FlexFit.tight,
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text("FAIL", style: TextStyle(fontSize: 20)),
                    onPressed: () => submit(false),
                  ),
                ),
                Flexible(
                    fit: FlexFit.tight,
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12)),
                        child:
                            const Text("PASS", style: TextStyle(fontSize: 20)),
                        onPressed: () => submit(true),
                      ),
                    )),
                Flexible(
                  fit: FlexFit.tight,
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text("RETIRE", style: TextStyle(fontSize: 20)),
                    onPressed: () => submit(true, retire: true),
                  ),
                )
              ],
            ),
            Expanded(
              child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    field(VetField.HR1, data.hr1,
                        (n) => setState(() => data.hr1 = n)),
                    field(VetField.HR2, data.hr2,
                        (n) => setState(() => data.hr2 = n)),
                    field(VetField.RESP, data.resp,
                        (n) => setState(() => data.resp = n)),
                    field(VetField.MUC_MEM, data.mucMem,
                        (n) => setState(() => data.mucMem = n)),
                    field(VetField.CAP, data.cap,
                        (n) => setState(() => data.cap = n)),
                    field(VetField.JUG, data.jug,
                        (n) => setState(() => data.jug = n)),
                    field(VetField.HYDR, data.hydr,
                        (n) => setState(() => data.hydr = n)),
                    field(VetField.GUT, data.gut,
                        (n) => setState(() => data.gut = n)),
                    field(VetField.SORE, data.sore,
                        (n) => setState(() => data.sore = n)),
                    field(VetField.WNDS, data.wounds,
                        (n) => setState(() => data.wounds = n)),
                    field(VetField.GAIT, data.gait,
                        (n) => setState(() => data.gait = n)),
                    field(VetField.ATT, data.attitude,
                        (n) => setState(() => data.attitude = n)),
                  ]),
            ),
          ],
        ),
      ));

  Widget field(VetField field, int? val, void Function(int? n) onChange) =>
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(8),
        ),
        onLongPress: () => onChange(null),
        onPressed: () {
          switch (field.type) {
            case VetFieldType.NUMBER:
              onChange(null);
              showDialog(
                  context: context,
                  builder: (context) => Dialog(
                      child: SizedBox(
                          width: 400,
                          height: 400,
                          child: IntPicker(
                            onAccept: (n) {
                              onChange(n);
                              Navigator.of(context).pop();
                            },
                          ))));
              break;
            default:
              if (val case int value) {
                val = (value + 1) % 4;
                if (val == 0) val = null;
              } else {
                val = 1;
              }
              onChange(val);
              break;
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              val != null ? field.withValue(val).toString() : "-",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(
              field.name,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
