defmodule Try do
  def try_rescue do
    try do
      if true do
        throw("good")
      else
        raise "oops"
      end
    rescue
      e in RuntimeError ->
        _ = 11
        e
    catch
      val ->
        _ = 12
        val
    end
  end

  def try_else do
    x = 2

    try do
      1 / x
    rescue
      ArithmeticError ->
        _ = 1
        :infinity
    else
      y when y < 1 and y > -1 ->
        _ = 2
        :small

      _ ->
        _ = 3
        :large
    end
  end

  def try_after do
    {:ok, file} = File.open("sample", [:utf8, :write])

    try do
      IO.write(file, "olá")
      raise "oops, something went wrong"
    after
      File.close(file)
    end
  end

  def body_after do
    raise '12'
    1
  after
    -1
  end
end
