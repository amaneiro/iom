  var old_value;


  $(document).ready(function(ev){
    if ($('div.right.menu').length>0) {
      $('div.right.menu').height($('div.block div.med div.left').height());
    }
    
    //remove text from input
    $('input.main_search').focusin(function(ev){
      var value = $(this).attr('value');
      console.log(value);
      if (value == "Search donors by name, place,..." || value == "Search NGOs by name, place,..." || value == "Search projects by name, place,..." || value == "Search sites by name, place,...") {
        old_value = value;
        $(this).attr('value','');
      }
    });
    $('input.main_search').focusout(function(ev){
      var value = $(this).attr('value');
      if (value == "") {                                      
        $(this).attr('value',old_value);
      }
    });
    
    //if there is an error in some field
    $('a.error').hover(
      function() {
        $(this).parent().find('div.error_msg').show();
      }
    );
    $('div.error_msg p').hover(function(){},
      function() {
        $(this).parent().hide();
      }
    );
	
	//  combo tags click
	$('div.list_combo').children('span.combo_large').click(function(ev){
		if ($(this).attr('id') == 'hidden'){
			$('div.list_combo').find('ul.list_combo_content').css('display','inline');
			$(this).addClass('displayed');
			$(this).attr('id','visible');
		}else{
			$('div.list_combo').find('ul.list_combo_content').css('display','none');
			$(this).attr('id','hidden');
			$(this).removeClass('displayed');
		}
	});
	
	$('ul.list_combo_content').find('li.element').click(function(ev){
		$('input#project_primary_organization_id').val($(this).attr('id'));
		
		$('div.list_combo').find('ul.list_combo_content').css('display','none');
		$('div.list_combo').children('span.combo_large').attr('id','hidden');
		$('div.list_combo').children('span.combo_large').removeClass('displayed');
	});
		
	
  });