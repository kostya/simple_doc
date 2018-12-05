require "./src/simple_doc"

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

