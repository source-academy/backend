defmodule Cadet.Factory do
  @moduledoc """
  Factory for testing
  """
  use ExMachina.Ecto, repo: Cadet.Repo

  # TODO: Remove this dialyzer tag when ex_machina > v2.2.0 is released
  # (git commit b17ba1c is merged)
  # fields_for has been deprecated, only raising exception
  @dialyzer {:no_return, fields_for: 1}

  use Cadet.Accounts.{AuthorizationFactory, UserFactory}

  use Cadet.Assessments.{
    AnswerFactory,
    AssessmentFactory,
    LibraryFactory,
    QuestionFactory,
    SubmissionFactory
  }

  use Cadet.Course.{AnnouncementFactory, GroupFactory, MaterialFactory}

  def upload_factory do
    %Plug.Upload{
      content_type: "text/plain",
      filename: sequence(:upload, &"upload#{&1}.txt"),
      path: "test/fixtures/upload.txt"
    }
  end
end
