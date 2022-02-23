defmodule NestedModules do
  defmodule ModuleA do
    def name do
      :module_a
    end
  end

  defmodule ModuleB do
    def name do
      :module_b
    end
  end

  def name do
    :module
  end
end
