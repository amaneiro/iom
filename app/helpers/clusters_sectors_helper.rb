# -*- coding: utf-8 -*-
module ClustersSectorsHelper
  def clusters_sectors_projects_list_subtitle
    if @filter_by_location
      pluralize(@cluster_sector_projects_count, "PROYECTO DE #{@data.name}", "PROYECTOS DE #{@data.name}") + " EN #{@location_name}"
    else
       location = if @site.navigate_by_country?
         pluralize(@data.total_countries(@site), 'país', 'países')
       else
         pluralize(@data.total_regions(@site), @site.word_for_regions.singularize, @site.word_for_regions)
       end
       "#{pluralize(@cluster_sector_projects_count, 'PROYECTO', 'PROYECTOS')}  EN #{location}"
    end
  end

end
