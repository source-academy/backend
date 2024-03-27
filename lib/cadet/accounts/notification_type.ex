import EctoEnum

defenum(Cadet.Accounts.NotificationType, :notification_type, [
  # Notifications for new assessments
  :new,
  # Notifications for unsubmitted submissions
  :unsubmitted,
  # Notifications for submitted assessments
  :submitted,
  # Notifications for published grades
  :published_grading,
  # Notifications for unpublished grades
  :unpublished_grading
])
