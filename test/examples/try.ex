defmodule Try do
  def try_rescue do
    try do
      if true do
        throw "good"
      else
        raise "oops"
      end
    rescue
      e in RuntimeError -> 
        11
        e
    catch
      val ->
        12
        val
    end
  end
end
