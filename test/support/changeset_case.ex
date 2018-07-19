defmodule Cadet.ChangesetCase do
  @moduledoc """
  This module defines the setup for changeset tests
  """
  use ExUnit.CaseTemplate

  import ExUnit.Assertions, only: [assert: 2, refute: 2]

  using do
    quote do
      import Cadet.{ChangesetCase, Factory}
    end
  end

  defmacro valid_changesets(mod, do: block) do
    test_changesets("Valid", &assert/2, mod, block)
  end

  defmacro invalid_changesets(mod, do: block) do
    test_changesets("Invalid", &refute/2, mod, block)
  end

  def build_upload(path, content_type \\ "image\png") do
    %Plug.Upload{path: path, filename: Path.basename(path), content_type: content_type}
  end

  defp test_changesets(header, func, mod, block) do
    params =
      case block do
        {:__block__, _, params} -> params
        {:%{}, _, _} -> [block]
      end

    quote do
      test "#{unquote(header)} #{unquote(mod)} changesets" do
        for param <- unquote(params) do
          changeset = unquote(mod).changeset(%unquote(mod){}, param)
          unquote(func).(changeset.valid?(), Kernel.inspect(param))
        end
      end
    end
  end
end
