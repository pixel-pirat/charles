defmodule VisoBackendWeb.ChannelCase do
  @moduledoc """
  This module defines the test case to be used by channel tests.

  Such tests rely on `Phoenix.ChannelTest` and also import other
  functionality to make it easier to build common data structures and
  query the data layer.

  Finally, if the test case interacts with the database, we enable the
  SQL sandbox, so changes done to the database are reverted at the end
  of every test. This is done by calling `Ecto.Adapters.SQL.Sandbox.mode/2`
  and explicitly starting the sandbox in tests that need to run concurrently.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with channels
      import Phoenix.ChannelTest
      import VisoBackendWeb.ChannelCase

      # The default endpoint for testing
      @endpoint VisoBackendWeb.Endpoint
    end
  end

  setup tags do
    VisoBackend.DataCase.setup_sandbox(tags)
    :ok
  end
end
