enum PdfiumStatus {
  success(0),
  unknownError(1),
  fileError(2),
  formatError(3),
  passwordError(4),
  securityError(5),
  pageError(6),
  xfaLoadError(7),
  xfaLayoutError(8),
  unrecognizedError(-1);

  const PdfiumStatus(this.code);

  final int code;

  static PdfiumStatus fromCode(int code) {
    return PdfiumStatus.values.firstWhere(
      (e) => e.code == code,
      orElse: () => PdfiumStatus.unrecognizedError,
    );
  }
}
