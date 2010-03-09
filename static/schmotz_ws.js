  //<!------------------------------ WEBSoCKET-RELATED ----------------------------------->
function addStatus(text){
    var date = new Date();
    document.getElementById('status').innerHTML = date + ": " + text + "<br>" + document.getElementById('status').innerHTML;                
}
function ready(){
    if ("WebSocket" in window) {
        // browser supports websockets
        var ws = new WebSocket("ws://localhost:"+ document.ws_port +"/service") //" + document.getElementById("Username").value);
        ws.onopen = function() {
            // websocket is connected
            addStatus("websocket connected!");
            // send hello data to server.
            addStatus("{\"group\":\""+ document.getElementById("group_input").value +"\"}");
            ws_send("{\"group\":\""+ document.getElementById("group_input").value +"\"}",true);
            ws_send("{\"username\":\""+ document.getElementById("user_name_input").value +"\"}",true);
            addStatus("sent message to server: 'hello server'!");
        };
        ws.onmessage = function (evt) {
            message_handler(evt)
            
            //addStatus("server sent the following: '" + receivedMsg + "'");
        };
        ws.onclose = function() {
            // websocket was closed
            addStatus("websocket was closed");
        };
        document.ws = ws;
    } else {
        // browser does not support websockets
        addStatus("sorry, your browser does not support websockets.");
    }
}
function close_ws(){document.ws.close()}

function ws_send(Data,ServerParse){
    if (ServerParse){
        document.ws.send("1" + Data)
    } else {
        document.ws.send("0" + Data)
    }
}

function send_user_input(str_){
    ws_send(str_,true)
}
function message_handler(evt){
    var data = evt.data.evalJSON();
    //addStatus("insp: " + data.inspect())
    if (data["mouse"] == "up"){
        //addStatus("mouse: up")
        document.stroke_interrupted = true
        document.other_mouseDown = false
    } else if (data["mouse"] == "down"){
        document.other_mouseDown = true
        document.stroke_interrupted = false
  
    //} else if (typeof(data) == 'object' && data.get && data.get("group") ){
    } else if (data["group"]){
        addStatus("joined group: " + data["group"])
    } else if (data == "clear"){
        addStatus("requested clearing");
        draw_bg();
    } else if (data["color"]){
        addStatus("changed color to: " + data["color"])
        set_uParam(document.dato.get("last_active_user"), "color", data["color"])
        change_style(document.dato.get("last_active_user"));
    } else if (data["lineWidth"]){
        addStatus("changed lineWidth to: " + data["lineWidth"]);
        set_uParam(document.dato.get("last_active_user"), "lineWidth", data["lineWidth"])
        change_style(document.dato.get("last_active_user"));
    } else if (data["last_active_user"]){
        var Un = data["last_active_user"];
        $('last_active_user').innerHTML = Un; 
        check_user_record(Un);
        change_style(Un);
        document.dato.set("last_active_user",Un);
        //addStatus("changed username to: " + data["username"])
    } else if (data[0] && typeof(data[0]) == 'number'){
        //addStatus("should draw")
        if (!document.mouseDown) canvas_move(data,false);
    } else {
      addStatus("received: " + Data);
    }
}
