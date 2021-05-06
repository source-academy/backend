Definitions.

SINGLELINECOMMENT = \/\/.*
MULTILINECOMMENT = [/][*][^*]*[*]+([^*/][^*]*[*]+)*[/]
KEYWORDS = ([a-zA-Z0-9_])*
OPERATORS = (;|\+|\+\+|--|-|\*|\/|=|==|===|>|<|>=|<=|&|\||%|!|\^|\(|\)|\{|\})
WHITESPACE = [\s\t\r\n]+ 

Rules.

{SINGLELINECOMMENT} : skip_token.
{MULTILINECOMMENT} : skip_token. 
{WHITESPACE} : skip_token.
{OPERATORS} : {token, {list_to_atom(TokenChars), TokenLine}}.
{KEYWORDS} : {token, {list_to_atom(TokenChars), TokenLine}}. 
. : skip_token. 

Erlang code.