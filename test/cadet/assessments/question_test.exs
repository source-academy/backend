defmodule Cadet.Assessments.QuestionTest do
  use Cadet.DataCase

  alias Cadet.Assessments.Question

  @required_fields ~w(title question type assessment_id)a
  @required_embeds ~w(library)a

  setup do
    assessment = insert(:assessment)

    valid_programming_params = %{
      title: "programming_question",
      type: :programming,
      assessment_id: assessment.id,
      library: build(:library),
      question: %{
        content: Faker.Pokemon.name(),
        solution_header: Faker.Pokemon.location(),
        solution_template: Faker.Lorem.Shakespeare.as_you_like_it(),
        solution: Faker.Lorem.Shakespeare.hamlet()
      }
    }

    valid_mcq_params = %{
      title: "mcq_question",
      type: :mcq,
      assessment_id: assessment.id,
      library: build(:library),
      question: %{
        content: Faker.Pokemon.name(),
        choices: Enum.map(0..2, &build(:mcq_choice, %{choice_id: &1, is_correct: &1 == 0}))
      }
    }

    %{
      assessment: assessment,
      valid_mcq_params: valid_mcq_params,
      valid_programming_params: valid_programming_params
    }
  end

  describe "valid changesets" do
    test "valid mcq question", %{valid_mcq_params: params} do
      res =
        %Question{}
        |> Question.changeset(params)
        |> Repo.insert()

      assert({:ok, _} = res, inspect(res, pretty: true))
    end

    test "valid programming question", %{valid_programming_params: params} do
      res =
        %Question{}
        |> Question.changeset(params)
        |> Repo.insert()

      assert({:ok, _} = res, inspect(res, pretty: true))
    end

    test "cast model param in valid changeset to id", %{
      assessment: assessment,
      valid_mcq_params: params
    } do
      params =
        params
        |> Map.delete(:assessment_id)
        |> Map.put(:assessment, assessment)

      res =
        %Question{}
        |> Question.changeset(params)
        |> Repo.insert()

      assert({:ok, _} = res, inspect(res, pretty: true))
    end
  end

  describe "invalid changesets" do
    test "missing params", %{
      valid_mcq_params: mcq_params,
      valid_programming_params: programming_params
    } do
      Enum.each([mcq_params, programming_params], fn params ->
        Enum.each(@required_fields ++ @required_embeds, fn field ->
          params_missing_field = Map.delete(params, field)

          refute(
            Question.changeset(%Question{}, params_missing_field).valid?,
            inspect(params_missing_field, pretty: true)
          )
        end)
      end)
    end

    test "invalid question content", %{
      valid_mcq_params: mcq_params,
      valid_programming_params: programming_params
    } do
      mcq_params = Map.put(mcq_params, :type, :programming)

      refute(
        Question.changeset(%Question{}, mcq_params).valid?,
        inspect(mcq_params, pretty: true)
      )

      programming_params = Map.put(programming_params, :type, :mcq)

      refute(
        Question.changeset(%Question{}, programming_params).valid?,
        inspect(programming_params, pretty: true)
      )
    end

    test "foreign key constraints", %{
      assessment: assessment,
      valid_mcq_params: params
    } do
      {:ok, _} = Repo.delete(assessment)

      res =
        %Question{}
        |> Question.changeset(params)
        |> Repo.insert()

      assert({:error, _} = res, inspect(res, pretty: true))
    end
  end
end
