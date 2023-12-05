defmodule ApplicationRunner.DocsController do
  use ApplicationRunner, :controller

  alias ApplicationRunner.Environment.MongoInstance
  alias ApplicationRunner.Environment.TokenAgent
  alias LenraCommon.Errors.DevError
  alias ApplicationRunner.{Guardian.AppGuardian, MongoStorage}
  alias QueryParser.Parser

  require Logger

  def action(conn, _) do
    with resources <- get_resource!(conn) do
      mongo_user_id = get_mongo_user_id(resources)
      args = [conn, conn.path_params, conn.body_params, resources, %{"me" => mongo_user_id}]

      Logger.debug(
        "#{__MODULE__} handle #{inspect(conn.method)} on #{inspect(conn.request_path)} with path_params #{inspect(conn.path_params)} and body_params #{inspect(conn.body_params)}"
      )

      apply(__MODULE__, action_name(conn), args)
    end
  end

  defp get_mongo_user_id(%{mongo_user_link: mongo_user_link}) do
    mongo_user_link.mongo_user_id
  end

  defp get_mongo_user_id(_res) do
    nil
  end

  defp get_resource!(conn) do
    case AppGuardian.Plug.current_resource(conn) do
      nil -> raise DevError.exception(message: "There is no resource loaded from token.")
      res -> res
    end
  end

  def get(
        conn,
        %{"coll" => coll, "docId" => doc_id},
        _body_params,
        %{environment: env},
        _replace_params
      ) do
    with {:ok, doc} <-
           MongoInstance.run_mongo_task(
             env.id,
             MongoStorage,
             :fetch_doc,
             [env.id, coll, doc_id]
           ) do
      Logger.debug(
        "#{__MODULE__} respond to #{inspect(conn.method)} on #{inspect(conn.request_path)} with res #{inspect(doc)}"
      )

      reply(conn, doc)
    end
  end

  def get_all(conn, %{"coll" => coll}, _body_params, %{environment: env}, _replace_params) do
    with {:ok, docs} <-
           MongoInstance.run_mongo_task(env.id, MongoStorage, :fetch_all_docs, [env.id, coll]) do
      Logger.debug(
        "#{__MODULE__} respond to #{inspect(conn.method)} on #{inspect(conn.request_path)} with res #{inspect(docs)}"
      )

      reply(conn, docs)
    end
  end

  def create(conn, %{"coll" => coll}, docs, %{environment: env, transaction_id: transaction_id}, replace_params)
      when is_list(docs) do
    with filtered_docs <- IO.inspect(Enum.map(docs, fn doc -> Map.delete(doc, "_id") end)),
         {:ok, docs_res} <-
           MongoInstance.run_mongo_task(env.id, MongoStorage, :create_docs, [
             env.id,
             coll,
             Parser.replace_params(filtered_docs, replace_params),
             transaction_id
           ]) do
      Logger.debug(
        "#{__MODULE__} respond to #{inspect(conn.method)} on #{inspect(conn.request_path)} with res #{inspect(docs_res)}"
      )

      reply(conn, docs_res)
    end
  end

  def create(conn, %{"coll" => coll}, docs, %{environment: env}, replace_params)
      when is_list(docs) do
    with filtered_docs <- IO.inspect(Enum.map(docs, fn doc -> Map.delete(doc, "_id") end)),
         {:ok, docs_res} <-
           MongoInstance.run_mongo_task(env.id, MongoStorage, :create_docs, [
             env.id,
             coll,
             Parser.replace_params(filtered_docs, replace_params)
           ]) do
      Logger.debug(
        "#{__MODULE__} respond to #{inspect(conn.method)} on #{inspect(conn.request_path)} with res #{inspect(docs_res)}"
      )

      reply(conn, docs_res)
    end
  end

  def create(
        conn,
        %{"coll" => coll},
        doc,
        %{environment: env, transaction_id: transaction_id},
        replace_params
      ) do
    with filtered_doc <- Map.delete(doc, "_id"),
         {:ok, docs} <-
           MongoInstance.run_mongo_task(env.id, MongoStorage, :create_doc, [
             env.id,
             coll,
             Parser.replace_params(filtered_doc, replace_params),
             transaction_id
           ]) do
      Logger.debug(
        "#{__MODULE__} respond to #{inspect(conn.method)} on #{inspect(conn.request_path)} with res #{inspect(docs)}"
      )

      reply(conn, docs)
    end
  end

  def create(conn, %{"coll" => coll}, doc, %{environment: env}, replace_params) do
    with filtered_doc <- Map.delete(doc, "_id"),
         {:ok, docs} <-
           MongoInstance.run_mongo_task(env.id, MongoStorage, :create_doc, [
             env.id,
             coll,
             Parser.replace_params(filtered_doc, replace_params)
           ]) do
      Logger.debug(
        "#{__MODULE__} respond to #{inspect(conn.method)} on #{inspect(conn.request_path)} with res #{inspect(docs)}"
      )

      reply(conn, docs)
    end
  end

  def update(
        conn,
        %{"coll" => coll, "docId" => doc_id},
        new_doc,
        %{environment: env, transaction_id: transaction_id},
        replace_params
      ) do
    with {:ok, docs} <-
           MongoInstance.run_mongo_task(env.id, MongoStorage, :update_doc, [
             env.id,
             coll,
             doc_id,
             Parser.replace_params(new_doc, replace_params),
             transaction_id
           ]) do
      Logger.debug(
        "#{__MODULE__} respond to #{inspect(conn.method)} on #{inspect(conn.request_path)} with res #{inspect(docs)}"
      )

      reply(conn, docs)
    end
  end

  def update(
        conn,
        %{"docId" => doc_id, "coll" => coll},
        new_doc,
        %{environment: env},
        replace_params
      ) do
    with {:ok, docs} <-
           MongoInstance.run_mongo_task(env.id, MongoStorage, :update_doc, [
             env.id,
             coll,
             doc_id,
             Parser.replace_params(new_doc, replace_params)
           ]) do
      Logger.debug(
        "#{__MODULE__} respond to #{inspect(conn.method)} on #{inspect(conn.request_path)} with res #{inspect(docs)}"
      )

      reply(conn, docs)
    end
  end

  def delete(
        conn,
        %{"coll" => coll, "docId" => doc_id},
        _body_params,
        %{environment: env, transaction_id: transaction_id},
        _replace_params
      ) do
    with :ok <-
           MongoInstance.run_mongo_task(env.id, MongoStorage, :delete_doc, [
             env.id,
             coll,
             doc_id,
             transaction_id
           ]) do
      Logger.debug("#{__MODULE__} respond to #{inspect(conn.method)} on #{inspect(conn.request_path)} with status :ok")

      reply(conn)
    end
  end

  def delete(
        conn,
        %{"docId" => doc_id, "coll" => coll},
        _body_params,
        %{environment: env},
        _replace_params
      ) do
    with :ok <-
           MongoInstance.run_mongo_task(env.id, MongoStorage, :delete_doc, [env.id, coll, doc_id]) do
      Logger.debug("#{__MODULE__} respond to #{inspect(conn.method)} on #{inspect(conn.request_path)} with status :ok")

      reply(conn)
    end
  end

  def find(
        conn,
        %{"coll" => coll},
        %{
          "query" => query,
          "projection" => projection
        },
        %{environment: env},
        replace_params
      ) do
    with {:ok, docs} <-
           MongoInstance.run_mongo_task(env.id, MongoStorage, :filter_docs, [
             env.id,
             coll,
             Parser.replace_params(query, replace_params),
             [projection: projection]
           ]) do
      Logger.debug(
        "#{__MODULE__} respond to #{inspect(conn.method)} on #{inspect(conn.request_path)} with res #{inspect(docs)}"
      )

      reply(conn, docs)
    end
  end

  def find(conn, %{"coll" => coll}, filter, %{environment: env}, replace_params) do
    Logger.warning(
      "This form of query is deprecated, prefer using: {query: <your query>, projection: {projection}}, more info at: https://www.mongodb.com/docs/manual/reference/method/db.collection.find/#mongodb-method-db.collection.find"
    )

    with {:ok, docs} <-
           MongoInstance.run_mongo_task(env.id, MongoStorage, :filter_docs, [
             env.id,
             coll,
             Parser.replace_params(filter, replace_params)
           ]) do
      Logger.debug(
        "#{__MODULE__} respond to #{inspect(conn.method)} on #{inspect(conn.request_path)} with res #{inspect(docs)}"
      )

      reply(conn, docs)
    end
  end

  def update_many(
        conn,
        %{"coll" => coll},
        %{"filter" => filter, "update" => update} = body_params,
        %{environment: env},
        replace_params
      ) do
    opts = Map.get(body_params, :opts, [])

    with {:ok, res} <-
           MongoInstance.run_mongo_task(env.id, MongoStorage, :update_many, [
             env.id,
             coll,
             Parser.replace_params(filter, replace_params),
             update,
             opts
           ]) do
      reply(conn, res)
    end
  end

  ###############
  # Transaction #
  ###############
  def transaction(conn, _params, _body_params, %{environment: env, user: user}, _replace_params) do
    with {:ok, transaction_id} <-
           MongoInstance.run_mongo_task(env.id, MongoStorage, :start_transaction, [env.id]) do
      uuid = Ecto.UUID.generate()

      {:ok, token, _claims} =
        AppGuardian.encode_and_sign(uuid, %{
          type: "session",
          env_id: env.id,
          user: user.id,
          transaction_id: transaction_id
        })

      TokenAgent.add_token(env.id, uuid, token)

      reply(conn, token)
    end
  end

  def transaction(conn, _params, _body_params, %{environment: env}, _replace_params) do
    with {:ok, transaction_id} <-
           MongoInstance.run_mongo_task(env.id, MongoStorage, :start_transaction, [env.id]) do
      uuid = Ecto.UUID.generate()

      {:ok, token, _claims} =
        AppGuardian.encode_and_sign(uuid, %{
          type: "env",
          env_id: env.id,
          transaction_id: transaction_id
        })

      TokenAgent.add_token(env.id, uuid, token)

      reply(conn, token)
    end
  end

  def commit_transaction(
        conn,
        _params,
        _body_params,
        %{environment: env, transaction_id: transaction_id},
        _replace_params
      ) do
    with :ok <-
           MongoInstance.run_mongo_task(env.id, MongoStorage, :commit_transaction, [
             transaction_id,
             env.id
           ]) do
      Logger.debug("#{__MODULE__} respond to #{inspect(conn.method)} on #{inspect(conn.request_path)} with status :ok")

      reply(conn)
    end
  end

  def abort_transaction(
        conn,
        _params,
        _body_params,
        %{environment: env, transaction_id: transaction_id},
        _replace_params
      ) do
    with :ok <-
           MongoInstance.run_mongo_task(env.id, MongoStorage, :revert_transaction, [
             transaction_id,
             env.id
           ]) do
      Logger.debug("#{__MODULE__} respond to #{inspect(conn.method)} on #{inspect(conn.request_path)} with status :ok")

      reply(conn)
    end
  end
end
