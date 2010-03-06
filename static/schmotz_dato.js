function get_dato_default_user_record(Un){
    return $H({username : Un,
              lineWidth: 1.5,
              color:"rgba(0,0,200,0.5)"
            });
}

function check_user_record(Un){
    if (!document.dato.get(Un)) {
        document.dato.set(Un, get_dato_default_user_record(Un))
    }
}

function set_uParam(Un,key,val){
  var usRec = document.dato.get(Un);
  if (usRec){
    usRec.set(key,val)
  }
  //addStatus(usRec.inspect());
}

function get_uParam(Un,key){
  var usRec = document.dato.get(Un);
  if (usRec){
    usRec.get(key);
  }
}
