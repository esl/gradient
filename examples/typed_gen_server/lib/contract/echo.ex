defmodule Contract.Echo do
  @type req :: {:echo_req, String.t()}
  @type res :: {:echo_res, String.t()}
end
