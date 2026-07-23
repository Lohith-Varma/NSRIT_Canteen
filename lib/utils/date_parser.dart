import 'package:cloud_firestore/cloud_firestore.dart';

DateTime parseModelDate(dynamic value, {DateTime? fallback}) {
  final fallbackDate = fallback ?? DateTime.now();
  if (value == null || value == '') return fallbackDate;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value) ?? fallbackDate;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  return DateTime.tryParse(value.toString()) ?? fallbackDate;
}

DateTime? parseOptionalModelDate(dynamic value) {
  if (value == null || value == '') return null;
  return parseModelDate(value);
}
