///
/// 返回[StackTrace]特定行号[lineIndex] #n 的内容
String? selectLineAt(String trace, int lineIndex) {
  final reg = RegExp("#$lineIndex" r'\s*(.*)\n');
  final m = reg.allMatches(trace).first;
  return m.group(1);
}

///
/// 返回[StackTrace]包含特定内容[$name]的行号
int? findLineIndexBy(String trace, String content) {
  final reg = RegExp(r'#(\d+)\s*.*' "$content" r'.*\n');
  final m = reg.allMatches(trace).first;
  final r = m.group(1);
  return r == null ? null : int.tryParse(r);
}

extension StaceTraceX on StackTrace {
  String? lineAt(int line) => selectLineAt(toString(), line);

  int? lineIndexBy(String content) => findLineIndexBy(toString(), content);

  String? parentLineBy(String content) {
    final trace = StackTrace.current.toString();
    final index = findLineIndexBy(trace, content);
    return index == null ? null : selectLineAt(trace, index + 1);
  }
}
