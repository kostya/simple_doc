# simple_doc

Simple autodocumentation for Struct and Classes.

## Installation

1. Add the dependency to your `shard.yml`:
```yaml
dependencies:
  simple_doc:
    github: kostya/simple_doc
```
2. Run `shards install`

## Usage

```crystal
require "simple_doc"

class A
  include SimpleDoc

  property a : Int32
  
  @[SimpleDoc::Field(comment: "comment")]
  property b = "bla"
  
  property c : Float64?

  @[SimpleDoc::Field(ignore: true)]
  property d : String?

  def initialize
    @a = 0
  end
end

puts A.document_type.to_s
#  {a: Int32, c: Float64?, b: String("bla")}

puts A.document_type.to_printable_root
#  A:
#    a: Int32
#    c: Float64?
#    b: String("bla") # comment
```
