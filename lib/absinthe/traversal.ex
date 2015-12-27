defmodule Absinthe.Traversal do

  @moduledoc """
  Graph/Tree traversal utilities for dealing with ASTs and schemas using the
  `Absinthe.Traversal.Node` protocol.
  """

  alias __MODULE__
  alias Absinthe.Schema
  alias Absinthe.Traversal.Node

  @type t :: %{schema: Schema.t, seen: [Node.t], path: [Node.t]}
  defstruct schema: nil, seen: [], path: []

  @typedoc """
  Instructions defining behavior during traversal
  * `{:ok, value, schema}`: The value of the node is `value`, and traversal should continue to children (using `schema`)
  * `{:prune, value}`: The value of the node is `value` and traversal should NOT continue to children
  * `{:error, message}`: Bad stuff happened, explained by `message`
  """
  @type instruction_t :: {:ok, any} | {:prune, any} | {:error, any}

  @doc """
  Traverse, reducing nodes using a given function to evaluate their value.
  """
  @spec reduce(Node.t, Schema.tt, any, (Node.t -> instruction_t)) :: any
  def reduce(node, schema, initial_value, node_evaluator) do
    {result, traversal} = do_reduce(node, %Traversal{schema: schema}, initial_value, node_evaluator)
    result
  end

  # Reduce using a traversal struct
  @spec do_reduce(Node.t, t, any, (Node.t -> instruction_t)) :: {any, t}
  defp do_reduce(node, traversal, initial_value, node_evaluator) do
    if seen?(traversal, node) do
      {initial_value, traversal}
    else
      case node_evaluator.(node, traversal, initial_value) do
        {:ok, value, next_traversal} ->
          reduce_children(node, next_traversal |> put_seen(node), value, node_evaluator)
        {:prune, value, next_traversal} ->
          {value, next_traversal |> put_seen(node)}
      end
    end
  end

  # Traverse a node's children
  @spec reduce(Node.t, t, any, (Node.t -> instruction_t)) :: any
  defp reduce_children(node, traversal, initial, node_evalator) do
    Enum.reduce(Node.children(node, traversal), {initial, traversal}, fn
      child, {this_value, this_traversal} ->
        do_reduce(child, this_traversal, this_value, node_evalator)
    end)
  end

  @spec seen?(t, Node.t) :: boolean
  defp seen?(traversal, node), do: traversal.seen |> Enum.member?(node)

  @spec put_seen(t, Node.t) :: t
  defp put_seen(traversal, node) do
    %{traversal | seen: [node | traversal.seen]}
  end

end
