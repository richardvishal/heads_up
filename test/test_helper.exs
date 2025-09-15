ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(HeadsUp.Repo, :manual)

# Define mocks for behaviours we created
Mox.defmock(PhoenixPresenceMock, for: HeadsUpWeb.PresenceBehaviour)
Mox.defmock(PhoenixPubSubMock, for: HeadsUpWeb.PubSubBehaviour)
Mox.defmock(HeadsUp.IncidentsMock, for: HeadsUp.IncidentsBehaviour)

# Make the test environment use the mocks at runtime
Application.put_env(:heads_up, :presence_module, PhoenixPresenceMock)
Application.put_env(:heads_up, :pubsub_module, PhoenixPubSubMock)
