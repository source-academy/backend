defmodule Cadet.Chatbot.SicpNotes do
  @moduledoc """
  Module to store SICP notes.
  """
  @summary_1 """
  1. Building Abstractions with Functions
  1. **Introduction to Programming Concepts:**
  - Discusses John Locke's ideas on mental processes, emphasizing abstraction as a key concept in forming general ideas
  - Introduces the concept of computational processes, likening them to abstract beings that manipulate data according to program rules.
  2. **Programming Language Selection:**
  - Chooses JavaScript as the programming language for expressing procedural thoughts.
  - Traces the development of JavaScript from its origins in controlling web browsers to its current status as a general-purpose programming language.
  3. **JavaScript Characteristics and Standardization:**
  - Highlights JavaScript's core features inherited from Scheme and Self languages.
  - Notes the standardization efforts, leading to ECMAScript, and its evolution, with ECMAScript 2015 as a significant edition.
  - Discusses JavaScript's initial interpretation in web browsers and its subsequent efficient execution using techniques like JIT compilation.
  4. **Practical Application of JavaScript:**
  - Emphasizes the practicality of embedding JavaScript in web pages and its role in web browser interactions.
  - Recognizes JavaScript's expanding role as a general-purpose programming language, especially with the advent of systems like Node.js.
  - Points out JavaScript's suitability for an online version of a book on computer programs due to its execution capabilities in web browsers.
  """

  @summary_1_1 """
  1.1: The Elements of Programming
  1. **Programming Language Components:**
  - A powerful programming language involves more than instructing a computer; it's a framework for organizing ideas about processes.
  - Focuses on three mechanisms: primitive expressions, means of combination, and means of abstraction.
  2. **Elements in Programming:**
  - Programming deals with two key elements: functions and data.
  - Defines data as manipulable 'stuff' and functions as rules for manipulating data.
  - Emphasizes the importance of a language describing primitive data and functions and combining/abstracting them.
  3. **Chapter Scope:**
  - Chapter focuses on simple numerical data to explore rules for building functions.
  - Acknowledges the complexity of handling numbers in programming languages, deferring detailed exploration to later chapters.
  4. **Numerical Considerations:**
  - Raises issues in dealing with numbers, such as distinctions between integers and real numbers.
  - Acknowledges challenges like arithmetic operations, representation limits, and roundoff behavior.
  - Declares the book's focus on large-scale program design, deferring detailed numerical analysis.
  """

  @summary_1_1_1 """
  1.1.1  Expressions
  1. **JavaScript Interpreter Interaction:**
  - Introduction to programming via interactions with a JavaScript interpreter.
  - Statements involve typing expressions, and the interpreter responds by displaying the evaluated results.
  2. **Expression Statements:**
  - Expression statements consist of an expression followed by a semicolon.
  - Primitive expressions include numbers; evaluation involves clicking, displaying the interpreter, and running the statement.
  3. **Compound Expressions:**
  - Expressions combining numbers with operators form compound expressions.
  - Examples of operator combinations with arithmetic operators and infix notation are provided.
  4. **Read-Evaluate-Print Loop:**
  - JavaScript interpreter operates in a read-evaluate-print loop.
  - Complex expressions are handled, and the interpreter reads, evaluates, and prints results in a cycle.
  """

  @summary_1_1_2 """
  1.1.2  Naming and the Environment
  1. **Constants and Declarations:**
  - JavaScript uses constant declarations (e.g., const size = 2;) to associate names with values (constants).
  - Names like size can then be used in expressions, providing a means of abstraction for simple values.
  2. **Abstraction with Constants:**
  - Constant declaration is a simple form of abstraction, allowing the use of names for results of compound operations.
  - Examples include using constants like pi and radius in calculations for circumference.
  3. **Incremental Program Development:**
  - JavaScript's incremental development involves step-by-step construction of computational objects using name-object associations.
  - The interpreter supports this process by allowing incremental creation of associations in successive interactions.
  4. **Program Environment:**
  - The interpreter maintains a memory called the program environment, tracking name-object pairs.
  - This environment is crucial for understanding interpreter operation and implementing interpreters in later chapters.
  """

  @summary_1_1_3 """
  1.1.3: Evaluating Operator Combinations
  1. **Evaluation of Operator Combinations:**
  - The interpreter follows a procedure to evaluate operator combinations.
  - Recursive evaluation involves assessing operand expressions and applying the operator's function.
  - Recursive nature simplifies the understanding of complex, nested combinations in a hierarchical, tree-like structure.
  2. **Recursion in Evaluation:**
  - Recursion efficiently handles deeply nested combinations.
  - A tree representation illustrates the percolation of operand values upward during evaluation.
  - General process type known as 'tree accumulation.'
  3. **Handling Primitive Expressions:**
  - Primitive cases involve evaluating numerals and names.
  - Numerals represent the numbers they name.
  - Names derive values from the environment where associations are stored.
  4. **Role of Environment in Evaluation:**
  - The environment is crucial for determining name meanings in expressions.
  - In JavaScript, a name's value depends on the environment, especially in interactive contexts.
  - Declarations, like `const x = 3;`, associate names with values and aren't handled by the evaluation rule.
  """

  @summary_1_1_4 """
  1.1.4 Compound Functions
  1. **Compound Functions in JavaScript:**
  - Function declarations offer a powerful abstraction, allowing compound operations to be named.
  - Declaring a function involves specifying parameters, a return expression, and associating it with a name.
  - Function applications, like `square(21)`, execute the named function with specified arguments, yielding a result.
  2. **Function Application in JavaScript:**
  - To evaluate a function application, subexpressions (function and arguments) are evaluated, and the function is applied to the arguments.
  - Nested function applications, such as `square(square(3))`, demonstrate the versatility of this approach.
  3. **Building Functions with Compound Functions:**
  - Functions like `sum_of_squares` can be defined using previously declared functions (e.g., `square`) as building blocks.
  - Primitive functions provided by the JavaScript environment, like `math_log`, are used similarly to compound functions.
  4. **Syntax and Naming Conventions:**
  - Function declaration syntax involves naming, specifying parameters, and defining the return expression.
  - Common JavaScript conventions, like camel case or snake case, affect the readability of multi-part function names (e.g., `sum_of_squares`).
  """

  @summary_1_1_5 """
  1.1.5 The Substitution Model for Function Application
  1. **Substitution Model for Function Application:**
  - The interpreter follows a substitution model when evaluating function applications in JavaScript.
  - For compound functions, it involves replacing parameters with corresponding arguments in the return expression.
  - This model helps conceptualize function application but differs from the actual interpreter's workings.
  2. **Applicative-Order vs. Normal-Order Evaluation:**
  - Applicative-order evaluation, used by JavaScript, evaluates arguments before function application.
  - Normal-order evaluation substitutes arguments for parameters until only operators and primitive functions remain, then evaluates.
  - Both methods yield the same result for functions modeled using substitution, but normal order is more complex.
  3. **Implications of Evaluation Models:**
  - The substitution model serves as a starting point for thinking formally about evaluation.
  - Over the book, more refined models will replace the substitution model, especially when dealing with 'mutable data.'
  - JavaScript uses applicative-order evaluation for efficiency, while normal-order evaluation has its own implications explored later.
  4. **Challenges in Substitution Process:**
  - The substitution process, despite its simplicity, poses challenges in giving a rigorous mathematical definition.
  - Issues arise from potential confusion between parameter names and identical names in expressions to which a function is applied.
  - Future chapters will explore variations, including normal-order evaluation and its use in handling infinite data structures.
  """

  @summary_1_1_6 """
  1.1.6 Conditional Expressions and Predicates
  1. **Conditional Expressions and Predicates:**
  - JavaScript's conditional expressions involve a predicate, a consequent expression, and an alternative expression.
  - The interpreter evaluates the predicate; if true, it returns the consequent expression, else the alternative expression.
  - Predicates include boolean operators (&&, ||) and logical negation (!), aiding in conditional logic.
  2. **Handling Multiple Cases:**
  - Nested conditional expressions handle multiple cases, enabling complex case analyses.
  - The structure uses clauses with predicates and consequent expressions, ending with a final alternative expression.
  - Logical composition operations like && and || assist in constructing compound predicates.
  3. **Examples and Applications:**
  - Functions, like absolute value (abs), can be defined using conditional expressions.
  - Logical operations (&&, ||, !) and comparison operators enhance the expressiveness of conditional expressions.
  - Exercises demonstrate practical applications, such as evaluating sequences of statements and translating expressions into JavaScript.
  4. **Evaluation Models:**
  - Applicative-order evaluation (JavaScript's approach) evaluates arguments before function application.
  - Normal-order evaluation fully expands and then reduces expressions, leading to potential multiple evaluations.
  - Substitution models are foundational for understanding function application but become inadequate in detailed analyses.
  """

  @summary_1_1_7 """
  1.1.7 Example: Square Roots by Newton's Method
  1. **Newton's Method for Square Roots:**
  - Mathematical and computer functions differ; computer functions must be effective.
  - Newton's method, an iterative approach, is used to compute square roots.
  - The process involves successive approximations, improving guesses through simple manipulations.
  2. **Functional Approach to Square Roots:**
  - Functions like `sqrt_iter`, `improve`, `average`, and `is_good_enough` formalize the iterative square-root computation.
  - The basic strategy is expressed through recursion without explicit iterative constructs.
  - The example demonstrates that a simple functional language can handle numerical programs efficiently.
  3. **Declarative vs. Imperative Knowledge:**
  - The distinction between mathematical and computer functions reflects declarative (what is) vs. imperative (how to) knowledge.
  - Computer science deals with imperative descriptions, focusing on how to perform tasks.
  - Newton's method for square roots exemplifies the transition from declarative to imperative knowledge in programming.
  4. **Exercises and Challenges:**
  - Exercises involve evaluating the effectiveness of conditional expressions and exploring improvements to the square-root program.
  - Newton's method is extended to cube roots, showcasing the general applicability of the approach.
  - Considerations for precision and handling small/large numbers in square-root computation are discussed.
  """

  @summary_1_1_8 """
  1.1.8 Functions as Black-Box Abstractions
  1. **Function Decomposition:**
  - The square root program illustrates a cluster of functions decomposing the problem into subproblems.
  - Functions like `is_good_enough` and `improve` operate as modules, contributing to the overall process.
  - Decomposition is crucial for readability and modularity, enabling the use of functions as black-box abstractions.
  2. **Functional Abstraction:**
  - Functions should act as black boxes, allowing users to focus on the result, not implementation details.
  - Parameter names, being bound, don't affect function behavior, promoting functional abstraction.
  - The significance of local names and the independence of function meaning from parameter names are emphasized.
  3. **Lexical Scoping:**
  - Lexical scoping allows functions to have internal declarations, localizing subfunctions.
  - Block structure and lexical scoping enhance the organization of large programs.
  - Free names in internal declarations derive their values from the enclosing function's arguments.
  4. **Simplification and Organization:**
  - Internalizing declarations simplifies auxiliary functions in a block structure.
  - Lexical scoping eliminates the need to pass certain arguments explicitly, enhancing clarity.
  - The combination of block structure and lexical scoping aids in the organization of complex programs.
  """

  @summary_1_2 """
  1.2 Functions and the Processes They Generate
  1. **Programming Expertise Analogy:**
  - Programming is likened to chess, where knowing piece movements isn't enough without strategic understanding.
  - Similar to a novice chess player, knowing primitive operations isn't sufficient without understanding common programming patterns.
  2. **Importance of Process Visualization:**
  - Expert programmers visualize consequences and patterns of actions, akin to a photographer planning exposure for desired effects.
  - Understanding the local evolution of computational processes is crucial for constructing programs with desired behaviors.
  3. **Function as Process Pattern:**
  - A function serves as a pattern for the local evolution of a computational process.
  - Describing global behavior based on local evolution is challenging but understanding typical process patterns is essential.
  4. **Analysis of Process Shapes:**
  - Examining common shapes of processes generated by simple functions.
  - Investigating how these processes consume computational resources like time and space.
  """

  @summary_1_2_1 """
  1.2.1 Linear Recursion and Iteration
  1. **Factorial Computation:**
  - Two methods for computing factorial: recursive (linear recursive process) and iterative (linear iterative process).
  - Recursive process involves a chain of deferred operations, while iterative process maintains fixed state variables.
  2. **Recursive vs. Iterative:**
  - Recursive process builds a chain of deferred operations, resulting in linear growth of information.
  - Iterative process maintains fixed state variables, described as a linear iterative process with constant space.
  3. **Tail-Recursion and Implementation:**
  - Tail-recursive implementations execute iterative processes in constant space.
  - Common languages may consume memory with recursive functions; JavaScript (ECMAScript 2015) supports tail recursion.
  4. **Exercise: Ackermann's Function:**
  - Illustration of Ackermann's function.
  - Definition of functions f, g, and h in terms of Ackermann's function.
  """

  @summary_1_2_2 """
  1.2.2 Tree Recursion
  1. **Tree Recursion:**
  - Tree recursion is illustrated using the Fibonacci sequence computation.
  - Recursive function `fib` exhibits a tree-recursive process with exponential growth in redundant computations.
  2. **Iterative Fibonacci:**
  - An alternative linear iterative process for Fibonacci computation is introduced.
  - Contrast between the exponential growth of tree recursion and linear growth of the iterative process is highlighted.
  3. **Smart Compilation and Efficiency:**
  - Tree-recursive processes, while inefficient, are often easy to understand.
  - A 'smart compiler' is proposed to transform tree-recursive functions into more efficient forms.
  4. **Example: Counting Change:**
  - The problem of counting change for a given amount is introduced.
  - A recursive solution is presented, demonstrating tree recursion with a clear reduction rule.
  """

  @summary_1_2_3 """
  1.2.3 Orders of Growth
  1. **Orders of Growth:**
  - Processes exhibit varying resource consumption rates, described by the order of growth.
  - Represented as Θ(f(n)), indicating resource usage between k₁f(n) and k₂f(n) for large n.
  2. **Examples of Order of Growth:**
  - Linear recursive factorial process has Θ(n) steps and space.
  - Iterative factorial has Θ(n) steps but Θ(1) space.
  - Tree-recursive Fibonacci has Θ(ϕⁿ) steps and Θ(n) space, where ϕ is the golden ratio.
  3. **Crude Description:**
  - Orders of growth offer a basic overview, e.g., Θ(n²) for quadratic processes.
  - Useful for anticipating behavior changes with problem size variations.
  4. **Upcoming Analysis:**
  - Future exploration includes algorithms with logarithmic order of growth.
  - Expected behavior changes, such as doubling problem size's impact on resource utilization.
  """

  @summary_1_2_4 """
  1.2.4 Exponentiation
  1. **Exponentiation Process:**
  - Recursive process for exponentiation: bⁿ = b * bⁿ⁻¹.
  - Linear recursive process: Θ(n) steps and Θ(n) space.
  - Improved iterative version: Θ(n) steps but Θ(1) space.
  2. **Successive Squaring:**
  - Successive squaring reduces steps for exponentiation.
  - Fast_expt function exhibits logarithmic growth: Θ(log n) steps and space.
  3. **Multiplication Algorithms:**
  - Design logarithmic steps multiplication using successive doubling and halving.
  - Utilize observation from exponentiation for efficient iterative multiplication.
  4. **Fibonacci Numbers:**
  - Clever algorithm for Fibonacci in logarithmic steps.
  - Transformation T and Tⁿ for Fibonacci computation using successive squaring.
  """

  @summary_1_2_5 """
  1.2.5 Greatest Common Divisors
  1. **Greatest Common Divisors (GCD):**
  - GCD of a and b is the largest integer dividing both with no remainder.
  - Euclid's Algorithm efficiently computes GCD using recursive reduction.
  - Algorithm based on the observation: GCD(a, b) = GCD(b, a % b).
  2. **Algorithm Complexity:**
  - Euclid's Algorithm has logarithmic growth.
  - Lamé's Theorem relates Euclid's steps to Fibonacci numbers.
  - Order of growth: Θ(log n).
  3. **Euclid's Algorithm Function:**
  - Express Euclid's Algorithm as a function: `gcd(a, b)`.
  - Iterative process with logarithmic growth in steps.
  4. **Exercise:**
  - Normal-order evaluation impacts the process generated by gcd function.
  - Lamé's Theorem applied to estimate the order of growth for Euclid's Algorithm.
  """

  @summary_1_2_6 """
  1.2.6 Example: Testing for Primality
  1. **Primality Testing Methods:**
  - Methods for checking primality: Order Θ(n) and probabilistic method with Θ(log n).
  - Finding divisors: Program to find the smallest integral divisor of a given number.
  - Fermat's Little Theorem: Θ(log n) primality test based on number theory.
  - Fermat test and Miller–Rabin test as probabilistic algorithms.
  2. **Fermat's Little Theorem:**
  - If n is prime, a^(n-1) ≡ 1 (mod n) for a < n.
  - Fermat test: Randomly choosing a and checking congruence.
  - Probabilistic nature: Result is probably correct, with rare chances of error.
  3. **Algorithm Implementation:**
  - Implementation of Fermat test using expmod function.
  - Miller–Rabin test: Squaring step checks for nontrivial square roots of 1.
  - Probabilistic algorithms and their reliability in practical applications.
  4. **Exercises:**
  - Exercise 1.21: Finding the smallest divisor using the smallest_divisor function.
  - Exercise 1.22: Timed prime tests for different ranges, comparing Θ(n) and Θ(log n) methods.
  - Exercise 1.23: Optimizing smallest_divisor for efficiency.
  - Exercise 1.24: Testing primes using the Fermat method (Θ(log n)).
  - Exercise 1.25: Comparing expmod and fast_expt for primality testing.
  - Exercise 1.26: Identifying algorithmic transformation affecting efficiency.
  - Exercise 1.27: Testing Carmichael numbers that fool the Fermat test.
  - Exercise 1.28: Implementing the Miller–Rabin test and testing its reliability.
  """

  @summary_1_3 """
  1.3 Formulating Abstractions with Higher-Order Functions
  1. **Higher-Order Functions:**
  - Functions as abstractions for compound operations on numbers.
  - Declaring functions allows expressing concepts like cubing, enhancing language expressiveness.
  - Importance of building abstractions using function names.
  - Introduction of higher-order functions that accept or return functions, increasing expressive power.
  2. **Abstraction in Programming:**
  - Programming languages should allow building abstractions through named common patterns.
  - Functions enable working with higher-level operations beyond primitive language functions.
  - Limitations without abstractions force work at the level of primitive operations.
  - Higher-order functions extend the ability to create abstractions in programming languages.
  """

  @summary_1_3_1 """
  1.3.1 Functions as Arguments
  1. **Common Pattern in Functions:**
  - Three functions share a common pattern for summing series.
  - Functions differ in name, term computation, and next value.
  - Identification of the summation abstraction in mathematical series.
  - Introduction of a common template for expressing summation patterns.
  2. **Higher-Order Function for Summation:**
  - Introduction of a higher-order function for summation, named 'sum.'
  - 'sum' takes a term, lower and upper bounds, and next function as parameters.
  - Examples of using 'sum' to compute sum_cubes, sum_integers, and pi_sum.
  - Application of 'sum' in numerical integration and approximation of π.
  3. **Iterative Formulation:**
  - Transformation of summation function into an iterative process.
  - Example of an iterative summation function using Simpson's Rule.
  - Extension to a more general notion called 'accumulate' for combining terms.
  4. **Filtered Accumulation:**
  - Introduction of filtered accumulation using a predicate for term selection.
  - Examples of filtered accumulation: sum of squares of prime numbers and product of relatively prime integers.
  - Acknowledgment of the expressive power attained through appropriate abstractions.
  """

  @summary_1_3_2 """
  1.3.2 Constructing Functions using Lambda Expressions
  1. **Lambda Expressions for Function Creation:**
  - Introduction of lambda expressions for concise function creation.
  - Lambda expressions used to directly specify functions without declaration.
  - Elimination of the need for auxiliary functions like pi_term and pi_next.
  - Examples of pi_sum and integral functions using lambda expressions.
  2. **Lambda Expression Syntax:**
  - Lambda expressions written as `(parameters) => expression`.
  - Equivalent functionality to function declarations but without a specified name.
  - Readability and equivalence demonstrated with examples.
  - Usage of lambda expressions in various contexts, such as function application.
  3. **Local Names Using Lambda Expressions:**
  - Lambda expressions employed to create anonymous functions for local names.
  - Example of computing a function with intermediate quantities like 'a' and 'b'.
  - Comparison with alternative approaches, including using auxiliary functions.
  - Utilization of constant declarations within function bodies for local names.
  4. **Conditional Statements in JavaScript:**
  - Introduction of conditional statements using `if-else` syntax.
  - Example of applying conditional statements in the 'expmod' function.
  - Scope considerations for constant declarations within conditional statements.
  - Efficient use of conditional statements to improve function performance.
  5. **Exercise 1.34:**
  - A function `f` that takes a function `g` and applies it to the value 2.
  - Demonstrations with `square` and a lambda expression.
  - A hypothetical scenario of evaluating `f(f)` and its explanation as an exercise.
  - Illustration of function composition and its outcome.
  """

  @summary_1_3_3 """
  1.3.3 Functions as General Methods
  1. **Introduction to General Methods:**
  - Compound functions and higher-order functions for abstracting numerical operations.
  - Higher-order functions express general methods of computation.
  - Examples of general methods for finding zeros and fixed points of functions.
  2. **Half-Interval Method for Finding Roots:**
  - A strategy for finding roots of continuous functions using the half-interval method.
  - Implementation of the method in JavaScript with the `search` function.
  - Use of the method to approximate roots, e.g., finding π and solving a cubic equation.
  3. **Fixed Points of Functions:**
  - Definition of a fixed point of a function and methods to locate it.
  - Introduction of the `fixed_point` function for finding fixed points with a given tolerance.
  - Examples using cosine and solving equations involving trigonometric functions.
  4. **Square Root Computation and Averaging:**
  - Attempt to compute square roots using fixed-point search and the challenge with convergence.
  - Introduction of average damping to control oscillations and improve convergence.
  - Illustration of square root computation using average damping in the `sqrt` function.
  5. **Exercises and Further Exploration:**
  - Exercise 1.35: Golden ratio as a fixed point.
  - Exercise 1.36: Modifying `fixed_point` and solving equations.
  - Exercise 1.37: Continued fraction representation and approximating values.
  - Exercise 1.38: Approximating Euler's number using continued fractions.
  - Exercise 1.39: Lambert's continued fraction for the tangent function.
  """

  @summary_1_3_4 """
  1.3.4 Functions as Returned Values
  1. **Programming Concepts:**
  - Demonstrates the use of functions as first-class citizens in JavaScript.
  - Highlights the application of higher-order functions in expressing general methods.
  - Shows how to create abstractions and build upon them for more powerful functionalities.
  - Discusses the significance of first-class functions in JavaScript and their expressive power.
  2. **Specific Programming Techniques:**
  - Introduces and applies average damping and fixed-point methods in function computations.
  - Explores Newton's method and expresses it as a fixed-point process.
  - Provides examples of implementing functions for square roots, cube roots, and nth roots.
  - Discusses iterative improvement as a general computational strategy.
  3. **Exercises and Problem Solving:**
  - Includes exercises like implementing functions for cubic equations, function composition, and iterative improvement.
  - Addresses challenges in computing nth roots using repeated average damping.
  4. **General Programming Advice:**
  - Emphasizes the importance of identifying and building upon underlying abstractions in programming.
  - Encourages programmers to think in terms of abstractions and choose appropriate levels of abstraction for tasks.
  - Discusses the benefits and challenges of first-class functions in programming languages.
  """

  @summary_2 """
  2 Building Abstractions with Data
  1. **Focus on Compound Data:** The chapter discusses the importance of compound data in programming languages to model complex phenomena and improve design modularity.
  2. **Data Abstraction:** Introduces the concept of data abstraction, emphasizing how it simplifies program design by separating the representation and usage of data objects.
  3. **Expressive Power:** Compound data enhances the expressive power of programming languages, allowing the manipulation of different data types without detailed knowledge of their representations.
  4. **Symbolic Expressions and Generic Operations:** Explores symbolic expressions, alternatives for representing sets, and the need for generic operations in handling differently represented data, illustrated with polynomial arithmetic.
  """

  @summary_2_1 """
  2.1 Introduction to Data Abstraction
  1. **Data Abstraction Definition:** Data abstraction is a methodology separating how compound data is used from its construction details using selectors and constructors.
  2. **Functional Abstraction Analogy:** Similar to functional abstraction, data abstraction allows replacing details of data implementation while preserving overall behavior.
  3. **Program Structuring:** Programs should operate on "abstract data" without unnecessary assumptions, with a defined interface using selectors and constructors for concrete data representation.
  4. **Illustration with Rational Numbers:** The concept is illustrated by designing functions for manipulating rational numbers through data abstraction techniques.
  """

  @summary_2_1_1 """
  2.1.1 Example: Arithmetic Operations for Rational Numbers
  1. **Rational Number Operations:** Describes arithmetic operations for rational numbers: add, subtract, multiply, divide, and equality tests.
  2. **Synthetic Strategy:** Utilizes "wishful thinking" synthesis, assuming constructor and selectors for rational numbers without defining their implementation details.
  3. **Pairs and Glue:** Introduces pairs as the glue for implementing concrete data abstraction and list-structured data, illustrating their use in constructing complex data structures.
  4. **Rational Number Representation:** Represents rational numbers as pairs of integers (numerator and denominator) and implements operations using pairs as building blocks. Also addresses reducing rational numbers to lowest terms.
  """

  @summary_2_1_2 """
  2.1.2 Abstraction Barriers
  1. **Abstraction Barriers:** Discusses the concept of abstraction barriers, separating program levels using interfaces for data manipulation.
  2. **Advantages of Data Abstraction:** Simplifies program maintenance and modification by confining data structure representation changes to a few modules.
  3. **Flexibility in Implementation:** Illustrates the flexibility of choosing when to compute certain values, such as gcd, based on use patterns without modifying higher-level functions.
  4. **Exercise Examples:** Presents exercises on representing line segments and rectangles, highlighting the application of abstraction barriers and flexibility in design.
  """

  @summary_2_1_3 """
  2.1.3 What Is Meant by Data?
  1. **Defining Data:** Discusses the concept of data, emphasizing the need for specific conditions that selectors and constructors must fulfill.
  2. **Data as Collections of Functions:** Demonstrates the functional representation of pairs, illustrating that functions can serve as data structures fulfilling necessary conditions.
  3. **Functional Pairs Implementation:** Presents an alternative functional representation of pairs and verifies its correctness in terms of head and tail functions.
  4. **Church Numerals:** Introduces Church numerals, representing numbers through functions, and provides exercises to define one, two, and addition in this system.
  """

  @summary_2_1_4 """
  2.1.4 Extended Exercise: Interval Arithmetic
  1. **Interval Arithmetic Concept:** Alyssa P. Hacker is designing a system for interval arithmetic to handle inexact quantities with known precision.
  2. **Interval Operations:** Alyssa defines operations like addition, multiplication, and division for intervals based on their lower and upper bounds.
  3. **Interval Constructors and Selectors:** The text introduces an interval constructor and selectors, and there are exercises to complete the implementation and explore related concepts.
  4. **User Issues:** The user, Lem E. Tweakit, encounters discrepancies in computing parallel resistors using different algebraic expressions in Alyssa's system.
  """

  @summary_2_2 """
  2.2 Hierarchical Data and the Closure Property
  1. **Pair Representation:** Pairs, represented using box-and-pointer notation, serve as a primitive "glue" to create compound data objects.
  2. **Universal Building Block:** Pairs, capable of combining numbers and other pairs, act as a universal building block for constructing diverse data structures.
  3. **Closure Property:** The closure property of pairs enables the creation of hierarchical structures, facilitating the combination of elements with the same operation.
  4. **Importance in Programming:** Closure is crucial in programming, allowing the construction of complex structures made up of parts, leading to powerful combinations.
  """

  @summary_2_2_1 """
  2.2.1 Representing Sequences
  1. **Sequence Representation:** Pairs are used to represent sequences, visualized as chains of pairs, forming a list structure in box-and-pointer notation.
  2. **List Operations:** Lists, constructed using pairs, support operations like head and tail for element extraction, length for counting, and append for combining.
  3. **Mapping with Higher-Order Function:** The higher-order function map abstracts list transformations, allowing the application of a function to each element, enhancing abstraction in list processing.
  4. **For-Each Operation:** The for_each function applies a given function to each element in a list, useful for actions like printing, with the option to return an arbitrary value.
  """

  @summary_2_2_2 """
  2.2.2 Hierarchical Structures
  1. **Hierarchical Sequences:** Sequences of sequences are represented as hierarchical structures, extending the list structure to form trees.
  2. **Tree Operations:** Recursion is used for tree operations, such as counting leaves and length, demonstrating natural tree processing with recursive functions.
  3. **Mobile Representation:** Binary mobiles, consisting of branches and weights, are represented using compound data structures, with operations to check balance and calculate total weight.
  4. **Mapping Over Trees:** Operations like scale_tree demonstrate mapping over trees, combining sequence operations and recursion for efficient tree manipulation.
  """

  @summary_2_2_3 """
  2.2.3 Sequences as Conventional Interfaces
  1. **Sequence Operations:**
  - Use signals flowing through stages to design programs, enhancing conceptual clarity.
  - Represent signals as lists, enabling modular program design with standard components.
  2. **Operations on Sequences:**
  - Implement mapping, filtering, and accumulation operations for sequence processing.
  - Examples: map, filter, accumulate functions for various computations, providing modularity.
  3. **Signal-Flow Structure:**
  - Organize programs to manifest signal-flow structure for clarity.
  - Utilize sequence operations like map, filter, and accumulate to express program designs.
  4. **Exercises and Solutions:**
  - Includes exercises involving list-manipulation operations and matrix operations.
  - Demonstrates nested mappings for problem-solving, like permutations and eight-queens puzzle.
  """

  @summary_2_2_4 """
  2.2.4 Example: A Picture Language
  1. **Picture Language Overview:**
  - Utilizes a simple language for drawing pictures, showcasing data abstraction, closure, and higher-order functions.
  - Painters, representing images, draw within designated frames, enabling easy experimentation with patterns.
  - Operations like flip, rotate, and squash transform painters, while combinations like beside and below create compound painters.
  2. **Painter Operations:**
  - `transform_painter` is a key operation, transforming painters based on specified frame points.
  - Operations like flip_vert, rotate90, and squash_inwards leverage `transform_painter` to achieve specific effects.
  - `beside` and `below` combine painters, each transformed to draw in specific regions of the frame.
  3. **Stratified Design Principles:**
  - Embraces stratified design, structuring complexity through levels and languages.
  - Primitives like primitive painters are combined at lower levels, forming components for higher-level operations.
  - Enables robust design, allowing changes at different levels with minimal impact.
  4. **Examples and Exercises:**
  - Illustrates examples like square_limit, flipped_pairs, and square_of_four.
  - Exercises involve modifying patterns, defining new transformations, and demonstrating the versatility of the picture language.
  """

  @summary_2_3 """
  2.3 Symbolic Data
  1. **Compound Data Objects:**
  - Constructed from numbers in previous sections.
  - Introduction of working with strings as data.
  2. **Representation Extension:**
  - Enhances language capabilities.
  - Adds versatility to data representation.
  """

  @summary_2_3_1 """
  2.3.1 Strings
  1. **String Usage:**
  - Strings used for messages.
  - Compound data with strings in lists.
  2. **String Representation:**
  - Strings in double quotes.
  - Distinction from names in code.
  3. **Comparison Operations:**
  - Introduction of === and !== for strings.
  - Example function using ===: `member(item, x)`.
  4. **Exercises:**
  - Evaluation exercises with lists and strings.
  - Implementation exercise: `equal` function.
  """

  @summary_2_3_2 """
  2.3.2 Example: Symbolic Differentiation
  1. **Symbolic Differentiation:**
  - Purpose: Deriving algebraic expressions symbolically.
  - Historical Significance: Influential in Lisp development and symbolic mathematical systems.
  2. **Differentiation Algorithm:**
  - Abstract algorithm for sums, products, and variables.
  - Recursive reduction rules for symbolic expressions.
  3. **Expression Representation:**
  - Use of prefix notation for mathematical structure.
  - Variables represented as strings, sums, and products as lists.
  4. **Algorithm Implementation:**
  - `deriv` function for symbolic differentiation.
  - Examples and the need for expression simplification.
  """

  @summary_2_3_3 """
  2.3.3 Example: Representing Sets
  1. **Set Representation:**
  - Informal definition: a collection of distinct objects.
  - Defined using data abstraction with operations: union_set, intersection_set, is_element_of_set, adjoin_set.
  - Various representations: unordered lists, ordered lists, binary trees.
  2. **Sets as Unordered Lists:**
  - Represented as a list with no duplicate elements.
  - Operations: is_element_of_set, adjoin_set, intersection_set.
  - Efficiency concerns: is_element_of_set may require Θ(n) steps.
  3. **Sets as Ordered Lists:**
  - Elements listed in increasing order for efficiency.
  - Operations like is_element_of_set benefit from ordered representation.
  - Intersection_set exhibits significant speedup (Θ(n) instead of Θ(n^2)).
  4. **Sets as Binary Trees:**
  - Further speedup using a tree structure.
  - Each node holds an entry and links to left and right subtrees.
  - Operations: is_element_of_set, adjoin_set with Θ(log n) complexity.
  - Balancing strategies needed to maintain efficiency.
  Note: Code snippets and exercises provide implementation details for each representation.
  """

  @summary_2_3_4 """
  2.3.4 Example: Huffman Encoding Trees
  1. **Huffman Encoding Basics:**
  - Describes the concept of encoding data using sequences of 0s and 1s (bits).
  - Introduces fixed-length and variable-length codes for symbols.
  - Illustrates an example of a fixed-length code and a variable-length code for a set of symbols.
  2. **Variable-Length Codes:**
  - Explains the concept of variable-length codes, where different symbols may have different bit lengths.
  - Highlights the efficiency of variable-length codes in comparison to fixed-length codes.
  - Introduces the idea of prefix codes, ensuring no code is a prefix of another.
  3. **Huffman Encoding Method:**
  - Presents the Huffman encoding method, a variable-length prefix code.
  - Describes how Huffman codes are represented as binary trees.
  - Explains the construction of Huffman trees based on symbol frequencies.
  4. **Decoding with Huffman Trees:**
  - Outlines the process of decoding a bit sequence using a Huffman tree.
  - Describes the algorithm to traverse the tree and decode symbols.
  - Provides functions for constructing, representing, and decoding Huffman trees in JavaScript.
  """

  @summary_2_4 """
  2.4 Multiple Representations for Abstract Data
  1. **Data Abstraction:**
  - Introduces data abstraction as a methodology for structuring systems.
  - Explains the use of abstraction barriers to separate design from implementation for rational numbers.
  2. **Need for Multiple Representations:**
  - Recognizes the limitation of a single underlying representation for data objects.
  - Discusses the importance of accommodating multiple representations for flexibility.
  3. **Generic Functions:**
  - Highlights the concept of generic functions that operate on data with multiple representations.
  - Introduces type tags and data-directed style for building generic functions.
  4. **Complex-Number Example:**
  - Illustrates the implementation of complex numbers with both rectangular and polar representations.
  - Emphasizes the role of abstraction barriers in managing different design choices.
  """

  @summary_2_4_1 """
  2.4.1 Representations for Complex Numbers
  1. **Complex Number Representations:**
  - Discusses two representations for complex numbers: rectangular form (real and imaginary parts) and polar form (magnitude and angle).
  - Emphasizes the need for generic operations that work with both representations.
  2. **Operations on Complex Numbers:**
  - Describes arithmetic operations on complex numbers, highlighting differences in representation for addition, subtraction, multiplication, and division.
  - Illustrates the use of selectors and constructors for implementing these operations.
  3. **Programming Choices:**
  - Introduces two programmers, Ben and Alyssa, independently choosing different representations for complex numbers.
  - Presents the implementations of selectors and constructors for both rectangular and polar forms.
  4. **Data Abstraction Discipline:**
  - Ensures that the same generic operations work seamlessly with different representations.
  - Acknowledges the example's simplification for clarity, noting the preference for rectangular form in practical computational systems.
  """

  @summary_2_4_2 """
  2.4.2 Tagged data
  1. **Principle of Least Commitment:**
  - Data abstraction follows the principle of least commitment, allowing flexibility in choosing representations at the last possible moment.
  - Maintains maximum design flexibility by deferring the choice of concrete representation for data objects.
  2. **Tagged Data Implementation:**
  - Introduces type tags to distinguish between different representations of complex numbers (rectangular or polar).
  - Utilizes functions like `attach_tag`, `type_tag`, and `contents` to manage type information.
  3. **Coexistence of Representations:**
  - Shows how Ben and Alyssa can modify their representations to coexist in the same system using type tags.
  - Ensures that functions do not conflict by appending "rectangular" or "polar" to their names.
  4. **Generic Complex-Arithmetic System:**
  - Implements generic complex-number arithmetic operations that work seamlessly with both rectangular and polar representations.
  - The resulting system is decomposed into three parts: complex-number-arithmetic operations, polar implementation, and rectangular implementation.
  """

  @summary_2_4_3 """
  2.4.3 Data-Directed Programming and Additivity
  1. **Dispatching on Type:**
  - Dispatching on type involves checking the type of a datum and calling an appropriate function.
  - Provides modularity but has weaknesses, such as the need for generic functions to know about all representations.
  2. **Data-Directed Programming:**
  - Data-directed programming modularizes system design further.
  - Uses an operation-and-type table, allowing easy addition of new representations without modifying existing functions.
  3. **Implementation with Tables:**
  - Uses functions like `put` and `get` for manipulating the operation-and-type table.
  - Ben and Alyssa implement their packages by adding entries to the table, facilitating easy integration.
  4. **Message Passing:**
  - Message passing represents data objects as functions that dispatch on operation names.
  - Provides an alternative to data-directed programming, where the data object receives operation names as "messages."
  """

  @notes %{
    "1" => @summary_1,
    "1.1" => @summary_1_1,
    "1.1.1" => @summary_1_1_1,
    "1.1.2" => @summary_1_1_2,
    "1.1.3" => @summary_1_1_3,
    "1.1.4" => @summary_1_1_4,
    "1.1.5" => @summary_1_1_5,
    "1.1.6" => @summary_1_1_6,
    "1.1.7" => @summary_1_1_7,
    "1.1.8" => @summary_1_1_8,
    "1.2" => @summary_1_2,
    "1.2.1" => @summary_1_2_1,
    "1.2.2" => @summary_1_2_2,
    "1.2.3" => @summary_1_2_3,
    "1.2.4" => @summary_1_2_4,
    "1.2.5" => @summary_1_2_5,
    "1.2.6" => @summary_1_2_6,
    "1.3" => @summary_1_3,
    "1.3.1" => @summary_1_3_1,
    "1.3.2" => @summary_1_3_2,
    "1.3.3" => @summary_1_3_3,
    "1.3.4" => @summary_1_3_4,
    "2" => @summary_2,
    "2.1" => @summary_2_1,
    "2.1.1" => @summary_2_1_1,
    "2.1.2" => @summary_2_1_2,
    "2.1.3" => @summary_2_1_3,
    "2.1.4" => @summary_2_1_4,
    "2.2" => @summary_2_2,
    "2.2.1" => @summary_2_2_1,
    "2.2.2" => @summary_2_2_2,
    "2.2.3" => @summary_2_2_3,
    "2.2.4" => @summary_2_2_4,
    "2.3" => @summary_2_3,
    "2.3.1" => @summary_2_3_1,
    "2.3.2" => @summary_2_3_2,
    "2.3.3" => @summary_2_3_3,
    "2.3.4" => @summary_2_3_4,
    "2.4" => @summary_2_4,
    "2.4.1" => @summary_2_4_1,
    "2.4.2" => @summary_2_4_2,
    "2.4.3" => @summary_2_4_3
  }

  @spec get_summary(String.t()) :: String.t() | nil
  def get_summary(section) do
    Map.get(@notes, section)
  end
end
