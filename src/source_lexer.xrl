Definitions.

SINGLELINECOMMENT = \/\/.*
MULTILINECOMMENT = [/][*][^*]*[*]+([^*/][^*]*[*]+)*[/]
KEYWORDS = [a-zA-Z0-9_$]*
OPERATORS = (>>>=|===|!==|>>>|<<=|>>=|!=|==|<=|>=|\+=|-=|\*=|%=|<<|>>|&=|\|=|&&|\|\||\^=|--|\+\+|\+|-|\*|/|%|<|>|=|&|\||\^|\(|\)|\[|\]|\{|\}|!|~|,|;|\.|:|\?)
WHITESPACE = [\s\t\r\n]+
SQSTRING = '([^\\'\r\n]|\\(.|[\r\n]))*'
DQSTRING = "([^\\"\r\n]|\\(.|[\r\n]))*"

Rules.

{SINGLELINECOMMENT} : skip_token.
{MULTILINECOMMENT} : skip_token.
{WHITESPACE} : skip_token.
{OPERATORS} : {token, nil}.
{KEYWORDS} : {token, nil}.
{SQSTRING} : {token, nil}.
{DQSTRING} : {token, nil}.
. : {token, nil}.

Erlang code.
