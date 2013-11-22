module GeoregionHelper
  def georegion_projects_list_subtitle
    if @filter_by_category
      pluralize(@georegion_projects_count, "PROYECTO DE #{@category_name}", "PROYECTOS DE #{@category_name}") + " EN #{@area.name.upcase}"
    else
      "#{pluralize(@georegion_projects_count, 'PROYECTO', 'PROYECTOS')} EN #{@area.name.upcase}"
    end
  end

end
