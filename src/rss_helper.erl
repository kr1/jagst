%http://feeds.delicious.com/v2/rss/tag/erlang?count=15

%% call as: 
%% {Doc,_} = xmerl_scan:file(<path>).  
%% rss_helper:printItems(rss_helper:getElementsByTagName(Doc,item)).

-module(rss_helper).
-export([getElementsByTagName/2, printItem/1, printItems/1, get_feed/1, all/2, director/1]).

-include("/usr/lib/erlang/lib/xmerl-1.1.10/include/xmerl.hrl").
-include("../include/jagst_deli.hrl").


director(Tags) ->
    inets:start(),
    case get_feed({tags,Tags}) of
      error ->
        error;
      Doc ->
        Items = getElementsByTagName(Doc,item),
        Parsed = parse_items(Items),
        %io:format("parsed: ~p~n",[Parsed]),
        Parsed
     end.
  
  
getElementsByTagName([H|T], Item) when H#xmlElement.name == Item ->
    [H | getElementsByTagName(T, Item)];
getElementsByTagName([H|T], Item) when record(H, xmlElement) ->
    getElementsByTagName(H#xmlElement.content, Item) ++
      getElementsByTagName(T, Item);                                                                  
getElementsByTagName(X, Item) when record(X, xmlElement) ->
    getElementsByTagName(X#xmlElement.content, Item);
getElementsByTagName([_|T], Item) ->
    getElementsByTagName(T, Item);
getElementsByTagName([], _) ->
    [].

printItems(Items) ->
    F = fun(Item) -> printItem(Item) end,
    lists:foreach(F, Items).

printItem(Item) ->
    io:format("title: ~s~n", [textOf(first(Item, title))]),
    io:format("date: ~s~n", [textOf(first(Item, pubDate))]),
    io:format("link: ~s~n", [textOf(first(Item, link))]),
    [H|T] = [textOf(X) || X <- all(Item, category)],
    
    io:format("tags: ~s~n",[lists:foldl(fun(I,Str) -> string:concat(Str ++ ", ",I) end, H,T)]),
    %printItems(getElementsByTagName(Item, category)),
    %io:format("description: ~s~n", [textOf(first(Item, description))]),
    %io:format("author: ~s~n", [textOf(first(Item, 'dc:creator'))]),
    io:nl().

parse_items(Items)->
    F = fun(Item) -> parse_item(Item) end,
    lists:map(F,Items).

parse_item(Item) ->
    Title = textOf(first(Item, title)),
    Date = textOf(first(Item, pubDate)),
    Desc = textOf(first(Item, description)),
    Link = textOf(first(Item, link)),
    Tags = [textOf(X) || X <- all(Item, category)],
    #tagging{title = Title,
            date = Date,
            description = Desc,
            link = Link,
            other_tags = Tags}.

all(Item,Tag) ->
  %io:format("embe: ~p~n",[Item#xmlElement.content]),
  case length([X || X <- Item#xmlElement.content, X#xmlElement.name == Tag]) > 0 of
    true ->
      [X || X <- Item#xmlElement.content,
          X#xmlElement.name == Tag];
    false ->
      []
  end.

first(Item, Tag) ->
  case length([X || X <- Item#xmlElement.content, X#xmlElement.name == Tag]) > 0 of
    true ->
      hd([X || X <- Item#xmlElement.content,
          X#xmlElement.name == Tag]);
    false ->
      ""
  end.

textOf(Item) ->
    case Item == "" of
      false ->
        lists:flatten([X#xmlText.value || X <- Item#xmlElement.content,
                       element(1,X) == xmlText]);
      true ->
        ""
   end.

get_feed({tags,Tags}) ->
  Url = io_lib:format("http://feeds.delicious.com/v2/rss/tag/~s?count=15",[Tags]),
  io:format("Url: ~s~n",[Url]),
  get_feed({url,Url});
get_feed({url, Url}) ->
  %{ ok, {Status, Headers, Body }} = http:request(Url),
  %Body = Url,
  case http:request(Url) of
    { ok, {_,_, Body }} ->
      %io:format("~s~n",[Body]),
      {Doc,_} = xmerl_scan:string(Body),
      Doc;
    _ ->
      error
 end.