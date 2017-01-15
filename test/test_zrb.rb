require 'minitest/autorun'
require 'zrb'

class TestZRB < Minitest::Test
  include ZRB
  
  def build_zrb_buffer
    flunk "no buffer setup" unless @buffer
    return @buffer
  ensure
    @buffer = nil
  end

  def test_text
    @buffer = Buffer.new
    t = Template.new { "Hello world" }
    assert_equal "Hello world", t.render(self)

    @buffer = Buffer.new
    t = Template.new { "Hello\nworld" }
    assert_equal "Hello\nworld", t.render(self)
  end

  def test_capture
    @buffer = Buffer.new
    t = Template.new { <<-EOF }
    <? @res = buffer.capture(proc do ?>
      Hello world!
    <? end) ?>
    EOF

    assert_equal "", t.render(self).strip
    assert_instance_of Buffer, @res
    assert_equal "Hello world!", @res.strip
  end

  def test_stmt_spacing
    t = Template.new { <<-EOF }
<? if check ?>
hello
<? else ?>
world
<? end ?>
    EOF

    @buffer = Buffer.new
    assert_equal "hello\n", t.render(self, :check => true)
    @buffer = Buffer.new
    assert_equal "world\n", t.render(self, :check => false)
  end

  def test_nested_capture
    @buffer = Buffer.new
    t = Template.new { <<-EOF }
    <? @res1 = buffer.capture(proc do ?>
      Hello world!
      <? @res2 = buffer.capture(proc do ?>
        Hello second!
      <? end) ?>
    <? end) ?>
    EOF

    assert_equal "", t.render(self).strip
    assert_instance_of Buffer, @res1
    assert_instance_of Buffer, @res2
    assert_equal "Hello world!", @res1.strip
    assert_equal "Hello second!", @res2.strip
  end

  def test_line_numbers
    t = Template.new { <<-EOF }
    <? raise if a == 1 ?>
    hello
    <? raise if a == 3 ?>
    <? if a == 6 ?>
      bar
      <? raise ?>
    <? elsif a == 8 ?>
      <? raise ?>
      wat
    <? end ?>
    hello
    world
    <? raise ?>
    EOF

    [1, 3, 6, 8, 13].each do |lineno|
      @buffer = Buffer.new
      exc = assert_raises do
        t.render(self, :a => lineno)
      end
      actual = exc.backtrace[0][/:(\d+)/, 1].to_i
      assert_equal lineno, actual
    end
  end

  def test_expr
    @buffer = Buffer.new
    t = Template.new { 'Hello #{1 + 1}' }
    assert_equal "Hello 2", t.render(self)
  end

  def form_for(&blk)
    "<form>#{@form_buffer.capture(blk, "/awesome").strip}</form>"
  end

  def test_block_expr
    @form_buffer = @buffer = Buffer.new
    t = Template.new { <<-'EOF' }
    <?= form_for do |path| ?>
    Hello #{path}!
    <? end ?>
    EOF

    assert_equal "<form>Hello /awesome!</form>", t.render(self).strip
  end

  def test_block_expr_error
    @form_buffer = @buffer = Buffer.new
    t = Template.new { <<-'EOF' }
    <?= form_for do |path| ?>
    Hello #{path}!
    <? raise ?>
    <? end ?>
    EOF

    assert_raises do
      t.render(self)
    end
  end

  def test_html
    @buffer = HTMLBuffer.new
    t = Template.new { 'Hello #{"&"}' }
    assert_equal "Hello &amp;", t.render(self)
  end
end

