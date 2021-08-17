
# Lenra Server

Prerequis : 
  * Démarrer la base de donnée avec docker `docker run --restart always -p 5432:5432 --name lenra-postgres -e POSTGRES_DB=lenra_dev -e POSTGRES_PASSWORD=postgres -d postgres`
  * Créer la db et démarrer la migration `mix setup`. Cela équivaux à lancer les commandes suivantes : 
    * `mix deps.get` pour installer les dépendances
    * `mix ecto.create` pour créer la base de donnée
    * `mix ecto.migrate` pour démarrer toutes les migrations et avoir une base de donnée à jour
    * `mix run priv/repo/seeds.exs` pour alimenter la base de donnée avec les valeurs par défaut

Vous pouvez à présent démarrer votre serveur avec la commande `mix phx.server`

Le serveur est démarré à l'adresse `localhost:4000`

Vérification de qualité de code : 
  * formattage du code avec `mix format`
  * Vérification de syntaxe/règles de code `mix credo --strict`
  * Vérification de sécurité `mix sobelow`
  * lancer les tests `mix test`
  * Test + couverture de code `mix coveralls [--umbrella]`
  * Test + couverture de code + rapport html `mix coveralls.html [--umbrella]`

## Liens utiles

  * Site officiel: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix


## Pour respecter le modèle en couche, quelques règles 
Utiliser 3 couches : 
 - Le Controlleur pour gérer l'objet conn, appeler le service et gérer les erreurs. Il est le seul à résoudre les transactions.
 - Le Model entité pour gérer les changements sur l'objet ajouté/modifier et les associations en base de donnée.
 - Le Service pour gérer la logique métier. C'est le seul à accéder directement à la base.

Pour le nommage, on utilise un nom singulier puis on le dérive (User, UserController, UserServices)

### Le Controlleur 
- Point d'entrée pour la requête.
- Il peut appeler plusieurs services seulement si leur combinaison n'implique pas de logique métier.
- Exécute la transaction "finale" et gère les erreurs potentielles
- Assign data/error selon les besoins
- fini par "reply" pour mettre fin à la requête et renvoyer les résultat au client.

#### Exemple
Exemple simplifié d'un controlleur "de base" : 
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
### Le Model entité
Il permet la création/update d'une structure de donnée via des fonction d'aide.
- une fonction changeset UNIQUE permet de vérifier l'integrité de l'entité lors de création/update.
- une fonction new qui permet la création de la structure qui s'occupe de créer les possibles associations (clé étrangères)
  - Cette fonction prends en paramètres "params" et si besoin les autres entité auquel se lier.
  - Cette fonction appelle elle même la fonction "changeset" pour valider l'integrité des params.
  - Cette fonction peut définir des valeur par défaut.
- une fonction update qui permet la mise à jour de l'objet (et éventuellement de ses associations)
  - Cette fonction prends en paramètres une entité du même type, "params" et si besoin les autres entité pour modifier l'association.
  - Cette fonction appelle elle même la fonction "changeset" pour valider l'integrité des params.

#### Exemple
Exemple simplifié de Model "de base" : 
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

### Le Service
C'est lui qui contient la logique métier. Il part du principe que ses entrées ont été vérifiés.
Il existe 2 grand type d'opération en base, les lecture et les écritures.
- Une lecture ne nécessite pas de Ecto.Multi
- Une écriture est TOUJOURS fait via un Ecto.Multi

- On implémente toujours la base CRUD qui sera la base appelé par d'autres fonctions de services.
- Cela veut dire qu'on ne fait jamais d'insert/delete depuis d'autres services mais on appel ces services là.
- Pour créer une entité, on fait appel à la fonction new du model (ex : User.new(params)) puis on l'insert dans la base (avec Ecto.Multi).
- Pour combiner plusieurs appels aux à des services Ecto.Multi, utiliser Ecto.Multi.merge
- Si besoin, créer des services "haut niveau" pour preload la donnée et combiner plusieurs opération simple. 
  - Exemple, lors de la validation d'un utilisateur avec son code : 
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
