defmodule Cadet.Chatbot.RagEvaluation do
  @moduledoc """
  Evaluation cases and helpers for the Python textbook vector-RAG chatbot.

  The cases are simulated student questions aimed at difficult or failure-prone
  concepts across the whole SICP Python text. They are used by the live
  `priv/rag/evaluate_questions.exs` script and by deterministic unit tests.
  """

  @section_regex ~r/^\d+(?:\.\d+)+$/

  @type case_data :: %{
          required(:id) => String.t(),
          required(:chapter) => pos_integer(),
          required(:difficulty) => :medium | :hard,
          required(:category) => :conceptual | :edge_case | :debugging,
          required(:question) => String.t(),
          required(:current_section) => String.t(),
          required(:expected_sections) => [String.t()],
          required(:require_section_reference) => boolean(),
          required(:rationale) => String.t()
        }

  @spec cases() :: [case_data()]
  def cases do
    [
      %{
        id: "normal_vs_applicative_order",
        chapter: 1,
        difficulty: :hard,
        category: :edge_case,
        question:
          "In the p() example, why does one evaluation order terminate while Python's usual evaluation gets stuck? I thought both orders should compute the same value.",
        current_section: "1.1.5",
        expected_sections: ["1.1.5"],
        require_section_reference: true,
        rationale:
          "Applicative-order evaluation can diverge where normal order avoids evaluating an unused argument."
      },
      %{
        id: "recursive_process_python_stack",
        chapter: 1,
        difficulty: :hard,
        category: :debugging,
        question:
          "My factorial helper is tail-recursive, so why can it still hit recursion depth in Python? Is tail recursion the same thing as an iterative process?",
        current_section: "1.2.1",
        expected_sections: ["1.2.1"],
        require_section_reference: true,
        rationale: "Students often confuse process shape with the host language's stack behavior."
      },
      %{
        id: "tree_recursion_repeated_work",
        chapter: 1,
        difficulty: :medium,
        category: :conceptual,
        question:
          "Why is the simple recursive Fibonacci function so slow if each line of code looks small? Where does all the repeated work come from?",
        current_section: "1.2.2",
        expected_sections: ["1.2.2"],
        require_section_reference: false,
        rationale: "Tree recursion creates many overlapping subcomputations."
      },
      %{
        id: "fermat_carmichael_false_positive",
        chapter: 1,
        difficulty: :hard,
        category: :edge_case,
        question:
          "If a number passes the Fermat primality test for many bases, is it definitely prime? What exactly goes wrong with Carmichael numbers?",
        current_section: "1.2.6",
        expected_sections: ["1.2.6"],
        require_section_reference: true,
        rationale: "Probabilistic tests have subtle false-positive cases."
      },
      %{
        id: "fixed_point_nonconvergence_damping",
        chapter: 1,
        difficulty: :hard,
        category: :debugging,
        question:
          "My fixed-point iteration keeps bouncing between two values. How does average damping change the process, and when should I use it?",
        current_section: "1.3.3",
        expected_sections: ["1.3.3", "1.3.4"],
        require_section_reference: false,
        rationale: "Convergence depends on the transformation, not just the target equation."
      },
      %{
        id: "interval_dependency_problem",
        chapter: 2,
        difficulty: :hard,
        category: :edge_case,
        question:
          "Why do two algebraically equivalent interval formulas give different ranges when the same uncertain value appears twice?",
        current_section: "2.1.4",
        expected_sections: ["2.1.4"],
        require_section_reference: true,
        rationale: "The dependency problem is a classic interval-arithmetic trap."
      },
      %{
        id: "abstraction_barrier_rational_numbers",
        chapter: 2,
        difficulty: :medium,
        category: :conceptual,
        question:
          "If I change the internal representation of rational numbers, which code should need to change and which code should not?",
        current_section: "2.1.2",
        expected_sections: ["2.1.2"],
        require_section_reference: false,
        rationale: "Abstraction barriers are foundational for later data-directed design."
      },
      %{
        id: "closure_property_nested_sequences",
        chapter: 2,
        difficulty: :medium,
        category: :conceptual,
        question:
          "What does the closure property mean for lists and trees? Why is it important that pairs can contain other pairs?",
        current_section: "2.2",
        expected_sections: ["2.2"],
        require_section_reference: false,
        rationale: "Nested structures underpin sequence and tree processing."
      },
      %{
        id: "symbolic_derivative_new_operator",
        chapter: 2,
        difficulty: :hard,
        category: :debugging,
        question:
          "My symbolic differentiator handles sums and products, but exponentiation gives the wrong answer. Where should a new operator's rules be added?",
        current_section: "2.3.2",
        expected_sections: ["2.3.2"],
        require_section_reference: true,
        rationale:
          "Symbolic systems need both representation predicates/selectors and algebraic rules."
      },
      %{
        id: "huffman_prefix_decode_failure",
        chapter: 2,
        difficulty: :hard,
        category: :edge_case,
        question:
          "Why can Huffman codes be decoded without separators between symbols, and what happens if one bit is corrupted?",
        current_section: "2.3.4",
        expected_sections: ["2.3.4"],
        require_section_reference: false,
        rationale: "Prefix-free codes are easy to use but brittle under bit errors."
      },
      %{
        id: "data_directed_new_type_vs_new_operation",
        chapter: 2,
        difficulty: :hard,
        category: :conceptual,
        question:
          "When using data-directed programming, why is adding a new type different from adding a new operation? Which approach changes fewer files?",
        current_section: "2.4.3",
        expected_sections: ["2.4.3"],
        require_section_reference: true,
        rationale: "This is the key tradeoff behind dispatch tables and message passing."
      },
      %{
        id: "generic_coercion_ambiguity",
        chapter: 2,
        difficulty: :hard,
        category: :edge_case,
        question:
          "If two generic numeric types can both be coerced toward each other, how should the system choose a coercion path without doing the wrong operation?",
        current_section: "2.5.2",
        expected_sections: ["2.5.2"],
        require_section_reference: false,
        rationale: "Coercion towers can introduce ambiguous dispatch paths."
      },
      %{
        id: "assignment_referential_transparency",
        chapter: 3,
        difficulty: :hard,
        category: :conceptual,
        question:
          "After adding assignment, why can't I replace a function call with its value the way substitution says I can?",
        current_section: "3.1.3",
        expected_sections: ["3.1.3"],
        require_section_reference: true,
        rationale: "Mutable state breaks simple substitution reasoning."
      },
      %{
        id: "aliasing_mutable_pairs",
        chapter: 3,
        difficulty: :hard,
        category: :edge_case,
        question:
          "Two variables point to the same list. Why does mutating one variable's list change what I see through the other variable?",
        current_section: "3.3.1",
        expected_sections: ["3.3.1"],
        require_section_reference: false,
        rationale: "Aliasing and identity are common sources of state bugs."
      },
      %{
        id: "environment_closure_lookup",
        chapter: 3,
        difficulty: :hard,
        category: :debugging,
        question:
          "A function returned from another function still remembers an old variable. Which environment is used when that inner function runs?",
        current_section: "3.2.3",
        expected_sections: ["3.2.2", "3.2.3"],
        require_section_reference: true,
        rationale: "Closures require environment-model reasoning."
      },
      %{
        id: "concurrent_exchange_deadlock",
        chapter: 3,
        difficulty: :hard,
        category: :edge_case,
        question:
          "Why is exchanging two account balances concurrently harder than just transferring money? How can serializers still lead to deadlock?",
        current_section: "3.4.2",
        expected_sections: ["3.4.2"],
        require_section_reference: true,
        rationale:
          "Concurrent mutation requires serializing compound operations and thinking about lock ordering."
      },
      %{
        id: "lazy_stream_infinite_sequence",
        chapter: 3,
        difficulty: :hard,
        category: :debugging,
        question:
          "Why does my infinite stream work only when the tail is delayed? What goes wrong if I build the whole sequence eagerly?",
        current_section: "3.5.2",
        expected_sections: ["3.5.2", "3.5.4"],
        require_section_reference: false,
        rationale: "Streams depend on delayed evaluation to represent infinite data."
      },
      %{
        id: "lazy_thunk_memoization_side_effect",
        chapter: 4,
        difficulty: :hard,
        category: :edge_case,
        question:
          "If a delayed argument has a side effect, will it run once or every time the parameter is used? How does memoizing thunks change the answer?",
        current_section: "4.2.2",
        expected_sections: ["4.2.2"],
        require_section_reference: true,
        rationale: "Call-by-name and call-by-need differ most visibly with side effects."
      },
      %{
        id: "internal_definitions_scan_out",
        chapter: 4,
        difficulty: :hard,
        category: :debugging,
        question:
          "Why do internal function definitions sometimes need to be scanned out before evaluating the body? What bug appears if they are treated sequentially?",
        current_section: "4.1.6",
        expected_sections: ["4.1.6"],
        require_section_reference: false,
        rationale: "Internal declarations affect environment construction."
      },
      %{
        id: "amb_backtracking_state_restore",
        chapter: 4,
        difficulty: :hard,
        category: :edge_case,
        question:
          "In the amb evaluator, if I assign to a variable and then backtrack, should the assignment be undone?",
        current_section: "4.3.3",
        expected_sections: ["4.3.3"],
        require_section_reference: true,
        rationale: "Backtracking with mutation requires restoration through continuations."
      },
      %{
        id: "logic_not_order_dependence",
        chapter: 4,
        difficulty: :hard,
        category: :edge_case,
        question:
          "Why can putting not before a query pattern in the logic system produce a different answer than putting it after?",
        current_section: "4.4.3",
        expected_sections: ["4.4.3"],
        require_section_reference: false,
        rationale: "Negation as failure is order-sensitive in query evaluation."
      },
      %{
        id: "unification_occurs_check",
        chapter: 4,
        difficulty: :hard,
        category: :edge_case,
        question:
          "What goes wrong if unification lets a variable match an expression that contains that same variable?",
        current_section: "4.4.2",
        expected_sections: ["4.4.2", "4.4.3"],
        require_section_reference: true,
        rationale: "Missing occurs-check style reasoning can create circular bindings."
      },
      %{
        id: "register_machine_stack_recursion",
        chapter: 5,
        difficulty: :hard,
        category: :debugging,
        question:
          "In the register-machine factorial, why do we save and restore registers around the recursive call? Which value would be lost otherwise?",
        current_section: "5.1.4",
        expected_sections: ["5.1.4"],
        require_section_reference: true,
        rationale: "The stack protocol makes recursive control explicit."
      },
      %{
        id: "garbage_collection_forwarding_pointers",
        chapter: 5,
        difficulty: :hard,
        category: :conceptual,
        question:
          "In stop-and-copy garbage collection, why do copied objects need forwarding pointers instead of just copying every pair reached?",
        current_section: "5.3.2",
        expected_sections: ["5.3.2"],
        require_section_reference: false,
        rationale: "Forwarding preserves sharing and prevents duplicate copies."
      },
      %{
        id: "explicit_control_tail_recursion",
        chapter: 5,
        difficulty: :hard,
        category: :conceptual,
        question:
          "How does the explicit-control evaluator avoid growing the stack for a tail-recursive call?",
        current_section: "5.4.2",
        expected_sections: ["5.4.2"],
        require_section_reference: true,
        rationale: "Proper tail recursion is visible in the evaluator's control sequence."
      },
      %{
        id: "compiler_lexical_addressing",
        chapter: 5,
        difficulty: :hard,
        category: :conceptual,
        question:
          "What does lexical addressing buy us in the compiler? Why is it better than searching frames by variable name at runtime?",
        current_section: "5.5.6",
        expected_sections: ["5.5.6"],
        require_section_reference: false,
        rationale: "Lexical addresses move environment lookup work from runtime to compile time."
      }
    ]
  end

  @spec citation_instruction(case_data()) :: String.t()
  def citation_instruction(%{require_section_reference: false}), do: ""

  def citation_instruction(%{expected_sections: sections}) do
    section_list = Enum.join(sections, " or Section ")

    "\n\nEvaluation requirement: End your answer with a short sentence that explicitly mentions Section #{section_list}. Do not invent any other section number."
  end

  @spec answer_mentions_expected_section?(String.t(), case_data()) :: boolean()
  def answer_mentions_expected_section?(answer, %{expected_sections: sections})
      when is_binary(answer) and is_list(sections) do
    Enum.any?(sections, &section_mentioned?(answer, &1))
  end

  def answer_mentions_expected_section?(_answer, _case), do: false

  @spec retrieval_hits_expected_section?([map()], case_data()) :: boolean()
  def retrieval_hits_expected_section?(chunks, %{expected_sections: sections})
      when is_list(chunks) and is_list(sections) do
    Enum.any?(chunks, fn chunk -> chunk_section(chunk) in sections end)
  end

  @spec valid_case?(case_data()) :: boolean()
  def valid_case?(case_data) do
    is_binary(case_data.id) and
      case_data.id != "" and
      case_data.chapter in 1..5 and
      case_data.difficulty in [:medium, :hard] and
      case_data.category in [:conceptual, :edge_case, :debugging] and
      is_binary(case_data.question) and
      String.length(case_data.question) >= 40 and
      valid_section?(case_data.current_section) and
      is_list(case_data.expected_sections) and
      case_data.expected_sections != [] and
      Enum.all?(case_data.expected_sections, &valid_section?/1) and
      is_boolean(case_data.require_section_reference) and
      is_binary(case_data.rationale) and
      case_data.rationale != ""
  end

  @spec chunk_section(map()) :: String.t() | nil
  def chunk_section(chunk) do
    metadata = Map.get(chunk, :metadata) || Map.get(chunk, "metadata") || %{}

    Map.get(metadata, "section") ||
      Map.get(metadata, :section)
  end

  defp valid_section?(section), do: is_binary(section) and section =~ @section_regex

  defp section_mentioned?(answer, section) do
    escaped = Regex.escape(section)
    Regex.match?(~r/\b[Ss]ection\s+#{escaped}\b/, answer)
  end
end
