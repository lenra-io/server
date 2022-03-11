
# Lenra Server

Requirement : 
  * Start database with Docker `docker run --restart always -p 5432:5432 --name lenra-postgres -e POSTGRES_DB=lenra_dev -e POSTGRES_PASSWORD=postgres -d postgres`
  * Install erlang in version 24.2 and elixir in version 1.12.3 otp-24
  * Create the database and start migration `mix setup`. This is equivalent to running the following commands : 
    * `mix deps.get` to install the dependencies
    * `mix ecto.create` to create database
    * `mix ecto.migrate` to start all migration and have an up-to-date database
    * `mix run priv/repo/seeds.exs` to fill database with default values

Now you can start the server with this command `mix phx.server`

The server is started at `localhost:4000`

Code quality check : 
  * Code formatting with `mix format`
  * Syntax verification/Code rules `mix credo --strict`
  * security check `mix sobelow`
  * run tests `mix test`
  * test + code coverage `mix coveralls [--umbrella]`
  * test + code coverage + html report `mix coveralls.html [--umbrella]`

## Troubleshooting
  * An error occurs when you have elixir or erlang in the wrong version and you can't launch the server.
  To install the correct version of erlang and elixir you can use the package asdf to install and manage all
  the versions of the packages you want. Documentation to use asdf : https://asdf-vm.com/guide/getting-started.html

## Links

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix


## Some rules to respect the layer model 
Use 3 layers : 
 - The Controller to manage the conn object, call the service and handle errors. He’s the only one who resolves the transactions.
 - The Entity Model to manage changes on the object such as add/modify and database associations.
 - The Service to manage business logic. He’s the only one with direct access to the database.

For the naming, we use a singular name then we derive it (User, UserController, UserServices)

### The Controller 
- Entry point for the request.
- It can call several services only if their combination does not involve business logic.
- Execute the "final" transaction and handle potential errors.
- Assign data/error as required.
- Ends by "reply" to terminate the request and send the result to the client.

#### Exemple
Simplified example of a "basic" controller: : 
```elixir
defmodule LenraWeb.PostController do
  use LenraWeb, :controller

  alias Lenra.Guardian.Plug
  alias Lenra.{PostServices}
  alias Lenra.{Repo}

  def index(conn, _params) do
    posts = PostServices.all()

    conn
    |> assign_data(:posts, posts)
    |> reply
  end

  def show(conn, params) do
    post = PostServices.get(params.id)

    conn
    |> assign_data(:post, post)
    |> reply
  end

  def create(conn, params) do
    Plug.current_resource(conn)
    |> PostServices.add_post(params)
    |> Repo.transaction()
    |> case do
      {:ok, %{inserted_post: post}} -> 
        conn
        |> assign_data(:post, post)
        |> reply
      {:error, {_, reason, _}} ->
        conn
        |> assign_error(reason)
        |> reply
      end
  end

  def update(conn, params) do
    PostServices.get(params.id)
    |> PostServices.update(params)
    |> Repo.transaction()
    |> case do
      {:ok, %{updated_post: post}} -> 
        conn
        |> assign_data(:post, post)
        |> reply
      {:error, {_, reason, _}} ->
        conn
        |> assign_error(reason)
        |> reply
      end
  end
end
```
### The Entity Model
It allows the creation/update of a data structure with help functions.
- A UNIQUE changeset function allow integrity verification of entity during creation/update.
- A 'new' function that allows the creation of the structure that deals with creating possible associations (foreign key)
  - This function takes as parameters "params" and if necessary the other entities to be linked to.
  - This function itself calls the "changeset" function to validate the integrity of the parameters.
  - This function can define default values.
- An 'update' function that allow object update (and eventually these associations)
  - This function take as parameter one entity of same type, "params" and if needed the others entities to modify the association.
  - This function itself calls the "changeset" function to validate the integrity of the parameters.

#### Exemple
Simplified example of "basic" model : 
```elixir
defmodule Post do
  use Ecto.Schema
  import Ecto.Changeset
  alias Lenra.User

  schema "posts" do
    field(:title, :string)
    field(:body, :string)
    belongs_to(:user, User)
    timestamps()
  end

  def changeset(post, params \\ %{}) do
    post
    |> cast(params, [:title, :body])
    |> validate_required([:title, :body])
    |> validate_length(:title, min: 3, max: 120)
    |> validate_length(:title, min: 10)
  end

  def new(user, params) do
    Ecto.build_assoc(user, :posts) # Création de l'association avec le user dans le new
    |> changeset(params) # création de l'objet + vérif des contraintes
  end

  def update(post, params) do
    post # Ici, pas d'association à mettre à jour
    |> changeset(params) # update de l'objet + vérif des contraintes
  end
end
```

### The Service
It contains the business logic. It assumes that its entries have been verified.
There are 2 main types of basic operation, reading and writing.
- A reading does not require Ecto.Multi
- A writing is ALWAYS done with an Ecto.Multi

- We always implement the CRUD database which will be the database called by other service functions.
- This means that we never insert/delete from other services but we call these services there.
- To create an entity, use the new function of the model (ex : User.new(params)) then we insert it in the database (with Ecto.Multi).
- To combine multiple calls to Ecto.Multi services, use Ecto.Multi.merge
- If needed, create "high level" services to preload the data and combine it with multiple simple operations. 
  - Example, when validating a user with their code : 
```elixir
def validate_user(id, code) do
  user = UserService.get(id) |> Repo.preload(:registration_code) # Chargement de l'utilisateur + preload

  Ecto.Multi.new()
  |> Ecto.Multi.run(:check_valid, fn _, _ -> RegistrationCodeServices.check_valid(user.registration_code, code) end) # Check si le code est valide ou non
  |> Ecto.Multi.merge(fn _ -> RegistrationCodeServices.delete(user.registration_code) end) # Delete le code (ne sera fait que si le code est valide.)
  |> Ecto.Multi.merge(fn _ -> UserServices.update(user, %{role: User.const_user_role()}) end) # Update l'utilisateur
end
```
#### Exemple
Exemple simplifié de service "de base" : 
```elixir
defmodule Lenra.PostServices do
  alias Lenra.{Repo, Post}
  alias Lenra.{UserServices, PostServices}
  
  def get(id) do
    Repo.get(Post, id)
  end

  def get_by(clauses) do
    Repo.get_by(Post, clauses)
  end

  def all do
    Repo.all(Post)
  end

  # crée un post associé à un utilisateur
  # Opération "simple"
  def create(user, params) do
    post = Post.new(user, params)
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:inserted_post, post)
  end

  # Update un post (opération simple)
  def update(post, params) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:updated_post, Post.update(post, params))
  end

  # Crée un post et notifie l'utilisateur (service de "haut niveau")
  def add_post(user_id, params) do
    user = UserServices.get(user_id)
    Ecto.Multi.new()
    |> Ecto.Multi.merge(fn _ -> PostServices.create(user, params) end)
    |> Ecto.Multi.run(fn _, %{inserted_post: post} -> NotifWorker.send_post_notif(user, post) end)
  end
end
```