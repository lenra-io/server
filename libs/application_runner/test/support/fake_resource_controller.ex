defmodule ApplicationRunner.FakeResourceController do
  use ApplicationRunner.ResourcesController, adapter: ApplicationRunner.FakeAppAdapter
end
