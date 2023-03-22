defmodule Gradient.ConfigCommentsTest do
  use ExUnit.Case

  alias Gradient.ConfigComments
  import ExUnit.CaptureIO

  describe "ignores_for_file/1" do
    test "finds magic comments for entire file" do
      assert ["test/examples/config_comments/whole_file.ex"] =
               ConfigComments.ignores_for_file("test/examples/config_comments/whole_file.ex")
    end

    test "finds magic comments for entire file with specific warning" do
      assert [{"test/examples/config_comments/whole_file_warning.ex", :call_undef}] =
               ConfigComments.ignores_for_file(
                 "test/examples/config_comments/whole_file_warning.ex"
               )
    end

    test "finds magic comments for entire file with specific warning and detail" do
      assert [
               {"test/examples/config_comments/whole_file_warning_detail.ex",
                {:spec_error, :no_spec}}
             ] =
               ConfigComments.ignores_for_file(
                 "test/examples/config_comments/whole_file_warning_detail.ex"
               )
    end

    test "finds magic comments for next/previous lines" do
      assert [
               # gradient:disable-for-next-line
               "test/examples/config_comments/next_and_previous_lines.ex:4",
               {"test/examples/config_comments/next_and_previous_lines.ex:8", :call_undef},
               {"test/examples/config_comments/next_and_previous_lines.ex:12",
                {:spec_error, :no_spec}},
               # gradient:disable-for-previous-line
               "test/examples/config_comments/next_and_previous_lines.ex:15",
               {"test/examples/config_comments/next_and_previous_lines.ex:19", :call_undef},
               {"test/examples/config_comments/next_and_previous_lines.ex:23",
                {:spec_error, :no_spec}}
             ] =
               ConfigComments.ignores_for_file(
                 "test/examples/config_comments/next_and_previous_lines.ex"
               )
    end
  end

  describe "Gradient.type_check_file takes into account magic comments" do
    test "magic comments for next/previous lines" do
      filename = "test/examples/config_comments/next_and_previous_lines_errors.ex"
      charlist_filename = to_charlist(filename)

      capture_io(fn ->
        assert [
                 {:error,
                  [
                    # Just one error, rest are suppressed with comments
                    {^charlist_filename, {:type_error, _, _, _}}
                  ]}
               ] = Gradient.type_check_file(filename)
      end)
    end

    test "magic comment for whole file" do
      capture_io(fn ->
        assert [:ok] = Gradient.type_check_file("test/examples/config_comments/whole_file.ex")
      end)
    end

    test "magic comment for whole file, specific warning" do
      filename = "test/examples/config_comments/whole_file_warning_error.ex"
      charlist_filename = to_charlist(filename)

      capture_io(fn ->
        assert [
                 {:error,
                  [
                    # Just one error, the other is suppressed with a comment
                    {^charlist_filename, {:undef, _, _, _}}
                  ]}
               ] = Gradient.type_check_file(filename)
      end)
    end
  end
end
