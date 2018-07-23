defmodule Cadet.Updater.XMLParser do
  @moduledoc """
  Parser for XML files from the cs1101s repository.
  """
  @local_name if Mix.env() != :test, do: "cs1101s", else: "test/local_repo"
  @locations %{mission: "missions", sidequest: "quests", path: "paths", contest: "contests"}

  @xml """
<?xml version="1.0"?>
<CONTENT xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xlink="http://128.199.210.247">

<!-- ***********************************************************************
**** MISSION #M99
************************************************************************ -->
<TASK kind="mission" number="M99" startdate="2018-07-23T00:00+08" duedate="2018-09-20T23:59+08" title="Simple Stuff">
  <READING>Textbook Sections 1.1.1 to 1.1.2</READING>
  <TEXT>
Welcome to this assessment! This is the *briefing*.

This mission consists of **two tasks**. First, find a way to add two numbers together, like so:

```
sum(3, 5); // returns 8
```

Then, let's test out the runes library.

```
mul(3, 5); // return 15
  </TEXT>
  <PROBLEMS>
    <PROBLEM maxgrade="2">
      <TEXT>
Your first task is to define a function `sum` that adds two numbers together.
      </TEXT>
        <SNIPPET>
          <TEMPLATE>
const sum = () => 0; // your solution here

/* test your program! */
sum(3, 5); // returns 8
          </TEMPLATE>
          <SOLUTION>
// [Marking Scheme]
// You may subtract 1 from the grade if the student does not use arrow functions.
          </SOLUTION>
          <GRADER>
function neiYa7eil5() {
  const test1 = sum(10, 10) === 20;
  const test2 = sum(0, 0) === 0;
  const test3 = sum(99, 1) === 100;
  return test1 &amp;&amp; test2 &amp;&amp; test3 ? 1 : 0;
}

neiYa7eil5();
          </GRADER>
          <GRADER>
function neiYa7eil5() {
  const test1 = sum(-10, 10) === 0;
  const test2 = sum(-1, -1) === -2;
  const test3 = sum(-99, 1) === 98;
  return test1 &amp;&amp; test2 &amp;&amp; test3 ? 1 : 0;
}

neiYa7eil5();
          </GRADER>
        </SNIPPET>
      </PROBLEM>
      <PROBLEM>
        <TEXT>
Use the function `show` to display a rune!
        </TEXT>
        <SNIPPET>
          <TEMPLATE>
// show the rune heart_bb
          </TEMPLATE>
        </SNIPPET>
      </PROBLEM>
    </PROBLEMS>
    <TEXT>
## Submission

Make sure that everything for your programs to work is on the left hand side and **not** in the REPL on the right! This is because only that program is used to assess your solution.

This TEXT will not be shown in cadet, but may be useful in the generated pdf.
    </TEXT>
    <DEPLOYMENT interpreter="1">
      <EXTERNAL name="TWO_DIM_RUNES">
        <SYMBOL>show</SYMBOL>
        <SYMBOL>heart_bb</SYMBOL>
        <SYMBOL>easter_egg2</SYMBOL>
      </EXTERNAL>
      <GLOBAL>
        <IDENTIFIER>easter_egg</IDENTIFIER>
        <VALUE>"This can be accessed through the browser console from window.easter_egg, or just easter_egg"</VALUE>
      </GLOBAL>
      <GLOBAL>
        <IDENTIFIER>easter_egg2</IDENTIFIER>
        <VALUE>"This can be accessed through the source interpreter, since it is defined in EXTERNAL as a SYMBOL"</VALUE>
      </GLOBAL>
    </DEPLOYMENT>
</TASK>

</CONTENT>
  """
  defmacrop is_non_empty_list(term) do
    quote do: is_list(unquote(term)) and unquote(term) != []
  end

  @spec parse_and_insert(:mission | :sidequest | :path | :contest) ::
          {:ok, nil} | {:error, String.t()}
  def parse_and_insert(type) do
    with {:assessment_type, true} <- {:assessment_type, type in Map.keys(@locations)},
         {:cloned?, {:ok, root}} when is_non_empty_list(root) <- {:cloned?, File.ls(@local_name)},
         {:type, true} <- {:type, @locations[type] in root},
         {:listing, {:ok, listing}} when is_non_empty_list(listing) <-
           {:listing, @local_name |> Path.join(@locations[type]) |> File.ls()},
         {:filter, xml_files} when is_non_empty_list(xml_files) <-
           {:filter, Enum.filter(listing, &String.ends_with?(&1, ".xml"))} do
      {:ok, nil}
    else
      {:assessment_type, false} -> {:error, "XML location of assessment type is not defined."}
      {:cloned?, {:error, _}} -> {:error, "Local copy of repository is either missing or empty."}
      {:type, false} -> {:error, "Directory containing XML is not found."}
      {:listing, {:error, _}} -> {:error, "Directory containing XML is empty."}
      {:filter, _} -> {:error, "No XML file is found."}
    end
  end
end
