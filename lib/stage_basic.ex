defmodule GenstageExamples.Basic do
    defmodule Producer do
        use GenStage
        def start_link do
            GenStage.start_link(__MODULE__, :no_state, name: __MODULE__)
        end
        def init(_) do
            {:producer, :no_state}
        end
        def handle_demand(demand, :no_state) do
            events = Enum.to_list(1..demand)
            {:noreply, events, :no_state}
        end
    end

    defmodule Consumer do
        use GenStage
        def start_link do
            GenStage.start_link(__MODULE__, :no_state, name: __MODULE__)
        end
        def init(:no_state) do
            {:consumer, :no_state}
        end
        def handle_events(events, _from, :no_state) do
            Enum.map(events, fn event -> IO.inspect(event) end)
            {:noreply, [], :no_state}
        end
    end
end