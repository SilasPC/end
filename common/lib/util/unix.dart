/// A time in the distant future
/// In this case the year 3000.
const UNIX_FUTURE = 32503676400;

/// Five minutes in seconds (300)
const FIVE_MINS = 5 * 60;

extension on DateTime {
  int get unix => (millisecondsSinceEpoch / 1000).floor();

  static DateTime todayHMS(int h, int m, int s) {
    var dt = DateTime.now();
    var midnight = dt.unix - dt.hour * 3600 - dt.minute * 60 - dt.second;
    return fromUNIX(midnight + 3600 * h + 60 * m + s);
  }

  static DateTime fromUnix(int unix) =>
      DateTime.fromMillisecondsSinceEpoch(unix * 1000);

  String toHMS() => toIso8601String().substring(11, 19);
}

String toHMS(DateTime t) => t.toIso8601String().substring(11, 19);
int toUNIX(DateTime t) => (t.millisecondsSinceEpoch / 1000).floor();
String unixHMS(int unix) => toHMS(fromUNIX(unix));
DateTime fromUNIX(int unix) => DateTime.fromMillisecondsSinceEpoch(unix * 1000);
int nowUNIX() => toUNIX(DateTime.now());
int hmsToUNIX(String hms) {
  var dt = DateTime.now();
  var midnight = toUNIX(dt) - dt.hour * 3600 - dt.minute * 60 - dt.second;
  List<int> hms0 = hms.split(":").map(int.parse).toList();
  return midnight + 3600 * hms0[0] + 60 * hms0[1] + hms0[2];
}

DateTime fromHMS(int h, int m, int s) {
  var dt = DateTime.now();
  var midnight = toUNIX(dt) - dt.hour * 3600 - dt.minute * 60 - dt.second;
  return fromUNIX(midnight + 3600 * h + 60 * m + s);
}

String unixDifToMS(int dif,
    {bool addPlus = false, bool addMinus = true, bool zeroPad = true}) {
  int m = (dif.abs() / 60).floor();
  int s = dif.abs() % 60;
  String ms = m > 9 || !zeroPad ? "$m" : "0$m";
  String ss = s > 9 ? "$s" : "0$s";
  return (dif < 0 && addMinus)
      ? "-$ms:$ss"
      : (addPlus ? "+$ms:$ss" : "$ms:$ss");
}
