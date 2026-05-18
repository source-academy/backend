defmodule CadetWeb.AssessmentsView do
  use CadetWeb, :view
  use Timex

  import CadetWeb.AssessmentsHelpers

  def render("index.json", %{assessments: assessments}) do
    render_many(assessments, CadetWeb.AssessmentsView, "overview.json", as: :assessment)
  end

  def render("overview.json", %{assessment: assessment}) do
    base_map = %{
      id: :id,
      courseId: :course_id,
      title: :title,
      shortSummary: :summary_short,
      openAt: &format_datetime(&1.open_at),
      closeAt: &format_datetime(&1.close_at),
      type: & &1.config.type,
      isManuallyGraded: & &1.config.is_manually_graded,
      story: :story,
      number: :number,
      reading: :reading,
      status: &(&1.user_status || "not_attempted"),
      maxXp: :max_xp,
      xp: &(&1.xp || 0),
      coverImage: :cover_picture,
      private: &password_protected?(&1.password),
      isPublished: :is_published,
      questionCount: :question_count,
      gradedCount: &(&1.graded_count || 0),
      isGradingPublished: :is_grading_published,
      earlySubmissionXp: & &1.config.early_submission_xp,
      maxTeamSize: :max_team_size,
      hasVotingFeatures: :has_voting_features,
      hasTokenCounter: :has_token_counter,
      isVotingPublished: :is_voting_published,
      hoursBeforeEarlyXpDecay: & &1.config.hours_before_early_xp_decay,
      isAutosaveEnabled: :is_autosave_enabled,
      isLlmGraded: &(&1.has_llm_questions || &1.llm_assessment_prompt not in [nil, ""])
    }

    # Only include LLM cost fields if the assessment is LLM graded
    is_llm_graded =
      assessment.has_llm_questions || assessment.llm_assessment_prompt not in [nil, ""]

    final_map =
      if is_llm_graded do
        Map.merge(base_map, %{
          llmInputCost: :llm_input_cost,
          llmOutputCost: :llm_output_cost,
          llmTotalInputTokens: :llm_total_input_tokens,
          llmTotalOutputTokens: :llm_total_output_tokens,
          llmTotalCachedTokens: :llm_total_cached_tokens,
          llmTotalCost: :llm_total_cost
        })
      else
        base_map
      end

    transform_map_for_view(assessment, final_map)
  end

  def render("show.json", %{assessment: assessment}) do
    transform_map_for_view(
      assessment,
      %{
        id: :id,
        courseId: :course_id,
        title: :title,
        type: & &1.config.type,
        story: :story,
        number: :number,
        reading: :reading,
        longSummary: :summary_long,
        hasTokenCounter: :has_token_counter,
        missionPDF: &Cadet.Assessments.Upload.url({&1.mission_pdf, &1}),
        isMinigame: & &1.config.is_minigame,
        isAutosaveEnabled: :is_autosave_enabled,
        questions:
          &Enum.map(&1.questions, fn question ->
            map =
              build_question_with_answer_and_solution_if_ungraded(%{
                question: question
              })

            map
          end)
      }
    )
  end

  def render("leaderboard.json", %{leaderboard: leaderboard}) do
    render_many(leaderboard, CadetWeb.AdminAssessmentsView, "contestEntry.json",
      as: :contestEntry
    )
  end

  def render("contestEntry.json", %{contestEntry: contestEntry}) do
    transform_map_for_view(
      contestEntry,
      %{
        student_name: :student_name,
        answer: & &1.answer["code"],
        final_score: "final_score",
        rank: :rank
      }
    )
  end

  defp password_protected?(nil), do: false

  defp password_protected?(_), do: true
end
