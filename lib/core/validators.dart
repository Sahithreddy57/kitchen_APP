/// Simple email check: something@something.xx
bool isValidEmail(String s) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(s.trim());