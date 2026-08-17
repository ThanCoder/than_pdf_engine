String pdfiumErrorMessage(int code) {
  return switch (code) {
    0 => 'Success',
    1 => 'Unknown error',
    2 => 'File error',
    3 => 'Format error',
    4 => 'Password error',
    5 => 'Security error',
    6 => 'Page error',
    7 => 'XFA load error',
    8 => 'XFA layout error',
    _ => 'Unknown PDFium error ($code)',
  };
}
