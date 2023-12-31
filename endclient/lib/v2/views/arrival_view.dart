import 'package:common/EnduranceEvent.dart';
import 'package:common/util/unix.dart';
import 'package:esys_client/services/identity.dart';
import 'package:esys_client/services/local_model.dart';
import 'package:esys_client/v2/views/timing_list_gate_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ArrivalView extends StatelessWidget {
  const ArrivalView({super.key});

  @override
  Widget build(BuildContext context) => TimingListGateView(
        gateName: "ARRIVAL",
        predicate: (eq) => eq.status.isRIDING,
        submit: (data) async {
          LocalModel model = context.read();
          final author = context.read<IdentityService>().author!;
          List<EnduranceEvent> evs = [];
          for (var (eq, dt) in data) {
            evs.add(ArrivalEvent(author, toUNIX(dt), eq.eid, eq.currentLoop));
          }
          await model.addSync(evs);
        },
      );
}
