module RequirementsHelper
  def markdown(text)
    html = text
      .gsub(/^### (.*?)$/, '<h3 class="text-lg font-bold mt-4 mb-2">\1</h3>')
      .gsub(/^## (.*?)$/, '<h2 class="text-2xl font-bold mt-6 mb-3">\1</h2>')
      .gsub(/^# (.*?)$/, '<h1 class="text-3xl font-bold mt-8 mb-4">\1</h1>')
      .gsub(/\*\*(.*?)\*\*/, '<strong>\1</strong>')
      .gsub(/\*(.*?)\*/, '<em>\1</em>')
      .gsub(/`([^`]+)`/, '<code class="bg-gray-800 text-gray-100 px-2 py-1 rounded text-sm">\1</code>')
      .gsub(/\n\n/, '</p><p class="mb-3">')
      .gsub(/\n/, '<br />')
      .prepend('<p class="mb-3">')
      .concat('</p>')
    
    sanitize(html, tags: %w(h1 h2 h3 p br strong em code), attributes: %w(class))
  end
end
