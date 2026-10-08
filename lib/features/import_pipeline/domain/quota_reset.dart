/// Rinnovo della quota giornaliera di Gemini (D-62): mezzanotte nel fuso del
/// Pacifico (America/Los_Angeles), con l'ora legale USA (dalla seconda
/// domenica di marzo alla prima domenica di novembre, alle 2:00 locali).
///
/// In Italia di solito sono le 9:00; nelle settimane in cui l'ora legale USA
/// ed europea non coincidono sono le 8:00.
library;

/// Prima mezzanotte del Pacifico strettamente successiva a [now], in UTC.
///
/// Accetta [now] locale o UTC. Il giorno in cui inizia l'ora legale la
/// mezzanotte è ancora in ora solare (il cambio è alle 2:00), il giorno in
/// cui finisce è ancora in ora legale.
DateTime nextGeminiQuotaReset(DateTime now) {
  final utc = now.toUtc();
  // Il giorno del Pacifico è al più un giorno indietro rispetto a quello UTC.
  var day = DateTime.utc(utc.year, utc.month, utc.day - 1);
  while (true) {
    final reset = _pacificMidnight(day);
    if (reset.isAfter(utc)) return reset;
    day = DateTime.utc(day.year, day.month, day.day + 1);
  }
}

/// Mezzanotte del giorno [day] (data del Pacifico, in UTC a mezzanotte)
/// espressa in UTC: 07:00 in ora legale (PDT), 08:00 in ora solare (PST).
DateTime _pacificMidnight(DateTime day) {
  final dstStart = _sunday(day.year, 3, 2);
  final dstEnd = _sunday(day.year, 11, 1);
  final dst = day.isAfter(dstStart) && !day.isAfter(dstEnd);
  return day.add(Duration(hours: dst ? 7 : 8));
}

/// [n]-esima domenica del mese [month], a mezzanotte UTC.
DateTime _sunday(int year, int month, int n) {
  final first = DateTime.utc(year, month);
  final firstSunday = 1 + (DateTime.sunday - first.weekday) % 7;
  return DateTime.utc(year, month, firstSunday + 7 * (n - 1));
}
