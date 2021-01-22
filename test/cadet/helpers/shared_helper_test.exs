defmodule Cadet.SharedHelperTest do
  use ExUnit.Case

  import Cadet.SharedHelper

  describe "snake_casify_string_keys_recursive" do
    test "works correctly for one-level map" do
      assert snake_casify_string_keys_recursive(%{"helloWorld" => 1, "byeWorld" => 2}) == %{
               "hello_world" => 1,
               "bye_world" => 2
             }
    end

    test "works correctly for two-level map" do
      assert snake_casify_string_keys_recursive(%{
               "helloWorld" => 1,
               "byeWorld" => 2,
               "test" => %{"helloWorld" => 1, "byeWorld" => 2}
             }) == %{
               "hello_world" => 1,
               "bye_world" => 2,
               "test" => %{
                 "hello_world" => 1,
                 "bye_world" => 2
               }
             }
    end

    test "works correctly for maps in list" do
      map = %{"helloWorld" => 1, "byeWorld" => 2}
      pmap = %{"hello_world" => 1, "bye_world" => 2}

      assert snake_casify_string_keys_recursive([map, map]) == [pmap, pmap]
    end

    test "works correctly for maps in list in map" do
      map = %{"helloWorld" => 1, "byeWorld" => 2}
      pmap = %{"hello_world" => 1, "bye_world" => 2}

      assert snake_casify_string_keys_recursive(%{"valuesTest" => [map, map]}) == %{
               "values_test" => [pmap, pmap]
             }
    end
  end
end
