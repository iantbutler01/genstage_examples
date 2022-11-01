defmodule GenstageExamples.Backpressure do
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
            events = Enum.map(1..demand, fn _ -> 
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

    defmodule RateLimiter do
        use GenStage

        def init(_) do
            state = %{
                producers: %{}
            }

            {:producer_consumer, state}
        end

        def start_link do
            GenStage.start_link(__MODULE__, %{producers: %{}}, name: __MODULE__)
        end

        # https://hexdocs.pm/gen_stage/GenStage.html#module-asynchronous-work-and-handle_subscribe
        def handle_info({:ask, from}, %{producers: producers} = state) do
            producers = ask_and_schedule(producers, from)
            state = %{state | producers: producers}

            {:noreply, [], state}
        end

        # https://hexdocs.pm/gen_stage/GenStage.html#module-asynchronous-work-and-handle_subscribe
        defp ask_and_schedule(producers, from) do
            case producers do
              %{^from => {pending, interval}} ->
                GenStage.ask(from, pending)

                Process.send_after(self(), {:ask, from}, interval)

                Map.put(producers, from, {0, interval})
              %{} ->
                producers
            end
        end

        # https://hexdocs.pm/gen_stage/GenStage.html#module-asynchronous-work-and-handle_subscribe
        def handle_subscribe(:producer, opts, from, %{producers: producers} = state) do
            pending = opts[:max_demand] || 100
            interval = opts[:interval] || 2000

            producers = Map.put(producers, from, {pending, interval})
            producers = ask_and_schedule(producers, from)

            state = %{state | producers: producers}
        
            {:manual, state}
        end

        def handle_subscribe(:consumer, opts, from, state) do
            {:automatic, state}
        end

        def handle_events(events, from, %{producers: producers} = state) do
            producers = Map.update!(producers, from, fn {pending, interval} ->
              {pending + length(events), interval}
            end)
            
            IO.puts("Rate Limiter Processing")
            # Again, in a real case you may actually do some work here in the rate limiter before passing the events on.

            state = %{state | producers: producers}
            {:noreply, events, state}
        end

        def handle_cancel(_, from, %{producers: producers} = state) do
            producers = Map.delete(producers, from)

            state = %{state | producers: producers}

            {:noreply, [], state}
        end

    end
end

defmodule GenstageExamples.Backpressure do
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