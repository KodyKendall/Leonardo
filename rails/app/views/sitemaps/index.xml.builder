xml.instruct! :xml, version: "1.0"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  @urls.each do |slug|
    xml.url do
      if slug.blank?
        xml.loc root_url
      else
        xml.loc static_page_url(slug: slug)
      end
      xml.lastmod Time.current.strftime("%Y-%m-%d")
      xml.changefreq "weekly"
      xml.priority "0.8"
    end
  end
end
