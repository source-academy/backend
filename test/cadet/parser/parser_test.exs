defmodule Cadet.Parser.ParserTest do
  alias Cadet.Parser.Parser

  use ExUnit.Case

  test "lex() can count tokens for simple program" do
    # 1 for funtion and 1 for sayHello name 
    # 2 for () parenthesis and 2 for {} 
    # 1 for const, 1 for hello, 1 for = , 1 for "Hello" and 1 for ;
    # 1 for return and 1 for hello and 1 for ; 
    # = 14
    sample_program = "function sayHello() { 
            const hello = \"Hello\"; 
            return hello; 
            }"

    # 0 for multi line comment
    # 1 for function and 1 for hello_STUDENT_NAME
    # 2 for parenthesis () and 2 for {} 
    # 0 for single line comment 
    # 1 for return and 1 for "hello" and 1 for ; 
    # = 9
    sample_program_2 = "/* this is a multi-line comment \n line 2 */ 
        function hello_STUDENT_NAME() {
            // this is a single line comment \n 
            return \"hello\";
            } "
    assert Parser.lex(sample_program) == 14
    assert Parser.lex(sample_program_2) == 9
  end
end
