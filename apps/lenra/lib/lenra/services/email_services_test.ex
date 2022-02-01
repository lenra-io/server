defmodule Lenra.EmailService do
  @moduledoc false

  import Bamboo.Email
  import Bamboo.SendGridAdapter
  import Bamboo.SendGridHelper

  # def welcome_email(email) do
  #   new_email()
  #   |> to(email)
  #   |> from("test@lenra.io")
  #   |> subject("test")
  #   |> text_body("test")
  # end

  def template_email() do
    email =
      new_email(
        to: "john@example.com",
        from: "support@myapp.com",
        subject: "Welcome to the app.",
        html_body: "<strong>Thanks for joining!</strong>",
        text_body: "Thanks for joining!"
      )

    with_template(email, "d-bd160809d9a04b07ac6925a823f8f61c")
    |> add_dynamic_field("title", "Bonjour")
    |> deliver(%{
      adapter: SendGridAdapter,
      api_key: "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"
    })
  end

  # email
  # |> deliver(%{
  #   adapter: SendgridAdapter,
  #   api_key: "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"
  # })
  # end
end
