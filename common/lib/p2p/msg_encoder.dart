
import 'dart:typed_data';

Uint8List encodeMsg(int seqNr, String msg, List<int> data)
	=> Uint8List.fromList([
		...Uint32List.fromList([seqNr])
			.buffer.asUint8List(),
		0,
		...msg.codeUnits,
		0,
		...data,
	]);

Uint8List encodeReply(int seqNr, List<int> data)
	=> Uint8List.fromList([
		...Uint32List.fromList([seqNr])
			.buffer.asUint8List(),
		1,
		...data,
	]);

(int, String, List<int>, bool) decodeMsg(List<int> data) {

	var seqNr = Uint8List.fromList(data.sublist(0,4)).buffer.asUint32List()[0];
	var isReply = data[4] == 1;
	var i = isReply ? 4 : data.indexOf(0, 5);
	var msg = isReply ? '' : String.fromCharCodes(data.skip(5).take(i-5));
	data = data.sublist(i+1);

	return (seqNr, msg, data, isReply);

}
