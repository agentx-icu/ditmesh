/// Built-in vocabularies for [WordDrill] and [QsoDrill].
///
/// Everything is upper-case and contains only A-Z / 0-9 so any word can be
/// checked against a Koch lesson's symbol set with `MorseText.usesOnly`.
abstract final class WordLists {
  /// Roughly 300 of the most common English words plus a few radio words.
  static const List<String> commonWords = <String>[
    'THE', 'BE', 'TO', 'OF', 'AND', 'A', 'IN', 'THAT', 'HAVE', 'I', //
    'IT', 'FOR', 'NOT', 'ON', 'WITH', 'HE', 'AS', 'YOU', 'DO', 'AT', //
    'THIS', 'BUT', 'HIS', 'BY', 'FROM', 'THEY', 'WE', 'SAY', 'HER', 'SHE', //
    'OR',
    'AN',
    'WILL',
    'MY',
    'ONE',
    'ALL',
    'WOULD',
    'THERE',
    'THEIR',
    'WHAT', //
    'SO', 'UP', 'OUT', 'IF', 'ABOUT', 'WHO', 'GET', 'WHICH', 'GO', 'ME', //
    'WHEN',
    'MAKE',
    'CAN',
    'LIKE',
    'TIME',
    'NO',
    'JUST',
    'HIM',
    'KNOW',
    'TAKE', //
    'PEOPLE', 'INTO', 'YEAR', 'YOUR', 'GOOD', 'SOME', 'COULD', 'THEM', 'SEE', //
    'OTHER', 'THAN', 'THEN', 'NOW', 'LOOK', 'ONLY', 'COME', 'ITS', 'OVER', //
    'THINK', 'ALSO', 'BACK', 'AFTER', 'USE', 'TWO', 'HOW', 'OUR', 'WORK', //
    'FIRST', 'WELL', 'WAY', 'EVEN', 'NEW', 'WANT', 'BECAUSE', 'ANY', 'THESE', //
    'GIVE', 'DAY', 'MOST', 'US', 'IS', 'ARE', 'WAS', 'WERE', 'BEEN', 'HAS', //
    'HAD', 'DID', 'SAID', 'MAN', 'WOMAN', 'CHILD', 'WORLD', 'LIFE', 'HAND', //
    'PART', 'PLACE', 'CASE', 'WEEK', 'COMPANY', 'SYSTEM', 'PROGRAM', //
    'QUESTION',
    'NUMBER',
    'NIGHT',
    'POINT',
    'HOME',
    'WATER',
    'ROOM',
    'MOTHER', //
    'AREA',
    'MONEY',
    'STORY',
    'FACT',
    'MONTH',
    'LOT',
    'RIGHT',
    'STUDY',
    'BOOK', //
    'EYE',
    'JOB',
    'WORD',
    'BUSINESS',
    'ISSUE',
    'SIDE',
    'KIND',
    'HEAD',
    'HOUSE', //
    'SERVICE', 'FRIEND', 'FATHER', 'POWER', 'HOUR', 'GAME', 'LINE', 'END', //
    'MEMBER', 'LAW', 'CAR', 'CITY', 'NAME', 'TEAM', 'MINUTE', 'IDEA', 'KID', //
    'BODY', 'PARENT', 'FACE', 'LEVEL', 'OFFICE', 'DOOR', 'HEALTH', 'PERSON', //
    'ART',
    'WAR',
    'HISTORY',
    'PARTY',
    'RESULT',
    'CHANGE',
    'MORNING',
    'REASON', //
    'GIRL', 'GUY', 'MOMENT', 'AIR', 'TEACHER', 'FORCE', 'FOOT', 'BOY', 'AGE', //
    'PROCESS', 'MUSIC', 'MARKET', 'SENSE', 'NATION', 'PLAN', 'INTEREST', //
    'EFFECT', 'CLASS', 'CONTROL', 'CARE', 'FIELD', 'ROLE', 'EFFORT', 'RATE', //
    'HEART', 'SHOW', 'LEADER', 'LIGHT', 'VOICE', 'WIFE', 'MIND', 'PRICE', //
    'REPORT',
    'SON',
    'VIEW',
    'TOWN',
    'ROAD',
    'ARM',
    'VALUE',
    'ACTION',
    'MODEL', //
    'SEASON', 'TAX', 'PLAYER', 'RECORD', 'PAPER', 'SPACE', 'GROUND', 'FORM', //
    'EVENT',
    'MATTER',
    'CENTER',
    'COUPLE',
    'SITE',
    'PROJECT',
    'STAR',
    'TABLE', //
    'NEED', 'COURT', 'OIL', 'COST', 'FIGURE', 'STREET', 'IMAGE', 'PHONE', //
    'DATA', 'PICTURE', 'PRACTICE', 'PIECE', 'LAND', 'PRODUCT', 'DOCTOR', //
    'WALL', 'NEWS', 'TEST', 'NORTH', 'SOUTH', 'EAST', 'WEST', 'LOVE', 'STEP', //
    'BABY', 'TYPE', 'RADIO', 'ANTENNA', 'SIGNAL', 'CODE', 'KEY', 'SEND', //
    'COPY', 'FAST', 'SLOW', 'RAIN', 'SUN', 'WIND', 'SNOW', 'COLD', 'WARM', //
    'HOT', 'OLD', 'BIG', 'SMALL', 'LONG', 'HIGH', 'LOW', 'OPEN', 'CLOSE', //
    'RUN', 'WALK', 'READ', 'WRITE', 'HEAR', 'CALL', 'TALK', 'MEET', 'HELP', //
    'KEEP', 'START', 'STOP', 'TURN', 'MOVE', 'LIVE', 'PLAY', 'PAY', 'BUY', //
    'TRY', 'ASK', 'TELL', 'FEEL', 'LEAVE', 'PUT', 'MEAN', 'LET', 'BEGIN', //
    'SEEM', 'STAND', 'LOSE', 'ADD', 'SIT', 'WAIT', 'CUT', 'EAT', 'DRINK', //
    'ONCE', 'MORE', 'VERY', 'STILL', 'HERE', 'MUCH', 'NEVER', 'AGAIN', 'OFF', //
    'DOWN', 'WHERE', 'WHY', 'EACH', 'SAME', 'FEW', 'MANY', 'LAST', 'NEXT', //
    'BEST', 'FREE', 'TRUE', 'REAL', 'FULL', 'LATE', 'EARLY', 'QUIET', 'ZERO', //
    'QUICK', 'JUMP', 'FOX', 'LAZY', 'DOG', 'VEX', 'JAZZ', 'ZONE', 'QUIZ',
  ];

  /// Common CW abbreviations, prosign-free (prosigns live in
  /// `MorseAlphabet.prosigns`).
  static const List<String> cwAbbreviations = <String>[
    'CQ',
    'DE',
    'K',
    'KN',
    '73',
    '88',
    'TU',
    'AGN',
    'ANT',
    'BK',
    'BTU',
    'CUL', //
    'ES', 'FB', 'GA', 'GE', 'GM', 'HR', 'HW', 'NR', 'OM', 'PSE', 'PWR', 'R', //
    'RIG', 'RST', 'SRI', 'TNX', 'UR', 'WX', 'XYL', 'YL',
  ];

  /// The Q-codes heard on the air every day (meanings in the app reference).
  static const List<String> qCodes = <String>[
    'QRG', 'QRL', 'QRM', 'QRN', 'QRO', 'QRP', 'QRQ', 'QRS', 'QRT', 'QRU', //
    'QRV', 'QRX', 'QRZ', 'QSB', 'QSK', 'QSL', 'QSO', 'QSY', 'QTH', 'QTR',
  ];

  /// Short operator names as used in QSO exchanges.
  static const List<String> operatorNames = <String>[
    'BOB', 'TOM', 'JIM', 'JOE', 'DAN', 'RON', 'KEN', 'DON', 'RAY', 'SAM', //
    'ANN', 'SUE', 'MAY', 'KAY', 'JAN', 'LEE', 'MAX', 'ED', 'AL', 'BEN', //
    'HANS',
    'KLAUS',
    'PETER',
    'PAUL',
    'MARK',
    'JOHN',
    'DAVE',
    'MIKE',
    'STEVE', //
    'CARL', 'ERIC', 'FRED', 'GARY', 'LUIS', 'IVAN', 'YURI', 'OLAF', 'NILS',
  ];

  /// City names used for QTH in QSO exchanges.
  static const List<String> qthNames = <String>[
    'BOSTON', 'DENVER', 'DALLAS', 'MIAMI', 'SEATTLE', 'CHICAGO', 'AUSTIN', //
    'LONDON',
    'LEEDS',
    'YORK',
    'BERLIN',
    'HAMBURG',
    'MUNICH',
    'PARIS',
    'LYON', //
    'ROME', 'MILAN', 'MADRID', 'LISBON', 'OSLO', 'BERGEN', 'MALMO', 'VIENNA', //
    'PRAGUE', 'WARSAW', 'TOKYO', 'OSAKA', 'SYDNEY', 'PERTH', 'TORONTO', //
    'OTTAWA', 'AUCKLAND', 'DUBLIN', 'CORK', 'ZURICH', 'BERN', 'HELSINKI',
  ];

  /// Rigs and antennas mentioned in a rag-chew.
  static const List<String> rigNames = <String>[
    'K3',
    'KX3',
    'KX2',
    'IC7300',
    'IC705',
    'FT991',
    'FTDX10',
    'TS590',
    'TS890', //
    'QCX', 'QMX', 'K2', 'HW8',
  ];

  static const List<String> antennaNames = <String>[
    'DIPOLE', 'VERTICAL', 'YAGI', 'LOOP', 'EFHW', 'G5RV', 'HEXBEAM', 'WIRE', //
    'BEAM', 'DOUBLET', 'INV VEE', 'RANDOM WIRE',
  ];

  /// Signal reports; both full and cut-number forms.
  static const List<String> rstReports = <String>[
    '599',
    '5NN',
    '579',
    '559',
    '589',
    '569',
    '449',
    '539',
  ];
}
