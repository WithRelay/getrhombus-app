$(document).ready(function () {
    
    // Add coode to make this run only on signup pages
    
    if (window.location.pathname == "getrhombus.com/signup") {
        if (window.location.search.substring(1) != "")   {
            document.getElementById('num').value = window.location.search.substring(1).split("=")[1];
        }
        else  {
            document.getElementById('num').value = ""
        }
    }
    

});