require "./spec_helper"

class Test1
  include SimpleDoc

  property a : Int32

  @[SimpleDoc::Field(comment: "comment")]
  property b = "bla"

  property c : Float64?

  def initialize
    @a = 0
  end
end

class Test2
  include SimpleDoc

  property e : Test1

  def initialize
    @e = Test2.new
  end
end

class Test4
  include SimpleDoc

  @[SimpleDoc::Field(comment: "O_o")]
  property a : Int32

  @[SimpleDoc::Field(ignore: true)]
  property b : String

  def initialize
    @a = 0
    @b = ""
  end
end

class Test5
  include SimpleDoc

  @[SimpleDoc::Field(comment: "O_o")]
  property a : Int32

  @[SimpleDoc::Field(type_name: "Json")]
  property b : String

  def initialize
    @a = 0
    @b = ""
  end
end

describe SimpleDoc do
  context "to_s" do
    it "test1" do
      Test1.document_type.to_s.should eq "{a: Int32, c: Float64?, b: String(\"bla\")}"
    end

    it do
      Test2.document_type.to_s.should eq "{e: {a: Int32, c: Float64?, b: String(\"bla\")}}"
    end

    it do
      Hash(String, Test1).document_type.to_s.should eq "Hash(String, {a: Int32, c: Float64?, b: String(\"bla\")})"
    end

    it do
      Array(Test1).document_type.to_s.should eq "Array({a: Int32, c: Float64?, b: String(\"bla\")})"
    end

    it do
      Test4.document_type.to_s.should eq "{a: Int32}"
    end

    it do
      Test5.document_type.to_s.should eq "{a: Int32, b: Json}"
    end
  end

  it "test1" do
    Test1.document_type.to_printable_root.should eq "Test1:\n  a: Int32\n  c: Float64?\n  b: String(\"bla\") # comment"
  end
end
