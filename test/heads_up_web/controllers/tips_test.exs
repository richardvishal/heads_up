defmodule HeadsUp.TipsTest do
  use ExUnit.Case, async: true

  alias HeadsUp.Tips

  describe "tips" do
    test "list_tips/0 returns all tips" do
      tips = Tips.list_tips()
      assert is_list(tips)
      assert length(tips) == 3
      assert hd(tips).id == 1
    end

    test "get_tip!/1 returns the tip with a given integer id" do
      tip = Tips.get_tip!(1)
      assert tip.id == 1
      assert tip.text == "Slow is smooth, and smooth is fast! 🐢"
    end

    test "get_tip!/1 returns the tip with a given string id" do
      tip = Tips.get_tip!("2")
      assert tip.id == 2
      assert tip.text == "Working with a buddy is always a smart move. 👯"
    end
  end
end
