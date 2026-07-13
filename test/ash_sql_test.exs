# SPDX-FileCopyrightText: 2024 ash_sql contributors <https://github.com/ash-project/ash_sql/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshSqlTest do
  @moduledoc false
  use ExUnit.Case

  import Ecto.Query

  doctest AshSql

  test "rewrites nested calculation maps below later select merges" do
    sort_value = true

    query =
      "users"
      |> from()
      |> select([user], user)
      |> select_merge([user], %{
        calculations: %{sort_value: type(^sort_value, :boolean)}
      })
      |> select_merge([user], %{is_followed: true})
      |> Map.put(:__ash_bindings__, %{select_calculations: [:calculations]})

    {calculation_merges, aggregate_merges, rewritten} =
      AshSql.Query.rewrite_nested_selects(query)

    assert calculation_merges == %{__calculations__sort_value: :sort_value}
    assert aggregate_merges == %{}
    refute inspect(rewritten.select.expr) =~ "calculations:"
    assert inspect(rewritten.select.expr) =~ "__calculations__sort_value"
    assert rewritten.__ash_bindings__.select_calculations == []
  end
end
