
abstract class GateState {
	void refresh();
}

class GateController {

	GateState? _state;
	set state (GateState state) => _state = state;

	void refresh() {
		_state?.refresh();
	}

}
