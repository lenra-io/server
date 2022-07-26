defmodule Lenra.Seeds do
  @moduledoc """
  Module to populate the database. The "run" function must be idempotent.
  """

  def run do
    generate_dev_codes()
    generate_cgu()
  end

  def generate_dev_codes do
    dev_codes = [
      "fbd1ff7e-5751-4617-afaa-ef3be4cc43a6",
      "caeee9e4-2bc7-4c4f-b3fa-a64a2a53d97d",
      "09c39cbe-f0ad-4257-b1f6-4efcf0e1140b",
      "e0f1541b-424f-4754-b34c-a6f0c7a6d3fa",
      "709e3b85-3eb8-4ac5-8510-5873be041aa3",
      "ca0cadb5-bfa6-4c76-a209-0089f775d50b",
      "daf5b1f8-825c-4989-82d5-032dee5fadc5",
      "b8e7bc51-7d58-4ffd-acde-34f869788744",
      "0fefb5cb-04c4-4005-a009-661b85d96f97",
      "f3c3ee4e-ab37-4bda-a1ec-ffa6896b89f0",
      "9a129b8a-c30d-4501-b37d-2a11f1600309",
      "6f0e82fd-b255-4dee-8e00-34a414ef7e3d",
      "c6b2dc9d-676a-4cb0-805e-25f88d3ee09b",
      "a26e5765-25db-42af-a9bd-c153a15ea511",
      "b511194c-ee55-4b11-99f4-2327dd4ff856",
      "f3a9b065-77ca-45f6-ae45-355e4c9894ed",
      "5aedce88-4d2c-4c5e-874c-40e802b55e6d",
      "e54a987d-ff80-4508-8671-cefffe49ae41",
      "f07b5638-d550-4f20-841a-1de9fc83d4dc",
      "c5340f3d-39b6-4b7c-b76e-098620aebbd5",
      "0cf7823c-07da-4106-b673-2db06bd1b5eb",
      "f343f446-c475-4f16-82af-ae9c76bd7e36",
      "7fb86b7f-5b49-4358-afd2-f0fbd28a261a",
      "5cbd6dc6-952e-49d8-9ded-bcaa4144630c",
      "5bd97508-f99f-4c5e-bca2-c2755380a82c",
      "a5e3e671-966c-464d-8e76-cb6a14182396",
      "13af32fd-2f57-4045-bf7f-a04430881389",
      "1e5a86df-f0da-4019-9916-e68aaefce904",
      "326c5f96-279c-4ec6-9147-eeaa9ae6f16f",
      "64e04683-6422-4c7f-b6b5-f65cc57cce69",
      "37bddcde-f114-4c8c-b942-857926bd614c",
      "f77ae21e-1b17-4df6-89ae-bce213a39466",
      "a39331c4-5465-46ee-962a-47d3b56f1f8f",
      "96f9541d-39e9-445e-8b4b-59598a78ae02",
      "3cbb5e08-8ff3-4310-bc32-74d3c1e52c8f",
      "78c280b2-9ce4-4984-ae8c-eb9f586956e2",
      "422868b8-2f57-4e16-ad1d-3e111b3ed668",
      "311bf696-adc0-43fb-9505-6b7266d47bad",
      "df09a53a-92ff-4489-a515-c9ebf499f6d2",
      "8eeed52a-b2e8-4c9d-98a1-4cec15c0be1e",
      "9e612c30-f3d9-4fb8-8ac2-27a85df0d549",
      "1505d230-8932-46c8-8ffc-257dbd105f28",
      "47985170-b975-4a8b-9ec5-97ede16ce782",
      "c5c5ce5d-be6e-4fbf-bf4f-ec4548386348",
      "4ac2ab18-0710-4954-98f4-b5da8233724b",
      "70426cee-d8d9-464f-93f2-037a798b636f",
      "0b90a309-dadb-4f8b-8677-f6ee96b3c8c6",
      "5df37bf2-a456-4cf4-86d3-37dd01b82fb5",
      "8d6b8601-4c1f-45ff-8cd9-42839ee7f3d7",
      "b5e0178b-72e4-4531-836b-aa2d7c19d80f"
    ]

    Enum.map(dev_codes, fn
      uuid_bin ->
        Lenra.Repo.insert(
          %Lenra.Accounts.DevCode{
            code: uuid_bin
          },
          on_conflict: :nothing
        )
    end)
  end

  def generate_cgu do
    wildcard =
      "./apps/lenra_web/priv/static/cgu/CGU_fr_*.md"
      |> Path.wildcard()

    Enum.each(wildcard, fn path ->
      "CGU_fr_" <> version = path |> Path.basename(".md")
      Lenra.Legal.add_cgu("./apps/lenra_web/priv/static/cgu/CGU_fr_#{version}.md", version)
    end)
  end
end
