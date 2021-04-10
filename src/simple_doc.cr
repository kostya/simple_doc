module SimpleDoc
  VERSION = "0.2.0"

  # Options
  #   :ignore
  #   :type_name
  #   :comment

  annotation Field; end

  macro included
    extend ClassExt
  end

  module ClassExt
    def document_type
      {% begin %}
        s = ::SimpleDoc::Describe::StructType.new(self.name)

        {% for ivar in @type.instance_vars %}
          {% doc = ivar.annotation(::SimpleDoc::Field) %}
          {% ignore = doc && doc[:ignore] %}

          {% unless ignore %}
            key = {{ivar.id.stringify}}
            value = {% if doc && doc[:type_name] %} ::SimpleDoc::Describe::PrimitiveType.new({{doc[:type_name]}}) {% else %} {{ivar.type}}.document_type {% end %}
            {% if ivar.has_default_value? %}
              d = {{ivar.default_value}}
              default = d.is_a?(Enum) ? d.value.inspect : d.inspect
            {% else %}
              default = nil
            {% end %}
            comment = {% if doc && doc[:comment] %} {{doc[:comment]}} {% else %} nil {% end %}
            rec = ::SimpleDoc::Describe::StructRecordType.new(key, value, default, comment)
            s.add(rec)
          {% end %}
        {% end %}
        s
      {% end %}
    end
  end
end

require "./simple_doc/*"
