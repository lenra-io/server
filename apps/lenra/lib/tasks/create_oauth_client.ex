defmodule Mix.Tasks.CreateOauth2Client do
  @shortdoc "Create the Hydra OAuth clients (backoffice or apps client)"

  @moduledoc "Create the OAuth clients.

  mix create_oauth2_client backoffice # Create the backoffice OAuth client
  mix create_oauth2_client apps # Create the \"apps client\" OAuth client
  "
  use Mix.Task

  @usage_msg """
  Use : mix create_oauth2_client <backoffice|apps|custom>
  Override values (or specify for custom) :
  --name <client_name>
  --scope <scope>
  --redirect-uri <redirect>
  --allowed-origin <origin>

  Example :
  mix create_oauth2_client custom \
    --name "My Custom Client" \
    --scope foo --scope bar \
    --redirect-uri http://example.com/redirect.html \
    --redirect-uri com.example.app:/oauth2redirect \
    --allowed-origin http://example.com \
    --allowed-origin http://auth.example.com


  """
  @show_fields [
    "client_id",
    "redirect_uris",
    "client_name",
    "allowed_cors_origins",
    "scope",
    "metadata"
  ]

  @backoffice_name "Lenra Backoffice"
  @backoffice_scopes ["profile", "store", "manage:account", "manage:apps"]
  @backoffice_url_dev "http://localhost:10000"
  @backoffice_url_prod "https://dev.lenra.io"

  @app_name "Lenra Client"
  @app_scopes ["profile", "store", "resources", "manage:account"]
  @app_url_dev "http://localhost:10000"
  @app_url_prod "https://app.lenra.io"

  @default_params %{
    token_endpoint_auth_method: "none",
    skip_consent: false
  }

  @args [
    name: :string,
    scope: :keep,
    allowed_origin: :keep,
    redirect_uri: :keep
  ]

  @impl true
  def run(args) do
    Application.ensure_all_started(:hackney)
    {opts, path} = OptionParser.parse!(args, strict: @args)

    case path do
      [] ->
        IO.puts(:stderr, "No arguments Error. #{@usage_msg}")

      [app_name] ->
        create_client(opts, app_name)

      _invalid ->
        IO.puts(:stderr, "Too many arguments Error. #{@usage_msg}")
    end
  end

  defp create_client(opts, app_name) do
    params = parse_opts(opts, app_name)

    @default_params
    |> Map.merge(params)
    |> HydraApi.create_hydra_client()
    |> handle_response(app_name)
  end

  defp parse_opts(opts, "backoffice") do
    prod? = Mix.env() == :prod

    name = Keyword.get(opts, :name, @backoffice_name)
    scopes = get_all_values(opts, :scope, @backoffice_scopes)
    redirect_uris = get_all_values(opts, :redirect_uri, backoffice_redirect_uris(prod?))
    allowed_origins = get_all_values(opts, :allowed_origin, backoffice_allowed_origins(prod?))

    %{
      client_name: name,
      scope: scopes |> Enum.join(" "),
      redirect_uris: redirect_uris,
      allowed_cors_origins: allowed_origins
    }
  end

  defp parse_opts(opts, "apps") do
    prod? = Mix.env() == :prod

    name = Keyword.get(opts, :name, @app_name)
    scopes = get_all_values(opts, :scope, @app_scopes)
    redirect_uris = get_all_values(opts, :redirect_uri, app_redirect_uris(prod?))
    allowed_origins = get_all_values(opts, :allowed_origin, app_allowed_origins(prod?))

    %{
      client_name: name,
      scope: scopes |> Enum.join(" "),
      redirect_uris: redirect_uris,
      allowed_cors_origins: allowed_origins
    }
  end

  defp parse_opts(opts, "custom") do
    name = Keyword.fetch!(opts, :name)
    scopes = Keyword.get_values(opts, :scope)
    redirect_uris = Keyword.get_values(opts, :redirect_uri)
    allowed_origins = Keyword.get_values(opts, :allowed_origin)

    %{
      client_name: name,
      scope: scopes |> Enum.join(" "),
      redirect_uris: redirect_uris,
      allowed_cors_origins: allowed_origins
    }
  end

  defp parse_opts(_opts, unknown) do
    raise "unknown parameter #{unknown}. #{@usage_msg}"
  end

  defp get_all_values(keyword, key, default) do
    values = Keyword.get_values(keyword, key)

    if Enum.empty?(values) do
      default
    else
      values
    end
  end

  defp handle_response({:ok, response}, app_name) do
    IO.puts("Oauth client #{app_name} :")

    response.body
    |> Map.take(@show_fields)
    |> inspect(pretty: true)
    |> IO.puts()
  end

  defp handle_response({:error, reason}, app_name) do
    IO.puts("Unable to create the backoffice client for #{app_name}. Reason : #{inspect(reason)}")
  end

  defp backoffice_redirect_uris(prod?) do
    ["#{backoffice_url(prod?)}/redirect.html"]
  end

  defp app_redirect_uris(prod?) do
    ["#{app_url(prod?)}/redirect.html", "io.lenra.app:/oauth2redirect"]
  end

  defp backoffice_allowed_origins(prod?) do
    [backoffice_url(prod?)]
  end

  defp app_allowed_origins(prod?) do
    [app_url(prod?)]
  end

  defp backoffice_url(prod?) do
    if prod? do
      @backoffice_url_prod
    else
      @backoffice_url_dev
    end
  end

  defp app_url(prod?) do
    if prod? do
      @app_url_prod
    else
      @app_url_dev
    end
  end
end
