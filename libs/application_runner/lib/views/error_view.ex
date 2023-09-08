defmodule ApplicationRunner.ErrorView do
  @dialyzer {:nowarn_function, render_template: 2}

  use LenraCommonWeb.ErrorView
end
