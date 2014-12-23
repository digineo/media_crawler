Array::sum = (fn = (x) -> x) ->
  @reduce ((a, b) -> a + fn b), 0
