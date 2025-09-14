defmodule HeadsUpWeb.ConnCaseTest do
  use HeadsUpWeb.ConnCase, async: true

  setup :register_and_log_in_user

  test "register_and_log_in_user/1 sets up user and conn", %{conn: conn, user: user} do
    assert user
    assert user.email
    assert get_session(conn, :user_token)
  end
end
