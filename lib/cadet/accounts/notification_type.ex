import EctoEnum

defenum(Cadet.Accounts.NotificationType, :notification_type, [
  # Notifications for New assessments
  :new,
  # Notifications for deadlines
  :deadline,
  # Notifications for autograded assessments
  :autograded,
  # Notifications for manually graded assessments
  :graded,

  # Notifications for Submitted assessments
  :submitted
])
