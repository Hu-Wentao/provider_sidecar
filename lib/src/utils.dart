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

/// 只保留位置信息
String onlyStack(String traceLine) {
  return traceLine.replaceAllMapped(RegExp(r"^.+\((package:.+\d)\)"), (m)=>'${m.group(1)}');
}

extension StaceTraceX on StackTrace {
  String? lineAt([int line = 0, bool trim = true]) {
    final l = selectLineAt(toString(), line);
    if (l == null) return null;
    return trim ? onlyStack(l) : l;
  }

  int? lineIndexBy(String content) => findLineIndexBy(toString(), content);

  String? parentLineBy(String content, {bool trim = true}) {
    final trace = StackTrace.current.toString();
    final index = findLineIndexBy(trace, content);
    if (index == null) return null;
    final l = selectLineAt(trace, index + 1);
    if (l == null) return null;
    return trim ? onlyStack(l) : l;
  }
}
