-module(test).

-export([positive/1]).

-spec positive(integer()) -> ok | error.
positive(A) when A > 0 ->
    ok;
positive(_) ->
    error.
