[
  ## still to be fixed

  # error occurs only on GitHub Actions
  "test/support/helpers.ex:14",

  # https://github.com/esl/gradient/issues/85
  {:type_error, :unreachable_clause},

  # https://github.com/esl/gradient/issues/37
  {:type_error, :cyclic_type_vars},

  ## ignores below are fixed in open PRs

  # https://github.com/esl/gradient/pull/118
  "test/support/ast_data.ex"
]
