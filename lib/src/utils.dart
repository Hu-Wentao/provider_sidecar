/// 返回[StackTrace]特定一行的内容
String? selectLineAt(String trace, int line) {
  final reg = RegExp("#$line" r'\s*(.*)\n');
  final m = reg.allMatches(trace).first;
  return m.group(1);
}
extension StaceTraceX on StackTrace {
  lineAt(int line) => selectLineAt(toString(), line);
}
