defmodule GenstageExamples.Partitioning do
    defmodule PartitionProducer do
        use GenStage
        def start_link do
            GenStage.start_link(__MODULE__, :no_state, name: __MODULE__)
        end

        def init(_) do
            {:producer, :no_state, dispatcher: {GenStage.PartitionDispatcher, partitions: 0..2 }}
        end

        def handle_demand(demand, :no_state) do
            IO.puts("Demand Received!")
            colors = [:red, :blue, :orange]
            events = Enum.map(1..demand, fn num -> 
                %{color: Enum.random(colors)}
            end)

            {:noreply, events, :no_state}
        end
    end

    defmodule BroadcasterProducerConsumer do
        use GenStage

        def start_link do
            GenStage.start_link(__MODULE__, name: __MODULE__)
        end

        def init(state) do
            {:producer_consumer, state, dispatcher: GenStage.BroadcastDispatcher}
        end

        def handle_events(events, _from, _state) do
            # In reality you'd do some work here before passing the events along.
            IO.puts("Producer Consumer Processing!")
            {:noreply, events, :no_state}
        end
    end
end

defmodule GenstageExamples.Partitioning do
    defmodule AConsumer do
        use GenStage
        def start_link do
            GenStage.start_link(__MODULE__, :no_state, name: __MODULE__)
        end
        def init(:no_state) do
            {:consumer, :no_state}
        end
        def handle_events(events, _from, :no_state) do
            Enum.map(events, fn event -> IO.puts("Cons A: #{event[:color]}") end)
            {:noreply, [], :no_state}
        end
    end

    defmodule BConsumer do
        use GenStage
        def start_link do
            GenStage.start_link(__MODULE__, :no_state, name: __MODULE__)
        end
        def init(:no_state) do
            {:consumer, :no_state}
        end
        def handle_events(events, _from, :no_state) do
            Enum.map(events, fn event -> IO.puts("Cons B: #{event[:color]}") end)
            {:noreply, [], :no_state}
        end
    end

    defmodule CConsumer do
        use GenStage

        def start_link do
            GenStage.start_link(__MODULE__, :no_state, name: __MODULE__)
        end
        def init(:no_state) do
            {:consumer, :no_state}
        end
        def handle_events(events, _from, :no_state) do
            Enum.map(events, fn event -> IO.puts("Cons C: #{event[:color]}") end)
            {:noreply, [], :no_state}
        end
    end
end