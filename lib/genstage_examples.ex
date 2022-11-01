defmodule GenstageExamples do
  alias GenstageExamples.Basic
  alias GenstageExamples.Partitioning
  alias GenstageExamples.Backpressure

  @doc"""
          producer
             |
          consumer
  """
  def basic_ex do
    {:ok, prod} = Basic.Producer.start_link()  # Start the producer
    {:ok, cons} = Basic.Consumer.start_link()  # Start the consumer

    GenStage.sync_subscribe(cons, to: prod, min_demand: 1, max_demand: 100) # Subscribe the consumer to the producer
  end

  @doc"""
          part_prod
          /       \
       a_cons   bcast_prod_cons
                  /     \
              b_cons    c_cons
  """
  def partition_ex do
    {:ok, part_prod} = Partitioning.PartitionProducer.start_link()
    {:ok, broadcast_prod_cons} = Partitioning.BroadcasterProducerConsumer.start_link()
    {:ok, a_cons} = Partitioning.AConsumer.start_link()
    {:ok, b_cons} = Partitioning.BConsumer.start_link()
    {:ok, c_cons} = Partitioning.CConsumer.start_link()


    GenStage.sync_subscribe(a_cons, to: part_prod, partition: 0)
    GenStage.sync_subscribe(broadcast_prod_cons, to: part_prod, partition: 1)
    GenStage.sync_subscribe(broadcast_prod_cons, to: part_prod, partition: 2)
    GenStage.sync_subscribe(b_cons, to: broadcast_prod_cons, selector: fn %{color: c} -> c == :orange end)
    GenStage.sync_subscribe(c_cons, to: broadcast_prod_cons, selector: fn %{color: c} -> c == :blue end)
  end

  @doc"""
          part_prod
          /       \
    rate_limiter   bcast_prod_cons
        /         /     \
    a_cons   b_cons    c_cons
  """
  def backpressure_ex do
    {:ok, part_prod} = Backpressure.PartitionProducer.start_link()
    {:ok, rate_limiter} = Backpressure.RateLimiter.start_link()
    {:ok, broadcast_prod_cons} = Backpressure.BroadcasterProducerConsumer.start_link()
    {:ok, a_cons} = Backpressure.AConsumer.start_link()
    {:ok, b_cons} = Backpressure.BConsumer.start_link()
    {:ok, c_cons} = Backpressure.CConsumer.start_link()


    GenStage.sync_subscribe(rate_limiter, to: part_prod, partition: 0, max_demand: 10, interval: 5000)
    GenStage.sync_subscribe(a_cons, to: rate_limiter)
    GenStage.sync_subscribe(broadcast_prod_cons, to: part_prod, partition: 1)
    GenStage.sync_subscribe(broadcast_prod_cons, to: part_prod, partition: 2)
    GenStage.sync_subscribe(b_cons, to: broadcast_prod_cons, selector: fn %{color: c} -> c == :orange end)
    GenStage.sync_subscribe(c_cons, to: broadcast_prod_cons, selector: fn %{color: c} -> c == :blue end)
  end
end
