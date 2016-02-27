function nav_toggle(event) {
    event.target.classList.toggle("collapsed");
    event.stopPropagation();
    if(isNavOpen(event.target.id)) {
        closeNav(event.target.id);
	console.log("Closed");
    } else {
        openNav(event.target.id);
	console.log("Opened");
    }
}

function nav_hook() {
    var elems = document.getElementsByClassName("collapsible");
    
    for(var i = 0; i < elems.length; i++) {
        elems[i].onclick = nav_toggle;
        if(isNavOpen(elems[i].id)) {
            elems[i].classList.remove("collapsed");
        }
    }
}

function openNav(navpath) {
	rawJson = readCookie("open_navs");
	paths = [];
	if("" != rawJson) {
		paths = JSON.parse(rawJson);
	}
	paths.push(navpath);
	writeCookie("open_navs", JSON.stringify(paths), 1);
}

function closeNav(navpath) {
	rawJson = readCookie("open_navs");
	paths = [];
	if("" != rawJson) {
		paths = JSON.parse(rawJson);
	}
	index = paths.indexOf(navpath);
	if(index != -1) {
		paths.splice(index, 1);
		writeCookie("open_navs", JSON.stringify(paths), 1);
	}
}

function isNavOpen(navpath) {
	rawJson = readCookie("open_navs");
	if("" != rawJson) {
		paths = JSON.parse(rawJson);
		return paths.indexOf(navpath) > -1;
	} else {
		return false;
	}
}

/* Cookie code from: http://stackoverflow.com/questions/2257631/how-create-a-session-using-javascript#2257895 */
function writeCookie(name,value,days) {
    var date, expires;
    if (days) {
        date = new Date();
        date.setTime(date.getTime()+(days*24*60*60*1000));
        expires = "; expires=" + date.toGMTString();
            }else{
        expires = "";
    }
    document.cookie = name + "=" + value + expires + "; path=/";
}

function readCookie(name) {
    var i, c, ca, nameEQ = name + "=";
    ca = document.cookie.split(';');
    for(i=0;i < ca.length;i++) {
        c = ca[i];
        while (c.charAt(0)==' ') {
            c = c.substring(1,c.length);
        }
        if (c.indexOf(nameEQ) == 0) {
            return c.substring(nameEQ.length,c.length);
        }
    }
    return '';
}
