//<!------------------------------ Data Object Related ----------------------------------->
function init_dato(){
    document.dato = $H({'itemQueue' : [],
                        'q_len' : 15});
}

function addToQ(I){
  dato = document.dato
  var q = dato.get('itemQueue');
  //alert(q.length)
  q.push(I['date'])
  if (q.length > dato.get('q_len')){
    var ele= q.shift();
    $(ele).remove();
    }
  dato.set('itemQueue',q)
  //addStatus("dato: " + Object.inspect(dato.get('itemQueue')))
}

function duplicateD(Item){
    var q = document.dato.get('itemQueue');
    return q.any(function(I){I==Item['date']})
}
