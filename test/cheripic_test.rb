require 'test_helper'

class CheripicTest < Minitest::Test
  def test_module_has_version_number
    refute_nil ::Cheripic::VERSION
  end

  # def test_it_does_something_useful
  #   assert false
  # end
end
