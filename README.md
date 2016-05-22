# ZRB, simple Ruby template engine

ZRB is a lightweight template engine with the following features:

* Automatic HTML escaping of expressions
* Ruby-like syntax for expressions: `#{person.name}`
* Helper functions can capture the result of yielding a block
* Block helpers are supported

Example:

```zrb
<h1>Welcome #{user.name}</h1>

<ul>
  <? messages.each do |msg| ?>
    <li>#{msg.text}</li>
  <? end ?>
</ul>

<?= form_for messages_path do |f| ?>
  <textarea name="content"></textarea>
<? end ?>
```

## Usage

ZRB uses [Tilt](https://github.com/rtomayko/tilt) for rendering.
`ZRB::Template` is a Tilt template and you can use all of Tilt's
features:

```ruby
require 'zrb'
tmpl = ZRB::Template.new('index.zrb')
tmpl.render(scope, :user => user)
```

Note however that ZRB has one strict requirement on the scope: **The
scope must implement the method `build_zrb_buffer`**. This method should
return an instance of `ZRB::Buffer` (or a subclass like
`ZRB::HTMLBuffer`). This is required in order to support block helpers:

```ruby
class RenderScope
  def build_zrb_buffer
    @_buffer = ZRB::HTMLBuffer.new
  end

  def form_for(path, &blk)
    "<form>#{@_buffer.capture(blk)}</form>"
  end
end
```

