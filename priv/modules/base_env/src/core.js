'use strict';

function display(text) {
  let outputDiv = document.getElementById('output-div');
  let element = document.createElement('p');
  element.appendChild(document.createTextNode(text));
  outputDiv.appendChild(element);
}

function math_abs(x) {
  return Math.abs(x);
}