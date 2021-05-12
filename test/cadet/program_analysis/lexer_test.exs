defmodule Cadet.ProgramAnalysis.LexerTest do
  alias Cadet.ProgramAnalysis.Lexer

  use ExUnit.Case

  test "count_tokens() can count tokens for simple program" do
    # 1 for funtion and 1 for sayHello name
    # 2 for () parenthesis and 2 for {}
    # 1 for const, 1 for hello, 1 for = , 1 for "Hello" and 1 for ;
    # 1 for return and 1 for hello and 1 for ;
    # = 14
    sample_program = ~S"""
    function sayHello() {
      const hello = "Hello";
      return hello;
    }
    """

    # 0 for multi line comment
    # 1 for function and 1 for hello_STUDENT_NAME
    # 2 for parenthesis () and 2 for {}
    # 0 for single line comment
    # 1 for return and 1 for "hello" and 1 for ;
    # = 9
    sample_program_2 = ~S"""
    /********* /****** /* this is a multi-line comment \n line 2 *** /* /* */
    function hello_STUDENT_NAME() {
    // this is a single line comment \n
    return "hello world this is a string with spaces \
    that also spans multiple lines and \\n has escape sequences\
    hello";
    }
    """

    huge_program = ~S"""
    /*
    Virtual machine implementation of language Source §0
    following the virtual machine of Lecture Week 2 of CS4215

    Instructions: Copy this file into the Source Academy frontend:
                  https://source-academy.github.io/playground
            You can use the google drive feature to save your
            work. When done, copy the file back to the
            repository and push your changes.

                  To run your program, press "Run" and observe
            the result on the right.

    The language Source §0 is defined as follows:

    prgm    ::= expr ;

    expr    ::= number
              |  true | false
              |  expr binop expr
              |  unop expr
    binop   ::= + | - | * | / | < | >
              | === |  && | ||
    unop    ::= !
    */

    // Functions from SICP JS Section 4.1.2
    // with slight modifications


    function is_tagged_list(expr, the_tag) {
        return is_pair(expr) && head(expr) === the_tag;
    }

    function make_literal(value) {
        return list("literal", value);
    }

    function is_literal(expr) {
        return is_tagged_list(expr, "literal");
    }

    function literal_value(expr) {
        return head(tail(expr));
    }

    function is_operator_combination(expr) {
        return is_unary_operator_combination(expr) ||
              is_binary_operator_combination(expr);
    }

    function is_unary_operator_combination(expr) {
        return is_tagged_list(expr, "unary_operator_combination");
    }

    // logical composition (&&, ||) is treated as binary operator combination
    function is_binary_operator_combination(expr) {
        return is_tagged_list(expr, "binary_operator_combination") ||
              is_tagged_list(expr, "logical_composition");
    }

    function operator(expr) {
        return head(tail(expr));
    }

    function first_operand(expr) {
        return head(tail(tail(expr)));
    }

    function second_operand(expr) {
        return head(tail(tail(tail(expr))));
    }

    // two new functions, not in 4.1.2

    function is_boolean_literal(expr) {
        return is_tagged_list(expr, "literal") &&
                is_boolean(literal_value(expr));
    }

    function is_number_literal(expr) {
        return is_tagged_list(expr, "literal") &&
                is_number(literal_value(expr));
    }

    // functions to represent virtual machine code

    function op_code(instr) {
        return head(instr);
    }

    function arg(instr) {
        return head(tail(instr));
    }

    function make_simple_instruction(op_code) {
        return list(op_code);
    }

    function DONE() {
        return list("DONE");
    }

    function LDCI(i) {
        return list("LDCI", i);
    }

    function LDCB(b) {
        return list("LDCB", b);
    }

    function PLUS() {
        return list("PLUS");
    }

    function MINUS() {
        return list("MINUS");
    }

    function TIMES() {
        return list("TIMES");
    }

    function DIV() {
        return list("DIV");
    }

    function AND() {
        return list("AND");
    }

    function OR() {
        return list("OR");
    }

    function NOT() {
        return list("NOT");
    }

    function LT() {
        return list("LT");
    }

    function GT() {
        return list("GT");
    }

    function EQ() {
        return list("EQ");
    }

    // compile_program: see relation ->> in Section 3.5.2

    function compile_program(program) {
        return append(compile_expression(program), list(DONE()));
    }

    // compile_expression: see relation hookarrow in 3.5.2

    function compile_expression(expr) {
        if (is_number_literal(expr)) {
            return list(LDCI(literal_value(expr)));
        } else if (is_boolean_literal(expr)) {
            return list(LDCB(literal_value(expr)));
        } else {
            const op = operator(expr);
            const operand_1 = first_operand(expr);
            if (op === "!") {
                return append(compile_expression(operand_1),
                              list(NOT()));
            } else {
                const operand_2 = second_operand(expr);
                const op_code = op === "+" ? "PLUS"
                              : op === "-" ? "MINUS"
                              : op === "*" ? "TIMES"
                              : op === "/" ? "DIV"
                              : op === "===" ? "EQ"
                              : op === "<" ? "LT"
                              : op === ">" ? "GT"
                              : op === "&&" ? "AND"
                              : /*op === "||" ?*/ "OR";
                return append(compile_expression(operand_1),
                              append(compile_expression(operand_2),
                                      list(make_simple_instruction(op_code))));
            }
        }
    }

    function parse_and_compile(string) {
        return compile_program(parse(string));
    }

    // parse_and_compile("! (1 === 1 && 2 > 3);");
    // parse_and_compile("1 + 2 / 0;");
    // parse_and_compile("1 + 2 / 1;");
    // parse_and_compile("3 / 4;");

    // machine state: a pair consisting
    // of an operand stack and a program counter,
    // following 3.5.3

    function make_state(stack, pc) {
        return pair(stack, pc);
    }

    function get_stack(state) {
        return head(state);
    }

    function get_pc(state) {
        return tail(state);
    }

    // operations on the operand stack

    function empty_stack() {
        return null;
    }
    function push(stack, value) {
        return pair(value, stack);
    }

    function pop(stack) {
        return tail(stack);
    }

    function top(stack) {
        return head(stack);
    }

    // run the machine according to 3.5.3

    function run(code) {
        const initial_state = make_state(empty_stack(), 0);
        return transition(code, initial_state);
    }

    function transition(code, state) {
        const pc = get_pc(state);
        const stack = get_stack(state);
        const instr = list_ref(code, pc);
        if (op_code(instr) === "DONE") {
            return top(stack);
        } else {
            return transition(code, make_state(next_stack(stack, instr),
                                                pc + 1));
        }
    }

    function next_stack(stack, instr) {
        const op = op_code(instr);
        return op === "LDCI" ? push(stack, arg(instr))
          : op === "LDCB" ? push(stack, arg(instr))
          : op === "PLUS" ? push(pop(pop(stack)), top(pop(stack)) + top(stack))
          : op === "MINUS" ? push(pop(pop(stack)), top(pop(stack)) - top(stack))
          : op === "TIMES" ? push(pop(pop(stack)), top(pop(stack)) * top(stack))
          : op === "DIV" ? push(pop(pop(stack)), math_floor(top(pop(stack)) /
                                                            top(stack)))
          : op === "NOT" ? push(pop(stack), ! top(stack))
          : op === "EQ" ? push(pop(pop(stack)), top(pop(stack)) === top(stack))
          : op === "LT" ? push(pop(pop(stack)), top(pop(stack)) < top(stack))
          : op === "GT" ? push(pop(pop(stack)), top(pop(stack)) > top(stack))
          : op === "AND" ? push(pop(pop(stack)), top(pop(stack)) && top(stack))
          : /*op === "OR" ?*/ push(pop(pop(stack)), top(pop(stack)) || top(stack));
    }

    function parse_compile_and_run(string) {
        const code = compile_program(parse(string));
        return run(code);
    }

    // parse_compile_and_run("! (1 === 1 && 2 > 3);");
    // parse_compile_and_run("1 + 2 / 0;");
    // parse_compile_and_run("1 + 2 / 1;");
    // parse_compile_and_run("3 / 4;");
    parse_compile_and_run("3 < 4 && 7 > 6;");
    """

    assert Lexer.count_tokens(sample_program) == 14
    assert Lexer.count_tokens(sample_program_2) == 9
    assert Lexer.count_tokens(huge_program) == 1192
  end
end
