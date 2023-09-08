defmodule ApplicationRunner.Router do
  defmacro app_routes do
    quote do
      alias ApplicationRunner.Guardian.EnsureAuthenticatedAppPipeline

      pipeline :ensure_auth_app do
        plug(EnsureAuthenticatedAppPipeline)
      end

      scope "/app", ApplicationRunner do
        pipe_through([:api, :ensure_auth_app])

        delete("/colls/:coll", CollsController, :delete)
        get("/colls/:coll/docs", DocsController, :get_all)
        post("/colls/:coll/docs", DocsController, :create)
        get("/colls/:coll/docs/:docId", DocsController, :get)
        put("/colls/:coll/docs/:docId", DocsController, :update)
        delete("/colls/:coll/docs/:docId", DocsController, :delete)
        post("/colls/:coll/docs/find", DocsController, :find)
        post("/colls/:coll/updateMany", DocsController, :update_many)

        resources("/crons", CronController,
          only: [:create, :index, :update, :delete],
          param: "name"
        )

        post("/transaction", DocsController, :transaction)
        post("/transaction/commit", DocsController, :commit_transaction)

        post("/transaction/abort", DocsController, :abort_transaction)

        post("/webhooks", Webhooks.WebhooksController, :create)
      end
    end
  end

  defmacro resource_route(resource_controller) do
    quote do
      get(
        "/apps/:app_name/resources/*resource",
        unquote(resource_controller),
        :get_app_resource
      )
    end
  end
end
