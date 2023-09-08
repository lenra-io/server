<div id="top"></div>
<!--
*** Thanks for checking out the Best-README-Template. If you have a suggestion
*** that would make this better, please fork the repo and create a pull request
*** or simply open an issue with the tag "enhancement".
*** Don't forget to give the project a star!
*** Thanks again! Now go create something AMAZING! :D
-->



<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![AGPL License][license-shield]][license-url]



<!-- PROJECT LOGO -->
<br />
<div align="center">
  <!-- <a href="https://github.com/lenra-io/template-hello-world-node12">
    <img src="images/logo.png" alt="Logo" width="80" height="80">
  </a> -->

<h3 align="center">Application Runner</h3>

  <p align="center">
    This repository provides an Phoenix application that can run Lenra Application.
    <br />
    <br />
    <a href="https://github.com/lenra-io/application-runner/issues">Report Bug</a>
    ·
    <a href="https://github.com/lenra-io/application-runner/issues">Request Feature</a>
  </p>
</div>

<!-- GETTING STARTED -->
## Getting Started

### Prerequisites

You can run Application Runner itself, but it is generally built as a library and needs a Phoenix parent application to access all functionalities: 

To begin, make sure you have two databases, namely PostgreSQL and MongoDB, up and running. You can accomplish this by either executing the commands at the root of this project or manually running the Docker commands as shown below:

* Start them both with Docker Compose:
    ```
    docker compose up -d
    ```

or

* Start them separatly with Docker 
    ```
    # Start PostgreSQL
    docker run --rm -dt -p 5432:5432 --name lenra-postgres -e POSTGRES_DB=lenra_dev -e POSTGRES_PASSWORD=postgres postgres:13
    # Start MongoDB
    docker run --rm -dt -p 27017:27017 --name lenra-mongo -e MONGO_INITDB_DATABASE=test -e CONFIG='{"_id" : "rs0", "members" : [{"_id" : 0,"host" : "mongodb:27017"}]}' -d mongo:5 mongod --replSet rs0
    ```

Load git submodules:
```
git submodule update --init --recursive
```

Next, you'll need to install and configure the necessary prerequisites for Elixir's application_runner to function correctly. Follow these steps:

* Install erlang version 24.2 and Elixir version 1.13 otp-24
* Create the database and start migration `mix setup`. This is equivalent to running the following commands : 
  * `mix deps.get` to install the dependencies
  * `mix ecto.create` to create database
  * `mix ecto.migrate` to start all migration and have an up-to-date database
  
#### Add Application Runner to your project:
```elixir
{:application_runner, git: "https://github.com/lenra-io/application-runner.git", tag: "v1.0.0.beta.X"}
```
#### Configure the Library:
```elixir
config :application_runner,
  lenra_environment_table: __,
  lenra_user_table: __,
  repo: __,
  url: __,
```
with:  
- **lenra_environment_table**: the name of the environment table as String
- **lenra_user_table**: the name of the user table as String
- **repo**: Your app repository
- **url**: the url of your application, this url is passed to Lenra application to make API requests

#### Implement Web socket & Channel:  
   - You also need to implement a channel using ApplicationRunner's channel

```elixir
defmodule __APPLICATION__.AppAdapter do
  @behaviour ApplicationRunner.Adapter

  @impl ApplicationRunner.Adapter
  def allow(user_id, app_name) do
    #This function authorizes a user for the following app_name
    #Return true to authorize access
    #Return false to deny access
  end

  @impl ApplicationRunner.Adapter
  def get_function_name(app_name) do
    #This fucntion return the name of the application to call
  end

  @impl ApplicationRunner.Adapter
  def get_env(app_name) do
    #This function return the environment of the following app_name
  end
end

defmodule __APPLICATION__.Channel do
    use ApplicationRunner.AppChannel, adapter: __APPLICATION__.AppAdapter
end
```
  - How to implement a Socket for your application that uses ApplicationRunner Socket:

```elixir
defmodule YourApp.Socket do
  use ApplicationRunner.UserSocket, channel: _Yourchannel
  
  defp resource_from_params(params) do
    # This function validate that the client can open a socket following params
    # To accept the connection return {:ok, _params}
    # To refuse the connection return :error 
  end
end
  ```

<p align="right">(<a href="#top">back to top</a>)</p>

<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please open an issue with the tag "enhancement" or "bug".
Don't forget to give the project a star! Thanks again!

<p align="right">(<a href="#top">back to top</a>)</p>

<!-- LICENSE -->
## License

Distributed under the **AGPL** License. See [LICENSE](./LICENSE) for more information.

<p align="right">(<a href="#top">back to top</a>)</p>

<!-- CONTACT -->
## Contact

Lenra - [@lenra_dev](https://twitter.com/lenra_dev) - contact@lenra.io

Project Link: [https://github.com/lenra-io/application-runner](https://github.com/lenra-io/application-runner)

<p align="right">(<a href="#top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/lenra-io/application-runner.svg?style=for-the-badge
[contributors-url]: https://github.com/lenra-io/application-runner/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/lenra-io/application-runner.svg?style=for-the-badge
[forks-url]: https://github.com/lenra-io/application-runner/network/members
[stars-shield]: https://img.shields.io/github/stars/lenra-io/application-runner.svg?style=for-the-badge
[stars-url]: https://github.com/lenra-io/application-runner/stargazers
[issues-shield]: https://img.shields.io/github/issues/lenra-io/application-runner.svg?style=for-the-badge
[issues-url]: https://github.com/lenra-io/application-runner/issues
[license-shield]: https://img.shields.io/github/license/lenra-io/application-runner.svg?style=for-the-badge
[license-url]: https://github.com/lenra-io/application-runner/blob/master/LICENSE