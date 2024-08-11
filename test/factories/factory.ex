defmodule Cadet.Factory do
  @moduledoc """
  Factory for testing
  """
  use ExMachina.Ecto, repo: Cadet.Repo

  use Cadet.Accounts.{
    NotificationFactory,
    UserFactory,
    CourseRegistrationFactory,
    TeamFactory,
    TeamMemberFactory
  }

  use Cadet.Assessments.{
    AnswerFactory,
    AssessmentFactory,
    LibraryFactory,
    QuestionFactory,
    SubmissionFactory,
    SubmissionVotesFactory
  }

  use Cadet.Chatbot.{ConversationFactory}

  use Cadet.Stories.{StoryFactory}

  use Cadet.Incentives.{
    AchievementFactory,
    GoalFactory
  }

  use Cadet.Courses.{
    AssessmentConfigFactory,
    CourseFactory,
    GroupFactory,
    SourcecastFactory
  }

  use Cadet.Notifications.{
    NotificationTypeFactory,
    NotificationConfigFactory,
    NotificationPreferenceFactory,
    TimeOptionFactory
  }

  use Cadet.Devices.DeviceFactory

  def upload_factory do
    %Plug.Upload{
      content_type: "text/plain",
      filename: sequence(:upload, &"upload#{&1}.txt"),
      path: "test/fixtures/upload.txt"
    }
  end
end
