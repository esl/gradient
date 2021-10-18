# Gradient

Gradient is a [gradual typechecker][siek:what-is-gt] for Elixir.

Gradual typing is a bit like static typing,
because it provides error messages if your code has types and specs - and any errors, obviously.
Gradual typing is also a bit like dynamic typing,
because it doesn't require all the functions to have specs and just agrees when you say:
"Trust me, I'm a (software) engineer!" 

[siek:what-is-gt]: https://wphomes.soic.indiana.edu/jsiek/what-is-gradual-typing/

Gradient relies on [Gradualizer](https://github.com/josefs/Gradualizer) as the actual typechecker,
but aims to make jumping the hoops between your Elixir code and the Erlang abstract
syntax tree that Gradualizer works on effortless.


## Usage

Gradient can be installed by adding `gradient` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gradient, "~> 0.1.0"}
  ]
end
```

Gradient comes with a Mix task that runs the typechecker on an Elixir project:

```
mix gradient
```

And presents errors in Elixir syntax:

![Result after simple app analysis](examples/simple_app_result.png)

The `examples/` folder contains example applications showing how the produced error messages look like.


## Problem with abstract code generated from Elixir

The Elixir AST stores literals as themselves.
Thus the abstract code generated from Elixir doesn't have information about the line of the literals.
This lack of information makes it hard to localize the error in a code because the line is set to 0.

To overcome this problem Gradient reads the abstract code from beam files,
then traverses it and fills the missing lines.
The lines are taken from the corresponding token or from the parent form.


## Progress

### Mix task

For now, this task localizes all project beams and runs Gradient on each file.
What's more, it tries to import all dependencies to Gradualizer.
Umbrella projects are supported.

##### TODO

- Support options
- Ensure that deps are imported correctly to Gradualizer

### Printing errors

The type errors are highlighted in the Elixir code.
Erlang pretty printers are still used in the error descriptions.

##### TODO

- Highlight the specific expression, not the entire line
- Implement expr pretty printer for Elixir
- Implement type pretty printer for Elixir

### Specyfing lines in expressions

Each form has a corresponding mapper.
On each form is invoked a mapper function which specifies the line when is missing
and also runs mappers on the children of the form.

Firstly the expr with missing line obtains the line after the parent.
Then the tokens are browsed to specify the line more precisely.
When the corresponding token is found the line is taken and assigned to the expression.
Otherwise, we assume that the expression was generated and leave it with the parent line.

Currently mappers for the most forms, expressions and literals are ready:

- function [x]
- fun [x]
- clause [x]
- case [x]
- block [X]
- call [x]
- match [x]
- op [x]
- tuple [X]
- var [X]
- cons (list, keyword, charlist) [X]
- binary [X]
- map [X]
- try [x]
- receive [X]
- atomic literals (atom, char, float, integer, string) [X]

Most of the Elixir features as **pipes**, **with**, **if**, **unless**, **cond**, **case**,
**guards**, **struct**, **range**, **record**, **list comprehension**
should be handled by the above mappers.

##### TODO

- Attach info about the column.
- Expand Pipes support to specifying lines from tokens.
- Add more tests to detect possible malfunctions.
- Support nested modules.
- Specify lines in type specification.

<!--
vim: colorcolumn=100
-->
