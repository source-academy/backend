# credo:disable-for-this-file Credo.Check.Readability.ModuleDoc
# @moduledoc is actually generated by a macro inside Quantum
defmodule Cadet.Jobs.Scheduler do
  @moduledoc """
  Quantum is used for scheduling jobs with cron jobs.
  """
  use Quantum, otp_app: :cadet
end
