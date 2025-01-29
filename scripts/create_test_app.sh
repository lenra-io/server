#!/bin/bash

# Add your code here
echo "Creating a test user"
user_id="$(mix run -e '
	{:ok, %{inserted_user: user}} = Lenra.Accounts.register_user(%{"email" => "john.doe@lenra.io","password" => "Johndoe@thefirst","password_confirmation" => "Johndoe@thefirst"}, :dev);
	IO.inspect "user_id=" <> to_string(user.id)' | grep -E '^"user_id=' | sed -E 's/^"user_id=(.+)"$/\1/')"
echo "User created with id: $user_id"

echo "Creating a test app"
app_name="$(mix run -e "
	{:ok, %{inserted_application: app, inserted_env: env}} = Lenra.Apps.create_app(${user_id}, %{ name: \"test\", color: \"FFFFFF\", icon: \"60189\" });
	{:ok, %{inserted_build: build}} = Lenra.Repo.transaction(Lenra.Apps.create_build(${user_id}, app.id, %{}));
	{:ok, %{inserted_deployment: deployment}} = Lenra.Apps.create_deployment(
		env.id,
		build.id,
		${user_id},
		%{}
	);
	Lenra.Apps.update_build(build, %{status: :success});
	Lenra.Apps.update_deployment(deployment, %{status: :success});
	env
		|> Ecto.Changeset.change(is_public: true, deployment_id: deployment.id)
		|> Lenra.Repo.update();
	IO.inspect \"app_name=\" <> to_string(app.service_name)" | grep -E '^\"app_name=' | sed -E 's/^\"app_name=(.+)\"$/\1/')"

echo "App created with name: $app_name"