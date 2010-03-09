//<!------------------------------ Delicious Items Related ----------------------------------->
function addStatus(text){
    var date = new Date();
    $('status').innerHTML = date + ": " + text + "<br>" + $('status').innerHTML;                
}

function parse_erl_string(arr){
  if (typeof(arr) != 'object') return arr;
  str="";
  arr.each(function(ele){str+=String.fromCharCode(ele)})
  return str
}

function parse_field(k, Item){
    if (k == "other_tags"){
        arr = []
        Item[k].each(function(ele){
                      arr = arr.concat(parse_erl_string(ele))
                  })
        str = arr.join(", ")
    
    } else {
      str=""
      Item[k].each(function(ele){
                        str+=String.fromCharCode(ele)
                  })
    }
    return str
}

function handle_item(Item){
    var Item = Item.evalJSON();
    if (Item["date"]){
        Item["date"] = parse_erl_string(Item["date"]); 
        if (!duplicateD(Item)){
          addToQ(Item);
          //Object.keys(Item).each(function(k){
           //                         parse_field(k, Item)
           //                     })
          //addStatus("received: " + Object.inspect(Item));
          var ele = new Element("div",{"id":Item["date"]});
          html = assemble_item(Item);
          ele.insert(html);
          $('rotation').insert({top:ele});
        }
    } else {
      //addStatus("received: something" + Item);
    }
}

function assemble_item(It){
  html = "<h3><a href='" + parse_field("link", It) +"'>" + parse_field("title", It) + "</a></h3>";
  html += "<p>" + parse_field("description", It) + "</p>";
  html += "<span class='rotation_date'>" + It["date"] + "</span><br/>";
  html += "<a href='" + parse_field("link", It) +"'>" + parse_field("link", It) + "</a><br/>";
  html += "<big>" + parse_field("other_tags", It) + "</big><br/><br/>";
  return html
}
