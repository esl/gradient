# TypedGenServer

This is an experiment which abuses Gradualizer's exhaustiveness checking
to type message passing protocols.

This does not automatically determine the types of messages passed around - it's
the programmer who's responsbile for providing this information in form of a type
defining the message.

However, given that type in place, the techniques used here make it easier
to catch bugs if:

- some messages are not handled (completely forgotten or added to the
  protocol, but not to the implementation)
- some messages get malformed (think typos, pattern match mistakes, etc)
- some responses are not handled (i.e. response handlers are incomplete,
  for example if new response types were introduced after the handler was
  in place)

I hope you're interested ;)
If so, please check out [`lib/typed_gen_server/multi_server.ex`](/lib/typed_gen_server/multi_server.ex).
