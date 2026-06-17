/// Strip customer contact fields before showing data to astrologers.
Map<String, dynamic> stripUserContactFields(Map<String, dynamic> data) {
  final copy = Map<String, dynamic>.from(data);
  for (final key in [
    'phone',
    'email',
    'userPhone',
    'userEmail',
    'contact',
    'mobile',
  ]) {
    copy.remove(key);
  }
  if (copy['user'] is Map) {
    copy['user'] = stripUserContactFields(
      Map<String, dynamic>.from(copy['user'] as Map),
      );
  }
  return copy;
}

String displayUserLabel(Map<String, dynamic> session) {
  final name = (session['userName'] ?? session['name'] ?? 'User').toString();
  if (name.trim().isEmpty) return 'User';
  return name.trim();
}
