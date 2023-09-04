
abstract class GateState {
	void refresh();
}

// TODO: more idiomatic
class GateController {

	GateState? _state;
	set state (GateState state) => _state = state;

	void refresh() {
		_state?.refresh();
	}

}
