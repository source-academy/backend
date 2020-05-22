import EctoEnum

defenum(Cadet.Accounts.NotificationType, :notification_type, [
  # Notifications for new assessments
  :new,
  # Notifications for autograded assessments
  :autograded,
  # Notifications for manually graded assessments
  :graded,
  # Notifications for unsubmitted submissions
  :unsubmitted,
  # Notifications for submitted assessments
  :submitted
])
