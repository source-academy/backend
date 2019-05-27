import EctoEnum

defenum(Cadet.Assessments.Answer.AutogradingStatus, :autograding_status, [
  :none,
  :processing,
  :success,
  # note that :failed refers to the autograder failing due to system errors
  :failed
])
