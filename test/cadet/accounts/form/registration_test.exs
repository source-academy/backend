defmodule Cadet.Accounts.Form.RegistrationTest do
  use Cadet.ChangesetCase, async: true

  alias Cadet.Accounts.Form.Registration

  valid_changesets Registration do
    %{
      name: "happy",
      nusnet_id: "e853820"
    }
  end

  invalid_changesets Registration do
    %{}

    %{
      name: "happy"
    }

    %{
      nusnet_id: "e853820"
    }

    %{
      name: "",
      nusnet_id: ""
    }

    %{
      name: "",
      nusnet_id: "e853820"
    }

    %{
      name: "happy",
      nusnet_id: ""
    }
  end
end
