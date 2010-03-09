  //<!------------------------------ WEBSoCKET-RELATED ----------------------------------->
function addStatus(text){
    var date = new Date();
    document.getElementById('status').innerHTML = date + ": " + text + "<br>" + document.getElementById('status').innerHTML;                
}
function ready(){
    if ("WebSocket" in window) {
        // browser supports websockets
        var ws = new WebSocket("ws://localhost:"+ document.ws_port +"/deli") //" + document.getElementById("Username").value);
        ws.onopen = function() {
            // websocket is connected
            addStatus("websocket connected!");
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

function ws_send(Data){
    document.ws.send(Data)
}

function message_handler(evt){
  //addStatus(evt.data);
  handle_item(evt.data)
}
