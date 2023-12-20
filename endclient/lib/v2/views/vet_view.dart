import 'package:common/EnduranceEvent.dart';
import 'package:common/util/unix.dart';
import 'package:esys_client/services/identity.dart';
import 'package:esys_client/services/local_model.dart';
import 'package:esys_client/v2/views/timing_list_gate_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VetView extends StatelessWidget {
  const VetView({super.key});

  @override
  Widget build(BuildContext context) => TimingListGateView(
        predicate: (eq) => eq.status.isCOOLING,
        submit: (data) async {
          LocalModel model = context.read();
          final author = context.read<IdentityService>().author;
          List<EnduranceEvent> evs = [];
          for (var (eq, dt) in data) {
            evs.add(VetEvent(author, toUNIX(dt), eq.eid, eq.currentLoop));
          }
          await model.addSync(evs);
        },
      );
}
