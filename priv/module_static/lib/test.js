(function() {
  function sq(x) {
    return x * x;
  }
  function max(x, y) {
      return Math.max(x, y);
  }
  function documentTest(msg) {
    document.write('msg')
  }
  return {
    sq: sq,
    max: max,
    document_test: documentTest
  }
})();
