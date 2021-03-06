module SitesHelper
  def site_project_count
    output = "#{pluralize(@site.total_projects, 'proyecto activo', 'proyectos activos')} en "

    if @site.navigate_by_country?
      output << pluralize(@site.total_countries, 'país', 'países').strip
    else
      output << pluralize(@site.total_regions, @site.word_for_regions.singularize, @site.word_for_regions).strip
    end
    truncate(output.strip, :length => 60)
  end
end
