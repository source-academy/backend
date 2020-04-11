(function (exports) {
  'use strict';

  /*
   * @fileoverview gl-matrix - High performance matrix and vector operations
   * @author Brandon Jones
   * @author Colin MacKenzie IV
   * @version 2.2.2
   */
  (function(_global) {

    var shim = {};
    shim.exports = typeof window !== 'undefined' ? window : _global

    ;(function(exports) {
      /* Copyright (c) 2013, Brandon Jones, Colin MacKenzie IV. All rights reserved.

  Redistribution and use in source and binary forms, with or without modification,
  are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this
      list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation 
      and/or other materials provided with the distribution.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */

      if (!GLMAT_EPSILON) {
        var GLMAT_EPSILON = 0.000001;
      }

      if (!GLMAT_ARRAY_TYPE) {
        var GLMAT_ARRAY_TYPE = typeof Float32Array !== 'undefined' ? Float32Array : Array;
      }

      if (!GLMAT_RANDOM) {
        var GLMAT_RANDOM = Math.random;
      }

      /**
       * @class Common utilities
       * @name glMatrix
       */
      var glMatrix = {};

      /**
       * Sets the type of array used when creating new vectors and matrices
       *
       * @param {Type} type Array type, such as Float32Array or Array
       */
      glMatrix.setMatrixArrayType = function(type) {
        GLMAT_ARRAY_TYPE = type;
      };

      if (typeof exports !== 'undefined') {
        exports.glMatrix = glMatrix;
      }

      var degree = Math.PI / 180;

      /**
       * Convert Degree To Radian
       *
       * @param {Number} Angle in Degrees
       */
      glMatrix.toRadian = function(a) {
        return a * degree
      };
      /* Copyright (c) 2013, Brandon Jones, Colin MacKenzie IV. All rights reserved.

  Redistribution and use in source and binary forms, with or without modification,
  are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this
      list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation 
      and/or other materials provided with the distribution.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */

      /**
       * @class 2 Dimensional Vector
       * @name vec2
       */

      var vec2 = {};

      /**
       * Creates a new, empty vec2
       *
       * @returns {vec2} a new 2D vector
       */
      vec2.create = function() {
        var out = new GLMAT_ARRAY_TYPE(2);
        out[0] = 0;
        out[1] = 0;
        return out
      };

      /**
       * Creates a new vec2 initialized with values from an existing vector
       *
       * @param {vec2} a vector to clone
       * @returns {vec2} a new 2D vector
       */
      vec2.clone = function(a) {
        var out = new GLMAT_ARRAY_TYPE(2);
        out[0] = a[0];
        out[1] = a[1];
        return out
      };

      /**
       * Creates a new vec2 initialized with the given values
       *
       * @param {Number} x X component
       * @param {Number} y Y component
       * @returns {vec2} a new 2D vector
       */
      vec2.fromValues = function(x, y) {
        var out = new GLMAT_ARRAY_TYPE(2);
        out[0] = x;
        out[1] = y;
        return out
      };

      /**
       * Copy the values from one vec2 to another
       *
       * @param {vec2} out the receiving vector
       * @param {vec2} a the source vector
       * @returns {vec2} out
       */
      vec2.copy = function(out, a) {
        out[0] = a[0];
        out[1] = a[1];
        return out
      };

      /**
       * Set the components of a vec2 to the given values
       *
       * @param {vec2} out the receiving vector
       * @param {Number} x X component
       * @param {Number} y Y component
       * @returns {vec2} out
       */
      vec2.set = function(out, x, y) {
        out[0] = x;
        out[1] = y;
        return out
      };

      /**
       * Adds two vec2's
       *
       * @param {vec2} out the receiving vector
       * @param {vec2} a the first operand
       * @param {vec2} b the second operand
       * @returns {vec2} out
       */
      vec2.add = function(out, a, b) {
        out[0] = a[0] + b[0];
        out[1] = a[1] + b[1];
        return out
      };

      /**
       * Subtracts vector b from vector a
       *
       * @param {vec2} out the receiving vector
       * @param {vec2} a the first operand
       * @param {vec2} b the second operand
       * @returns {vec2} out
       */
      vec2.subtract = function(out, a, b) {
        out[0] = a[0] - b[0];
        out[1] = a[1] - b[1];
        return out
      };

      /**
       * Alias for {@link vec2.subtract}
       * @function
       */
      vec2.sub = vec2.subtract;

      /**
       * Multiplies two vec2's
       *
       * @param {vec2} out the receiving vector
       * @param {vec2} a the first operand
       * @param {vec2} b the second operand
       * @returns {vec2} out
       */
      vec2.multiply = function(out, a, b) {
        out[0] = a[0] * b[0];
        out[1] = a[1] * b[1];
        return out
      };

      /**
       * Alias for {@link vec2.multiply}
       * @function
       */
      vec2.mul = vec2.multiply;

      /**
       * Divides two vec2's
       *
       * @param {vec2} out the receiving vector
       * @param {vec2} a the first operand
       * @param {vec2} b the second operand
       * @returns {vec2} out
       */
      vec2.divide = function(out, a, b) {
        out[0] = a[0] / b[0];
        out[1] = a[1] / b[1];
        return out
      };

      /**
       * Alias for {@link vec2.divide}
       * @function
       */
      vec2.div = vec2.divide;

      /**
       * Returns the minimum of two vec2's
       *
       * @param {vec2} out the receiving vector
       * @param {vec2} a the first operand
       * @param {vec2} b the second operand
       * @returns {vec2} out
       */
      vec2.min = function(out, a, b) {
        out[0] = Math.min(a[0], b[0]);
        out[1] = Math.min(a[1], b[1]);
        return out
      };

      /**
       * Returns the maximum of two vec2's
       *
       * @param {vec2} out the receiving vector
       * @param {vec2} a the first operand
       * @param {vec2} b the second operand
       * @returns {vec2} out
       */
      vec2.max = function(out, a, b) {
        out[0] = Math.max(a[0], b[0]);
        out[1] = Math.max(a[1], b[1]);
        return out
      };

      /**
       * Scales a vec2 by a scalar number
       *
       * @param {vec2} out the receiving vector
       * @param {vec2} a the vector to scale
       * @param {Number} b amount to scale the vector by
       * @returns {vec2} out
       */
      vec2.scale = function(out, a, b) {
        out[0] = a[0] * b;
        out[1] = a[1] * b;
        return out
      };

      /**
       * Adds two vec2's after scaling the second operand by a scalar value
       *
       * @param {vec2} out the receiving vector
       * @param {vec2} a the first operand
       * @param {vec2} b the second operand
       * @param {Number} scale the amount to scale b by before adding
       * @returns {vec2} out
       */
      vec2.scaleAndAdd = function(out, a, b, scale) {
        out[0] = a[0] + b[0] * scale;
        out[1] = a[1] + b[1] * scale;
        return out
      };

      /**
       * Calculates the euclidian distance between two vec2's
       *
       * @param {vec2} a the first operand
       * @param {vec2} b the second operand
       * @returns {Number} distance between a and b
       */
      vec2.distance = function(a, b) {
        var x = b[0] - a[0],
          y = b[1] - a[1];
        return Math.sqrt(x * x + y * y)
      };

      /**
       * Alias for {@link vec2.distance}
       * @function
       */
      vec2.dist = vec2.distance;

      /**
       * Calculates the squared euclidian distance between two vec2's
       *
       * @param {vec2} a the first operand
       * @param {vec2} b the second operand
       * @returns {Number} squared distance between a and b
       */
      vec2.squaredDistance = function(a, b) {
        var x = b[0] - a[0],
          y = b[1] - a[1];
        return x * x + y * y
      };

      /**
       * Alias for {@link vec2.squaredDistance}
       * @function
       */
      vec2.sqrDist = vec2.squaredDistance;

      /**
       * Calculates the length of a vec2
       *
       * @param {vec2} a vector to calculate length of
       * @returns {Number} length of a
       */
      vec2.length = function(a) {
        var x = a[0],
          y = a[1];
        return Math.sqrt(x * x + y * y)
      };

      /**
       * Alias for {@link vec2.length}
       * @function
       */
      vec2.len = vec2.length;

      /**
       * Calculates the squared length of a vec2
       *
       * @param {vec2} a vector to calculate squared length of
       * @returns {Number} squared length of a
       */
      vec2.squaredLength = function(a) {
        var x = a[0],
          y = a[1];
        return x * x + y * y
      };

      /**
       * Alias for {@link vec2.squaredLength}
       * @function
       */
      vec2.sqrLen = vec2.squaredLength;

      /**
       * Negates the components of a vec2
       *
       * @param {vec2} out the receiving vector
       * @param {vec2} a vector to negate
       * @returns {vec2} out
       */
      vec2.negate = function(out, a) {
        out[0] = -a[0];
        out[1] = -a[1];
        return out
      };

      /**
       * Returns the inverse of the components of a vec2
       *
       * @param {vec2} out the receiving vector
       * @param {vec2} a vector to invert
       * @returns {vec2} out
       */
      vec2.inverse = function(out, a) {
        out[0] = 1.0 / a[0];
        out[1] = 1.0 / a[1];
        return out
      };

      /**
       * Normalize a vec2
       *
       * @param {vec2} out the receiving vector
       * @param {vec2} a vector to normalize
       * @returns {vec2} out
       */
      vec2.normalize = function(out, a) {
        var x = a[0],
          y = a[1];
        var len = x * x + y * y;
        if (len > 0) {
          //TODO: evaluate use of glm_invsqrt here?
          len = 1 / Math.sqrt(len);
          out[0] = a[0] * len;
          out[1] = a[1] * len;
        }
        return out
      };

      /**
       * Calculates the dot product of two vec2's
       *
       * @param {vec2} a the first operand
       * @param {vec2} b the second operand
       * @returns {Number} dot product of a and b
       */
      vec2.dot = function(a, b) {
        return a[0] * b[0] + a[1] * b[1]
      };

      /**
       * Computes the cross product of two vec2's
       * Note that the cross product must by definition produce a 3D vector
       *
       * @param {vec3} out the receiving vector
       * @param {vec2} a the first operand
       * @param {vec2} b the second operand
       * @returns {vec3} out
       */
      vec2.cross = function(out, a, b) {
        var z = a[0] * b[1] - a[1] * b[0];
        out[0] = out[1] = 0;
        out[2] = z;
        return out
      };

      /**
       * Performs a linear interpolation between two vec2's
       *
       * @param {vec2} out the receiving vector
       * @param {vec2} a the first operand
       * @param {vec2} b the second operand
       * @param {Number} t interpolation amount between the two inputs
       * @returns {vec2} out
       */
      vec2.lerp = function(out, a, b, t) {
        var ax = a[0],
          ay = a[1];
        out[0] = ax + t * (b[0] - ax);
        out[1] = ay + t * (b[1] - ay);
        return out
      };

      /**
       * Generates a random vector with the given scale
       *
       * @param {vec2} out the receiving vector
       * @param {Number} [scale] Length of the resulting vector. If ommitted, a unit vector will be returned
       * @returns {vec2} out
       */
      vec2.random = function(out, scale) {
        scale = scale || 1.0;
        var r = GLMAT_RANDOM() * 2.0 * Math.PI;
        out[0] = Math.cos(r) * scale;
        out[1] = Math.sin(r) * scale;
        return out
      };

      /**
       * Transforms the vec2 with a mat2
       *
       * @param {vec2} out the receiving vector
       * @param {vec2} a the vector to transform
       * @param {mat2} m matrix to transform with
       * @returns {vec2} out
       */
      vec2.transformMat2 = function(out, a, m) {
        var x = a[0],
          y = a[1];
        out[0] = m[0] * x + m[2] * y;
        out[1] = m[1] * x + m[3] * y;
        return out
      };

      /**
       * Transforms the vec2 with a mat2d
       *
       * @param {vec2} out the receiving vector
       * @param {vec2} a the vector to transform
       * @param {mat2d} m matrix to transform with
       * @returns {vec2} out
       */
      vec2.transformMat2d = function(out, a, m) {
        var x = a[0],
          y = a[1];
        out[0] = m[0] * x + m[2] * y + m[4];
        out[1] = m[1] * x + m[3] * y + m[5];
        return out
      };

      /**
       * Transforms the vec2 with a mat3
       * 3rd vector component is implicitly '1'
       *
       * @param {vec2} out the receiving vector
       * @param {vec2} a the vector to transform
       * @param {mat3} m matrix to transform with
       * @returns {vec2} out
       */
      vec2.transformMat3 = function(out, a, m) {
        var x = a[0],
          y = a[1];
        out[0] = m[0] * x + m[3] * y + m[6];
        out[1] = m[1] * x + m[4] * y + m[7];
        return out
      };

      /**
       * Transforms the vec2 with a mat4
       * 3rd vector component is implicitly '0'
       * 4th vector component is implicitly '1'
       *
       * @param {vec2} out the receiving vector
       * @param {vec2} a the vector to transform
       * @param {mat4} m matrix to transform with
       * @returns {vec2} out
       */
      vec2.transformMat4 = function(out, a, m) {
        var x = a[0],
          y = a[1];
        out[0] = m[0] * x + m[4] * y + m[12];
        out[1] = m[1] * x + m[5] * y + m[13];
        return out
      };

      /**
       * Perform some operation over an array of vec2s.
       *
       * @param {Array} a the array of vectors to iterate over
       * @param {Number} stride Number of elements between the start of each vec2. If 0 assumes tightly packed
       * @param {Number} offset Number of elements to skip at the beginning of the array
       * @param {Number} count Number of vec2s to iterate over. If 0 iterates over entire array
       * @param {Function} fn Function to call for each vector in the array
       * @param {Object} [arg] additional argument to pass to fn
       * @returns {Array} a
       * @function
       */
      vec2.forEach = (function() {
        var vec = vec2.create();

        return function(a, stride, offset, count, fn, arg) {
          var i, l;
          if (!stride) {
            stride = 2;
          }

          if (!offset) {
            offset = 0;
          }

          if (count) {
            l = Math.min(count * stride + offset, a.length);
          } else {
            l = a.length;
          }

          for (i = offset; i < l; i += stride) {
            vec[0] = a[i];
            vec[1] = a[i + 1];
            fn(vec, vec, arg);
            a[i] = vec[0];
            a[i + 1] = vec[1];
          }

          return a
        }
      })();

      /**
       * Returns a string representation of a vector
       *
       * @param {vec2} vec vector to represent as a string
       * @returns {String} string representation of the vector
       */
      vec2.str = function(a) {
        return 'vec2(' + a[0] + ', ' + a[1] + ')'
      };

      if (typeof exports !== 'undefined') {
        exports.vec2 = vec2;
      }
      /* Copyright (c) 2013, Brandon Jones, Colin MacKenzie IV. All rights reserved.

  Redistribution and use in source and binary forms, with or without modification,
  are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this
      list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation 
      and/or other materials provided with the distribution.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */

      /**
       * @class 3 Dimensional Vector
       * @name vec3
       */

      var vec3 = {};

      /**
       * Creates a new, empty vec3
       *
       * @returns {vec3} a new 3D vector
       */
      vec3.create = function() {
        var out = new GLMAT_ARRAY_TYPE(3);
        out[0] = 0;
        out[1] = 0;
        out[2] = 0;
        return out
      };

      /**
       * Creates a new vec3 initialized with values from an existing vector
       *
       * @param {vec3} a vector to clone
       * @returns {vec3} a new 3D vector
       */
      vec3.clone = function(a) {
        var out = new GLMAT_ARRAY_TYPE(3);
        out[0] = a[0];
        out[1] = a[1];
        out[2] = a[2];
        return out
      };

      /**
       * Creates a new vec3 initialized with the given values
       *
       * @param {Number} x X component
       * @param {Number} y Y component
       * @param {Number} z Z component
       * @returns {vec3} a new 3D vector
       */
      vec3.fromValues = function(x, y, z) {
        var out = new GLMAT_ARRAY_TYPE(3);
        out[0] = x;
        out[1] = y;
        out[2] = z;
        return out
      };

      /**
       * Copy the values from one vec3 to another
       *
       * @param {vec3} out the receiving vector
       * @param {vec3} a the source vector
       * @returns {vec3} out
       */
      vec3.copy = function(out, a) {
        out[0] = a[0];
        out[1] = a[1];
        out[2] = a[2];
        return out
      };

      /**
       * Set the components of a vec3 to the given values
       *
       * @param {vec3} out the receiving vector
       * @param {Number} x X component
       * @param {Number} y Y component
       * @param {Number} z Z component
       * @returns {vec3} out
       */
      vec3.set = function(out, x, y, z) {
        out[0] = x;
        out[1] = y;
        out[2] = z;
        return out
      };

      /**
       * Adds two vec3's
       *
       * @param {vec3} out the receiving vector
       * @param {vec3} a the first operand
       * @param {vec3} b the second operand
       * @returns {vec3} out
       */
      vec3.add = function(out, a, b) {
        out[0] = a[0] + b[0];
        out[1] = a[1] + b[1];
        out[2] = a[2] + b[2];
        return out
      };

      /**
       * Subtracts vector b from vector a
       *
       * @param {vec3} out the receiving vector
       * @param {vec3} a the first operand
       * @param {vec3} b the second operand
       * @returns {vec3} out
       */
      vec3.subtract = function(out, a, b) {
        out[0] = a[0] - b[0];
        out[1] = a[1] - b[1];
        out[2] = a[2] - b[2];
        return out
      };

      /**
       * Alias for {@link vec3.subtract}
       * @function
       */
      vec3.sub = vec3.subtract;

      /**
       * Multiplies two vec3's
       *
       * @param {vec3} out the receiving vector
       * @param {vec3} a the first operand
       * @param {vec3} b the second operand
       * @returns {vec3} out
       */
      vec3.multiply = function(out, a, b) {
        out[0] = a[0] * b[0];
        out[1] = a[1] * b[1];
        out[2] = a[2] * b[2];
        return out
      };

      /**
       * Alias for {@link vec3.multiply}
       * @function
       */
      vec3.mul = vec3.multiply;

      /**
       * Divides two vec3's
       *
       * @param {vec3} out the receiving vector
       * @param {vec3} a the first operand
       * @param {vec3} b the second operand
       * @returns {vec3} out
       */
      vec3.divide = function(out, a, b) {
        out[0] = a[0] / b[0];
        out[1] = a[1] / b[1];
        out[2] = a[2] / b[2];
        return out
      };

      /**
       * Alias for {@link vec3.divide}
       * @function
       */
      vec3.div = vec3.divide;

      /**
       * Returns the minimum of two vec3's
       *
       * @param {vec3} out the receiving vector
       * @param {vec3} a the first operand
       * @param {vec3} b the second operand
       * @returns {vec3} out
       */
      vec3.min = function(out, a, b) {
        out[0] = Math.min(a[0], b[0]);
        out[1] = Math.min(a[1], b[1]);
        out[2] = Math.min(a[2], b[2]);
        return out
      };

      /**
       * Returns the maximum of two vec3's
       *
       * @param {vec3} out the receiving vector
       * @param {vec3} a the first operand
       * @param {vec3} b the second operand
       * @returns {vec3} out
       */
      vec3.max = function(out, a, b) {
        out[0] = Math.max(a[0], b[0]);
        out[1] = Math.max(a[1], b[1]);
        out[2] = Math.max(a[2], b[2]);
        return out
      };

      /**
       * Scales a vec3 by a scalar number
       *
       * @param {vec3} out the receiving vector
       * @param {vec3} a the vector to scale
       * @param {Number} b amount to scale the vector by
       * @returns {vec3} out
       */
      vec3.scale = function(out, a, b) {
        out[0] = a[0] * b;
        out[1] = a[1] * b;
        out[2] = a[2] * b;
        return out
      };

      /**
       * Adds two vec3's after scaling the second operand by a scalar value
       *
       * @param {vec3} out the receiving vector
       * @param {vec3} a the first operand
       * @param {vec3} b the second operand
       * @param {Number} scale the amount to scale b by before adding
       * @returns {vec3} out
       */
      vec3.scaleAndAdd = function(out, a, b, scale) {
        out[0] = a[0] + b[0] * scale;
        out[1] = a[1] + b[1] * scale;
        out[2] = a[2] + b[2] * scale;
        return out
      };

      /**
       * Calculates the euclidian distance between two vec3's
       *
       * @param {vec3} a the first operand
       * @param {vec3} b the second operand
       * @returns {Number} distance between a and b
       */
      vec3.distance = function(a, b) {
        var x = b[0] - a[0],
          y = b[1] - a[1],
          z = b[2] - a[2];
        return Math.sqrt(x * x + y * y + z * z)
      };

      /**
       * Alias for {@link vec3.distance}
       * @function
       */
      vec3.dist = vec3.distance;

      /**
       * Calculates the squared euclidian distance between two vec3's
       *
       * @param {vec3} a the first operand
       * @param {vec3} b the second operand
       * @returns {Number} squared distance between a and b
       */
      vec3.squaredDistance = function(a, b) {
        var x = b[0] - a[0],
          y = b[1] - a[1],
          z = b[2] - a[2];
        return x * x + y * y + z * z
      };

      /**
       * Alias for {@link vec3.squaredDistance}
       * @function
       */
      vec3.sqrDist = vec3.squaredDistance;

      /**
       * Calculates the length of a vec3
       *
       * @param {vec3} a vector to calculate length of
       * @returns {Number} length of a
       */
      vec3.length = function(a) {
        var x = a[0],
          y = a[1],
          z = a[2];
        return Math.sqrt(x * x + y * y + z * z)
      };

      /**
       * Alias for {@link vec3.length}
       * @function
       */
      vec3.len = vec3.length;

      /**
       * Calculates the squared length of a vec3
       *
       * @param {vec3} a vector to calculate squared length of
       * @returns {Number} squared length of a
       */
      vec3.squaredLength = function(a) {
        var x = a[0],
          y = a[1],
          z = a[2];
        return x * x + y * y + z * z
      };

      /**
       * Alias for {@link vec3.squaredLength}
       * @function
       */
      vec3.sqrLen = vec3.squaredLength;

      /**
       * Negates the components of a vec3
       *
       * @param {vec3} out the receiving vector
       * @param {vec3} a vector to negate
       * @returns {vec3} out
       */
      vec3.negate = function(out, a) {
        out[0] = -a[0];
        out[1] = -a[1];
        out[2] = -a[2];
        return out
      };

      /**
       * Returns the inverse of the components of a vec3
       *
       * @param {vec3} out the receiving vector
       * @param {vec3} a vector to invert
       * @returns {vec3} out
       */
      vec3.inverse = function(out, a) {
        out[0] = 1.0 / a[0];
        out[1] = 1.0 / a[1];
        out[2] = 1.0 / a[2];
        return out
      };

      /**
       * Normalize a vec3
       *
       * @param {vec3} out the receiving vector
       * @param {vec3} a vector to normalize
       * @returns {vec3} out
       */
      vec3.normalize = function(out, a) {
        var x = a[0],
          y = a[1],
          z = a[2];
        var len = x * x + y * y + z * z;
        if (len > 0) {
          //TODO: evaluate use of glm_invsqrt here?
          len = 1 / Math.sqrt(len);
          out[0] = a[0] * len;
          out[1] = a[1] * len;
          out[2] = a[2] * len;
        }
        return out
      };

      /**
       * Calculates the dot product of two vec3's
       *
       * @param {vec3} a the first operand
       * @param {vec3} b the second operand
       * @returns {Number} dot product of a and b
       */
      vec3.dot = function(a, b) {
        return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
      };

      /**
       * Computes the cross product of two vec3's
       *
       * @param {vec3} out the receiving vector
       * @param {vec3} a the first operand
       * @param {vec3} b the second operand
       * @returns {vec3} out
       */
      vec3.cross = function(out, a, b) {
        var ax = a[0],
          ay = a[1],
          az = a[2],
          bx = b[0],
          by = b[1],
          bz = b[2];

        out[0] = ay * bz - az * by;
        out[1] = az * bx - ax * bz;
        out[2] = ax * by - ay * bx;
        return out
      };

      /**
       * Performs a linear interpolation between two vec3's
       *
       * @param {vec3} out the receiving vector
       * @param {vec3} a the first operand
       * @param {vec3} b the second operand
       * @param {Number} t interpolation amount between the two inputs
       * @returns {vec3} out
       */
      vec3.lerp = function(out, a, b, t) {
        var ax = a[0],
          ay = a[1],
          az = a[2];
        out[0] = ax + t * (b[0] - ax);
        out[1] = ay + t * (b[1] - ay);
        out[2] = az + t * (b[2] - az);
        return out
      };

      /**
       * Generates a random vector with the given scale
       *
       * @param {vec3} out the receiving vector
       * @param {Number} [scale] Length of the resulting vector. If ommitted, a unit vector will be returned
       * @returns {vec3} out
       */
      vec3.random = function(out, scale) {
        scale = scale || 1.0;

        var r = GLMAT_RANDOM() * 2.0 * Math.PI;
        var z = GLMAT_RANDOM() * 2.0 - 1.0;
        var zScale = Math.sqrt(1.0 - z * z) * scale;

        out[0] = Math.cos(r) * zScale;
        out[1] = Math.sin(r) * zScale;
        out[2] = z * scale;
        return out
      };

      /**
       * Transforms the vec3 with a mat4.
       * 4th vector component is implicitly '1'
       *
       * @param {vec3} out the receiving vector
       * @param {vec3} a the vector to transform
       * @param {mat4} m matrix to transform with
       * @returns {vec3} out
       */
      vec3.transformMat4 = function(out, a, m) {
        var x = a[0],
          y = a[1],
          z = a[2],
          w = m[3] * x + m[7] * y + m[11] * z + m[15];
        w = w || 1.0;
        out[0] = (m[0] * x + m[4] * y + m[8] * z + m[12]) / w;
        out[1] = (m[1] * x + m[5] * y + m[9] * z + m[13]) / w;
        out[2] = (m[2] * x + m[6] * y + m[10] * z + m[14]) / w;
        return out
      };

      /**
       * Transforms the vec3 with a mat3.
       *
       * @param {vec3} out the receiving vector
       * @param {vec3} a the vector to transform
       * @param {mat4} m the 3x3 matrix to transform with
       * @returns {vec3} out
       */
      vec3.transformMat3 = function(out, a, m) {
        var x = a[0],
          y = a[1],
          z = a[2];
        out[0] = x * m[0] + y * m[3] + z * m[6];
        out[1] = x * m[1] + y * m[4] + z * m[7];
        out[2] = x * m[2] + y * m[5] + z * m[8];
        return out
      };

      /**
       * Transforms the vec3 with a quat
       *
       * @param {vec3} out the receiving vector
       * @param {vec3} a the vector to transform
       * @param {quat} q quaternion to transform with
       * @returns {vec3} out
       */
      vec3.transformQuat = function(out, a, q) {
        // benchmarks: http://jsperf.com/quaternion-transform-vec3-implementations

        var x = a[0],
          y = a[1],
          z = a[2],
          qx = q[0],
          qy = q[1],
          qz = q[2],
          qw = q[3],
          // calculate quat * vec
          ix = qw * x + qy * z - qz * y,
          iy = qw * y + qz * x - qx * z,
          iz = qw * z + qx * y - qy * x,
          iw = -qx * x - qy * y - qz * z;

        // calculate result * inverse quat
        out[0] = ix * qw + iw * -qx + iy * -qz - iz * -qy;
        out[1] = iy * qw + iw * -qy + iz * -qx - ix * -qz;
        out[2] = iz * qw + iw * -qz + ix * -qy - iy * -qx;
        return out
      };

      /**
       * Rotate a 3D vector around the x-axis
       * @param {vec3} out The receiving vec3
       * @param {vec3} a The vec3 point to rotate
       * @param {vec3} b The origin of the rotation
       * @param {Number} c The angle of rotation
       * @returns {vec3} out
       */
      vec3.rotateX = function(out, a, b, c) {
        var p = [],
          r = [];
        //Translate point to the origin
        p[0] = a[0] - b[0];
        p[1] = a[1] - b[1];
        p[2] = a[2] - b[2];

        //perform rotation
        r[0] = p[0];
        r[1] = p[1] * Math.cos(c) - p[2] * Math.sin(c);
        r[2] = p[1] * Math.sin(c) + p[2] * Math.cos(c);

        //translate to correct position
        out[0] = r[0] + b[0];
        out[1] = r[1] + b[1];
        out[2] = r[2] + b[2];

        return out
      };

      /**
       * Rotate a 3D vector around the y-axis
       * @param {vec3} out The receiving vec3
       * @param {vec3} a The vec3 point to rotate
       * @param {vec3} b The origin of the rotation
       * @param {Number} c The angle of rotation
       * @returns {vec3} out
       */
      vec3.rotateY = function(out, a, b, c) {
        var p = [],
          r = [];
        //Translate point to the origin
        p[0] = a[0] - b[0];
        p[1] = a[1] - b[1];
        p[2] = a[2] - b[2];

        //perform rotation
        r[0] = p[2] * Math.sin(c) + p[0] * Math.cos(c);
        r[1] = p[1];
        r[2] = p[2] * Math.cos(c) - p[0] * Math.sin(c);

        //translate to correct position
        out[0] = r[0] + b[0];
        out[1] = r[1] + b[1];
        out[2] = r[2] + b[2];

        return out
      };

      /**
       * Rotate a 3D vector around the z-axis
       * @param {vec3} out The receiving vec3
       * @param {vec3} a The vec3 point to rotate
       * @param {vec3} b The origin of the rotation
       * @param {Number} c The angle of rotation
       * @returns {vec3} out
       */
      vec3.rotateZ = function(out, a, b, c) {
        var p = [],
          r = [];
        //Translate point to the origin
        p[0] = a[0] - b[0];
        p[1] = a[1] - b[1];
        p[2] = a[2] - b[2];

        //perform rotation
        r[0] = p[0] * Math.cos(c) - p[1] * Math.sin(c);
        r[1] = p[0] * Math.sin(c) + p[1] * Math.cos(c);
        r[2] = p[2];

        //translate to correct position
        out[0] = r[0] + b[0];
        out[1] = r[1] + b[1];
        out[2] = r[2] + b[2];

        return out
      };

      /**
       * Perform some operation over an array of vec3s.
       *
       * @param {Array} a the array of vectors to iterate over
       * @param {Number} stride Number of elements between the start of each vec3. If 0 assumes tightly packed
       * @param {Number} offset Number of elements to skip at the beginning of the array
       * @param {Number} count Number of vec3s to iterate over. If 0 iterates over entire array
       * @param {Function} fn Function to call for each vector in the array
       * @param {Object} [arg] additional argument to pass to fn
       * @returns {Array} a
       * @function
       */
      vec3.forEach = (function() {
        var vec = vec3.create();

        return function(a, stride, offset, count, fn, arg) {
          var i, l;
          if (!stride) {
            stride = 3;
          }

          if (!offset) {
            offset = 0;
          }

          if (count) {
            l = Math.min(count * stride + offset, a.length);
          } else {
            l = a.length;
          }

          for (i = offset; i < l; i += stride) {
            vec[0] = a[i];
            vec[1] = a[i + 1];
            vec[2] = a[i + 2];
            fn(vec, vec, arg);
            a[i] = vec[0];
            a[i + 1] = vec[1];
            a[i + 2] = vec[2];
          }

          return a
        }
      })();

      /**
       * Get the angle between two 3D vectors
       * @param {vec3} a The first operand
       * @param {vec3} b The second operand
       * @returns {Number} The angle in radians
       */
      vec3.angle = function(a, b) {
        var tempA = vec3.fromValues(a[0], a[1], a[2]);
        var tempB = vec3.fromValues(b[0], b[1], b[2]);

        vec3.normalize(tempA, tempA);
        vec3.normalize(tempB, tempB);

        var cosine = vec3.dot(tempA, tempB);

        if (cosine > 1.0) {
          return 0
        } else {
          return Math.acos(cosine)
        }
      };

      /**
       * Returns a string representation of a vector
       *
       * @param {vec3} vec vector to represent as a string
       * @returns {String} string representation of the vector
       */
      vec3.str = function(a) {
        return 'vec3(' + a[0] + ', ' + a[1] + ', ' + a[2] + ')'
      };

      if (typeof exports !== 'undefined') {
        exports.vec3 = vec3;
      }
      /* Copyright (c) 2013, Brandon Jones, Colin MacKenzie IV. All rights reserved.

  Redistribution and use in source and binary forms, with or without modification,
  are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this
      list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation 
      and/or other materials provided with the distribution.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */

      /**
       * @class 4 Dimensional Vector
       * @name vec4
       */

      var vec4 = {};

      /**
       * Creates a new, empty vec4
       *
       * @returns {vec4} a new 4D vector
       */
      vec4.create = function() {
        var out = new GLMAT_ARRAY_TYPE(4);
        out[0] = 0;
        out[1] = 0;
        out[2] = 0;
        out[3] = 0;
        return out
      };

      /**
       * Creates a new vec4 initialized with values from an existing vector
       *
       * @param {vec4} a vector to clone
       * @returns {vec4} a new 4D vector
       */
      vec4.clone = function(a) {
        var out = new GLMAT_ARRAY_TYPE(4);
        out[0] = a[0];
        out[1] = a[1];
        out[2] = a[2];
        out[3] = a[3];
        return out
      };

      /**
       * Creates a new vec4 initialized with the given values
       *
       * @param {Number} x X component
       * @param {Number} y Y component
       * @param {Number} z Z component
       * @param {Number} w W component
       * @returns {vec4} a new 4D vector
       */
      vec4.fromValues = function(x, y, z, w) {
        var out = new GLMAT_ARRAY_TYPE(4);
        out[0] = x;
        out[1] = y;
        out[2] = z;
        out[3] = w;
        return out
      };

      /**
       * Copy the values from one vec4 to another
       *
       * @param {vec4} out the receiving vector
       * @param {vec4} a the source vector
       * @returns {vec4} out
       */
      vec4.copy = function(out, a) {
        out[0] = a[0];
        out[1] = a[1];
        out[2] = a[2];
        out[3] = a[3];
        return out
      };

      /**
       * Set the components of a vec4 to the given values
       *
       * @param {vec4} out the receiving vector
       * @param {Number} x X component
       * @param {Number} y Y component
       * @param {Number} z Z component
       * @param {Number} w W component
       * @returns {vec4} out
       */
      vec4.set = function(out, x, y, z, w) {
        out[0] = x;
        out[1] = y;
        out[2] = z;
        out[3] = w;
        return out
      };

      /**
       * Adds two vec4's
       *
       * @param {vec4} out the receiving vector
       * @param {vec4} a the first operand
       * @param {vec4} b the second operand
       * @returns {vec4} out
       */
      vec4.add = function(out, a, b) {
        out[0] = a[0] + b[0];
        out[1] = a[1] + b[1];
        out[2] = a[2] + b[2];
        out[3] = a[3] + b[3];
        return out
      };

      /**
       * Subtracts vector b from vector a
       *
       * @param {vec4} out the receiving vector
       * @param {vec4} a the first operand
       * @param {vec4} b the second operand
       * @returns {vec4} out
       */
      vec4.subtract = function(out, a, b) {
        out[0] = a[0] - b[0];
        out[1] = a[1] - b[1];
        out[2] = a[2] - b[2];
        out[3] = a[3] - b[3];
        return out
      };

      /**
       * Alias for {@link vec4.subtract}
       * @function
       */
      vec4.sub = vec4.subtract;

      /**
       * Multiplies two vec4's
       *
       * @param {vec4} out the receiving vector
       * @param {vec4} a the first operand
       * @param {vec4} b the second operand
       * @returns {vec4} out
       */
      vec4.multiply = function(out, a, b) {
        out[0] = a[0] * b[0];
        out[1] = a[1] * b[1];
        out[2] = a[2] * b[2];
        out[3] = a[3] * b[3];
        return out
      };

      /**
       * Alias for {@link vec4.multiply}
       * @function
       */
      vec4.mul = vec4.multiply;

      /**
       * Divides two vec4's
       *
       * @param {vec4} out the receiving vector
       * @param {vec4} a the first operand
       * @param {vec4} b the second operand
       * @returns {vec4} out
       */
      vec4.divide = function(out, a, b) {
        out[0] = a[0] / b[0];
        out[1] = a[1] / b[1];
        out[2] = a[2] / b[2];
        out[3] = a[3] / b[3];
        return out
      };

      /**
       * Alias for {@link vec4.divide}
       * @function
       */
      vec4.div = vec4.divide;

      /**
       * Returns the minimum of two vec4's
       *
       * @param {vec4} out the receiving vector
       * @param {vec4} a the first operand
       * @param {vec4} b the second operand
       * @returns {vec4} out
       */
      vec4.min = function(out, a, b) {
        out[0] = Math.min(a[0], b[0]);
        out[1] = Math.min(a[1], b[1]);
        out[2] = Math.min(a[2], b[2]);
        out[3] = Math.min(a[3], b[3]);
        return out
      };

      /**
       * Returns the maximum of two vec4's
       *
       * @param {vec4} out the receiving vector
       * @param {vec4} a the first operand
       * @param {vec4} b the second operand
       * @returns {vec4} out
       */
      vec4.max = function(out, a, b) {
        out[0] = Math.max(a[0], b[0]);
        out[1] = Math.max(a[1], b[1]);
        out[2] = Math.max(a[2], b[2]);
        out[3] = Math.max(a[3], b[3]);
        return out
      };

      /**
       * Scales a vec4 by a scalar number
       *
       * @param {vec4} out the receiving vector
       * @param {vec4} a the vector to scale
       * @param {Number} b amount to scale the vector by
       * @returns {vec4} out
       */
      vec4.scale = function(out, a, b) {
        out[0] = a[0] * b;
        out[1] = a[1] * b;
        out[2] = a[2] * b;
        out[3] = a[3] * b;
        return out
      };

      /**
       * Adds two vec4's after scaling the second operand by a scalar value
       *
       * @param {vec4} out the receiving vector
       * @param {vec4} a the first operand
       * @param {vec4} b the second operand
       * @param {Number} scale the amount to scale b by before adding
       * @returns {vec4} out
       */
      vec4.scaleAndAdd = function(out, a, b, scale) {
        out[0] = a[0] + b[0] * scale;
        out[1] = a[1] + b[1] * scale;
        out[2] = a[2] + b[2] * scale;
        out[3] = a[3] + b[3] * scale;
        return out
      };

      /**
       * Calculates the euclidian distance between two vec4's
       *
       * @param {vec4} a the first operand
       * @param {vec4} b the second operand
       * @returns {Number} distance between a and b
       */
      vec4.distance = function(a, b) {
        var x = b[0] - a[0],
          y = b[1] - a[1],
          z = b[2] - a[2],
          w = b[3] - a[3];
        return Math.sqrt(x * x + y * y + z * z + w * w)
      };

      /**
       * Alias for {@link vec4.distance}
       * @function
       */
      vec4.dist = vec4.distance;

      /**
       * Calculates the squared euclidian distance between two vec4's
       *
       * @param {vec4} a the first operand
       * @param {vec4} b the second operand
       * @returns {Number} squared distance between a and b
       */
      vec4.squaredDistance = function(a, b) {
        var x = b[0] - a[0],
          y = b[1] - a[1],
          z = b[2] - a[2],
          w = b[3] - a[3];
        return x * x + y * y + z * z + w * w
      };

      /**
       * Alias for {@link vec4.squaredDistance}
       * @function
       */
      vec4.sqrDist = vec4.squaredDistance;

      /**
       * Calculates the length of a vec4
       *
       * @param {vec4} a vector to calculate length of
       * @returns {Number} length of a
       */
      vec4.length = function(a) {
        var x = a[0],
          y = a[1],
          z = a[2],
          w = a[3];
        return Math.sqrt(x * x + y * y + z * z + w * w)
      };

      /**
       * Alias for {@link vec4.length}
       * @function
       */
      vec4.len = vec4.length;

      /**
       * Calculates the squared length of a vec4
       *
       * @param {vec4} a vector to calculate squared length of
       * @returns {Number} squared length of a
       */
      vec4.squaredLength = function(a) {
        var x = a[0],
          y = a[1],
          z = a[2],
          w = a[3];
        return x * x + y * y + z * z + w * w
      };

      /**
       * Alias for {@link vec4.squaredLength}
       * @function
       */
      vec4.sqrLen = vec4.squaredLength;

      /**
       * Negates the components of a vec4
       *
       * @param {vec4} out the receiving vector
       * @param {vec4} a vector to negate
       * @returns {vec4} out
       */
      vec4.negate = function(out, a) {
        out[0] = -a[0];
        out[1] = -a[1];
        out[2] = -a[2];
        out[3] = -a[3];
        return out
      };

      /**
       * Returns the inverse of the components of a vec4
       *
       * @param {vec4} out the receiving vector
       * @param {vec4} a vector to invert
       * @returns {vec4} out
       */
      vec4.inverse = function(out, a) {
        out[0] = 1.0 / a[0];
        out[1] = 1.0 / a[1];
        out[2] = 1.0 / a[2];
        out[3] = 1.0 / a[3];
        return out
      };

      /**
       * Normalize a vec4
       *
       * @param {vec4} out the receiving vector
       * @param {vec4} a vector to normalize
       * @returns {vec4} out
       */
      vec4.normalize = function(out, a) {
        var x = a[0],
          y = a[1],
          z = a[2],
          w = a[3];
        var len = x * x + y * y + z * z + w * w;
        if (len > 0) {
          len = 1 / Math.sqrt(len);
          out[0] = a[0] * len;
          out[1] = a[1] * len;
          out[2] = a[2] * len;
          out[3] = a[3] * len;
        }
        return out
      };

      /**
       * Calculates the dot product of two vec4's
       *
       * @param {vec4} a the first operand
       * @param {vec4} b the second operand
       * @returns {Number} dot product of a and b
       */
      vec4.dot = function(a, b) {
        return a[0] * b[0] + a[1] * b[1] + a[2] * b[2] + a[3] * b[3]
      };

      /**
       * Performs a linear interpolation between two vec4's
       *
       * @param {vec4} out the receiving vector
       * @param {vec4} a the first operand
       * @param {vec4} b the second operand
       * @param {Number} t interpolation amount between the two inputs
       * @returns {vec4} out
       */
      vec4.lerp = function(out, a, b, t) {
        var ax = a[0],
          ay = a[1],
          az = a[2],
          aw = a[3];
        out[0] = ax + t * (b[0] - ax);
        out[1] = ay + t * (b[1] - ay);
        out[2] = az + t * (b[2] - az);
        out[3] = aw + t * (b[3] - aw);
        return out
      };

      /**
       * Generates a random vector with the given scale
       *
       * @param {vec4} out the receiving vector
       * @param {Number} [scale] Length of the resulting vector. If ommitted, a unit vector will be returned
       * @returns {vec4} out
       */
      vec4.random = function(out, scale) {
        scale = scale || 1.0;

        //TODO: This is a pretty awful way of doing this. Find something better.
        out[0] = GLMAT_RANDOM();
        out[1] = GLMAT_RANDOM();
        out[2] = GLMAT_RANDOM();
        out[3] = GLMAT_RANDOM();
        vec4.normalize(out, out);
        vec4.scale(out, out, scale);
        return out
      };

      /**
       * Transforms the vec4 with a mat4.
       *
       * @param {vec4} out the receiving vector
       * @param {vec4} a the vector to transform
       * @param {mat4} m matrix to transform with
       * @returns {vec4} out
       */
      vec4.transformMat4 = function(out, a, m) {
        var x = a[0],
          y = a[1],
          z = a[2],
          w = a[3];
        out[0] = m[0] * x + m[4] * y + m[8] * z + m[12] * w;
        out[1] = m[1] * x + m[5] * y + m[9] * z + m[13] * w;
        out[2] = m[2] * x + m[6] * y + m[10] * z + m[14] * w;
        out[3] = m[3] * x + m[7] * y + m[11] * z + m[15] * w;
        return out
      };

      /**
       * Transforms the vec4 with a quat
       *
       * @param {vec4} out the receiving vector
       * @param {vec4} a the vector to transform
       * @param {quat} q quaternion to transform with
       * @returns {vec4} out
       */
      vec4.transformQuat = function(out, a, q) {
        var x = a[0],
          y = a[1],
          z = a[2],
          qx = q[0],
          qy = q[1],
          qz = q[2],
          qw = q[3],
          // calculate quat * vec
          ix = qw * x + qy * z - qz * y,
          iy = qw * y + qz * x - qx * z,
          iz = qw * z + qx * y - qy * x,
          iw = -qx * x - qy * y - qz * z;

        // calculate result * inverse quat
        out[0] = ix * qw + iw * -qx + iy * -qz - iz * -qy;
        out[1] = iy * qw + iw * -qy + iz * -qx - ix * -qz;
        out[2] = iz * qw + iw * -qz + ix * -qy - iy * -qx;
        return out
      };

      /**
       * Perform some operation over an array of vec4s.
       *
       * @param {Array} a the array of vectors to iterate over
       * @param {Number} stride Number of elements between the start of each vec4. If 0 assumes tightly packed
       * @param {Number} offset Number of elements to skip at the beginning of the array
       * @param {Number} count Number of vec4s to iterate over. If 0 iterates over entire array
       * @param {Function} fn Function to call for each vector in the array
       * @param {Object} [arg] additional argument to pass to fn
       * @returns {Array} a
       * @function
       */
      vec4.forEach = (function() {
        var vec = vec4.create();

        return function(a, stride, offset, count, fn, arg) {
          var i, l;
          if (!stride) {
            stride = 4;
          }

          if (!offset) {
            offset = 0;
          }

          if (count) {
            l = Math.min(count * stride + offset, a.length);
          } else {
            l = a.length;
          }

          for (i = offset; i < l; i += stride) {
            vec[0] = a[i];
            vec[1] = a[i + 1];
            vec[2] = a[i + 2];
            vec[3] = a[i + 3];
            fn(vec, vec, arg);
            a[i] = vec[0];
            a[i + 1] = vec[1];
            a[i + 2] = vec[2];
            a[i + 3] = vec[3];
          }

          return a
        }
      })();

      /**
       * Returns a string representation of a vector
       *
       * @param {vec4} vec vector to represent as a string
       * @returns {String} string representation of the vector
       */
      vec4.str = function(a) {
        return 'vec4(' + a[0] + ', ' + a[1] + ', ' + a[2] + ', ' + a[3] + ')'
      };

      if (typeof exports !== 'undefined') {
        exports.vec4 = vec4;
      }
      /* Copyright (c) 2013, Brandon Jones, Colin MacKenzie IV. All rights reserved.

  Redistribution and use in source and binary forms, with or without modification,
  are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this
      list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation 
      and/or other materials provided with the distribution.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */

      /**
       * @class 2x2 Matrix
       * @name mat2
       */

      var mat2 = {};

      /**
       * Creates a new identity mat2
       *
       * @returns {mat2} a new 2x2 matrix
       */
      mat2.create = function() {
        var out = new GLMAT_ARRAY_TYPE(4);
        out[0] = 1;
        out[1] = 0;
        out[2] = 0;
        out[3] = 1;
        return out
      };

      /**
       * Creates a new mat2 initialized with values from an existing matrix
       *
       * @param {mat2} a matrix to clone
       * @returns {mat2} a new 2x2 matrix
       */
      mat2.clone = function(a) {
        var out = new GLMAT_ARRAY_TYPE(4);
        out[0] = a[0];
        out[1] = a[1];
        out[2] = a[2];
        out[3] = a[3];
        return out
      };

      /**
       * Copy the values from one mat2 to another
       *
       * @param {mat2} out the receiving matrix
       * @param {mat2} a the source matrix
       * @returns {mat2} out
       */
      mat2.copy = function(out, a) {
        out[0] = a[0];
        out[1] = a[1];
        out[2] = a[2];
        out[3] = a[3];
        return out
      };

      /**
       * Set a mat2 to the identity matrix
       *
       * @param {mat2} out the receiving matrix
       * @returns {mat2} out
       */
      mat2.identity = function(out) {
        out[0] = 1;
        out[1] = 0;
        out[2] = 0;
        out[3] = 1;
        return out
      };

      /**
       * Transpose the values of a mat2
       *
       * @param {mat2} out the receiving matrix
       * @param {mat2} a the source matrix
       * @returns {mat2} out
       */
      mat2.transpose = function(out, a) {
        // If we are transposing ourselves we can skip a few steps but have to cache some values
        if (out === a) {
          var a1 = a[1];
          out[1] = a[2];
          out[2] = a1;
        } else {
          out[0] = a[0];
          out[1] = a[2];
          out[2] = a[1];
          out[3] = a[3];
        }

        return out
      };

      /**
       * Inverts a mat2
       *
       * @param {mat2} out the receiving matrix
       * @param {mat2} a the source matrix
       * @returns {mat2} out
       */
      mat2.invert = function(out, a) {
        var a0 = a[0],
          a1 = a[1],
          a2 = a[2],
          a3 = a[3],
          // Calculate the determinant
          det = a0 * a3 - a2 * a1;

        if (!det) {
          return null
        }
        det = 1.0 / det;

        out[0] = a3 * det;
        out[1] = -a1 * det;
        out[2] = -a2 * det;
        out[3] = a0 * det;

        return out
      };

      /**
       * Calculates the adjugate of a mat2
       *
       * @param {mat2} out the receiving matrix
       * @param {mat2} a the source matrix
       * @returns {mat2} out
       */
      mat2.adjoint = function(out, a) {
        // Caching this value is nessecary if out == a
        var a0 = a[0];
        out[0] = a[3];
        out[1] = -a[1];
        out[2] = -a[2];
        out[3] = a0;

        return out
      };

      /**
       * Calculates the determinant of a mat2
       *
       * @param {mat2} a the source matrix
       * @returns {Number} determinant of a
       */
      mat2.determinant = function(a) {
        return a[0] * a[3] - a[2] * a[1]
      };

      /**
       * Multiplies two mat2's
       *
       * @param {mat2} out the receiving matrix
       * @param {mat2} a the first operand
       * @param {mat2} b the second operand
       * @returns {mat2} out
       */
      mat2.multiply = function(out, a, b) {
        var a0 = a[0],
          a1 = a[1],
          a2 = a[2],
          a3 = a[3];
        var b0 = b[0],
          b1 = b[1],
          b2 = b[2],
          b3 = b[3];
        out[0] = a0 * b0 + a2 * b1;
        out[1] = a1 * b0 + a3 * b1;
        out[2] = a0 * b2 + a2 * b3;
        out[3] = a1 * b2 + a3 * b3;
        return out
      };

      /**
       * Alias for {@link mat2.multiply}
       * @function
       */
      mat2.mul = mat2.multiply;

      /**
       * Rotates a mat2 by the given angle
       *
       * @param {mat2} out the receiving matrix
       * @param {mat2} a the matrix to rotate
       * @param {Number} rad the angle to rotate the matrix by
       * @returns {mat2} out
       */
      mat2.rotate = function(out, a, rad) {
        var a0 = a[0],
          a1 = a[1],
          a2 = a[2],
          a3 = a[3],
          s = Math.sin(rad),
          c = Math.cos(rad);
        out[0] = a0 * c + a2 * s;
        out[1] = a1 * c + a3 * s;
        out[2] = a0 * -s + a2 * c;
        out[3] = a1 * -s + a3 * c;
        return out
      };

      /**
       * Scales the mat2 by the dimensions in the given vec2
       *
       * @param {mat2} out the receiving matrix
       * @param {mat2} a the matrix to rotate
       * @param {vec2} v the vec2 to scale the matrix by
       * @returns {mat2} out
       **/
      mat2.scale = function(out, a, v) {
        var a0 = a[0],
          a1 = a[1],
          a2 = a[2],
          a3 = a[3],
          v0 = v[0],
          v1 = v[1];
        out[0] = a0 * v0;
        out[1] = a1 * v0;
        out[2] = a2 * v1;
        out[3] = a3 * v1;
        return out
      };

      /**
       * Returns a string representation of a mat2
       *
       * @param {mat2} mat matrix to represent as a string
       * @returns {String} string representation of the matrix
       */
      mat2.str = function(a) {
        return 'mat2(' + a[0] + ', ' + a[1] + ', ' + a[2] + ', ' + a[3] + ')'
      };

      /**
       * Returns Frobenius norm of a mat2
       *
       * @param {mat2} a the matrix to calculate Frobenius norm of
       * @returns {Number} Frobenius norm
       */
      mat2.frob = function(a) {
        return Math.sqrt(
          Math.pow(a[0], 2) + Math.pow(a[1], 2) + Math.pow(a[2], 2) + Math.pow(a[3], 2)
        )
      };

      /**
       * Returns L, D and U matrices (Lower triangular, Diagonal and Upper triangular) by factorizing the input matrix
       * @param {mat2} L the lower triangular matrix
       * @param {mat2} D the diagonal matrix
       * @param {mat2} U the upper triangular matrix
       * @param {mat2} a the input matrix to factorize
       */

      mat2.LDU = function(L, D, U, a) {
        L[2] = a[2] / a[0];
        U[0] = a[0];
        U[1] = a[1];
        U[3] = a[3] - L[2] * U[1];
        return [L, D, U]
      };

      if (typeof exports !== 'undefined') {
        exports.mat2 = mat2;
      }
      /* Copyright (c) 2013, Brandon Jones, Colin MacKenzie IV. All rights reserved.

  Redistribution and use in source and binary forms, with or without modification,
  are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this
      list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation 
      and/or other materials provided with the distribution.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */

      /**
       * @class 2x3 Matrix
       * @name mat2d
       *
       * @description
       * A mat2d contains six elements defined as:
       * <pre>
       * [a, c, tx,
       *  b, d, ty]
       * </pre>
       * This is a short form for the 3x3 matrix:
       * <pre>
       * [a, c, tx,
       *  b, d, ty,
       *  0, 0, 1]
       * </pre>
       * The last row is ignored so the array is shorter and operations are faster.
       */

      var mat2d = {};

      /**
       * Creates a new identity mat2d
       *
       * @returns {mat2d} a new 2x3 matrix
       */
      mat2d.create = function() {
        var out = new GLMAT_ARRAY_TYPE(6);
        out[0] = 1;
        out[1] = 0;
        out[2] = 0;
        out[3] = 1;
        out[4] = 0;
        out[5] = 0;
        return out
      };

      /**
       * Creates a new mat2d initialized with values from an existing matrix
       *
       * @param {mat2d} a matrix to clone
       * @returns {mat2d} a new 2x3 matrix
       */
      mat2d.clone = function(a) {
        var out = new GLMAT_ARRAY_TYPE(6);
        out[0] = a[0];
        out[1] = a[1];
        out[2] = a[2];
        out[3] = a[3];
        out[4] = a[4];
        out[5] = a[5];
        return out
      };

      /**
       * Copy the values from one mat2d to another
       *
       * @param {mat2d} out the receiving matrix
       * @param {mat2d} a the source matrix
       * @returns {mat2d} out
       */
      mat2d.copy = function(out, a) {
        out[0] = a[0];
        out[1] = a[1];
        out[2] = a[2];
        out[3] = a[3];
        out[4] = a[4];
        out[5] = a[5];
        return out
      };

      /**
       * Set a mat2d to the identity matrix
       *
       * @param {mat2d} out the receiving matrix
       * @returns {mat2d} out
       */
      mat2d.identity = function(out) {
        out[0] = 1;
        out[1] = 0;
        out[2] = 0;
        out[3] = 1;
        out[4] = 0;
        out[5] = 0;
        return out
      };

      /**
       * Inverts a mat2d
       *
       * @param {mat2d} out the receiving matrix
       * @param {mat2d} a the source matrix
       * @returns {mat2d} out
       */
      mat2d.invert = function(out, a) {
        var aa = a[0],
          ab = a[1],
          ac = a[2],
          ad = a[3],
          atx = a[4],
          aty = a[5];

        var det = aa * ad - ab * ac;
        if (!det) {
          return null
        }
        det = 1.0 / det;

        out[0] = ad * det;
        out[1] = -ab * det;
        out[2] = -ac * det;
        out[3] = aa * det;
        out[4] = (ac * aty - ad * atx) * det;
        out[5] = (ab * atx - aa * aty) * det;
        return out
      };

      /**
       * Calculates the determinant of a mat2d
       *
       * @param {mat2d} a the source matrix
       * @returns {Number} determinant of a
       */
      mat2d.determinant = function(a) {
        return a[0] * a[3] - a[1] * a[2]
      };

      /**
       * Multiplies two mat2d's
       *
       * @param {mat2d} out the receiving matrix
       * @param {mat2d} a the first operand
       * @param {mat2d} b the second operand
       * @returns {mat2d} out
       */
      mat2d.multiply = function(out, a, b) {
        var a0 = a[0],
          a1 = a[1],
          a2 = a[2],
          a3 = a[3],
          a4 = a[4],
          a5 = a[5],
          b0 = b[0],
          b1 = b[1],
          b2 = b[2],
          b3 = b[3],
          b4 = b[4],
          b5 = b[5];
        out[0] = a0 * b0 + a2 * b1;
        out[1] = a1 * b0 + a3 * b1;
        out[2] = a0 * b2 + a2 * b3;
        out[3] = a1 * b2 + a3 * b3;
        out[4] = a0 * b4 + a2 * b5 + a4;
        out[5] = a1 * b4 + a3 * b5 + a5;
        return out
      };

      /**
       * Alias for {@link mat2d.multiply}
       * @function
       */
      mat2d.mul = mat2d.multiply;

      /**
       * Rotates a mat2d by the given angle
       *
       * @param {mat2d} out the receiving matrix
       * @param {mat2d} a the matrix to rotate
       * @param {Number} rad the angle to rotate the matrix by
       * @returns {mat2d} out
       */
      mat2d.rotate = function(out, a, rad) {
        var a0 = a[0],
          a1 = a[1],
          a2 = a[2],
          a3 = a[3],
          a4 = a[4],
          a5 = a[5],
          s = Math.sin(rad),
          c = Math.cos(rad);
        out[0] = a0 * c + a2 * s;
        out[1] = a1 * c + a3 * s;
        out[2] = a0 * -s + a2 * c;
        out[3] = a1 * -s + a3 * c;
        out[4] = a4;
        out[5] = a5;
        return out
      };

      /**
       * Scales the mat2d by the dimensions in the given vec2
       *
       * @param {mat2d} out the receiving matrix
       * @param {mat2d} a the matrix to translate
       * @param {vec2} v the vec2 to scale the matrix by
       * @returns {mat2d} out
       **/
      mat2d.scale = function(out, a, v) {
        var a0 = a[0],
          a1 = a[1],
          a2 = a[2],
          a3 = a[3],
          a4 = a[4],
          a5 = a[5],
          v0 = v[0],
          v1 = v[1];
        out[0] = a0 * v0;
        out[1] = a1 * v0;
        out[2] = a2 * v1;
        out[3] = a3 * v1;
        out[4] = a4;
        out[5] = a5;
        return out
      };

      /**
       * Translates the mat2d by the dimensions in the given vec2
       *
       * @param {mat2d} out the receiving matrix
       * @param {mat2d} a the matrix to translate
       * @param {vec2} v the vec2 to translate the matrix by
       * @returns {mat2d} out
       **/
      mat2d.translate = function(out, a, v) {
        var a0 = a[0],
          a1 = a[1],
          a2 = a[2],
          a3 = a[3],
          a4 = a[4],
          a5 = a[5],
          v0 = v[0],
          v1 = v[1];
        out[0] = a0;
        out[1] = a1;
        out[2] = a2;
        out[3] = a3;
        out[4] = a0 * v0 + a2 * v1 + a4;
        out[5] = a1 * v0 + a3 * v1 + a5;
        return out
      };

      /**
       * Returns a string representation of a mat2d
       *
       * @param {mat2d} a matrix to represent as a string
       * @returns {String} string representation of the matrix
       */
      mat2d.str = function(a) {
        return (
          'mat2d(' + a[0] + ', ' + a[1] + ', ' + a[2] + ', ' + a[3] + ', ' + a[4] + ', ' + a[5] + ')'
        )
      };

      /**
       * Returns Frobenius norm of a mat2d
       *
       * @param {mat2d} a the matrix to calculate Frobenius norm of
       * @returns {Number} Frobenius norm
       */
      mat2d.frob = function(a) {
        return Math.sqrt(
          Math.pow(a[0], 2) +
            Math.pow(a[1], 2) +
            Math.pow(a[2], 2) +
            Math.pow(a[3], 2) +
            Math.pow(a[4], 2) +
            Math.pow(a[5], 2) +
            1
        )
      };

      if (typeof exports !== 'undefined') {
        exports.mat2d = mat2d;
      }
      /* Copyright (c) 2013, Brandon Jones, Colin MacKenzie IV. All rights reserved.

  Redistribution and use in source and binary forms, with or without modification,
  are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this
      list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation 
      and/or other materials provided with the distribution.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */

      /**
       * @class 3x3 Matrix
       * @name mat3
       */

      var mat3 = {};

      /**
       * Creates a new identity mat3
       *
       * @returns {mat3} a new 3x3 matrix
       */
      mat3.create = function() {
        var out = new GLMAT_ARRAY_TYPE(9);
        out[0] = 1;
        out[1] = 0;
        out[2] = 0;
        out[3] = 0;
        out[4] = 1;
        out[5] = 0;
        out[6] = 0;
        out[7] = 0;
        out[8] = 1;
        return out
      };

      /**
       * Copies the upper-left 3x3 values into the given mat3.
       *
       * @param {mat3} out the receiving 3x3 matrix
       * @param {mat4} a   the source 4x4 matrix
       * @returns {mat3} out
       */
      mat3.fromMat4 = function(out, a) {
        out[0] = a[0];
        out[1] = a[1];
        out[2] = a[2];
        out[3] = a[4];
        out[4] = a[5];
        out[5] = a[6];
        out[6] = a[8];
        out[7] = a[9];
        out[8] = a[10];
        return out
      };

      /**
       * Creates a new mat3 initialized with values from an existing matrix
       *
       * @param {mat3} a matrix to clone
       * @returns {mat3} a new 3x3 matrix
       */
      mat3.clone = function(a) {
        var out = new GLMAT_ARRAY_TYPE(9);
        out[0] = a[0];
        out[1] = a[1];
        out[2] = a[2];
        out[3] = a[3];
        out[4] = a[4];
        out[5] = a[5];
        out[6] = a[6];
        out[7] = a[7];
        out[8] = a[8];
        return out
      };

      /**
       * Copy the values from one mat3 to another
       *
       * @param {mat3} out the receiving matrix
       * @param {mat3} a the source matrix
       * @returns {mat3} out
       */
      mat3.copy = function(out, a) {
        out[0] = a[0];
        out[1] = a[1];
        out[2] = a[2];
        out[3] = a[3];
        out[4] = a[4];
        out[5] = a[5];
        out[6] = a[6];
        out[7] = a[7];
        out[8] = a[8];
        return out
      };

      /**
       * Set a mat3 to the identity matrix
       *
       * @param {mat3} out the receiving matrix
       * @returns {mat3} out
       */
      mat3.identity = function(out) {
        out[0] = 1;
        out[1] = 0;
        out[2] = 0;
        out[3] = 0;
        out[4] = 1;
        out[5] = 0;
        out[6] = 0;
        out[7] = 0;
        out[8] = 1;
        return out
      };

      /**
       * Transpose the values of a mat3
       *
       * @param {mat3} out the receiving matrix
       * @param {mat3} a the source matrix
       * @returns {mat3} out
       */
      mat3.transpose = function(out, a) {
        // If we are transposing ourselves we can skip a few steps but have to cache some values
        if (out === a) {
          var a01 = a[1],
            a02 = a[2],
            a12 = a[5];
          out[1] = a[3];
          out[2] = a[6];
          out[3] = a01;
          out[5] = a[7];
          out[6] = a02;
          out[7] = a12;
        } else {
          out[0] = a[0];
          out[1] = a[3];
          out[2] = a[6];
          out[3] = a[1];
          out[4] = a[4];
          out[5] = a[7];
          out[6] = a[2];
          out[7] = a[5];
          out[8] = a[8];
        }

        return out
      };

      /**
       * Inverts a mat3
       *
       * @param {mat3} out the receiving matrix
       * @param {mat3} a the source matrix
       * @returns {mat3} out
       */
      mat3.invert = function(out, a) {
        var a00 = a[0],
          a01 = a[1],
          a02 = a[2],
          a10 = a[3],
          a11 = a[4],
          a12 = a[5],
          a20 = a[6],
          a21 = a[7],
          a22 = a[8],
          b01 = a22 * a11 - a12 * a21,
          b11 = -a22 * a10 + a12 * a20,
          b21 = a21 * a10 - a11 * a20,
          // Calculate the determinant
          det = a00 * b01 + a01 * b11 + a02 * b21;

        if (!det) {
          return null
        }
        det = 1.0 / det;

        out[0] = b01 * det;
        out[1] = (-a22 * a01 + a02 * a21) * det;
        out[2] = (a12 * a01 - a02 * a11) * det;
        out[3] = b11 * det;
        out[4] = (a22 * a00 - a02 * a20) * det;
        out[5] = (-a12 * a00 + a02 * a10) * det;
        out[6] = b21 * det;
        out[7] = (-a21 * a00 + a01 * a20) * det;
        out[8] = (a11 * a00 - a01 * a10) * det;
        return out
      };

      /**
       * Calculates the adjugate of a mat3
       *
       * @param {mat3} out the receiving matrix
       * @param {mat3} a the source matrix
       * @returns {mat3} out
       */
      mat3.adjoint = function(out, a) {
        var a00 = a[0],
          a01 = a[1],
          a02 = a[2],
          a10 = a[3],
          a11 = a[4],
          a12 = a[5],
          a20 = a[6],
          a21 = a[7],
          a22 = a[8];

        out[0] = a11 * a22 - a12 * a21;
        out[1] = a02 * a21 - a01 * a22;
        out[2] = a01 * a12 - a02 * a11;
        out[3] = a12 * a20 - a10 * a22;
        out[4] = a00 * a22 - a02 * a20;
        out[5] = a02 * a10 - a00 * a12;
        out[6] = a10 * a21 - a11 * a20;
        out[7] = a01 * a20 - a00 * a21;
        out[8] = a00 * a11 - a01 * a10;
        return out
      };

      /**
       * Calculates the determinant of a mat3
       *
       * @param {mat3} a the source matrix
       * @returns {Number} determinant of a
       */
      mat3.determinant = function(a) {
        var a00 = a[0],
          a01 = a[1],
          a02 = a[2],
          a10 = a[3],
          a11 = a[4],
          a12 = a[5],
          a20 = a[6],
          a21 = a[7],
          a22 = a[8];

        return (
          a00 * (a22 * a11 - a12 * a21) +
          a01 * (-a22 * a10 + a12 * a20) +
          a02 * (a21 * a10 - a11 * a20)
        )
      };

      /**
       * Multiplies two mat3's
       *
       * @param {mat3} out the receiving matrix
       * @param {mat3} a the first operand
       * @param {mat3} b the second operand
       * @returns {mat3} out
       */
      mat3.multiply = function(out, a, b) {
        var a00 = a[0],
          a01 = a[1],
          a02 = a[2],
          a10 = a[3],
          a11 = a[4],
          a12 = a[5],
          a20 = a[6],
          a21 = a[7],
          a22 = a[8],
          b00 = b[0],
          b01 = b[1],
          b02 = b[2],
          b10 = b[3],
          b11 = b[4],
          b12 = b[5],
          b20 = b[6],
          b21 = b[7],
          b22 = b[8];

        out[0] = b00 * a00 + b01 * a10 + b02 * a20;
        out[1] = b00 * a01 + b01 * a11 + b02 * a21;
        out[2] = b00 * a02 + b01 * a12 + b02 * a22;

        out[3] = b10 * a00 + b11 * a10 + b12 * a20;
        out[4] = b10 * a01 + b11 * a11 + b12 * a21;
        out[5] = b10 * a02 + b11 * a12 + b12 * a22;

        out[6] = b20 * a00 + b21 * a10 + b22 * a20;
        out[7] = b20 * a01 + b21 * a11 + b22 * a21;
        out[8] = b20 * a02 + b21 * a12 + b22 * a22;
        return out
      };

      /**
       * Alias for {@link mat3.multiply}
       * @function
       */
      mat3.mul = mat3.multiply;

      /**
       * Translate a mat3 by the given vector
       *
       * @param {mat3} out the receiving matrix
       * @param {mat3} a the matrix to translate
       * @param {vec2} v vector to translate by
       * @returns {mat3} out
       */
      mat3.translate = function(out, a, v) {
        var a00 = a[0],
          a01 = a[1],
          a02 = a[2],
          a10 = a[3],
          a11 = a[4],
          a12 = a[5],
          a20 = a[6],
          a21 = a[7],
          a22 = a[8],
          x = v[0],
          y = v[1];

        out[0] = a00;
        out[1] = a01;
        out[2] = a02;

        out[3] = a10;
        out[4] = a11;
        out[5] = a12;

        out[6] = x * a00 + y * a10 + a20;
        out[7] = x * a01 + y * a11 + a21;
        out[8] = x * a02 + y * a12 + a22;
        return out
      };

      /**
       * Rotates a mat3 by the given angle
       *
       * @param {mat3} out the receiving matrix
       * @param {mat3} a the matrix to rotate
       * @param {Number} rad the angle to rotate the matrix by
       * @returns {mat3} out
       */
      mat3.rotate = function(out, a, rad) {
        var a00 = a[0],
          a01 = a[1],
          a02 = a[2],
          a10 = a[3],
          a11 = a[4],
          a12 = a[5],
          a20 = a[6],
          a21 = a[7],
          a22 = a[8],
          s = Math.sin(rad),
          c = Math.cos(rad);

        out[0] = c * a00 + s * a10;
        out[1] = c * a01 + s * a11;
        out[2] = c * a02 + s * a12;

        out[3] = c * a10 - s * a00;
        out[4] = c * a11 - s * a01;
        out[5] = c * a12 - s * a02;

        out[6] = a20;
        out[7] = a21;
        out[8] = a22;
        return out
      };

      /**
       * Scales the mat3 by the dimensions in the given vec2
       *
       * @param {mat3} out the receiving matrix
       * @param {mat3} a the matrix to rotate
       * @param {vec2} v the vec2 to scale the matrix by
       * @returns {mat3} out
       **/
      mat3.scale = function(out, a, v) {
        var x = v[0],
          y = v[1];

        out[0] = x * a[0];
        out[1] = x * a[1];
        out[2] = x * a[2];

        out[3] = y * a[3];
        out[4] = y * a[4];
        out[5] = y * a[5];

        out[6] = a[6];
        out[7] = a[7];
        out[8] = a[8];
        return out
      };

      /**
       * Copies the values from a mat2d into a mat3
       *
       * @param {mat3} out the receiving matrix
       * @param {mat2d} a the matrix to copy
       * @returns {mat3} out
       **/
      mat3.fromMat2d = function(out, a) {
        out[0] = a[0];
        out[1] = a[1];
        out[2] = 0;

        out[3] = a[2];
        out[4] = a[3];
        out[5] = 0;

        out[6] = a[4];
        out[7] = a[5];
        out[8] = 1;
        return out
      };

      /**
       * Calculates a 3x3 matrix from the given quaternion
       *
       * @param {mat3} out mat3 receiving operation result
       * @param {quat} q Quaternion to create matrix from
       *
       * @returns {mat3} out
       */
      mat3.fromQuat = function(out, q) {
        var x = q[0],
          y = q[1],
          z = q[2],
          w = q[3],
          x2 = x + x,
          y2 = y + y,
          z2 = z + z,
          xx = x * x2,
          yx = y * x2,
          yy = y * y2,
          zx = z * x2,
          zy = z * y2,
          zz = z * z2,
          wx = w * x2,
          wy = w * y2,
          wz = w * z2;

        out[0] = 1 - yy - zz;
        out[3] = yx - wz;
        out[6] = zx + wy;

        out[1] = yx + wz;
        out[4] = 1 - xx - zz;
        out[7] = zy - wx;

        out[2] = zx - wy;
        out[5] = zy + wx;
        out[8] = 1 - xx - yy;

        return out
      };

      /**
       * Calculates a 3x3 normal matrix (transpose inverse) from the 4x4 matrix
       *
       * @param {mat3} out mat3 receiving operation result
       * @param {mat4} a Mat4 to derive the normal matrix from
       *
       * @returns {mat3} out
       */
      mat3.normalFromMat4 = function(out, a) {
        var a00 = a[0],
          a01 = a[1],
          a02 = a[2],
          a03 = a[3],
          a10 = a[4],
          a11 = a[5],
          a12 = a[6],
          a13 = a[7],
          a20 = a[8],
          a21 = a[9],
          a22 = a[10],
          a23 = a[11],
          a30 = a[12],
          a31 = a[13],
          a32 = a[14],
          a33 = a[15],
          b00 = a00 * a11 - a01 * a10,
          b01 = a00 * a12 - a02 * a10,
          b02 = a00 * a13 - a03 * a10,
          b03 = a01 * a12 - a02 * a11,
          b04 = a01 * a13 - a03 * a11,
          b05 = a02 * a13 - a03 * a12,
          b06 = a20 * a31 - a21 * a30,
          b07 = a20 * a32 - a22 * a30,
          b08 = a20 * a33 - a23 * a30,
          b09 = a21 * a32 - a22 * a31,
          b10 = a21 * a33 - a23 * a31,
          b11 = a22 * a33 - a23 * a32,
          // Calculate the determinant
          det = b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;

        if (!det) {
          return null
        }
        det = 1.0 / det;

        out[0] = (a11 * b11 - a12 * b10 + a13 * b09) * det;
        out[1] = (a12 * b08 - a10 * b11 - a13 * b07) * det;
        out[2] = (a10 * b10 - a11 * b08 + a13 * b06) * det;

        out[3] = (a02 * b10 - a01 * b11 - a03 * b09) * det;
        out[4] = (a00 * b11 - a02 * b08 + a03 * b07) * det;
        out[5] = (a01 * b08 - a00 * b10 - a03 * b06) * det;

        out[6] = (a31 * b05 - a32 * b04 + a33 * b03) * det;
        out[7] = (a32 * b02 - a30 * b05 - a33 * b01) * det;
        out[8] = (a30 * b04 - a31 * b02 + a33 * b00) * det;

        return out
      };

      /**
       * Returns a string representation of a mat3
       *
       * @param {mat3} mat matrix to represent as a string
       * @returns {String} string representation of the matrix
       */
      mat3.str = function(a) {
        return (
          'mat3(' +
          a[0] +
          ', ' +
          a[1] +
          ', ' +
          a[2] +
          ', ' +
          a[3] +
          ', ' +
          a[4] +
          ', ' +
          a[5] +
          ', ' +
          a[6] +
          ', ' +
          a[7] +
          ', ' +
          a[8] +
          ')'
        )
      };

      /**
       * Returns Frobenius norm of a mat3
       *
       * @param {mat3} a the matrix to calculate Frobenius norm of
       * @returns {Number} Frobenius norm
       */
      mat3.frob = function(a) {
        return Math.sqrt(
          Math.pow(a[0], 2) +
            Math.pow(a[1], 2) +
            Math.pow(a[2], 2) +
            Math.pow(a[3], 2) +
            Math.pow(a[4], 2) +
            Math.pow(a[5], 2) +
            Math.pow(a[6], 2) +
            Math.pow(a[7], 2) +
            Math.pow(a[8], 2)
        )
      };

      if (typeof exports !== 'undefined') {
        exports.mat3 = mat3;
      }
      /* Copyright (c) 2013, Brandon Jones, Colin MacKenzie IV. All rights reserved.

  Redistribution and use in source and binary forms, with or without modification,
  are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this
      list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation 
      and/or other materials provided with the distribution.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */

      /**
       * @class 4x4 Matrix
       * @name mat4
       */

      var mat4 = {};

      /**
       * Creates a new identity mat4
       *
       * @returns {mat4} a new 4x4 matrix
       */
      mat4.create = function() {
        var out = new GLMAT_ARRAY_TYPE(16);
        out[0] = 1;
        out[1] = 0;
        out[2] = 0;
        out[3] = 0;
        out[4] = 0;
        out[5] = 1;
        out[6] = 0;
        out[7] = 0;
        out[8] = 0;
        out[9] = 0;
        out[10] = 1;
        out[11] = 0;
        out[12] = 0;
        out[13] = 0;
        out[14] = 0;
        out[15] = 1;
        return out
      };

      /**
       * Creates a new mat4 initialized with values from an existing matrix
       *
       * @param {mat4} a matrix to clone
       * @returns {mat4} a new 4x4 matrix
       */
      mat4.clone = function(a) {
        var out = new GLMAT_ARRAY_TYPE(16);
        out[0] = a[0];
        out[1] = a[1];
        out[2] = a[2];
        out[3] = a[3];
        out[4] = a[4];
        out[5] = a[5];
        out[6] = a[6];
        out[7] = a[7];
        out[8] = a[8];
        out[9] = a[9];
        out[10] = a[10];
        out[11] = a[11];
        out[12] = a[12];
        out[13] = a[13];
        out[14] = a[14];
        out[15] = a[15];
        return out
      };

      /**
       * Copy the values from one mat4 to another
       *
       * @param {mat4} out the receiving matrix
       * @param {mat4} a the source matrix
       * @returns {mat4} out
       */
      mat4.copy = function(out, a) {
        out[0] = a[0];
        out[1] = a[1];
        out[2] = a[2];
        out[3] = a[3];
        out[4] = a[4];
        out[5] = a[5];
        out[6] = a[6];
        out[7] = a[7];
        out[8] = a[8];
        out[9] = a[9];
        out[10] = a[10];
        out[11] = a[11];
        out[12] = a[12];
        out[13] = a[13];
        out[14] = a[14];
        out[15] = a[15];
        return out
      };

      /**
       * Set a mat4 to the identity matrix
       *
       * @param {mat4} out the receiving matrix
       * @returns {mat4} out
       */
      mat4.identity = function(out) {
        out[0] = 1;
        out[1] = 0;
        out[2] = 0;
        out[3] = 0;
        out[4] = 0;
        out[5] = 1;
        out[6] = 0;
        out[7] = 0;
        out[8] = 0;
        out[9] = 0;
        out[10] = 1;
        out[11] = 0;
        out[12] = 0;
        out[13] = 0;
        out[14] = 0;
        out[15] = 1;
        return out
      };

      /**
       * Transpose the values of a mat4
       *
       * @param {mat4} out the receiving matrix
       * @param {mat4} a the source matrix
       * @returns {mat4} out
       */
      mat4.transpose = function(out, a) {
        // If we are transposing ourselves we can skip a few steps but have to cache some values
        if (out === a) {
          var a01 = a[1],
            a02 = a[2],
            a03 = a[3],
            a12 = a[6],
            a13 = a[7],
            a23 = a[11];

          out[1] = a[4];
          out[2] = a[8];
          out[3] = a[12];
          out[4] = a01;
          out[6] = a[9];
          out[7] = a[13];
          out[8] = a02;
          out[9] = a12;
          out[11] = a[14];
          out[12] = a03;
          out[13] = a13;
          out[14] = a23;
        } else {
          out[0] = a[0];
          out[1] = a[4];
          out[2] = a[8];
          out[3] = a[12];
          out[4] = a[1];
          out[5] = a[5];
          out[6] = a[9];
          out[7] = a[13];
          out[8] = a[2];
          out[9] = a[6];
          out[10] = a[10];
          out[11] = a[14];
          out[12] = a[3];
          out[13] = a[7];
          out[14] = a[11];
          out[15] = a[15];
        }

        return out
      };

      /**
       * Inverts a mat4
       *
       * @param {mat4} out the receiving matrix
       * @param {mat4} a the source matrix
       * @returns {mat4} out
       */
      mat4.invert = function(out, a) {
        var a00 = a[0],
          a01 = a[1],
          a02 = a[2],
          a03 = a[3],
          a10 = a[4],
          a11 = a[5],
          a12 = a[6],
          a13 = a[7],
          a20 = a[8],
          a21 = a[9],
          a22 = a[10],
          a23 = a[11],
          a30 = a[12],
          a31 = a[13],
          a32 = a[14],
          a33 = a[15],
          b00 = a00 * a11 - a01 * a10,
          b01 = a00 * a12 - a02 * a10,
          b02 = a00 * a13 - a03 * a10,
          b03 = a01 * a12 - a02 * a11,
          b04 = a01 * a13 - a03 * a11,
          b05 = a02 * a13 - a03 * a12,
          b06 = a20 * a31 - a21 * a30,
          b07 = a20 * a32 - a22 * a30,
          b08 = a20 * a33 - a23 * a30,
          b09 = a21 * a32 - a22 * a31,
          b10 = a21 * a33 - a23 * a31,
          b11 = a22 * a33 - a23 * a32,
          // Calculate the determinant
          det = b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;

        if (!det) {
          return null
        }
        det = 1.0 / det;

        out[0] = (a11 * b11 - a12 * b10 + a13 * b09) * det;
        out[1] = (a02 * b10 - a01 * b11 - a03 * b09) * det;
        out[2] = (a31 * b05 - a32 * b04 + a33 * b03) * det;
        out[3] = (a22 * b04 - a21 * b05 - a23 * b03) * det;
        out[4] = (a12 * b08 - a10 * b11 - a13 * b07) * det;
        out[5] = (a00 * b11 - a02 * b08 + a03 * b07) * det;
        out[6] = (a32 * b02 - a30 * b05 - a33 * b01) * det;
        out[7] = (a20 * b05 - a22 * b02 + a23 * b01) * det;
        out[8] = (a10 * b10 - a11 * b08 + a13 * b06) * det;
        out[9] = (a01 * b08 - a00 * b10 - a03 * b06) * det;
        out[10] = (a30 * b04 - a31 * b02 + a33 * b00) * det;
        out[11] = (a21 * b02 - a20 * b04 - a23 * b00) * det;
        out[12] = (a11 * b07 - a10 * b09 - a12 * b06) * det;
        out[13] = (a00 * b09 - a01 * b07 + a02 * b06) * det;
        out[14] = (a31 * b01 - a30 * b03 - a32 * b00) * det;
        out[15] = (a20 * b03 - a21 * b01 + a22 * b00) * det;

        return out
      };

      /**
       * Calculates the adjugate of a mat4
       *
       * @param {mat4} out the receiving matrix
       * @param {mat4} a the source matrix
       * @returns {mat4} out
       */
      mat4.adjoint = function(out, a) {
        var a00 = a[0],
          a01 = a[1],
          a02 = a[2],
          a03 = a[3],
          a10 = a[4],
          a11 = a[5],
          a12 = a[6],
          a13 = a[7],
          a20 = a[8],
          a21 = a[9],
          a22 = a[10],
          a23 = a[11],
          a30 = a[12],
          a31 = a[13],
          a32 = a[14],
          a33 = a[15];

        out[0] =
          a11 * (a22 * a33 - a23 * a32) -
          a21 * (a12 * a33 - a13 * a32) +
          a31 * (a12 * a23 - a13 * a22);
        out[1] = -(
          a01 * (a22 * a33 - a23 * a32) -
          a21 * (a02 * a33 - a03 * a32) +
          a31 * (a02 * a23 - a03 * a22)
        );
        out[2] =
          a01 * (a12 * a33 - a13 * a32) -
          a11 * (a02 * a33 - a03 * a32) +
          a31 * (a02 * a13 - a03 * a12);
        out[3] = -(
          a01 * (a12 * a23 - a13 * a22) -
          a11 * (a02 * a23 - a03 * a22) +
          a21 * (a02 * a13 - a03 * a12)
        );
        out[4] = -(
          a10 * (a22 * a33 - a23 * a32) -
          a20 * (a12 * a33 - a13 * a32) +
          a30 * (a12 * a23 - a13 * a22)
        );
        out[5] =
          a00 * (a22 * a33 - a23 * a32) -
          a20 * (a02 * a33 - a03 * a32) +
          a30 * (a02 * a23 - a03 * a22);
        out[6] = -(
          a00 * (a12 * a33 - a13 * a32) -
          a10 * (a02 * a33 - a03 * a32) +
          a30 * (a02 * a13 - a03 * a12)
        );
        out[7] =
          a00 * (a12 * a23 - a13 * a22) -
          a10 * (a02 * a23 - a03 * a22) +
          a20 * (a02 * a13 - a03 * a12);
        out[8] =
          a10 * (a21 * a33 - a23 * a31) -
          a20 * (a11 * a33 - a13 * a31) +
          a30 * (a11 * a23 - a13 * a21);
        out[9] = -(
          a00 * (a21 * a33 - a23 * a31) -
          a20 * (a01 * a33 - a03 * a31) +
          a30 * (a01 * a23 - a03 * a21)
        );
        out[10] =
          a00 * (a11 * a33 - a13 * a31) -
          a10 * (a01 * a33 - a03 * a31) +
          a30 * (a01 * a13 - a03 * a11);
        out[11] = -(
          a00 * (a11 * a23 - a13 * a21) -
          a10 * (a01 * a23 - a03 * a21) +
          a20 * (a01 * a13 - a03 * a11)
        );
        out[12] = -(
          a10 * (a21 * a32 - a22 * a31) -
          a20 * (a11 * a32 - a12 * a31) +
          a30 * (a11 * a22 - a12 * a21)
        );
        out[13] =
          a00 * (a21 * a32 - a22 * a31) -
          a20 * (a01 * a32 - a02 * a31) +
          a30 * (a01 * a22 - a02 * a21);
        out[14] = -(
          a00 * (a11 * a32 - a12 * a31) -
          a10 * (a01 * a32 - a02 * a31) +
          a30 * (a01 * a12 - a02 * a11)
        );
        out[15] =
          a00 * (a11 * a22 - a12 * a21) -
          a10 * (a01 * a22 - a02 * a21) +
          a20 * (a01 * a12 - a02 * a11);
        return out
      };

      /**
       * Calculates the determinant of a mat4
       *
       * @param {mat4} a the source matrix
       * @returns {Number} determinant of a
       */
      mat4.determinant = function(a) {
        var a00 = a[0],
          a01 = a[1],
          a02 = a[2],
          a03 = a[3],
          a10 = a[4],
          a11 = a[5],
          a12 = a[6],
          a13 = a[7],
          a20 = a[8],
          a21 = a[9],
          a22 = a[10],
          a23 = a[11],
          a30 = a[12],
          a31 = a[13],
          a32 = a[14],
          a33 = a[15],
          b00 = a00 * a11 - a01 * a10,
          b01 = a00 * a12 - a02 * a10,
          b02 = a00 * a13 - a03 * a10,
          b03 = a01 * a12 - a02 * a11,
          b04 = a01 * a13 - a03 * a11,
          b05 = a02 * a13 - a03 * a12,
          b06 = a20 * a31 - a21 * a30,
          b07 = a20 * a32 - a22 * a30,
          b08 = a20 * a33 - a23 * a30,
          b09 = a21 * a32 - a22 * a31,
          b10 = a21 * a33 - a23 * a31,
          b11 = a22 * a33 - a23 * a32;

        // Calculate the determinant
        return b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06
      };

      /**
       * Multiplies two mat4's
       *
       * @param {mat4} out the receiving matrix
       * @param {mat4} a the first operand
       * @param {mat4} b the second operand
       * @returns {mat4} out
       */
      mat4.multiply = function(out, a, b) {
        var a00 = a[0],
          a01 = a[1],
          a02 = a[2],
          a03 = a[3],
          a10 = a[4],
          a11 = a[5],
          a12 = a[6],
          a13 = a[7],
          a20 = a[8],
          a21 = a[9],
          a22 = a[10],
          a23 = a[11],
          a30 = a[12],
          a31 = a[13],
          a32 = a[14],
          a33 = a[15];

        // Cache only the current line of the second matrix
        var b0 = b[0],
          b1 = b[1],
          b2 = b[2],
          b3 = b[3];
        out[0] = b0 * a00 + b1 * a10 + b2 * a20 + b3 * a30;
        out[1] = b0 * a01 + b1 * a11 + b2 * a21 + b3 * a31;
        out[2] = b0 * a02 + b1 * a12 + b2 * a22 + b3 * a32;
        out[3] = b0 * a03 + b1 * a13 + b2 * a23 + b3 * a33;

        b0 = b[4];
        b1 = b[5];
        b2 = b[6];
        b3 = b[7];
        out[4] = b0 * a00 + b1 * a10 + b2 * a20 + b3 * a30;
        out[5] = b0 * a01 + b1 * a11 + b2 * a21 + b3 * a31;
        out[6] = b0 * a02 + b1 * a12 + b2 * a22 + b3 * a32;
        out[7] = b0 * a03 + b1 * a13 + b2 * a23 + b3 * a33;

        b0 = b[8];
        b1 = b[9];
        b2 = b[10];
        b3 = b[11];
        out[8] = b0 * a00 + b1 * a10 + b2 * a20 + b3 * a30;
        out[9] = b0 * a01 + b1 * a11 + b2 * a21 + b3 * a31;
        out[10] = b0 * a02 + b1 * a12 + b2 * a22 + b3 * a32;
        out[11] = b0 * a03 + b1 * a13 + b2 * a23 + b3 * a33;

        b0 = b[12];
        b1 = b[13];
        b2 = b[14];
        b3 = b[15];
        out[12] = b0 * a00 + b1 * a10 + b2 * a20 + b3 * a30;
        out[13] = b0 * a01 + b1 * a11 + b2 * a21 + b3 * a31;
        out[14] = b0 * a02 + b1 * a12 + b2 * a22 + b3 * a32;
        out[15] = b0 * a03 + b1 * a13 + b2 * a23 + b3 * a33;
        return out
      };

      /**
       * Alias for {@link mat4.multiply}
       * @function
       */
      mat4.mul = mat4.multiply;

      /**
       * Translate a mat4 by the given vector
       *
       * @param {mat4} out the receiving matrix
       * @param {mat4} a the matrix to translate
       * @param {vec3} v vector to translate by
       * @returns {mat4} out
       */
      mat4.translate = function(out, a, v) {
        var x = v[0],
          y = v[1],
          z = v[2],
          a00,
          a01,
          a02,
          a03,
          a10,
          a11,
          a12,
          a13,
          a20,
          a21,
          a22,
          a23;

        if (a === out) {
          out[12] = a[0] * x + a[4] * y + a[8] * z + a[12];
          out[13] = a[1] * x + a[5] * y + a[9] * z + a[13];
          out[14] = a[2] * x + a[6] * y + a[10] * z + a[14];
          out[15] = a[3] * x + a[7] * y + a[11] * z + a[15];
        } else {
          a00 = a[0];
          a01 = a[1];
          a02 = a[2];
          a03 = a[3];
          a10 = a[4];
          a11 = a[5];
          a12 = a[6];
          a13 = a[7];
          a20 = a[8];
          a21 = a[9];
          a22 = a[10];
          a23 = a[11];

          out[0] = a00;
          out[1] = a01;
          out[2] = a02;
          out[3] = a03;
          out[4] = a10;
          out[5] = a11;
          out[6] = a12;
          out[7] = a13;
          out[8] = a20;
          out[9] = a21;
          out[10] = a22;
          out[11] = a23;

          out[12] = a00 * x + a10 * y + a20 * z + a[12];
          out[13] = a01 * x + a11 * y + a21 * z + a[13];
          out[14] = a02 * x + a12 * y + a22 * z + a[14];
          out[15] = a03 * x + a13 * y + a23 * z + a[15];
        }

        return out
      };

      /**
       * Scales the mat4 by the dimensions in the given vec3
       *
       * @param {mat4} out the receiving matrix
       * @param {mat4} a the matrix to scale
       * @param {vec3} v the vec3 to scale the matrix by
       * @returns {mat4} out
       **/
      mat4.scale = function(out, a, v) {
        var x = v[0],
          y = v[1],
          z = v[2];

        out[0] = a[0] * x;
        out[1] = a[1] * x;
        out[2] = a[2] * x;
        out[3] = a[3] * x;
        out[4] = a[4] * y;
        out[5] = a[5] * y;
        out[6] = a[6] * y;
        out[7] = a[7] * y;
        out[8] = a[8] * z;
        out[9] = a[9] * z;
        out[10] = a[10] * z;
        out[11] = a[11] * z;
        out[12] = a[12];
        out[13] = a[13];
        out[14] = a[14];
        out[15] = a[15];
        return out
      };

      /**
       * Rotates a mat4 by the given angle
       *
       * @param {mat4} out the receiving matrix
       * @param {mat4} a the matrix to rotate
       * @param {Number} rad the angle to rotate the matrix by
       * @param {vec3} axis the axis to rotate around
       * @returns {mat4} out
       */
      mat4.rotate = function(out, a, rad, axis) {
        var x = axis[0],
          y = axis[1],
          z = axis[2],
          len = Math.sqrt(x * x + y * y + z * z),
          s,
          c,
          t,
          a00,
          a01,
          a02,
          a03,
          a10,
          a11,
          a12,
          a13,
          a20,
          a21,
          a22,
          a23,
          b00,
          b01,
          b02,
          b10,
          b11,
          b12,
          b20,
          b21,
          b22;

        if (Math.abs(len) < GLMAT_EPSILON) {
          return null
        }

        len = 1 / len;
        x *= len;
        y *= len;
        z *= len;

        s = Math.sin(rad);
        c = Math.cos(rad);
        t = 1 - c;

        a00 = a[0];
        a01 = a[1];
        a02 = a[2];
        a03 = a[3];
        a10 = a[4];
        a11 = a[5];
        a12 = a[6];
        a13 = a[7];
        a20 = a[8];
        a21 = a[9];
        a22 = a[10];
        a23 = a[11];

        // Construct the elements of the rotation matrix
        b00 = x * x * t + c;
        b01 = y * x * t + z * s;
        b02 = z * x * t - y * s;
        b10 = x * y * t - z * s;
        b11 = y * y * t + c;
        b12 = z * y * t + x * s;
        b20 = x * z * t + y * s;
        b21 = y * z * t - x * s;
        b22 = z * z * t + c;

        // Perform rotation-specific matrix multiplication
        out[0] = a00 * b00 + a10 * b01 + a20 * b02;
        out[1] = a01 * b00 + a11 * b01 + a21 * b02;
        out[2] = a02 * b00 + a12 * b01 + a22 * b02;
        out[3] = a03 * b00 + a13 * b01 + a23 * b02;
        out[4] = a00 * b10 + a10 * b11 + a20 * b12;
        out[5] = a01 * b10 + a11 * b11 + a21 * b12;
        out[6] = a02 * b10 + a12 * b11 + a22 * b12;
        out[7] = a03 * b10 + a13 * b11 + a23 * b12;
        out[8] = a00 * b20 + a10 * b21 + a20 * b22;
        out[9] = a01 * b20 + a11 * b21 + a21 * b22;
        out[10] = a02 * b20 + a12 * b21 + a22 * b22;
        out[11] = a03 * b20 + a13 * b21 + a23 * b22;

        if (a !== out) {
          // If the source and destination differ, copy the unchanged last row
          out[12] = a[12];
          out[13] = a[13];
          out[14] = a[14];
          out[15] = a[15];
        }
        return out
      };

      /**
       * Rotates a matrix by the given angle around the X axis
       *
       * @param {mat4} out the receiving matrix
       * @param {mat4} a the matrix to rotate
       * @param {Number} rad the angle to rotate the matrix by
       * @returns {mat4} out
       */
      mat4.rotateX = function(out, a, rad) {
        var s = Math.sin(rad),
          c = Math.cos(rad),
          a10 = a[4],
          a11 = a[5],
          a12 = a[6],
          a13 = a[7],
          a20 = a[8],
          a21 = a[9],
          a22 = a[10],
          a23 = a[11];

        if (a !== out) {
          // If the source and destination differ, copy the unchanged rows
          out[0] = a[0];
          out[1] = a[1];
          out[2] = a[2];
          out[3] = a[3];
          out[12] = a[12];
          out[13] = a[13];
          out[14] = a[14];
          out[15] = a[15];
        }

        // Perform axis-specific matrix multiplication
        out[4] = a10 * c + a20 * s;
        out[5] = a11 * c + a21 * s;
        out[6] = a12 * c + a22 * s;
        out[7] = a13 * c + a23 * s;
        out[8] = a20 * c - a10 * s;
        out[9] = a21 * c - a11 * s;
        out[10] = a22 * c - a12 * s;
        out[11] = a23 * c - a13 * s;
        return out
      };

      /**
       * Rotates a matrix by the given angle around the Y axis
       *
       * @param {mat4} out the receiving matrix
       * @param {mat4} a the matrix to rotate
       * @param {Number} rad the angle to rotate the matrix by
       * @returns {mat4} out
       */
      mat4.rotateY = function(out, a, rad) {
        var s = Math.sin(rad),
          c = Math.cos(rad),
          a00 = a[0],
          a01 = a[1],
          a02 = a[2],
          a03 = a[3],
          a20 = a[8],
          a21 = a[9],
          a22 = a[10],
          a23 = a[11];

        if (a !== out) {
          // If the source and destination differ, copy the unchanged rows
          out[4] = a[4];
          out[5] = a[5];
          out[6] = a[6];
          out[7] = a[7];
          out[12] = a[12];
          out[13] = a[13];
          out[14] = a[14];
          out[15] = a[15];
        }

        // Perform axis-specific matrix multiplication
        out[0] = a00 * c - a20 * s;
        out[1] = a01 * c - a21 * s;
        out[2] = a02 * c - a22 * s;
        out[3] = a03 * c - a23 * s;
        out[8] = a00 * s + a20 * c;
        out[9] = a01 * s + a21 * c;
        out[10] = a02 * s + a22 * c;
        out[11] = a03 * s + a23 * c;
        return out
      };

      /**
       * Rotates a matrix by the given angle around the Z axis
       *
       * @param {mat4} out the receiving matrix
       * @param {mat4} a the matrix to rotate
       * @param {Number} rad the angle to rotate the matrix by
       * @returns {mat4} out
       */
      mat4.rotateZ = function(out, a, rad) {
        var s = Math.sin(rad),
          c = Math.cos(rad),
          a00 = a[0],
          a01 = a[1],
          a02 = a[2],
          a03 = a[3],
          a10 = a[4],
          a11 = a[5],
          a12 = a[6],
          a13 = a[7];

        if (a !== out) {
          // If the source and destination differ, copy the unchanged last row
          out[8] = a[8];
          out[9] = a[9];
          out[10] = a[10];
          out[11] = a[11];
          out[12] = a[12];
          out[13] = a[13];
          out[14] = a[14];
          out[15] = a[15];
        }

        // Perform axis-specific matrix multiplication
        out[0] = a00 * c + a10 * s;
        out[1] = a01 * c + a11 * s;
        out[2] = a02 * c + a12 * s;
        out[3] = a03 * c + a13 * s;
        out[4] = a10 * c - a00 * s;
        out[5] = a11 * c - a01 * s;
        out[6] = a12 * c - a02 * s;
        out[7] = a13 * c - a03 * s;
        return out
      };

      /**
       * Creates a matrix from a quaternion rotation and vector translation
       * This is equivalent to (but much faster than):
       *
       *     mat4.identity(dest);
       *     mat4.translate(dest, vec);
       *     var quatMat = mat4.create();
       *     quat4.toMat4(quat, quatMat);
       *     mat4.multiply(dest, quatMat);
       *
       * @param {mat4} out mat4 receiving operation result
       * @param {quat4} q Rotation quaternion
       * @param {vec3} v Translation vector
       * @returns {mat4} out
       */
      mat4.fromRotationTranslation = function(out, q, v) {
        // Quaternion math
        var x = q[0],
          y = q[1],
          z = q[2],
          w = q[3],
          x2 = x + x,
          y2 = y + y,
          z2 = z + z,
          xx = x * x2,
          xy = x * y2,
          xz = x * z2,
          yy = y * y2,
          yz = y * z2,
          zz = z * z2,
          wx = w * x2,
          wy = w * y2,
          wz = w * z2;

        out[0] = 1 - (yy + zz);
        out[1] = xy + wz;
        out[2] = xz - wy;
        out[3] = 0;
        out[4] = xy - wz;
        out[5] = 1 - (xx + zz);
        out[6] = yz + wx;
        out[7] = 0;
        out[8] = xz + wy;
        out[9] = yz - wx;
        out[10] = 1 - (xx + yy);
        out[11] = 0;
        out[12] = v[0];
        out[13] = v[1];
        out[14] = v[2];
        out[15] = 1;

        return out
      };

      mat4.fromQuat = function(out, q) {
        var x = q[0],
          y = q[1],
          z = q[2],
          w = q[3],
          x2 = x + x,
          y2 = y + y,
          z2 = z + z,
          xx = x * x2,
          yx = y * x2,
          yy = y * y2,
          zx = z * x2,
          zy = z * y2,
          zz = z * z2,
          wx = w * x2,
          wy = w * y2,
          wz = w * z2;

        out[0] = 1 - yy - zz;
        out[1] = yx + wz;
        out[2] = zx - wy;
        out[3] = 0;

        out[4] = yx - wz;
        out[5] = 1 - xx - zz;
        out[6] = zy + wx;
        out[7] = 0;

        out[8] = zx + wy;
        out[9] = zy - wx;
        out[10] = 1 - xx - yy;
        out[11] = 0;

        out[12] = 0;
        out[13] = 0;
        out[14] = 0;
        out[15] = 1;

        return out
      };

      /**
       * Generates a frustum matrix with the given bounds
       *
       * @param {mat4} out mat4 frustum matrix will be written into
       * @param {Number} left Left bound of the frustum
       * @param {Number} right Right bound of the frustum
       * @param {Number} bottom Bottom bound of the frustum
       * @param {Number} top Top bound of the frustum
       * @param {Number} near Near bound of the frustum
       * @param {Number} far Far bound of the frustum
       * @returns {mat4} out
       */
      mat4.frustum = function(out, left, right, bottom, top, near, far) {
        var rl = 1 / (right - left),
          tb = 1 / (top - bottom),
          nf = 1 / (near - far);
        out[0] = near * 2 * rl;
        out[1] = 0;
        out[2] = 0;
        out[3] = 0;
        out[4] = 0;
        out[5] = near * 2 * tb;
        out[6] = 0;
        out[7] = 0;
        out[8] = (right + left) * rl;
        out[9] = (top + bottom) * tb;
        out[10] = (far + near) * nf;
        out[11] = -1;
        out[12] = 0;
        out[13] = 0;
        out[14] = far * near * 2 * nf;
        out[15] = 0;
        return out
      };

      /**
       * Generates a perspective projection matrix with the given bounds
       *
       * @param {mat4} out mat4 frustum matrix will be written into
       * @param {number} fovy Vertical field of view in radians
       * @param {number} aspect Aspect ratio. typically viewport width/height
       * @param {number} near Near bound of the frustum
       * @param {number} far Far bound of the frustum
       * @returns {mat4} out
       */
      mat4.perspective = function(out, fovy, aspect, near, far) {
        var f = 1.0 / Math.tan(fovy / 2),
          nf = 1 / (near - far);
        out[0] = f / aspect;
        out[1] = 0;
        out[2] = 0;
        out[3] = 0;
        out[4] = 0;
        out[5] = f;
        out[6] = 0;
        out[7] = 0;
        out[8] = 0;
        out[9] = 0;
        out[10] = (far + near) * nf;
        out[11] = -1;
        out[12] = 0;
        out[13] = 0;
        out[14] = 2 * far * near * nf;
        out[15] = 0;
        return out
      };

      /**
       * Generates a orthogonal projection matrix with the given bounds
       *
       * @param {mat4} out mat4 frustum matrix will be written into
       * @param {number} left Left bound of the frustum
       * @param {number} right Right bound of the frustum
       * @param {number} bottom Bottom bound of the frustum
       * @param {number} top Top bound of the frustum
       * @param {number} near Near bound of the frustum
       * @param {number} far Far bound of the frustum
       * @returns {mat4} out
       */
      mat4.ortho = function(out, left, right, bottom, top, near, far) {
        var lr = 1 / (left - right),
          bt = 1 / (bottom - top),
          nf = 1 / (near - far);
        out[0] = -2 * lr;
        out[1] = 0;
        out[2] = 0;
        out[3] = 0;
        out[4] = 0;
        out[5] = -2 * bt;
        out[6] = 0;
        out[7] = 0;
        out[8] = 0;
        out[9] = 0;
        out[10] = 2 * nf;
        out[11] = 0;
        out[12] = (left + right) * lr;
        out[13] = (top + bottom) * bt;
        out[14] = (far + near) * nf;
        out[15] = 1;
        return out
      };

      /**
       * Generates a look-at matrix with the given eye position, focal point, and up axis
       *
       * @param {mat4} out mat4 frustum matrix will be written into
       * @param {vec3} eye Position of the viewer
       * @param {vec3} center Point the viewer is looking at
       * @param {vec3} up vec3 pointing up
       * @returns {mat4} out
       */
      mat4.lookAt = function(out, eye, center, up) {
        var x0,
          x1,
          x2,
          y0,
          y1,
          y2,
          z0,
          z1,
          z2,
          len,
          eyex = eye[0],
          eyey = eye[1],
          eyez = eye[2],
          upx = up[0],
          upy = up[1],
          upz = up[2],
          centerx = center[0],
          centery = center[1],
          centerz = center[2];

        if (
          Math.abs(eyex - centerx) < GLMAT_EPSILON &&
          Math.abs(eyey - centery) < GLMAT_EPSILON &&
          Math.abs(eyez - centerz) < GLMAT_EPSILON
        ) {
          return mat4.identity(out)
        }

        z0 = eyex - centerx;
        z1 = eyey - centery;
        z2 = eyez - centerz;

        len = 1 / Math.sqrt(z0 * z0 + z1 * z1 + z2 * z2);
        z0 *= len;
        z1 *= len;
        z2 *= len;

        x0 = upy * z2 - upz * z1;
        x1 = upz * z0 - upx * z2;
        x2 = upx * z1 - upy * z0;
        len = Math.sqrt(x0 * x0 + x1 * x1 + x2 * x2);
        if (!len) {
          x0 = 0;
          x1 = 0;
          x2 = 0;
        } else {
          len = 1 / len;
          x0 *= len;
          x1 *= len;
          x2 *= len;
        }

        y0 = z1 * x2 - z2 * x1;
        y1 = z2 * x0 - z0 * x2;
        y2 = z0 * x1 - z1 * x0;

        len = Math.sqrt(y0 * y0 + y1 * y1 + y2 * y2);
        if (!len) {
          y0 = 0;
          y1 = 0;
          y2 = 0;
        } else {
          len = 1 / len;
          y0 *= len;
          y1 *= len;
          y2 *= len;
        }

        out[0] = x0;
        out[1] = y0;
        out[2] = z0;
        out[3] = 0;
        out[4] = x1;
        out[5] = y1;
        out[6] = z1;
        out[7] = 0;
        out[8] = x2;
        out[9] = y2;
        out[10] = z2;
        out[11] = 0;
        out[12] = -(x0 * eyex + x1 * eyey + x2 * eyez);
        out[13] = -(y0 * eyex + y1 * eyey + y2 * eyez);
        out[14] = -(z0 * eyex + z1 * eyey + z2 * eyez);
        out[15] = 1;

        return out
      };

      /**
       * Returns a string representation of a mat4
       *
       * @param {mat4} mat matrix to represent as a string
       * @returns {String} string representation of the matrix
       */
      mat4.str = function(a) {
        return (
          'mat4(' +
          a[0] +
          ', ' +
          a[1] +
          ', ' +
          a[2] +
          ', ' +
          a[3] +
          ', ' +
          a[4] +
          ', ' +
          a[5] +
          ', ' +
          a[6] +
          ', ' +
          a[7] +
          ', ' +
          a[8] +
          ', ' +
          a[9] +
          ', ' +
          a[10] +
          ', ' +
          a[11] +
          ', ' +
          a[12] +
          ', ' +
          a[13] +
          ', ' +
          a[14] +
          ', ' +
          a[15] +
          ')'
        )
      };

      /**
       * Returns Frobenius norm of a mat4
       *
       * @param {mat4} a the matrix to calculate Frobenius norm of
       * @returns {Number} Frobenius norm
       */
      mat4.frob = function(a) {
        return Math.sqrt(
          Math.pow(a[0], 2) +
            Math.pow(a[1], 2) +
            Math.pow(a[2], 2) +
            Math.pow(a[3], 2) +
            Math.pow(a[4], 2) +
            Math.pow(a[5], 2) +
            Math.pow(a[6], 2) +
            Math.pow(a[7], 2) +
            Math.pow(a[8], 2) +
            Math.pow(a[9], 2) +
            Math.pow(a[10], 2) +
            Math.pow(a[11], 2) +
            Math.pow(a[12], 2) +
            Math.pow(a[13], 2) +
            Math.pow(a[14], 2) +
            Math.pow(a[15], 2)
        )
      };

      if (typeof exports !== 'undefined') {
        exports.mat4 = mat4;
      }
      /* Copyright (c) 2013, Brandon Jones, Colin MacKenzie IV. All rights reserved.

  Redistribution and use in source and binary forms, with or without modification,
  are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this
      list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation 
      and/or other materials provided with the distribution.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */

      /**
       * @class Quaternion
       * @name quat
       */

      var quat = {};

      /**
       * Creates a new identity quat
       *
       * @returns {quat} a new quaternion
       */
      quat.create = function() {
        var out = new GLMAT_ARRAY_TYPE(4);
        out[0] = 0;
        out[1] = 0;
        out[2] = 0;
        out[3] = 1;
        return out
      };

      /**
       * Sets a quaternion to represent the shortest rotation from one
       * vector to another.
       *
       * Both vectors are assumed to be unit length.
       *
       * @param {quat} out the receiving quaternion.
       * @param {vec3} a the initial vector
       * @param {vec3} b the destination vector
       * @returns {quat} out
       */
      quat.rotationTo = (function() {
        var tmpvec3 = vec3.create();
        var xUnitVec3 = vec3.fromValues(1, 0, 0);
        var yUnitVec3 = vec3.fromValues(0, 1, 0);

        return function(out, a, b) {
          var dot = vec3.dot(a, b);
          if (dot < -0.999999) {
            vec3.cross(tmpvec3, xUnitVec3, a);
            if (vec3.length(tmpvec3) < 0.000001) vec3.cross(tmpvec3, yUnitVec3, a);
            vec3.normalize(tmpvec3, tmpvec3);
            quat.setAxisAngle(out, tmpvec3, Math.PI);
            return out
          } else if (dot > 0.999999) {
            out[0] = 0;
            out[1] = 0;
            out[2] = 0;
            out[3] = 1;
            return out
          } else {
            vec3.cross(tmpvec3, a, b);
            out[0] = tmpvec3[0];
            out[1] = tmpvec3[1];
            out[2] = tmpvec3[2];
            out[3] = 1 + dot;
            return quat.normalize(out, out)
          }
        }
      })();

      /**
       * Sets the specified quaternion with values corresponding to the given
       * axes. Each axis is a vec3 and is expected to be unit length and
       * perpendicular to all other specified axes.
       *
       * @param {vec3} view  the vector representing the viewing direction
       * @param {vec3} right the vector representing the local "right" direction
       * @param {vec3} up    the vector representing the local "up" direction
       * @returns {quat} out
       */
      quat.setAxes = (function() {
        var matr = mat3.create();

        return function(out, view, right, up) {
          matr[0] = right[0];
          matr[3] = right[1];
          matr[6] = right[2];

          matr[1] = up[0];
          matr[4] = up[1];
          matr[7] = up[2];

          matr[2] = -view[0];
          matr[5] = -view[1];
          matr[8] = -view[2];

          return quat.normalize(out, quat.fromMat3(out, matr))
        }
      })();

      /**
       * Creates a new quat initialized with values from an existing quaternion
       *
       * @param {quat} a quaternion to clone
       * @returns {quat} a new quaternion
       * @function
       */
      quat.clone = vec4.clone;

      /**
       * Creates a new quat initialized with the given values
       *
       * @param {Number} x X component
       * @param {Number} y Y component
       * @param {Number} z Z component
       * @param {Number} w W component
       * @returns {quat} a new quaternion
       * @function
       */
      quat.fromValues = vec4.fromValues;

      /**
       * Copy the values from one quat to another
       *
       * @param {quat} out the receiving quaternion
       * @param {quat} a the source quaternion
       * @returns {quat} out
       * @function
       */
      quat.copy = vec4.copy;

      /**
       * Set the components of a quat to the given values
       *
       * @param {quat} out the receiving quaternion
       * @param {Number} x X component
       * @param {Number} y Y component
       * @param {Number} z Z component
       * @param {Number} w W component
       * @returns {quat} out
       * @function
       */
      quat.set = vec4.set;

      /**
       * Set a quat to the identity quaternion
       *
       * @param {quat} out the receiving quaternion
       * @returns {quat} out
       */
      quat.identity = function(out) {
        out[0] = 0;
        out[1] = 0;
        out[2] = 0;
        out[3] = 1;
        return out
      };

      /**
       * Sets a quat from the given angle and rotation axis,
       * then returns it.
       *
       * @param {quat} out the receiving quaternion
       * @param {vec3} axis the axis around which to rotate
       * @param {Number} rad the angle in radians
       * @returns {quat} out
       **/
      quat.setAxisAngle = function(out, axis, rad) {
        rad = rad * 0.5;
        var s = Math.sin(rad);
        out[0] = s * axis[0];
        out[1] = s * axis[1];
        out[2] = s * axis[2];
        out[3] = Math.cos(rad);
        return out
      };

      /**
       * Adds two quat's
       *
       * @param {quat} out the receiving quaternion
       * @param {quat} a the first operand
       * @param {quat} b the second operand
       * @returns {quat} out
       * @function
       */
      quat.add = vec4.add;

      /**
       * Multiplies two quat's
       *
       * @param {quat} out the receiving quaternion
       * @param {quat} a the first operand
       * @param {quat} b the second operand
       * @returns {quat} out
       */
      quat.multiply = function(out, a, b) {
        var ax = a[0],
          ay = a[1],
          az = a[2],
          aw = a[3],
          bx = b[0],
          by = b[1],
          bz = b[2],
          bw = b[3];

        out[0] = ax * bw + aw * bx + ay * bz - az * by;
        out[1] = ay * bw + aw * by + az * bx - ax * bz;
        out[2] = az * bw + aw * bz + ax * by - ay * bx;
        out[3] = aw * bw - ax * bx - ay * by - az * bz;
        return out
      };

      /**
       * Alias for {@link quat.multiply}
       * @function
       */
      quat.mul = quat.multiply;

      /**
       * Scales a quat by a scalar number
       *
       * @param {quat} out the receiving vector
       * @param {quat} a the vector to scale
       * @param {Number} b amount to scale the vector by
       * @returns {quat} out
       * @function
       */
      quat.scale = vec4.scale;

      /**
       * Rotates a quaternion by the given angle about the X axis
       *
       * @param {quat} out quat receiving operation result
       * @param {quat} a quat to rotate
       * @param {number} rad angle (in radians) to rotate
       * @returns {quat} out
       */
      quat.rotateX = function(out, a, rad) {
        rad *= 0.5;

        var ax = a[0],
          ay = a[1],
          az = a[2],
          aw = a[3],
          bx = Math.sin(rad),
          bw = Math.cos(rad);

        out[0] = ax * bw + aw * bx;
        out[1] = ay * bw + az * bx;
        out[2] = az * bw - ay * bx;
        out[3] = aw * bw - ax * bx;
        return out
      };

      /**
       * Rotates a quaternion by the given angle about the Y axis
       *
       * @param {quat} out quat receiving operation result
       * @param {quat} a quat to rotate
       * @param {number} rad angle (in radians) to rotate
       * @returns {quat} out
       */
      quat.rotateY = function(out, a, rad) {
        rad *= 0.5;

        var ax = a[0],
          ay = a[1],
          az = a[2],
          aw = a[3],
          by = Math.sin(rad),
          bw = Math.cos(rad);

        out[0] = ax * bw - az * by;
        out[1] = ay * bw + aw * by;
        out[2] = az * bw + ax * by;
        out[3] = aw * bw - ay * by;
        return out
      };

      /**
       * Rotates a quaternion by the given angle about the Z axis
       *
       * @param {quat} out quat receiving operation result
       * @param {quat} a quat to rotate
       * @param {number} rad angle (in radians) to rotate
       * @returns {quat} out
       */
      quat.rotateZ = function(out, a, rad) {
        rad *= 0.5;

        var ax = a[0],
          ay = a[1],
          az = a[2],
          aw = a[3],
          bz = Math.sin(rad),
          bw = Math.cos(rad);

        out[0] = ax * bw + ay * bz;
        out[1] = ay * bw - ax * bz;
        out[2] = az * bw + aw * bz;
        out[3] = aw * bw - az * bz;
        return out
      };

      /**
       * Calculates the W component of a quat from the X, Y, and Z components.
       * Assumes that quaternion is 1 unit in length.
       * Any existing W component will be ignored.
       *
       * @param {quat} out the receiving quaternion
       * @param {quat} a quat to calculate W component of
       * @returns {quat} out
       */
      quat.calculateW = function(out, a) {
        var x = a[0],
          y = a[1],
          z = a[2];

        out[0] = x;
        out[1] = y;
        out[2] = z;
        out[3] = Math.sqrt(Math.abs(1.0 - x * x - y * y - z * z));
        return out
      };

      /**
       * Calculates the dot product of two quat's
       *
       * @param {quat} a the first operand
       * @param {quat} b the second operand
       * @returns {Number} dot product of a and b
       * @function
       */
      quat.dot = vec4.dot;

      /**
       * Performs a linear interpolation between two quat's
       *
       * @param {quat} out the receiving quaternion
       * @param {quat} a the first operand
       * @param {quat} b the second operand
       * @param {Number} t interpolation amount between the two inputs
       * @returns {quat} out
       * @function
       */
      quat.lerp = vec4.lerp;

      /**
       * Performs a spherical linear interpolation between two quat
       *
       * @param {quat} out the receiving quaternion
       * @param {quat} a the first operand
       * @param {quat} b the second operand
       * @param {Number} t interpolation amount between the two inputs
       * @returns {quat} out
       */
      quat.slerp = function(out, a, b, t) {
        // benchmarks:
        //    http://jsperf.com/quaternion-slerp-implementations

        var ax = a[0],
          ay = a[1],
          az = a[2],
          aw = a[3],
          bx = b[0],
          by = b[1],
          bz = b[2],
          bw = b[3];

        var omega, cosom, sinom, scale0, scale1;

        // calc cosine
        cosom = ax * bx + ay * by + az * bz + aw * bw;
        // adjust signs (if necessary)
        if (cosom < 0.0) {
          cosom = -cosom;
          bx = -bx;
          by = -by;
          bz = -bz;
          bw = -bw;
        }
        // calculate coefficients
        if (1.0 - cosom > 0.000001) {
          // standard case (slerp)
          omega = Math.acos(cosom);
          sinom = Math.sin(omega);
          scale0 = Math.sin((1.0 - t) * omega) / sinom;
          scale1 = Math.sin(t * omega) / sinom;
        } else {
          // "from" and "to" quaternions are very close
          //  ... so we can do a linear interpolation
          scale0 = 1.0 - t;
          scale1 = t;
        }
        // calculate final values
        out[0] = scale0 * ax + scale1 * bx;
        out[1] = scale0 * ay + scale1 * by;
        out[2] = scale0 * az + scale1 * bz;
        out[3] = scale0 * aw + scale1 * bw;

        return out
      };

      /**
       * Calculates the inverse of a quat
       *
       * @param {quat} out the receiving quaternion
       * @param {quat} a quat to calculate inverse of
       * @returns {quat} out
       */
      quat.invert = function(out, a) {
        var a0 = a[0],
          a1 = a[1],
          a2 = a[2],
          a3 = a[3],
          dot = a0 * a0 + a1 * a1 + a2 * a2 + a3 * a3,
          invDot = dot ? 1.0 / dot : 0;

        // TODO: Would be faster to return [0,0,0,0] immediately if dot == 0

        out[0] = -a0 * invDot;
        out[1] = -a1 * invDot;
        out[2] = -a2 * invDot;
        out[3] = a3 * invDot;
        return out
      };

      /**
       * Calculates the conjugate of a quat
       * If the quaternion is normalized, this function is faster than quat.inverse and produces the same result.
       *
       * @param {quat} out the receiving quaternion
       * @param {quat} a quat to calculate conjugate of
       * @returns {quat} out
       */
      quat.conjugate = function(out, a) {
        out[0] = -a[0];
        out[1] = -a[1];
        out[2] = -a[2];
        out[3] = a[3];
        return out
      };

      /**
       * Calculates the length of a quat
       *
       * @param {quat} a vector to calculate length of
       * @returns {Number} length of a
       * @function
       */
      quat.length = vec4.length;

      /**
       * Alias for {@link quat.length}
       * @function
       */
      quat.len = quat.length;

      /**
       * Calculates the squared length of a quat
       *
       * @param {quat} a vector to calculate squared length of
       * @returns {Number} squared length of a
       * @function
       */
      quat.squaredLength = vec4.squaredLength;

      /**
       * Alias for {@link quat.squaredLength}
       * @function
       */
      quat.sqrLen = quat.squaredLength;

      /**
       * Normalize a quat
       *
       * @param {quat} out the receiving quaternion
       * @param {quat} a quaternion to normalize
       * @returns {quat} out
       * @function
       */
      quat.normalize = vec4.normalize;

      /**
       * Creates a quaternion from the given 3x3 rotation matrix.
       *
       * NOTE: The resultant quaternion is not normalized, so you should be sure
       * to renormalize the quaternion yourself where necessary.
       *
       * @param {quat} out the receiving quaternion
       * @param {mat3} m rotation matrix
       * @returns {quat} out
       * @function
       */
      quat.fromMat3 = function(out, m) {
        // Algorithm in Ken Shoemake's article in 1987 SIGGRAPH course notes
        // article "Quaternion Calculus and Fast Animation".
        var fTrace = m[0] + m[4] + m[8];
        var fRoot;

        if (fTrace > 0.0) {
          // |w| > 1/2, may as well choose w > 1/2
          fRoot = Math.sqrt(fTrace + 1.0); // 2w
          out[3] = 0.5 * fRoot;
          fRoot = 0.5 / fRoot; // 1/(4w)
          out[0] = (m[5] - m[7]) * fRoot;
          out[1] = (m[6] - m[2]) * fRoot;
          out[2] = (m[1] - m[3]) * fRoot;
        } else {
          // |w| <= 1/2
          var i = 0;
          if (m[4] > m[0]) i = 1;
          if (m[8] > m[i * 3 + i]) i = 2;
          var j = (i + 1) % 3;
          var k = (i + 2) % 3;

          fRoot = Math.sqrt(m[i * 3 + i] - m[j * 3 + j] - m[k * 3 + k] + 1.0);
          out[i] = 0.5 * fRoot;
          fRoot = 0.5 / fRoot;
          out[3] = (m[j * 3 + k] - m[k * 3 + j]) * fRoot;
          out[j] = (m[j * 3 + i] + m[i * 3 + j]) * fRoot;
          out[k] = (m[k * 3 + i] + m[i * 3 + k]) * fRoot;
        }

        return out
      };

      /**
       * Returns a string representation of a quatenion
       *
       * @param {quat} vec vector to represent as a string
       * @returns {String} string representation of the vector
       */
      quat.str = function(a) {
        return 'quat(' + a[0] + ', ' + a[1] + ', ' + a[2] + ', ' + a[3] + ')'
      };

      if (typeof exports !== 'undefined') {
        exports.quat = quat;
      }
    })(shim.exports);
  })(undefined);
  //-----------------------Shaders------------------------------
  var shaders = {};

  shaders['2d-vertex-shader'] = [
    'attribute vec4 a_position;',

    'attribute vec4 a_mat1;',
    'attribute vec4 a_mat2;',
    'attribute vec4 a_mat3;',
    'attribute vec4 a_mat4;',
    'attribute vec4 a_color;',

    'varying vec4 v_color;',

    'void main() {',
    '    mat4 transformMatrix = mat4(a_mat1, a_mat2, a_mat3, a_mat4);',
    '    gl_Position = transformMatrix * a_position;',
    // correct the right/left handed thing
    '    gl_Position.z = -gl_Position.z;',
    '    v_color = a_color;',
    '}'
  ].join('\n');

  shaders['2d-fragment-shader'] = [
    'precision mediump float;',

    'varying vec4 v_color;',

    'void main() {',
    '    gl_FragColor = v_color;',
    '}'
  ].join('\n');

  shaders['3d-vertex-shader'] = [
    'attribute vec4 a_position;',

    'attribute vec4 a_mat1;',
    'attribute vec4 a_mat2;',
    'attribute vec4 a_mat3;',
    'attribute vec4 a_mat4;',
    'attribute vec4 a_color;',

    'varying vec4 v_color;',

    'void main() {',
    '    mat4 transformMatrix = mat4(a_mat1, a_mat2, a_mat3, a_mat4);',
    '    vec4 final_pos = transformMatrix * a_position;',
    // Correct the left-handed / right-handed stuff
    '    final_pos.z = -final_pos.z;',
    '    gl_Position = final_pos;',
    '    v_color = a_color;',
    '    float color_factor = final_pos.z;',
    '    v_color += color_factor * (1.0 - v_color);',
    '    v_color.a = 1.0;',
    '}'
  ].join('\n');

  shaders['3d-fragment-shader'] = [
    'precision mediump float;',

    'varying vec4 v_color;',

    'void main() {',
    '    gl_FragColor = v_color;',
    '}'
  ].join('\n');

  shaders['anaglyph-vertex-shader'] = [
    'attribute vec4 a_position;',

    'attribute vec4 a_mat1;',
    'attribute vec4 a_mat2;',
    'attribute vec4 a_mat3;',
    'attribute vec4 a_mat4;',
    'attribute vec4 a_color;',

    'uniform mat4 u_cameraMatrix;',
    'uniform vec4 u_colorFilter;',

    'varying vec4 v_color;',

    'void main() {',
    '    mat4 transformMatrix = mat4(a_mat1, a_mat2, a_mat3, a_mat4);',
    '    vec4 world_pos = transformMatrix * a_position;',
    '    gl_Position = u_cameraMatrix * world_pos;',
    // Correct the left-handed / right-handed stuff
    '    gl_Position.z = -gl_Position.z;',
    '    v_color = a_color;',
    '    float color_factor = -world_pos.z;',
    '    v_color += color_factor * (1.0 - v_color);',
    // average green and blue to form true cyan
    // v_color.g = 0.5 * (v_color.g + v_color.b);
    // v_color.b = v_color.g;
    // v_color = 1.0 - v_color;
    '    v_color = u_colorFilter * v_color + 1.0 - u_colorFilter;',
    '    v_color.a = 1.0;',
    '}'
  ].join('\n');

  shaders['anaglyph-fragment-shader'] = [
    'precision mediump float;',

    'varying vec4 v_color;',

    'void main() {',
    '    gl_FragColor = v_color;',
    '}'
  ].join('\n');

  shaders['combine-vertex-shader'] = [
    'attribute vec4 a_position;',

    'varying highp vec2 v_texturePosition;',

    'void main() {',
    '    gl_Position = a_position;',
    '    v_texturePosition.x = (a_position.x + 1.0) / 2.0;',
    '    v_texturePosition.y = (a_position.y + 1.0) / 2.0;',
    '}'
  ].join('\n');

  shaders['combine-fragment-shader'] = [
    'precision mediump float;',

    'uniform sampler2D u_sampler_red;',
    'uniform sampler2D u_sampler_cyan;',

    'varying highp vec2 v_texturePosition;',

    'void main() {',
    '    gl_FragColor = texture2D(u_sampler_red, v_texturePosition)',
    '            + texture2D(u_sampler_cyan, v_texturePosition) - 1.0;',
    '    gl_FragColor.a = 1.0;',
    '}'
  ].join('\n');

  shaders['copy-vertex-shader'] = [
    'attribute vec4 a_position;',

    'varying highp vec2 v_texturePosition;',

    'void main() {',
    '    gl_Position = a_position;',
    '    v_texturePosition.x = (a_position.x + 1.0) / 2.0;',
    '    v_texturePosition.y = 1.0 - (a_position.y + 1.0) / 2.0;',
    '}'
  ].join('\n');

  shaders['copy-fragment-shader'] = [
    'precision mediump float;',

    'uniform sampler2D u_sampler_image;',

    'varying highp vec2 v_texturePosition;',

    'void main() {',
    '    gl_FragColor = texture2D(u_sampler_image, v_texturePosition);',
    '}'
  ].join('\n');

  shaders['curve-vertex-shader'] = [
    'attribute vec2 a_position;',
    'uniform mat4 u_transformMatrix;',

    'void main() {',
    '    gl_PointSize = 2.0;',
    '    gl_Position = u_transformMatrix * vec4(a_position, 0, 1);',
    '}'
  ].join('\n');

  shaders['curve-fragment-shader'] = [
    'precision mediump float;',

    'void main() {',
    '    gl_FragColor = vec4(0, 0, 0, 1);',
    '}'
  ].join('\n');

  //-------------------------Constants-------------------------
  var antialias = 4; // common
  var halfEyeDistance = 0.03; // rune 3d only

  //----------------------Global variables----------------------
  // common
  var gl; // the WebGL context
  var curShaderProgram; // the shader program currently in use
  var normalShaderProgram; // the default shader program
  var vertexBuffer;
  var vertexPositionAttribute; // location of a_position
  var colorAttribute; // location of a_color
  const canvas = createCanvas(); // the <canvas> object that is used to display webGL output

  // rune 2d and 3d
  var instance_ext; // ANGLE_instanced_arrays extension
  var instanceBuffer;
  var indexBuffer;
  var indexSize; // number of bytes per element of index buffer
  var mat1Attribute; // location of a_mat1
  var mat2Attribute; // location of a_mat2
  var mat3Attribute; // location of a_mat3
  var mat4Attribute; // location of a_mat4

  // rune 3d only
  var anaglyphShaderProgram;
  var combineShaderProgram;
  var copyShaderProgram;
  var u_cameraMatrix; // locatin of u_cameraMatrix
  var u_colorFilter; // location of u_colorFilter
  var redUniform; // location of u_sampler_red
  var cyanUniform; // location of u_sampler_cyan
  var u_sampler_image;
  var leftCameraMatrix; // view matrix for left eye
  var rightCameraMatrix; // view matrix for right eye
  var leftFramebuffer;
  var rightFramebuffer;
  var copyTexture;

  function open_pixmap(name, horiz, vert, aa_off) {
    var this_aa;
    if (aa_off) {
      this_aa = 1;
    } else {
      this_aa = antialias;
    }
    var canvas = document.createElement('canvas');
    canvas.id = 'main-canvas';
    //this part uses actual canvas impl.
    canvas.width = horiz * this_aa;
    canvas.height = vert * this_aa;
    //this part uses CSS scaling, in this case is downsizing.
    canvas.style.width = horiz + 'px';
    canvas.style.height = vert + 'px';
    return canvas
  }

  /**
   * Creates a <canvas> object. Should only be called once.
   *
   * Post-condition: canvas is defined as the selected <canvas>
   *   object in the document.
   */
  function createCanvas() {
    const canvas = document.createElement('canvas');
    canvas.setAttribute('width', 512);
    canvas.setAttribute('height', 512);
    canvas.className = 'rune-canvas';
    canvas.hidden = true;
    document.body.appendChild(canvas);
    return canvas;
  }

  /*
   * Gets the WebGL object (gl) ready for usage. Use this
   * to reset the mode of rendering i.e to change from 2d to 3d runes.
   *
   * Post-condition: gl is non-null, uses an appropriate
   *   program and has an appropriate initialized state
   *   for mode-specific rendering (e.g props for 3d render).
   *
   * @param mode a string -- '2d'/'3d'/'curve' that is the usage of
   *   the gl object.
   */
  function getReadyWebGLForCanvas(mode) {
    // Get the rendering context for WebGL
    gl = initWebGL(canvas);
    if (gl) {
      gl.clearColor(1.0, 1.0, 1.0, 1.0); // Set clear color to white, fully opaque
      gl.enable(gl.DEPTH_TEST); // Enable depth testing
      gl.depthFunc(gl.LEQUAL); // Near things obscure far things
      // Clear the color as well as the depth buffer.
      clear_viewport();

      //TODO: Revise this, it seems unnecessary
      // Align the drawable canvas in the middle
      gl.viewport((canvas.width - canvas.height) / 2, 0, canvas.height, canvas.height);

      // setup a GLSL program i.e. vertex and fragment shader
      if (!(normalShaderProgram = initShader(mode))) {
        return
      }
      curShaderProgram = normalShaderProgram;
      gl.useProgram(curShaderProgram);

      // rune-specific operations
      if (mode === '2d' || mode === '3d') {
        initRuneCommon();
        initRuneBuffer(vertices, indices);
        initRune3d();
      }

      if (mode === 'curve') {
        initCurveAttributes(curShaderProgram);
      }
    }
  }

  function initWebGL(canvas) {
    var gl = null;

    try {
      // Try to grab the standard context. If it fails, fallback to experimental.
      gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
    } catch (e) {}

    // If we don't have a GL context, give up now
    if (!gl) {
      alert('Unable to initialize WebGL. Your browser may not support it.');
      gl = null;
    }
    return gl
  }

  function initShader(programName) {
    var vertexShader;
    if (!(vertexShader = getShader(gl, programName + '-vertex-shader', 'vertex'))) {
      return null
    }
    var fragmentShader;
    if (!(fragmentShader = getShader(gl, programName + '-fragment-shader', 'fragment'))) {
      return null
    }
    var shaderProgram = gl.createProgram();
    gl.attachShader(shaderProgram, vertexShader);
    gl.attachShader(shaderProgram, fragmentShader);
    gl.bindAttribLocation(shaderProgram, 0, 'a_position');
    gl.linkProgram(shaderProgram);
    if (!gl.getProgramParameter(shaderProgram, gl.LINK_STATUS)) {
      alert('Unable to initialize the shader program.');
      return null
    } else {
      return shaderProgram
    }
  }

  function getShader(gl, id, type) {
    var shader;
    var theSource = shaders[id];

    if (type == 'fragment') {
      shader = gl.createShader(gl.FRAGMENT_SHADER);
    } else if (type == 'vertex') {
      shader = gl.createShader(gl.VERTEX_SHADER);
    } else {
      // Unknown shader type
      return null
    }

    gl.shaderSource(shader, theSource);

    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      alert('An error occurred compiling the shaders: ' + gl.getShaderInfoLog(shader));
      return null
    }
    return shader
  }

  function initFramebufferObject() {
    var framebuffer, texture, depthBuffer;

    // Define the error handling function
    var error = function() {
      if (framebuffer) gl.deleteFramebuffer(framebuffer);
      if (texture) gl.deleteTexture(texture);
      if (depthBuffer) gl.deleteRenderbuffer(depthBuffer);
      return null
    };

    // create a framebuffer object
    framebuffer = gl.createFramebuffer();
    if (!framebuffer) {
      console.log('Failed to create frame buffer object');
      return error()
    }

    // create a texture object and set its size and parameters
    texture = gl.createTexture();
    if (!texture) {
      console.log('Failed to create texture object');
      return error()
    }
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texImage2D(
      gl.TEXTURE_2D,
      0,
      gl.RGBA,
      gl.drawingBufferWidth,
      gl.drawingBufferHeight,
      0,
      gl.RGBA,
      gl.UNSIGNED_BYTE,
      null
    );
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    framebuffer.texture = texture;

    // create a renderbuffer for depth buffer
    depthBuffer = gl.createRenderbuffer();
    if (!depthBuffer) {
      console.log('Failed to create renderbuffer object');
      return error()
    }

    // bind renderbuffer object to target and set size
    gl.bindRenderbuffer(gl.RENDERBUFFER, depthBuffer);
    gl.renderbufferStorage(
      gl.RENDERBUFFER,
      gl.DEPTH_COMPONENT16,
      gl.drawingBufferWidth,
      gl.drawingBufferHeight
    );

    // set the texture object to the framebuffer object
    gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer); // bind to target
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0);
    // set the renderbuffer object to the framebuffer object
    gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, depthBuffer);

    // check whether the framebuffer is configured correctly
    var e = gl.checkFramebufferStatus(gl.FRAMEBUFFER);
    if (gl.FRAMEBUFFER_COMPLETE !== e) {
      console.log('Frame buffer object is incomplete:' + e.toString());
      return error()
    }

    // Unbind the buffer object
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    gl.bindTexture(gl.TEXTURE_2D, null);
    gl.bindRenderbuffer(gl.RENDERBUFFER, null);

    return framebuffer
  }

  function clearFramebuffer(framebuffer) {
    gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
    clear_viewport();
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
  }

  function clear_viewport() {
    if (!gl) {
      throw new Error('Please activate the Canvas component by clicking it in the sidebar')
    }
    // Clear the viewport as well as the depth buffer
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    if (typeof clearHollusion !== 'undefined') {
      clearHollusion();
    }
  }

  //---------------------Rune 2d and 3d functions---------------------
  function initRuneCommon() {
    // set up attribute locations
    vertexPositionAttribute = gl.getAttribLocation(normalShaderProgram, 'a_position');
    colorAttribute = gl.getAttribLocation(normalShaderProgram, 'a_color');
    mat1Attribute = gl.getAttribLocation(normalShaderProgram, 'a_mat1');
    mat2Attribute = gl.getAttribLocation(normalShaderProgram, 'a_mat2');
    mat3Attribute = gl.getAttribLocation(normalShaderProgram, 'a_mat3');
    mat4Attribute = gl.getAttribLocation(normalShaderProgram, 'a_mat4');

    enableInstanceAttribs();

    // set up ANGLE_instanced_array extension
    if (!(instance_ext = gl.getExtension('ANGLE_instanced_arrays'))) {
      console.log('Unable to set up ANGLE_instanced_array extension!');
    }
  }

  function enableInstanceAttribs() {
    gl.enableVertexAttribArray(colorAttribute);
    gl.enableVertexAttribArray(mat1Attribute);
    gl.enableVertexAttribArray(mat2Attribute);
    gl.enableVertexAttribArray(mat3Attribute);
    gl.enableVertexAttribArray(mat4Attribute);
  }

  function disableInstanceAttribs() {
    gl.disableVertexAttribArray(colorAttribute);
    gl.disableVertexAttribArray(mat1Attribute);
    gl.disableVertexAttribArray(mat2Attribute);
    gl.disableVertexAttribArray(mat3Attribute);
    gl.disableVertexAttribArray(mat4Attribute);
  }

  function initRuneBuffer(vertices, indices) {
    // vertices should be Float32Array
    // indices should be Uint16Array
    vertexBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW);

    // enable assignment to vertex attribute
    gl.enableVertexAttribArray(vertexPositionAttribute);

    var FSIZE = vertices.BYTES_PER_ELEMENT;
    gl.vertexAttribPointer(vertexPositionAttribute, 4, gl.FLOAT, false, FSIZE * 4, 0);

    // Also initialize the indexBuffer
    indexBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, indices, gl.STATIC_DRAW);

    indexSize = indices.BYTES_PER_ELEMENT;
  }

  function drawRune(first, indexCount, instanceArray) {
    // instanceArray should be Float32Array
    // instanceCount should be instanceArray.length / 20

    // this draw function uses the "normal" shader
    if (curShaderProgram !== normalShaderProgram) {
      curShaderProgram = normalShaderProgram;
      gl.useProgram(curShaderProgram);
    }

    enableInstanceAttribs();

    // due to a bug in ANGLE implementation on Windows
    // a new buffer need to be created everytime for a new instanceArray
    // drawing mode MUST be STREAM_DRAW
    // delete the buffer at the end
    // More info about the ANGLE implementation (which helped me fix this bug)
    // https://code.google.com/p/angleproject/wiki/BufferImplementation
    instanceBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, instanceBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, instanceArray, gl.STREAM_DRAW);

    var FSIZE = instanceArray.BYTES_PER_ELEMENT;
    var instanceCount = instanceArray.length / 20;

    // pass transform matrix and color of instances
    assignRuneAttributes(FSIZE);

    instance_ext.drawElementsInstancedANGLE(
      gl.TRIANGLES,
      indexCount,
      gl.UNSIGNED_SHORT,
      first * indexSize,
      instanceCount
    );

    // delete the instance buffer
    gl.deleteBuffer(instanceBuffer);
  }

  function assignRuneAttributes(FSIZE) {
    gl.vertexAttribPointer(mat1Attribute, 4, gl.FLOAT, false, FSIZE * 20, 0);
    instance_ext.vertexAttribDivisorANGLE(mat1Attribute, 1);
    gl.vertexAttribPointer(mat2Attribute, 4, gl.FLOAT, false, FSIZE * 20, FSIZE * 4);
    instance_ext.vertexAttribDivisorANGLE(mat2Attribute, 1);
    gl.vertexAttribPointer(mat3Attribute, 4, gl.FLOAT, false, FSIZE * 20, FSIZE * 8);
    instance_ext.vertexAttribDivisorANGLE(mat3Attribute, 1);
    gl.vertexAttribPointer(mat4Attribute, 4, gl.FLOAT, false, FSIZE * 20, FSIZE * 12);
    instance_ext.vertexAttribDivisorANGLE(mat4Attribute, 1);
    gl.vertexAttribPointer(colorAttribute, 4, gl.FLOAT, false, FSIZE * 20, FSIZE * 16);
    instance_ext.vertexAttribDivisorANGLE(colorAttribute, 1);
  }

  //------------------------Rune 3d functions------------------------
  function initRune3d() {
    // set up other shaders
    if (
      !(
        (anaglyphShaderProgram = initShader('anaglyph')) &&
        (combineShaderProgram = initShader('combine'))
      )
    ) {
      console.log('Anaglyph cannot be used!');
    }
    if (!(copyShaderProgram = initShader('copy'))) {
      console.log('Stereogram and hollusion cannot be used!');
    }

    // set up uniform locations
    u_cameraMatrix = gl.getUniformLocation(anaglyphShaderProgram, 'u_cameraMatrix');
    u_colorFilter = gl.getUniformLocation(anaglyphShaderProgram, 'u_colorFilter');
    redUniform = gl.getUniformLocation(combineShaderProgram, 'u_sampler_red');
    cyanUniform = gl.getUniformLocation(combineShaderProgram, 'u_sampler_cyan');
    u_sampler_image = gl.getUniformLocation(copyShaderProgram, 'u_sampler_image');

    // calculate the left and right camera matrices
    leftCameraMatrix = mat4.create();
    mat4.lookAt(
      leftCameraMatrix,
      vec3.fromValues(-halfEyeDistance, 0, 0),
      vec3.fromValues(0, 0, -0.4),
      vec3.fromValues(0, 1, 0)
    );
    rightCameraMatrix = mat4.create();
    mat4.lookAt(
      rightCameraMatrix,
      vec3.fromValues(halfEyeDistance, 0, 0),
      vec3.fromValues(0, 0, -0.4),
      vec3.fromValues(0, 1, 0)
    );
    // set up frame buffers
    if (
      !((leftFramebuffer = initFramebufferObject()) && (rightFramebuffer = initFramebufferObject()))
    ) {
      console.log('Unable to initialize for anaglyph.');
      return
    }

    // set up a texture for copying
    // create a texture object and set its size and parameters
    copyTexture = gl.createTexture();
    if (!copyTexture) {
      console.log('Failed to create texture object');
      return error()
    }
  }

  function draw3D(first, indexCount, instanceArray, cameraMatrix, colorFilter, framebuffer) {
    // this draw function uses the "anaglyph" shader
    if (curShaderProgram !== anaglyphShaderProgram) {
      curShaderProgram = anaglyphShaderProgram;
      gl.useProgram(curShaderProgram);
    }

    enableInstanceAttribs();

    // due to a bug in ANGLE implementation on Windows
    // a new buffer need to be created everytime for a new instanceArray
    // drawing mode MUST be STREAM_DRAW
    // delete the buffer at the end
    // More info about the ANGLE implementation (which helped me fix this bug)
    // https://code.google.com/p/angleproject/wiki/BufferImplementation
    instanceBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, instanceBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, instanceArray, gl.STREAM_DRAW);

    var FSIZE = instanceArray.BYTES_PER_ELEMENT;
    var instanceCount = instanceArray.length / 20;

    // pass transform matrix and color of instances
    assignRuneAttributes(FSIZE);

    // pass the camera matrix and color filter for left eye
    gl.uniformMatrix4fv(u_cameraMatrix, false, cameraMatrix);
    gl.uniform4fv(u_colorFilter, new Float32Array(colorFilter));

    // draw left eye to frame buffer
    gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
    instance_ext.drawElementsInstancedANGLE(
      gl.TRIANGLES,
      indexCount,
      gl.UNSIGNED_SHORT,
      first * indexSize,
      instanceCount
    );

    gl.deleteBuffer(instanceBuffer);
  }

  function drawAnaglyph(first, indexCount, instanceArray) {
    // instanceArray should be Float32Array
    // instanceCount should be instanceArray.length / 20

    draw3D(first, indexCount, instanceArray, leftCameraMatrix, [1, 0, 0, 1], leftFramebuffer);
    draw3D(first, indexCount, instanceArray, rightCameraMatrix, [0, 1, 1, 1], rightFramebuffer);

    // combine to screen
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    combine(leftFramebuffer.texture, rightFramebuffer.texture);
  }

  function combine(texA, texB) {
    // this draw function uses the "combine" shader
    if (curShaderProgram !== combineShaderProgram) {
      curShaderProgram = combineShaderProgram;
      gl.useProgram(curShaderProgram);
    }

    disableInstanceAttribs();

    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, texA);
    gl.uniform1i(cyanUniform, 0);

    gl.activeTexture(gl.TEXTURE1);
    gl.bindTexture(gl.TEXTURE_2D, texB);
    gl.uniform1i(redUniform, 1);

    gl.drawElements(gl.TRIANGLES, square.count, gl.UNSIGNED_SHORT, indexSize * square.first);
  }

  function clearAnaglyphFramebuffer() {
    clearFramebuffer(leftFramebuffer);
    clearFramebuffer(rightFramebuffer);
  }
  //---------------------Cheating canvas functions-----------------
  function copy_viewport(src, dest) {
    dest.getContext('2d').clearRect(0, 0, dest.width, dest.height);
    dest.getContext('2d').drawImage(src, 0, 0, dest.width, dest.height); // auto scaling
  }

  //------------------------Curve functions------------------------
  function initCurveAttributes(shaderProgram) {
    vertexPositionAttribute = gl.getAttribLocation(shaderProgram, 'a_position');
    gl.enableVertexAttribArray(vertexPositionAttribute);
    u_transformMatrix = gl.getUniformLocation(shaderProgram, 'u_transformMatrix');
  }

  function ShapeDrawn(canvas) {
    this.$canvas = canvas;
  }
  var viewport_size = 512; // This is the height of the viewport
  // while a curve is approximated by a polygon,
  // the side of the polygon will be no longer than maxArcLength pixels
  var maxArcLength = 20;

  /*-----------------------Some class definitions----------------------*/
  function PrimaryRune(first, count) {
    this.isPrimary = true; // this is a primary rune
    this.first = first; // the first index in the index buffer
    // that belongs to this rune
    this.count = count; // number of indices to draw the rune
  }

  function Rune() {
    this.isPrimary = false;
    this.transMatrix = mat4.create();
    this.runes = [];
    this.color = undefined;
  }

  // set the transformation matrix related to the rune
  Rune.prototype.setM = function(matrix) {
    this.transMatrix = matrix;
  };

  // get the transformation matrix related to the rune
  Rune.prototype.getM = function() {
    return this.transMatrix
  };

  // get the sub-runes (array) of the rune
  Rune.prototype.getS = function() {
    return this.runes
  };

  Rune.prototype.setS = function(runes) {
    this.runes = runes;
  };

  Rune.prototype.addS = function(rune) {
    this.runes.push(rune);
  };

  Rune.prototype.getColor = function() {
    return this.color
  };

  Rune.prototype.setColor = function(color) {
    this.color = color;
  };

  /*-----------------Initialize vertex and index buffer----------------*/
  // vertices is an array of points
  // Each point has the following attribute, in that order:
  // x, y, z, t
  // (will be converted to Float32Array later)
  var vertices = [
    // center
    0.0,
    0.0,
    0.0,
    1.0,
    // 4 corners and 4 sides' midpoints
    1.0,
    0.0,
    0.0,
    1.0,
    1.0,
    1.0,
    0.0,
    1.0,
    0.0,
    1.0,
    0.0,
    1.0,
    -1.0,
    1.0,
    0.0,
    1.0,
    -1.0,
    0.0,
    0.0,
    1.0,
    -1.0,
    -1.0,
    0.0,
    1.0,
    0.0,
    -1.0,
    0.0,
    1.0,
    1.0,
    -1.0,
    0.0,
    1.0,
    // for rcross
    0.5,
    0.5,
    0.0,
    1.0,
    -0.5,
    0.5,
    0.0,
    1.0,
    -0.5,
    -0.5,
    0.0,
    1.0,
    0.5,
    -0.5,
    0.0,
    1.0,
    // for nova
    0.0,
    0.5,
    0.0,
    1.0,
    -0.5,
    0.0,
    0.0,
    1.0
  ];
  // indices is an array of indices, each refer to a point in vertices
  // (will be converted to Uint16Array later)
  var indices = [
    // square
    2,
    4,
    6,
    2,
    6,
    8,
    // rcross
    2,
    4,
    10,
    2,
    9,
    10,
    2,
    9,
    12,
    2,
    12,
    8,
    10,
    11,
    12,
    // sail
    7,
    8,
    3,
    // corner
    1,
    2,
    3,
    // nova
    3,
    0,
    14,
    13,
    0,
    1
  ];

  function makeCircle() {
    // draw a polygon with many vertices to approximate a circle
    var centerVerInd = 0;
    var firstVer = vertices.length / 4;
    var firstInd = indices.length;
    var numPoints = Math.ceil(Math.PI * viewport_size / maxArcLength);
    // generate points and store it in the vertex buffer
    for (var i = 0; i < numPoints; i++) {
      var angle = Math.PI * 2 * i / numPoints;
      vertices.push(Math.cos(angle), Math.sin(angle), 0, 1);
    }
    // generate indices for the triangles and store in the index buffer
    for (var i = firstVer; i < firstVer + numPoints - 1; i++) {
      indices.push(centerVerInd, i, i + 1);
    }
    indices.push(centerVerInd, firstVer, firstVer + numPoints - 1);
    var count = 3 * numPoints;
    return new PrimaryRune(firstInd, count)
  }

  function makeHeart() {
    var bottomMidInd = 7;
    var firstVer = vertices.length / 4;
    var firstInd = indices.length;
    var root2 = Math.sqrt(2);
    var r = 4 / (2 + 3 * root2);
    var scaleX = 1 / (r * (1 + root2 / 2));
    var numPoints = Math.ceil(Math.PI / 2 * viewport_size * r / maxArcLength);
    // right semi-circle
    var rightCenterX = r / root2;
    var rightCenterY = 1 - r;
    for (var i = 0; i < numPoints; i++) {
      var angle = Math.PI * (-1 / 4 + i / numPoints);
      vertices.push(
        (Math.cos(angle) * r + rightCenterX) * scaleX,
        Math.sin(angle) * r + rightCenterY,
        0,
        1
      );
    }
    // left semi-circle
    var leftCenterX = -r / root2;
    var leftCenterY = 1 - r;
    for (var i = 0; i <= numPoints; i++) {
      var angle = Math.PI * (1 / 4 + i / numPoints);
      vertices.push(
        (Math.cos(angle) * r + leftCenterX) * scaleX,
        Math.sin(angle) * r + leftCenterY,
        0,
        1
      );
    }
    // update index buffer
    for (var i = firstVer; i < firstVer + 2 * numPoints; i++) {
      indices.push(bottomMidInd, i, i + 1);
    }
    var count = 3 * 2 * numPoints;
    return new PrimaryRune(firstInd, count)
  }

  function makePentagram() {
    var firstVer = vertices.length / 4;
    var firstInd = indices.length;

    var v1 = Math.sin(Math.PI / 10);
    var v2 = Math.cos(Math.PI / 10);

    var w1 = Math.sin(3 * Math.PI / 10);
    var w2 = Math.cos(3 * Math.PI / 10);

    vertices.push(v2, v1, 0, 1);
    vertices.push(w2, -w1, 0, 1);
    vertices.push(-w2, -w1, 0, 1);
    vertices.push(-v2, v1, 0, 1);
    vertices.push(0, 1, 0, 1);

    for (var i = 0; i < 5; i++) {
      indices.push(0, firstVer + i, firstVer + (i + 2) % 5);
    }

    return new PrimaryRune(firstInd, 15)
  }

  function makeRibbon() {
    var firstVer = vertices.length / 4;
    var firstInd = indices.length;

    var theta_max = 30;
    var thickness = -1 / theta_max;
    var unit = 0.1;

    for (var i = 0; i < theta_max; i += unit) {
      vertices.push(i / theta_max * Math.cos(i), i / theta_max * Math.sin(i), 0, 1);
      vertices.push(
        Math.abs(Math.cos(i) * thickness) + i / theta_max * Math.cos(i),
        Math.abs(Math.sin(i) * thickness) + i / theta_max * Math.sin(i),
        0,
        1
      );
    }

    var totalPoints = Math.ceil(theta_max / unit) * 2;

    for (var i = firstVer; i < firstVer + totalPoints - 2; i++) {
      indices.push(i, i + 1, i + 2);
    }

    return new PrimaryRune(firstInd, 3 * totalPoints - 6)
  }

  /** 
   * primitive Rune in the rune of a full square
  **/
  var square = new PrimaryRune(0, 6);

  /** 
   * primitive Rune in the rune of a blank square
  **/
  var blank = new PrimaryRune(0, 0);

  /** 
   * primitive Rune in the rune of a 
   * smallsquare inside a large square,
   * each diagonally split into a
   * black and white half
  **/
  var rcross = new PrimaryRune(6, 15);

  /** 
   * primitive Rune in the rune of a sail
  **/
  var sail = new PrimaryRune(21, 3);

  /** 
   * primitive Rune with black triangle,
   * filling upper right corner
  **/
  var corner = new PrimaryRune(24, 3);

  /** 
   * primitive Rune in the rune of two overlapping
   * triangles, residing in the upper half
   * of 
  **/
  var nova = new PrimaryRune(27, 6);

  /** 
   * primitive Rune in the rune of a circle
  **/
  var circle = makeCircle();

  /** 
   * primitive Rune in the rune of a heart
  **/
  var heart = makeHeart();

  /** 
   * primitive Rune in the rune of a pentagram
  **/
  var pentagram = makePentagram();

  /** 
   * primitive Rune in the rune of a ribbon
   * winding outwards in an anticlockwise spiral
  **/
  var ribbon = makeRibbon();

  // convert vertices and indices to typed arrays
  vertices = new Float32Array(vertices);
  indices = new Uint16Array(indices);

  /*-----------------------Drawing functions----------------------*/
  function generateFlattenedRuneList(rune) {
    var matStack = [];
    var matrix = mat4.create();
    var rune_list = {};
    function pushMat() {
      matStack.push(mat4.clone(matrix));
    }
    function popMat() {
      if (matStack.length == 0) {
        throw 'Invalid pop matrix!'
      } else {
        matrix = matStack.pop();
      }
    }
    function helper(rune, color) {
      if (rune.isPrimary) {
        if (rune.count === 0) {
          // this is blank, do nothing
          return
        }
        if (!rune_list[rune.first]) {
          rune_list[rune.first] = {
            rune: rune,
            matrices: [],
            colors: []
          };
        }
        rune_list[rune.first].matrices.push(matrix);
        rune_list[rune.first].colors.push(color || [0, 0, 0, 1]);
      } else {
        if (color === undefined && rune.getColor() !== undefined) {
          color = rune.getColor();
        }
        pushMat();
        mat4.multiply(matrix, matrix, rune.getM());
        var childRunes = rune.getS();
        for (var i = 0; i < childRunes.length; i++) {
          helper(childRunes[i], color);
        }
        popMat();
      }
    }
    function flatten(matrices, colors) {
      var instanceArray = new Float32Array(matrices.length * 20);
      for (var i = 0; i < matrices.length; i++) {
        instanceArray.set(matrices[i], 20 * i);
        instanceArray.set(colors[i], 20 * i + 16);
      }
      return instanceArray
    }
    helper(rune);
    var flattened_rune_list = [];
    // draw a white square background first
    flattened_rune_list.push({
      rune: square,
      instanceArray: new Float32Array([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, -1, 1, 1, 1, 1, 1])
    });
    for (var key in rune_list) {
      if (rune_list.hasOwnProperty(key)) {
        var rune = rune_list[key].rune;
        var instanceArray = flatten(rune_list[key].matrices, rune_list[key].colors);
        flattened_rune_list.push({ rune: rune, instanceArray: instanceArray });
      }
    }
    return flattened_rune_list
  }

  function drawWithWebGL(flattened_rune_list, drawFunction) {
    for (var i = 0; i < flattened_rune_list.length; i++) {
      var rune = flattened_rune_list[i].rune;
      var instanceArray = flattened_rune_list[i].instanceArray;
      drawFunction(rune.first, rune.count, instanceArray);
    }
  }

  /**
   * turns a given Rune into a two-dimensional Picture
   * @param {Rune} rune - given Rune
   * @return {Picture}
   * If the result of evaluating a program is a Picture,
   * the REPL displays it graphically, instead of textually.
   */
  function show(rune) {
    const panel = document.getElementById('journey-frontend-lib-panel');
    if (panel === null) {
      return 'Please switch to library panel and run again!';
    } else {
      const frame = open_pixmap('frame', viewport_size, viewport_size, true);
      clear_viewport();
      var flattened_rune_list = generateFlattenedRuneList(rune);
      drawWithWebGL(flattened_rune_list, drawRune);
      copy_viewport(gl.canvas, frame);
      panel.innerHTML = '';
      panel.appendChild(frame);
    }
  }

  /**
   * turns a given Rune into an Anaglyph
   * @param {Rune} rune - given Rune
   * @return {Picture}
   * If the result of evaluating a program is an Anaglyph,
   * the REPL displays it graphically, using anaglyph
   * technology, instead of textually. Use your 3D-glasses
   * to view the Anaglyph.
   */
  function anaglyph(rune) {
    const frame = open_pixmap('frame', viewport_size, viewport_size, true);
    clear_viewport();
    clearAnaglyphFramebuffer();
    var flattened_rune_list = generateFlattenedRuneList(rune);
    drawWithWebGL(flattened_rune_list, drawAnaglyph);
    copy_viewport(gl.canvas, frame);
    return new ShapeDrawn(frame);
  }

  var hollusionTimeout;
  /* // to view documentation, put two * in this line
   * // currently, this function is not documented; 
   * // animation not working
   * turns a given Rune into Hollusion
   * @param {Rune} rune - given Rune
   * @return {Picture}
   * If the result of evaluating a program is a Hollusion,
   * the REPL displays it graphically, using hollusion
   * technology, instead of textually.
   */
  function hollusion(rune, num) {
    clear_viewport();
    var num = num > 5 ? num : 5;
    var flattened_rune_list = generateFlattenedRuneList(rune);
    var frame_list = [];
    for (var j = 0; j < num; j++) {
      var frame = open_pixmap('frame' + j, viewport_size, viewport_size, false);
      for (var i = 0; i < flattened_rune_list.length; i++) {
        var rune = flattened_rune_list[i].rune;
        var instanceArray = flattened_rune_list[i].instanceArray;
        var cameraMatrix = mat4.create();
        mat4.lookAt(
          cameraMatrix,
          vec3.fromValues(-halfEyeDistance + j / (num - 1) * 2 * halfEyeDistance, 0, 0),
          vec3.fromValues(0, 0, -0.4),
          vec3.fromValues(0, 1, 0)
        );
        draw3D(rune.first, rune.count, instanceArray, cameraMatrix, [1, 1, 1, 1], null);
      }
      gl.finish();
      copy_viewport(gl.canvas, frame);
      frame_list.push(frame);
      clear_viewport();
    }
    for (var i = frame_list.length - 2; i > 0; i--) {
      frame_list.push(frame_list[i]);
    }
    const outframe = open_pixmap('frame', viewport_size, viewport_size, true);
    function animate() {
      var frame = frame_list.shift();
      copy_viewport(frame, outframe);
      frame_list.push(frame);
      hollusionTimeout = setTimeout(animate, 500 / num);
    }
    animate();
    return new ShapeDrawn(outframe);
  }

  function clearHollusion() {
    clearTimeout(hollusionTimeout);
  }

  /*-----------------------Transformation functions----------------------*/
  /**
   * scales a given Rune by separate factors in x and y direction
   * @param {number} ratio_x - scaling factor in x direction
   * @param {number} ratio_y - scaling factor in y direction
   * @param {Rune} rune - given Rune
   * @return {Rune} resulting scaled Rune
   */
  function scale_independent(ratio_x, ratio_y, rune) {
    var scaleVec = vec3.fromValues(ratio_x, ratio_y, 1);
    var scaleMat = mat4.create();
    mat4.scale(scaleMat, scaleMat, scaleVec);
    var wrapper = new Rune();
    wrapper.addS(rune);
    wrapper.setM(scaleMat);
    return wrapper
  }


  /**
   * scales a given Rune by a given factor in both x and y direction
   * @param {number} ratio - scaling factor
   * @param {Rune} rune - given Rune
   * @return {Rune} resulting scaled Rune
   */
  function scale(ratio, rune) {
    return scale_independent(ratio, ratio, rune)
  }



  /**
   * translates a given Rune by given values in x and y direction
   * @param {number} x - translation in x direction
   * @param {number} y - translation in y direction
   * @param {Rune} rune - given Rune
   * @return {Rune} resulting translated Rune
   */
  function translate(x, y, rune) {
    var translateVec = vec3.fromValues(x, -y, 0);
    var translateMat = mat4.create();
    mat4.translate(translateMat, translateMat, translateVec);
    var wrapper = new Rune();
    wrapper.addS(rune);
    wrapper.setM(translateMat);
    return wrapper
  }

  /**
   * rotates a given Rune by a given angle,
   * given in radians, in anti-clockwise direction.
   * Note that parts of the Rune
   * may be cropped as a result.
   * @param {number} rad - fraction between 0 and 1
   * @param {Rune} rune - given Rune
   * @return {Rune} rotated Rune
   */
  function rotate(rad, rune) {
    var rotateMat = mat4.create();
    mat4.rotateZ(rotateMat, rotateMat, rad);
    var wrapper = new Rune();
    wrapper.addS(rune);
    wrapper.setM(rotateMat);
    return wrapper
  }

  /**
   * makes a new Rune from two given Runes by
   * placing the first on top of the second
   * such that the first one occupies frac 
   * portion of the height of the result and 
   * the second the rest
   * @param {number} frac - fraction between 0 and 1
   * @param {Rune} rune1 - given Rune
   * @param {Rune} rune2 - given Rune
   * @return {Rune} resulting Rune
   */
  function stack_frac(frac, rune1, rune2) {
    var upper = translate(0, -(1 - frac), scale_independent(1, frac, rune1));
    var lower = translate(0, frac, scale_independent(1, 1 - frac, rune2));
    var combined = new Rune();
    combined.setS([upper, lower]);
    return combined
  }

  /**
   * makes a new Rune from two given Runes by
   * placing the first on top of the second, each
   * occupying equal parts of the height of the 
   * result
   * @param {Rune} rune1 - given Rune
   * @param {Rune} rune2 - given Rune
   * @return {Rune} resulting Rune
   */
  function stack(rune1, rune2) {
    return stack_frac(1 / 2, rune1, rune2)
  }

  /**
   * makes a new Rune from a given Rune
   * by vertically stacking n copies of it
   * @param {number} n - positive integer
   * @param {Rune} rune - given Rune
   * @return {Rune} resulting Rune
   */
  function stackn(n, rune) {
    if (n === 1) {
      return rune
    } else {
      return stack_frac(1 / n, rune, stackn(n - 1, rune))
    }
  }

  /**
   * makes a new Rune from a given Rune
   * by turning it a quarter-turn around the centre in
   * clockwise direction. 
   * @param {Rune} rune - given Rune
   * @return {Rune} resulting Rune
   */
  function quarter_turn_right(rune) {
    return rotate(-Math.PI / 2, rune)
  }

  /**
   * makes a new Rune from a given Rune
   * by turning it a quarter-turn in
   * anti-clockwise direction.
   * @param {Rune} rune - given Rune
   * @return {Rune} resulting Rune
   */
  function quarter_turn_left(rune) {
    return rotate(Math.PI / 2, rune)
  }

  /**
   * makes a new Rune from a given Rune
   * by turning it upside-down
   * @param {Rune} rune - given Rune
   * @return {Rune} resulting Rune
   */
  function turn_upside_down(rune) {
    return rotate(Math.PI, rune)
  }

  /**
   * makes a new Rune from two given Runes by
   * placing the first on the left of the second
   * such that the first one occupies frac 
   * portion of the width of the result and 
   * the second the rest
   * @param {number} frac - fraction between 0 and 1
   * @param {Rune} rune1 - given Rune
   * @param {Rune} rune2 - given Rune
   * @return {Rune} resulting Rune
   */
  function beside_frac(frac, rune1, rune2) {
    var left = translate(-(1 - frac), 0, scale_independent(frac, 1, rune1));
    var right = translate(frac, 0, scale_independent(1 - frac, 1, rune2));
    var combined = new Rune();
    combined.setS([left, right]);
    return combined
  }

  /**
   * makes a new Rune from two given Runes by
   * placing the first on the left of the second,
   * both occupying equal portions of the width 
   * of the result
   * @param {Rune} rune1 - given Rune
   * @param {Rune} rune2 - given Rune
   * @return {Rune} resulting Rune
   */
  function beside(rune1, rune2) {
    return beside_frac(1 / 2, rune1, rune2)
  }

  /**
   * makes a new Rune from a given Rune by
   * flipping it around a horizontal axis,
   * turning it upside down
   * @param {Rune} rune - given Rune
   * @return {Rune} resulting Rune
   */
  function flip_vert(rune) {
    return scale_independent(1, -1, rune)
  }

  /**
   * makes a new Rune from a given Rune by
   * flipping it around a vertical axis,
   * creating a mirror image
   * @param {Rune} rune - given Rune
   * @return {Rune} resulting Rune
   */
  function flip_horiz(rune) {
    return scale_independent(-1, 1, rune)
  }

  /**
   * makes a new Rune from a given Rune by
   * arranging into a square for copies of the 
   * given Rune in different orientations
   * @param {Rune} rune - given Rune
   * @return {Rune} resulting Rune
   */
  function make_cross(rune) {
    return stack(
      beside(quarter_turn_right(rune), rotate(Math.PI, rune)),
      beside(rune, rotate(Math.PI / 2, rune))
    )
  }

  /**
   * applies a given function n times to an initial value
   * @param {number} n - a non-negative integer
   * @param {function} f - unary function from t to t
   * @param {t} initial - argument
   * @return {t} - result of n times application of 
   *               f to rune: f(f(...f(f(rune))...))
   */
  function repeat_pattern(n, pattern, initial) {
    if (n === 0) {
      return initial
    } else {
      return pattern(repeat_pattern(n - 1, pattern, initial))
    }
  }

  /*-----------------------Color functions----------------------*/
  function hexToColor(hex) {
    var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return [
      parseInt(result[1], 16) / 255,
      parseInt(result[2], 16) / 255,
      parseInt(result[3], 16) / 255,
      1
    ]
  }

  function addColorFromHex(rune, hex) {
    var wrapper = new Rune();
    wrapper.addS(rune);
    wrapper.setColor(hexToColor(hex));
    return wrapper
  }

  /**
   * colors the given rune red.
   * @param {Rune} rune - the rune to color
   * @returns {Rune} the colored Rune
   */
  function red(rune) {
    return addColorFromHex(rune, '#F44336')
  }

  /**
   * colors the given rune pink.
   * @param {Rune} rune - the rune to color
   * @returns {Rune} the colored Rune
   */
  function pink(rune) {
    return addColorFromHex(rune, '#E91E63')
  }

  /**
   * colors the given rune purple.
   * @param {Rune} rune - the rune to color
   * @returns {Rune} the colored Rune
   */
  function purple(rune) {
    return addColorFromHex(rune, '#AA00FF')
  }

  /**
   * colors the given rune indigo.
   * @param {Rune} rune - the rune to color
   * @returns {Rune} the colored Rune
   */
  function indigo(rune) {
    return addColorFromHex(rune, '#3F51B5')
  }

  /**
   * colors the given rune blexport ue.
   * @param {Rune} rune - the rune to color
   * @returns {Rune} the colored Rune
   */
  function blue(rune) {
    return addColorFromHex(rune, '#2196F3')
  }

  /**
   * colors the given rune green.
   * @param {Rune} rune - the rune to color
   * @returns {Rune} the colored Rune
   */
  function green(rune) {
    return addColorFromHex(rune, '#4CAF50')
  }

  /**
   * colors the given rune yellow.
   * @param {Rune} rune - the rune to color
   * @returns {Rune} the colored Rune
   */
  function yellow(rune) {
    return addColorFromHex(rune, '#FFEB3B')
  }

  /**
   * colors the given rune orange.
   * @param {Rune} rune - the rune to color
   * @returns {Rune} the colored Rune
   */
  function orange(rune) {
    return addColorFromHex(rune, '#FF9800')
  }

  /**
   * colors the given rune brown.
   * @param {Rune} rune - the rune to color
   * @returns {Rune} the colored Rune
   */
  function brown(rune) {
    return addColorFromHex(rune, '#795548')
  }

  /**
   * colors the given rune black.
   * @param {Rune} rune - the rune to color
   * @returns {Rune} the colored Rune
   */
  function black(rune) {
    return addColorFromHex(rune, '#000000')
  }

  /**
   * colors the given rune white.
   * @param {Rune} rune - the rune to color
   * @returns {Rune} the colored Rune
   */
  function white(rune) {
    return addColorFromHex(rune, '#FFFFFF')
  }

  /**
   * makes a 3D-Rune from two given Runes by
   * overlaying the first with the second
   * such that the first one occupies frac 
   * portion of the depth of the 3D result 
   * and the second the rest
   * @param {number} frac - fraction between 0 and 1
   * @param {Rune} rune1 - given Rune
   * @param {Rune} rune2 - given Rune
   * @return {Rune} resulting Rune
   */
  function overlay_frac(frac, rune1, rune2) {
    var front = new Rune();
    front.addS(rune1);
    var frontMat = front.getM();
    // z: scale by frac
    mat4.scale(frontMat, frontMat, vec3.fromValues(1, 1, frac));

    var back = new Rune();
    back.addS(rune2);
    var backMat = back.getM();
    // z: scale by (1-frac), translate by -frac
    mat4.scale(
      backMat,
      mat4.translate(backMat, backMat, vec3.fromValues(0, 0, -frac)),
      vec3.fromValues(1, 1, 1 - frac)
    );

    var combined = new Rune();
    combined.setS([front, back]); // render front first to avoid redrawing
    return combined
  }

  /**
   * makes a 3D-Rune from two given Runes by
   * overlaying the first with the second, each
   * occupying equal parts of the depth of the
   * result
   * @param {Rune} rune1 - given Rune
   * @param {Rune} rune2 - given Rune
   * @return {Rune} resulting Rune
   */
  function overlay(rune1, rune2) {
    return overlay_frac(0.5, rune1, rune2)
  }

  function animate(rune_list) {
    function aux(index) {
      show(rune_list[index]);
      setTimeout(() => {
        aux((index + 1) % rune_list.length);
      }, 500);
    }
    aux(0);
  }

  /*
  function stereogram(rune) {
    clear_viewport()
    var flattened_rune_list = generateFlattenedRuneList(rune)
    var depth_map = open_pixmap('depth_map', viewport_size, viewport_size, true)
    // draw the depth map
    for (var i = 0; i < flattened_rune_list.length; i++) {
      var rune = flattened_rune_list[i].rune
      var instanceArray = flattened_rune_list[i].instanceArray
      drawRune(rune.first, rune.count, instanceArray)
    }
    gl.finish()
    copy_viewport(gl.canvas, depth_map)

    // copy from the old library, with some modifications
    var E = 100 //; distance between eyes, 300 pixels
    var D = 600 //distance between eyes and image plane, 600 pixels
    var delta = 40 //stereo seperation
    var MAX_X = depth_map.width
    var MAX_Y = depth_map.height
    var MAX_Z = 0
    var CENTRE = Math.round(MAX_X / 2)

    var stereo_data = depth_map.getContext('2d').createImageData(depth_map.width, depth_map.height)
    var pixels = stereo_data.data
    var depth_data = depth_map.getContext('2d').getImageData(0, 0, depth_map.width, depth_map.height)
    var depth_pix = depth_data.data
    function get_depth(x, y) {
      if (x >= 0 && x < MAX_X) {
        var tgt = 4 * (y * depth_map.width + x)
        return -100 * depth_pix[tgt] / 255 - 400
      } else return -500
    }
    for (var y = 0; y < MAX_Y; y++) {
      //may want to use list of points instead
      var link_left = []
      var link_right = []
      var colours = []
      //varraint creation
      for (var x = 0; x < MAX_X; x++) {
        var z = get_depth(x, y)
        var s = delta + z * (E / (z - D)) // Determine distance between intersection of lines of sight on image plane
        var left = x - Math.round(s / 2) //x is integer, left is integer
        var right = left + Math.round(s) //right is integer
        if (left > 0 && right < MAX_X) {
          if (
            (!link_right[left] || s < link_right[left]) &&
            (!link_left[right] || s < link_left[right])
          ) {
            link_right[left] = Math.round(s)
            link_left[right] = Math.round(s)
          }
        }
      }
      //varraint resolution
      for (var x = 0; x < MAX_X; x++) {
        var s = link_left[x]
        if (s == undefined) s = Infinity
        else s = x
        var d
        if (x - s > 0) d = link_right[x - s]
        else d = Infinity
        if (s == Infinity || s > d) link_left[x] = 0
      }
      //drawing step
      for (var x = 0; x < MAX_X; x++) {
        var s = link_left[x] //should be valid for any integer till MAX_X
        var colour = colours[x - s] || [
          Math.round(Math.round(Math.random() * 10 / 9) * 255),
          Math.round(Math.round(Math.random() * 10 / 9) * 255),
          Math.round(Math.round(Math.random() * 10 / 9) * 255)
        ]
        var tgt = 4 * (y * depth_map.width + x)
        pixels[tgt] = colour[0]
        pixels[tgt + 1] = colour[1]
        pixels[tgt + 2] = colour[2]
        pixels[tgt + 3] = 255
        colours[x] = colour
      }
    }
    //throw on canvas
    depth_map.getContext('2d').putImageData(stereo_data, 0, 0)
    copy_viewport_webGL(depth_map)
    return new ShapeDrawn()
  }
  */
  getReadyWebGLForCanvas('2d');
  getReadyWebGLForCanvas('3d');

  exports.anaglyph = anaglyph;
  exports.animate = animate;
  exports.beside = beside;
  exports.beside_frac = beside_frac;
  exports.black = black;
  exports.blank = blank;
  exports.blue = blue;
  exports.brown = brown;
  exports.circle = circle;
  exports.clearHollusion = clearHollusion;
  exports.corner = corner;
  exports.flip_horiz = flip_horiz;
  exports.flip_vert = flip_vert;
  exports.green = green;
  exports.heart = heart;
  exports.hollusion = hollusion;
  exports.indigo = indigo;
  exports.make_cross = make_cross;
  exports.nova = nova;
  exports.orange = orange;
  exports.overlay = overlay;
  exports.overlay_frac = overlay_frac;
  exports.pentagram = pentagram;
  exports.pink = pink;
  exports.purple = purple;
  exports.quarter_turn_left = quarter_turn_left;
  exports.quarter_turn_right = quarter_turn_right;
  exports.rcross = rcross;
  exports.red = red;
  exports.repeat_pattern = repeat_pattern;
  exports.ribbon = ribbon;
  exports.rotate = rotate;
  exports.sail = sail;
  exports.scale = scale;
  exports.scale_independent = scale_independent;
  exports.show = show;
  exports.square = square;
  exports.stack = stack;
  exports.stack_frac = stack_frac;
  exports.stackn = stackn;
  exports.translate = translate;
  exports.turn_upside_down = turn_upside_down;
  exports.white = white;
  exports.yellow = yellow;

  return exports;

}({}));
