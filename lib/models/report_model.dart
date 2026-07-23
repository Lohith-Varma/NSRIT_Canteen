class ReportModel {
  final String title;
  final String type;
  final DateTime generatedAt;
  final List<String> columns;
  final List<List<String>> rows;

  const ReportModel({
    required this.title,
    required this.type,
    required this.generatedAt,
    required this.columns,
    required this.rows,
  });

  String toCsv() {
    final buffer = StringBuffer();
    buffer.writeln(columns.map(_escape).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(_escape).join(','));
    }
    return buffer.toString();
  }

  String toPrintableText() {
    final buffer = StringBuffer();
    buffer.writeln(title);
    buffer.writeln('Generated: ${generatedAt.toIso8601String()}');
    buffer.writeln('');
    buffer.writeln(columns.join(' | '));
    buffer.writeln('-' * 72);
    for (final row in rows) {
      buffer.writeln(row.join(' | '));
    }
    return buffer.toString();
  }

  String _escape(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
