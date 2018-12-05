class Object
  def self.document_type
    SimpleDoc::Describe::PrimitiveType.new({{@type.id.stringify}})
  end
end

class Array(T)
  def self.document_type
    SimpleDoc::Describe::ArrayType.new({{T.name.id}}.document_type)
  end
end

class Hash(K, V)
  def self.document_type
    SimpleDoc::Describe::HashType.new({{K.name.id}}.document_type, {{V.name.id}}.document_type)
  end
end

struct Enum
  def self.document_type
    res = SimpleDoc::Describe::EnumType.new({{@type.id.stringify}})
    {% for member in @type.constants %}
      res.add({{@type}}::{{member}}.to_s, {{@type}}::{{member}}.value.inspect)
    {% end %}
    res
  end
end

struct Union
  def self.document_type
    types = [] of SimpleDoc::Describe::Type
    nilable = false
    {% for type, index in T %}
      {% if type == Nil %}
        nilable = true
      {% else %}
        types << {{type}}.document_type
      {% end %}
    {% end %}

    if (types.size == 1) && !nilable
      types.first
    else
      SimpleDoc::Describe::UnionType.new(types, nilable)
    end
  end
end

module SimpleDoc
  module Describe
    class UnionType
      def initialize(@types : Array(Type), @nilable : Bool)
      end

      def to_s(io)
        if @types.size == 1
          @types.first.to_s(io)
        else
          io << "Union("
          @types.each_with_index do |tp, i|
            io << ", " unless i == 0
            tp.to_s(io)
          end
          io << ')'
        end

        io << '?' if @nilable
      end

      def to_printable(io)
        if @types.size == 1
          @types.first.to_printable(io)
        else
          io << '('
          @types.each_with_index do |tp, i|
            io << " | " unless i == 0
            tp.to_printable(io)
          end
          io << ')'
        end

        io << '?' if @nilable
      end
    end

    class PrimitiveType
      def initialize(@name : String)
      end

      def to_s(io)
        @name.to_s(io)
      end

      def to_printable(io)
        SimpleDoc::Describe.short_name(@name).to_s(io)
      end
    end

    class HashType
      def initialize(@key : Type, @value : Type)
      end

      def to_s(io)
        io << "Hash("
        @key.to_s(io)
        io << ", "
        @value.to_s(io)
        io << ')'
      end

      def to_printable(io)
        io << '{'
        @key.to_printable(io)
        io << " => "
        @value.to_printable(io)
        io << '}'
      end
    end

    class ArrayType
      def initialize(@type : Type)
      end

      def to_s(io)
        io << "Array("
        @type.to_s(io)
        io << ')'
      end

      def to_printable(io)
        io << '['
        @type.to_printable(io)
        io << ']'
      end
    end

    class EnumType
      def initialize(@name : String)
        @records = Array(Tuple(String, String)).new
      end

      def add(k, v)
        @records << {k, v}
      end

      def to_s(io)
        @name.to_s(io)
      end

      def to_printable(io)
        SimpleDoc::Describe.short_name(@name).to_s(io)
      end

      def to_printable_root(io)
        SimpleDoc::Describe.short_name(@name).to_s(io)
        io << ':'
        @records.each do |rec|
          io << '\n'
          io << "  "
          rec[1].to_s(io)
          io << '('
          rec[0].to_s(io)
          io << ')'
        end
      end
    end

    alias Type = StructType | UnionType | HashType | ArrayType | PrimitiveType | EnumType

    struct StructRecordType
      def initialize(@name : String, @type : Type, @default : String?, @comment : String?)
      end

      def to_s(io)
        io << @name
        io << ": "
        @type.to_s(io)
        if (d = @default) && (!d.empty?)
          io << '('
          d.to_s(io)
          io << ')'
        end
      end

      def to_printable(io)
        io << @name
        io << ": "
        @type.to_printable(io)
        if (d = @default) && (!d.empty?)
          io << '('
          d.to_s(io)
          io << ')'
        end
        if comment = @comment
          io << " # "
          io << comment
        end
      end
    end

    struct StructType
      def initialize(@name : String)
        @records = [] of StructRecordType
      end

      def short_name
        SimpleDoc::Describe.short_name(@name)
      end

      def add(rec : StructRecordType)
        @records << rec
      end

      def to_s(io)
        io << '{'
        @records.each_with_index do |rec, i|
          rec.to_s(io)
          io << ", " if i < @records.size - 1
        end
        io << '}'
      end

      def to_printable(io)
        io << short_name
      end

      def to_printable_root(io)
        short_name.to_s(io)
        io << ':'
        @records.each do |rec|
          io << '\n'
          io << "  "
          rec.to_printable(io)
        end
      end

      def to_printable_root
        String.build { |io| to_printable_root(io) }
      end
    end

    def self.short_name(name)
      name
    end

    def self.collect_struct_types(type : Type, result : Array(StructType | EnumType))
      case type
      when HashType
        collect_struct_types(type.@key, result)
        collect_struct_types(type.@value, result)
      when ArrayType
        collect_struct_types(type.@type, result)
      when UnionType
        type.@types.each { |t| collect_struct_types(t, result) }
      when StructType
        result << type
        type.@records.each do |rec|
          collect_struct_types(rec.@type, result)
        end
      when EnumType
        result << type
      end
    end

    def self.struct_types(type)
      result = Array(StructType | EnumType).new
      collect_struct_types(type, result)
      result.uniq!
      result
    end

    def self.type_description(type, nested = true)
      String.build do |io|
        struct_types(type).each_with_index do |st, i|
          io << "\n\n" unless i == 0
          st.to_printable_root(io)
        end
      end
    end
  end
end
