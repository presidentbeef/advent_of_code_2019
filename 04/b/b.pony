actor Main
  new create(env: Env) =>
    var secret : U32 = 347312
    let stop : U32 = 805915
    var count : U32 = 0

    while (secret < stop) do
      if verify(secret) then
        count = count + 1
      end

      secret = secret + 1
    end

    env.out.print(count.string())

  fun verify(secret: U32) : Bool =>
    var x = secret
    var last : U32 = 10
    var last_last : U32 = 10
    var double = false
    var fixed = false

    while x > 0 do
      var d : U32 = x % 10

      if d > last then
        return false
      end

      // This is terrible and I am ashamed of it
      if (d == last) and (d != last_last) then
        double = true
      elseif (not fixed) and double and (d == last) and (d == last_last) then
        double = false
      elseif double and (d != last) and (last == last_last) then
        fixed = true
      end

      last_last = last
      last = d
      x = x / 10
    end

    double
