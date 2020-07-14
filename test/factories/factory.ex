defmodule Cadet.Factory do
  @moduledoc """
  Factory for testing
  """
  use ExMachina.Ecto, repo: Cadet.Repo

  use Cadet.Accounts.{NotificationFactory, UserFactory}

  use Cadet.Assessments.{
    AnswerFactory,
    AssessmentFactory,
    LibraryFactory,
    QuestionFactory,
    SubmissionFactory
  }

  use Cadet.Stories.{StoryFactory}

  use Cadet.Chapters.{ChapterFactory}

  use Cadet.Course.{GroupFactory, SourcecastFactory}

  def upload_factory do
    %Plug.Upload{
      content_type: "text/plain",
      filename: sequence(:upload, &"upload#{&1}.txt"),
      path: "test/fixtures/upload.txt"
    }
  end
end
