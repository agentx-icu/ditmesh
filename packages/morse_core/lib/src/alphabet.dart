/// International (ITU) Morse alphabet plus common prosigns.
///
/// Patterns use `.` for dit and `-` for dah. Prosigns are addressed by their
/// bracketed form, e.g. `<AR>`, `<SK>`, `<BT>`, `<SOS>`, and encode as one
/// run of elements with no character gap inside.
abstract final class MorseAlphabet {
  /// Upper-case letter / digit / punctuation -> pattern.
  ///
  /// Keys are single characters. Lookups are case-insensitive via [encodeChar].
  static const Map<String, String> international = <String, String>{
    // Letters.
    'A': '.-',
    'B': '-...',
    'C': '-.-.',
    'D': '-..',
    'E': '.',
    'F': '..-.',
    'G': '--.',
    'H': '....',
    'I': '..',
    'J': '.---',
    'K': '-.-',
    'L': '.-..',
    'M': '--',
    'N': '-.',
    'O': '---',
    'P': '.--.',
    'Q': '--.-',
    'R': '.-.',
    'S': '...',
    'T': '-',
    'U': '..-',
    'V': '...-',
    'W': '.--',
    'X': '-..-',
    'Y': '-.--',
    'Z': '--..',
    // Digits.
    '0': '-----',
    '1': '.----',
    '2': '..---',
    '3': '...--',
    '4': '....-',
    '5': '.....',
    '6': '-....',
    '7': '--...',
    '8': '---..',
    '9': '----.',
    // ITU punctuation.
    '.': '.-.-.-',
    ',': '--..--',
    '?': '..--..',
    "'": '.----.',
    '!': '-.-.--',
    '/': '-..-.',
    '(': '-.--.',
    ')': '-.--.-',
    '&': '.-...',
    ':': '---...',
    ';': '-.-.-.',
    '=': '-...-',
    '+': '.-.-.',
    '-': '-....-',
    '_': '..--.-',
    '"': '.-..-.',
    r'$': '...-..-',
    '@': '.--.-.',
  };

  /// Prosign name (without brackets, upper-case) -> pattern.
  static const Map<String, String> prosigns = <String, String>{
    'AR': '.-.-.', // end of message
    'SK': '...-.-', // end of contact
    'BT': '-...-', // break / new paragraph
    'KN': '-.--.', // go ahead, named station only
    'AS': '.-...', // wait
    'SN': '...-.', // understood
    'SOS': '...---...', // distress
    'CT': '-.-.-', // start of transmission
    'HH': '........', // error
  };

  /// Reverse lookup for [international], built once on first use.
  static final Map<String, String> _patternToChar = <String, String>{
    for (final MapEntry<String, String> e in international.entries)
      e.value: e.key,
  };

  /// Reverse lookup for [prosigns], built once on first use.
  static final Map<String, String> _patternToProsign = <String, String>{
    for (final MapEntry<String, String> e in prosigns.entries) e.value: e.key,
  };

  /// Pattern for one character, or null if unsupported. Case-insensitive.
  static String? encodeChar(String char) {
    if (char.isEmpty) return null;
    return international[char.toUpperCase()];
  }

  /// Pattern for a prosign name such as `AR` or `SOS`, or null.
  ///
  /// The name may optionally carry its angle brackets (`<AR>`), and is matched
  /// case-insensitively.
  static String? encodeProsign(String name) {
    var key = name.trim();
    if (key.startsWith('<') && key.endsWith('>') && key.length >= 2) {
      key = key.substring(1, key.length - 1);
    }
    if (key.isEmpty) return null;
    return prosigns[key.toUpperCase()];
  }

  /// Character (upper-case) for a pattern such as `.-`, or null.
  ///
  /// Never returns a prosign; use [decodeProsignPattern] for those.
  static String? decodePattern(String pattern) => _patternToChar[pattern];

  /// Prosign name for a pattern such as `.-.-.` (AR), or null.
  static String? decodeProsignPattern(String pattern) =>
      _patternToProsign[pattern];

  /// All characters the alphabet supports, in Koch teaching order (the LCWO
  /// sequence): `K M R S U A P T L O W I . N J E F 0 Y , V G 5 / Q 9 Z H 3 8`
  /// `B ? 4 2 7 C 1 D 6 X` followed by the prosigns `<BT> <SK> <AR>` in their
  /// bracketed form.
  static const List<String> kochOrder = <String>[
    'K', 'M', 'R', 'S', 'U', 'A', 'P', 'T', 'L', 'O', //
    'W', 'I', '.', 'N', 'J', 'E', 'F', '0', 'Y', ',', //
    'V', 'G', '5', '/', 'Q', '9', 'Z', 'H', '3', '8', //
    'B', '?', '4', '2', '7', 'C', '1', 'D', '6', 'X', //
    '<BT>', '<SK>', '<AR>',
  ];
}
