function al_dato(){
  alert(document.dato.inspect())
  addStatus(document.dato.inspect())
}

function canvas_click(e){
    var X = e.pageX - document.canvas.offsetLeft;
    var Y = e.pageY - document.canvas.offsetTop;
    //drawline(X,Y)
}
function change_style(un){
  usRec = document.dato.get(un)
  if (usRec) {
    document.ctx.beginPath();
    if (usRec.get("color")){
      document.ctx.strokeStyle = usRec.get("color") 
    }
    if (usRec.get("lineWidth")){
      //addStatus("try to change lineWidth");
      document.ctx.lineWidth = usRec.get("lineWidth") 
    }
  } 
}

function parse_dato_self(){
  document.dato.get('self').each(function(pair) {
    if (pair.key == "color") document.ctx.strokeStyle = pair.value
    if (pair.key == "lineWidth") document.ctx.lineWidth = pair.value
    addStatus(pair.key + ":" + pair.value)
  })
}

function drawline(X,Y){
  document.ctx.lineTo(X,Y);
  document.ctx.stroke()
}

function moveTo(X,Y){
  document.ctx.moveTo(X,Y);
}


function canvas_move(pos_arr, senD){
  //addStatus(pos_arr)
  if (document.mouseDown || document.other_mouseDown){
    document.painter = document.mouseDown ? document.mouseDown : document.other_mouseDown 
    var X = pos_arr[0] - document.canvas.offsetLeft;
    var Y = pos_arr[1] - document.canvas.offsetTop ;   
    //var X = e.pageX - document.canvas.offsetLeft;
    //var Y = e.pageY - document.canvas.offsetTop    
    if (senD && document.mouseDown) ws_send("["+ pos_arr[0] +","+ pos_arr[1] +"]");
    if ((Math.abs(document.c_m_posX - X) > 30  || Math.abs(document.c_m_posY - Y) > 30) || (document.stroke_interrupted )) {
      document.ctx.moveTo(X,Y); 
    }
    document.c_m_posX = X
    document.c_m_posY = Y
    document.movement_buffer.push((X,Y));
    if (document.movement_buffer.length > 20){
        //alert(document.movement_buffer);
        document.movement_buffer = []
    }
    //document.ctx.lineTo(e.pageX - document.canvas.offsetLeft, e.pageY - document.canvas.offsetTop);
    document.ctx.lineTo(X,Y);
    document.ctx.stroke()
    document.last_painter = document.mouseDown ? document.mouseDown : document.other_mouseDown 
  }
}
function mouse_down(event){
  //alert("down")
  document.mouseDown = true
  document.stroke_interrupted = false
  document.ctx.beginPath();
  ws_send("{\"mouse\":\"down\"}")
}

function mouse_up(event){
  //alert("up")
    //document.ctx.closePath();
    ws_send("{\"mouse\":\"up\"}")
    document.stroke_interrupted = true
    document.c_m_posX = -100
    document.c_m_posY = -100
    document.mouseDown = false
}

function draw_bg() {
  //document.canvas = document.getElementById("canvas");
  ctx = document.ctx
  ctx.fillStyle = "rgb(250,250,250)";
  ctx.fillRect (document.canvas.offsetLeft, 
                document.canvas.offsetTop, 
                document.c_width,
                document.c_height);
  ctx.fillStyle = "rgba(0,100,200,0.2)";
  ctx.fillRect (document.canvas.offsetLeft, 
                document.canvas.offsetTop, 
                document.c_width,
                document.c_height);
}