function nav_toggle(event) {
    event.target.classList.toggle("collapsed");
    event.stopPropagation();
}

function nav_hook() {
    var elems = document.getElementsByClassName("collapsible");
    
    for(var i = 0; i < elems.length; i++) {
        elems[i].onclick = nav_toggle;
    }
}

