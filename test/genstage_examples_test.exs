defmodule GenstageExamplesTest do
  use ExUnit.Case
  doctest GenstageExamples

  test "greets the world" do
    assert GenstageExamples.hello() == :world
  end
end
