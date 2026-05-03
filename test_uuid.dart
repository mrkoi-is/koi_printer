void main() {
  bool _isSystemUuid(String uuid) {
    final lower = uuid.toLowerCase();
    print('Testing: $lower');
    if (lower.endsWith('-0000-1000-8000-00805f9b34fb')) {
      if (lower.startsWith('000018')) return true;
      if (lower.startsWith('00002a')) return true;
    }
    return false;
  }

  print('1800: ${_isSystemUuid('00001800-0000-1000-8000-00805f9b34fb')}');
  print('2A00: ${_isSystemUuid('00002a00-0000-1000-8000-00805f9b34fb')}');
  
  // What if flutter_blue_plus Guid.toString() does not include dashes?
  print('No dashes: ${_isSystemUuid('0000180000001000800000805f9b34fb')}');
}
