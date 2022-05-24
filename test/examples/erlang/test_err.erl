-module(test_err).

-export([positive/1]).

-spec positive(integer()) -> integer().
positive(A) when A > 0 ->
    ok;
positive(_) ->
    error.
