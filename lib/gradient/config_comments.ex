defmodule Gradient.ConfigComments do
  @moduledoc """
  Handles parsing text files and looking for magic comments that disable
  warnings for particular lines.

  The following comments are supported:

      gradient:disable-file [warning]
      gradient:disable-next-line [warning]
      gradient:disable-previous-line [warning]

  If [warning] is specified in the above patterns, only that particular warning
  will be disabled. Otherwise, all warnings will be disabled.

  Note that [warning] in the examples above may contain a second part for a warning
  detail. For example:

      gradient:disable-file spec_error no_spec

  is a valid config comment.
  """

  @instruction_prefix "# gradient:"
  @instruction_prefix_length String.length(@instruction_prefix)

  @instruction_disable_file "disable-file"
  @instruction_disable_next_line "disable-next-line"
  @instruction_disable_previous_line "disable-previous-line"

  @enable_extensions [".ex", ".exs"]

  @doc """
  Reads through the given file and parses magic warning-disabling comments into
  a list of ignores, usable by Gradient.Error.reject_ignored_errors/2.
  """
  @spec ignores_for_file(binary()) :: [tuple()]
  def ignores_for_file(path) do
    ext = Path.extname(path)

    path =
      if ext == ".beam" do
        get_source_file_from_beam(path)
      else
        path
      end

    if Path.extname(path) in @enable_extensions do
      read_file_and_parse_magic_comments(path)
    else
      []
    end
  end

  defp get_source_file_from_beam(beam_path) do
    beam_path = to_charlist(beam_path)

    case :beam_lib.chunks(beam_path, [:debug_info]) do
      {:ok,
       {_,
        [{:debug_info, {:debug_info_v1, :elixir_erl, {:elixir_v1, %{file: source_file_path}, _}}}]}} ->
        # source_file_path is absolute path -- need to call relative_to_cwd to
        # get relative path consistent with other ignore options
        source_file_path |> Path.relative_to_cwd()

      _ ->
        # Can't find original source file, just return beam path
        beam_path
    end
  end

  defp read_file_and_parse_magic_comments(path) do
    path
    # use stream to avoid reading entire file into memory up front
    |> File.stream!()
    # add 1-based line numbers
    |> Stream.with_index(1)
    # remove whitespace
    |> Stream.map(fn {line, line_number} -> {String.trim(line), line_number} end)
    # filter out everything but single-line comments
    |> Stream.filter(fn {line, _line_number} -> String.starts_with?(line, @instruction_prefix) end)
    # parse out magic comments
    |> Stream.map(&parse_magic_comment(&1, path))
    # filter out nil/false values returned by parse
    |> Stream.filter(& &1)
    |> Enum.to_list()
  end

  defp parse_magic_comment({line, line_number}, path) do
    # chop off prefix
    comment = String.slice(line, @instruction_prefix_length..-1)

    with file_line when not is_nil(file_line) <-
           get_file_and_maybe_line(comment, path, line_number) do
      maybe_add_specific_warning(file_line, comment)
    end
  end

  defp get_file_and_maybe_line(@instruction_disable_file <> _rest, path, _line_number), do: path

  defp get_file_and_maybe_line(@instruction_disable_next_line <> _rest, path, line_number),
    do: "#{path}:#{line_number + 1}"

  defp get_file_and_maybe_line(@instruction_disable_previous_line <> _rest, path, line_number),
    do: "#{path}:#{line_number - 1}"

  # Invalid magic comment
  defp get_file_and_maybe_line(_, _, _), do: nil

  defp maybe_add_specific_warning(file_line, comment) do
    case String.split(comment) do
      [_comment] ->
        file_line

      [_comment, warning] ->
        {file_line, String.to_atom(warning)}

      [_comment, warning_meta, warning_detail] ->
        {file_line, {String.to_atom(warning_meta), String.to_atom(warning_detail)}}
    end
  end
end
