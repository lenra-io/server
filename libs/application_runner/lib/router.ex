defmodule ApplicationRunner.Router do
  defmacro app_routes do
    quote do
      alias ApplicationRunner.Guardian.EnsureAuthenticatedAppPipeline

      pipeline :ensure_auth_app do
        plug(EnsureAuthenticatedAppPipeline)
      end

      scope "/app-api/v1", ApplicationRunner do
        pipe_through([:api, :ensure_auth_app])

        ### Data
        # CRUD
        delete("/data/colls/:coll", CollsController, :delete)
        get("/data/colls/:coll/docs", DocsController, :get_all)
        post("/data/colls/:coll/docs", DocsController, :create)
        get("/data/colls/:coll/docs/:docId", DocsController, :get)
        put("/data/colls/:coll/docs/:docId", DocsController, :update)
        delete("/data/colls/:coll/docs/:docId", DocsController, :delete)
        # Mongo functions
        post("/data/colls/:coll/docs/find", DocsController, :find)
        post("/data/colls/:coll/updateMany", DocsController, :update_many)
        # Transactions
        post("/data/transaction", DocsController, :transaction)
        post("/data/transaction/commit", DocsController, :commit_transaction)
        post("/data/transaction/abort", DocsController, :abort_transaction)


        resources("/crons", CronController,
          only: [:create, :index, :update, :delete],
          param: "name"
        )

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
