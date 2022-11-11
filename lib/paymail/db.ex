defmodule Paymail.DB do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    CubDB.start_link("cub/db")
  end

  def put(key, value) do
    GenServer.call(__MODULE__, {:put, key, value})
  end

  @doc """
  Delete all data, DANGEROUS!!!
  """
  def clear() do
    GenServer.call(__MODULE__, :clear)
  end

  def select(opts) do
    GenServer.call(__MODULE__, {:select, opts})
  end

  def handle_call({:put, key, value}, _, db) do
    {:reply, CubDB.put(db, key, value), db}
  end

  def handle_call({:select, opts}, _, db) do
    {:reply, CubDB.select(db, opts), db}
  end

  def handle_call(:clear, _, db) do
    {:reply, CubDB.clear(db), db}
  end
end
