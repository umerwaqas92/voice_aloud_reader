bool get isInTest {
  var inTest = false;
  assert(() {
    inTest = true;
    return true;
  }());
  return inTest;
}

