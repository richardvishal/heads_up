defmodule HeadsUp.AccountsFixturesTest do
  use HeadsUp.DataCase, async: true

  alias HeadsUp.AccountsFixtures

  test "valid_user_attributes/1 returns valid attributes" do
    attrs = AccountsFixtures.valid_user_attributes()
    assert is_binary(attrs.email)
    assert is_binary(attrs.password)
    assert is_binary(attrs.username)
  end
end
