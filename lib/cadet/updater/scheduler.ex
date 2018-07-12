defmodule Cadet.Updater.Scheduler do
  @moduledoc """
  Use Quantum's scheduler.
  """

  use Quantum.Scheduler, otp_app: :cadet
end
