var menu = function() {
	var currentActiveMenu;
	
	var initMenu = function (activeMenuId){
		currentActiveMenu = jQuery("table[id=journals] > tbody > tr > td[name=" + activeMenuId + "]").get(0);
		selectMenu(currentActiveMenu);
		
		jQuery("table[id=journals] > tbody > tr > td").click(function (){
			selectMenu(this);
		});
	}
	
	var selectMenu = function (menuItem){
		jQuery(currentActiveMenu).removeClass("active");
		currentActiveMenu = menuItem;
		jQuery(currentActiveMenu).addClass("active");
	}
	
	return {
		init: function(activeMenu){		
			initMenu(activeMenu);
		}
	}
}();