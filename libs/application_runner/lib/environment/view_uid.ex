defmodule ApplicationRunner.Environment.ViewUid do
  @moduledoc """
    This identify a unique widget for a given environment.
  """
  @enforce_keys [:name, :coll, :query_parsed, :query_transformed, :props, :context, :projection]
  defstruct [
    :name,
    :props,
    :query_parsed,
    :query_transformed,
    :context,
    :coll,
    :projection,
    prefix_path: ""
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          props: map() | nil,
          query_parsed: map() | nil,
          query_transformed: map() | nil,
          coll: String.t() | nil,
          context: map() | nil,
          prefix_path: String.t(),
          projection: map()
        }
end
