String? extractStorageKeyFromPublicUrl({
  required String publicUrl,
  required String bucket,
}) {
  // Match ".../storage/v1/object/public/<bucket>/(<key>)"
  final pattern = RegExp(
    r'/storage/v1/object/public/' + RegExp.escape(bucket) + r'/(.+)$',
  );
  final m = pattern.firstMatch(publicUrl);
  if (m != null && m.groupCount >= 1) {
    return m.group(1); // relative object key (can include folders)
  }
  return null;
}
