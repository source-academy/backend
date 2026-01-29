[
  # Ignore Ecto.Multi opaque type warnings - these are false positives from stricter
  # opaque type checking in OTP 28. Ecto.Multi.new() returns a struct with internal
  # MapSet representation that Dialyzer now flags as opaque type mismatch.
  ~r"call_without_opaque",
  ~r"Call does not have expected term of type",

  # Ignore unmatched return warnings - these are intentional in many cases
  # where error handling is done at a higher level
  ~r"unmatched_return",

  # Ignore contract supertype warnings - these are overly conservative
  ~r"contract_supertype",

  # Ignore callback argument type mismatches for OpenID providers
  ~r"callback_arg_type_mismatch"
]
