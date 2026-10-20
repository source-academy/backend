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
    SubmissionVotesFactory,
    VersionFactory
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
    GroupFactory
  }

  use Cadet.Notifications.{
    NotificationTypeFactory,
    NotificationConfigFactory,
    NotificationPreferenceFactory,
    TimeOptionFactory
  }

  use Cadet.Devices.DeviceFactory
end
