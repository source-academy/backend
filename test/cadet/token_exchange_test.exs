defmodule Cadet.TokenExchangeTest do
  use Cadet.DataCase

  alias Cadet.TokenExchange

  describe "get_by_code" do
    test "returns error when code not found" do
      result = TokenExchange.get_by_code("nonexistent_code")
      assert {:error, "Not found"} == result
    end

    test "returns error when code is expired" do
      user = insert(:user)

      TokenExchange.insert(%{
        code: "expired_code",
        generated_at: Timex.shift(Timex.now(), hours: -2),
        expires_at: Timex.shift(Timex.now(), hours: -1),
        user_id: user.id
      })

      result = TokenExchange.get_by_code("expired_code")
      assert {:error, "Expired"} == result
    end

    test "returns ok with user when code is valid and not expired" do
      user = insert(:user)
      code = "valid_code_123"

      {:ok, token} =
        TokenExchange.insert(%{
          code: code,
          generated_at: Timex.now(),
          expires_at: Timex.shift(Timex.now(), minutes: 5),
          user_id: user.id
        })

      assert {:ok, struct} = TokenExchange.get_by_code(code)
      assert struct.code == code
      assert struct.user.id == user.id
    end

    test "deletes the code after successful retrieval" do
      user = insert(:user)
      code = "code_to_delete"

      TokenExchange.insert(%{
        code: code,
        generated_at: Timex.now(),
        expires_at: Timex.shift(Timex.now(), minutes: 5),
        user_id: user.id
      })

      # First retrieval should succeed
      assert {:ok, _struct} = TokenExchange.get_by_code(code)

      # Second retrieval should fail as the code was deleted
      assert {:error, "Not found"} = TokenExchange.get_by_code(code)
    end

    test "preloads user association" do
      user = insert(:user, name: "Test User")
      code = "code_with_user"

      TokenExchange.insert(%{
        code: code,
        generated_at: Timex.now(),
        expires_at: Timex.shift(Timex.now(), minutes: 5),
        user_id: user.id
      })

      {:ok, struct} = TokenExchange.get_by_code(code)
      assert struct.user.name == "Test User"
    end
  end

  describe "delete_expired" do
    test "deletes all expired tokens" do
      user1 = insert(:user)
      user2 = insert(:user)

      # Insert expired tokens
      TokenExchange.insert(%{
        code: "expired_1",
        generated_at: Timex.shift(Timex.now(), hours: -2),
        expires_at: Timex.shift(Timex.now(), minutes: -30),
        user_id: user1.id
      })

      TokenExchange.insert(%{
        code: "expired_2",
        generated_at: Timex.shift(Timex.now(), hours: -1),
        expires_at: Timex.shift(Timex.now(), minutes: -15),
        user_id: user2.id
      })

      # Insert valid token
      TokenExchange.insert(%{
        code: "valid_token",
        generated_at: Timex.now(),
        expires_at: Timex.shift(Timex.now(), minutes: 10),
        user_id: user1.id
      })

      # Execute delete_expired
      {deleted_count, _} = TokenExchange.delete_expired()

      assert deleted_count == 2
      # Verify valid token still exists
      assert {:ok, _} = TokenExchange.get_by_code("valid_token")
    end
  end

  describe "insert" do
    test "creates a new token exchange record" do
      user = insert(:user)
      code = "test_code_insert"

      {:ok, token} =
        TokenExchange.insert(%{
          code: code,
          generated_at: Timex.now(),
          expires_at: Timex.shift(Timex.now(), minutes: 5),
          user_id: user.id
        })

      assert token.code == code
      assert token.user_id == user.id
    end

    test "fails when required fields are missing" do
      user = insert(:user)

      {:error, changeset} =
        TokenExchange.insert(%{
          code: "incomplete_code",
          user_id: user.id
        })

      refute changeset.valid?
    end
  end

  describe "changeset" do
    test "validates required fields" do
      user = insert(:user)

      changeset =
        TokenExchange.changeset(%TokenExchange{}, %{
          code: "test_code",
          generated_at: Timex.now(),
          expires_at: Timex.shift(Timex.now(), minutes: 5),
          user_id: user.id
        })

      assert changeset.valid?
    end

    test "marks changeset invalid when required fields are missing" do
      changeset =
        TokenExchange.changeset(%TokenExchange{}, %{
          code: "test_code"
        })

      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :generated_at)
      assert Keyword.has_key?(changeset.errors, :expires_at)
      assert Keyword.has_key?(changeset.errors, :user_id)
    end
  end
end