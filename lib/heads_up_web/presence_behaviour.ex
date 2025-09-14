defmodule HeadsUpWeb.PresenceBehaviour do
  @callback track(pid :: pid, topic :: String.t(), username :: String.t(), metas :: map) ::
              {:ok, any()} | {:error, any()}

  @callback list(topic :: String.t()) :: map()
end

defmodule HeadsUpWeb.PubSubBehaviour do
  @callback subscribe(server :: atom, topic :: String.t()) :: :ok | {:error, any()}
  @callback broadcast(server :: atom, topic :: String.t(), message :: any()) ::
              :ok | {:error, any()}
end
