require 'github/markdown'
require 'json'

class ApiJsonFilter < Nanoc::Filter
  identifier :api_json

  # ----- Helpers -----

  def class_source_link(data, params)
    source_link(data, "class")
  end

  def property_source_link(data, params)
    source_link(data, "property")
  end

  def source_link(item, type = nil)
    <<~HTML
      <a
        class="document-source"
        href="#{item["srcUrl"]}"
        #{type ? " title=\"View #{type} source\"" : ""}>
        #{octicon("file-code")}
      </a>
    HTML
  end

  def markdown(text)
    GitHub::Markdown.render(text)
  end

  def octicon(name)
    "<span class=\"octicon octicon-#{name}\"></span>"
  end

  def argument(arg)
    "<span class=\"argument\">#{arg["name"]}</span>"
  end

  def argument_list(func)
    args = func["arguments"]

    <<~HTML
      <span class="argument-list">(#{args ? args.map { |arg| argument(arg) }.join(", ") : ""})</span>
    HTML
  end

  def method(func, scope, params = {})
    <<~HTML
      <div
        class="api-entry js-api-entry #{visibility_class(func["visibility"])}"
        id="#{scope}-#{func["name"]}">
        <h3 class="name">
          #{func["name"]}#{argument_list(func)}
          #{source_link(func)}
        </h3>
      </div>
    HTML
  end

  def property(prop, scope, params = {})
    <<~HTML
      <div
        class="api-entry js-api-entry #{visibility_class(prop["visibility"])}"
        id="#{scope}-#{prop["name"]}">
        <h3 class="name">
          #{prop["name"]}
          #{property_source_link(prop, params)}
        </h3>
        <div>
          <div class="summary markdown-body">
            #{markdown(prop["summary"])}
          </div>
        </div>
      </div>
    HTML
  end

  def visibility(viz)
    case viz
    when "Public" then "Essential"
    else viz
    end
  end

  def visibility_class(viz)
    visibility(viz).downcase
  end

  def visibility_label(data, params)
    <<~HTML
      <span
        class="label label-#{visibility_class(data["visibility"])}"
        title="This class is in the #{visibility_class(data["visibility"])} API">
        #{data["visibility"]}
      </span>
    HTML
  end

  # ----- Page Sections -----

  def description(data, params)
    markdown(data["description"])
  end

  def page_title(data, params = {})
    <<~HTML
      <h2 class="page-title">
        #{data["name"]}
        #{visibility_label(data, params)}
        #{class_source_link(data, params)}
      </h2>
    HTML
  end

  def sections(data, params = {})
    section_text = data["sections"].map do |section|
      props = data["instanceProperties"].select { |prop| prop["sectionName"] == section["name"] }
      methods = data["instanceMethods"].select { |func| func["sectionName"] == section["name"] }

      <<~HTML
        <h2 class="detail-section">#{section["name"]}</h2>
        #{props.map { |prop| property(prop, "instance", params) }.join}
        #{methods.map { |func| method(func, "instance", params) }.join}
      HTML
    end

    section_text.join("\n")
  end

  def run(content, params = {})
    data = JSON.parse(content)

    page_title(data, params) +
      description(data, params) +
      sections(data, params)
  end
end
