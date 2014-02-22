$(document).ready(function () {  
    if (window.location.pathname == "/signup") {
        if (window.location.search.substring(1) != "" && window.location.search.substring(1).split("=")[0] == "num") {
            document.getElementById('num').value = window.location.search.substring(1).split("=")[1];
        }
        else  {
            document.getElementById('num').value = "";
        }
    }
	if ($.fn.parallax){
	   $('#working-section').parallax("50%", 0.1,false);
	}
});