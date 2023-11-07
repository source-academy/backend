defmodule Cadet.Assessments.QuestionTest do
  alias Cadet.Assessments.Question

  use Cadet.ChangesetCase, entity: Question

  @required_fields ~w(question type assessment_id)a
  @required_embeds ~w(library)a

  setup do
    assessment = insert(:assessment)

    valid_programming_params = %{
      type: :programming,
      assessment_id: assessment.id,
      library: build(:library),
      question: %{
        content: Faker.Pokemon.name(),
        prepend: "",
        template: Faker.Lorem.Shakespeare.as_you_like_it(),
        postpend: "",
        solution: Faker.Lorem.Shakespeare.hamlet()
      }
    }

    valid_mcq_params = %{
      type: :mcq,
      assessment_id: assessment.id,
      library: build(:library),
      question: %{
        content: Faker.Pokemon.name(),
        choices: Enum.map(0..2, &build(:mcq_choice, %{choice_id: &1, is_correct: &1 == 0}))
      }
    }

    valid_voting_params = %{
      type: :voting,
      assessment_id: assessment.id,
      library: build(:library),
      question: %{
        content: Faker.Pokemon.name(),
        contest_number: assessment.number,
        reveal_hours: 48,
        token_divider: 50
      }
    }

    %{
      assessment: assessment,
      valid_mcq_params: valid_mcq_params,
      valid_programming_params: valid_programming_params,
      valid_voting_params: valid_voting_params
    }
  end

  describe "valid changesets" do
    test "valid mcq question", %{valid_mcq_params: params} do
      assert_changeset_db(params, :valid)
    end

    test "valid programming question", %{valid_programming_params: params} do
      assert_changeset_db(params, :valid)
    end

    test "valid voting question", %{valid_voting_params: params} do
      assert_changeset_db(params, :valid)
    end

    test "cast model param in valid changeset to id", %{
      assessment: assessment,
      valid_mcq_params: params
    } do
      params
      |> Map.delete(:assessment_id)
      |> Map.put(:assessment, assessment)
      |> assert_changeset_db(:valid)
    end
  end

  describe "invalid changesets" do
    test "missing params", %{
      valid_mcq_params: mcq_params,
      valid_programming_params: programming_params,
      valid_voting_params: voting_params
    } do
      for params <- [mcq_params, programming_params, voting_params],
          field <- @required_fields ++ @required_embeds do
        params
        |> Map.delete(field)
        |> assert_changeset(:invalid)
      end
    end

    test "invalid question content", %{
      valid_mcq_params: mcq_params,
      valid_programming_params: programming_params,
      valid_voting_params: voting_params
    } do
      mcq_params
      |> Map.put(:type, :programming)
      |> assert_changeset(:invalid)

      programming_params
      |> Map.put(:type, :mcq)
      |> assert_changeset(:invalid)

      voting_params
      |> Map.put(:type, :programming)
      |> assert_changeset(:invalid)
    end

    test "foreign key constraints", %{
      assessment: assessment,
      valid_mcq_params: params
    } do
      {:ok, _} = Repo.delete(assessment)

      assert_changeset_db(params, :invalid)
    end
  end
end
