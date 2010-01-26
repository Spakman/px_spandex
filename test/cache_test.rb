require_relative "test_helper"
require_relative "../lib/cache"

class Spandex::Cache
  attr_reader :cache
end

class CacheTest < Test::Unit::TestCase
  def setup
    @cache = Spandex::Cache.new
  end

  def test_put
    @cache.put 123, "try me"
    assert_equal "try me", @cache.cache[123]
  end

  def test_put_over_cache_size_limit
    @cache = Spandex::Cache.new 1
    @cache.put 123, "say bye!"
    @cache.put 456, "try me"
    assert_nil @cache.cache[123]
    assert_equal "try me", @cache.cache[456]
  end

  def test_get
    @cache.put 123, "try me"
    @cache.put 456, "hanging about"
    assert_equal "try me", @cache.get(123)
    assert_equal "hanging about", @cache.get(456)
  end

  def test_expire
    @cache.put 123, "try me"
    @cache.put 456, "hanging about"
    assert_equal "try me", @cache.cache[123]
    assert_equal "hanging about", @cache.cache[456]
    @cache.expire 123
    assert_nil @cache.cache[123]
    assert_equal "hanging about", @cache.cache[456]
  end

  def test_method_aliases
    assert_equal @cache.method(:expire), @cache.method(:remove)
    assert_equal @cache.method(:expire), @cache.method(:delete)
    assert_equal @cache.method(:get), @cache.method(:[])
    assert_equal @cache.method(:put), @cache.method(:[]=)
  end
end
