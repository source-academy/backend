defmodule Cadet.Factory do
  @moduledoc """
  Factory for testing
  """
  use ExMachina.Ecto, repo: Cadet.Repo
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
