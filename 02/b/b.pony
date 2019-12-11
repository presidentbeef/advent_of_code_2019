use "files"

actor Main
  new create(env: Env) =>
    try
      let path = FilePath(env.root as AmbientAuth, "input.text")?
      let tape = input_to_tape(path)?

      var noun : USize = 0

      while noun < 100 do
        var verb : USize = 0
        while verb < 100 do
          let mem = tape.clone()
          mem.update(1, noun)?
          mem.update(2, verb)?
          let result = run_tape(mem, env)?

          if result(0)? == 19690720 then
            let answer = (100 * result(1)?) + result(2)?

            env.out.print(answer.string())
            break
          end

          verb = verb + 1
        end

        noun = noun + 1
      end
    else
      env.out.print("Something went wrong")
    end

  fun input_to_ints(input: Array[String]) : Array[USize]? =>
    let a : Array[USize] = Array[USize]

    for value in input.values() do
      a.push(value.usize()?)
    end

    a

  fun input_to_tape(path: FilePath) : Array[USize]? =>
    let file = File.open(path)
    let input_string = file.read_string(10000)
    input_string.strip()
    let input : Array[String] = input_string.split_by(",")
    let tape = input_to_ints(consume input)?
    tape

  fun run_tape(tape: Array[USize], env: Env) : Array[USize]? =>
    var i : USize = 0
    var stop : Bool = false

    repeat
      match tape(i)?
      | 1 =>
        let result = tape(tape(i + 1)?)? + tape(tape(i + 2)?)?
        tape.update(tape(i + 3)?, result)?
      | 2 =>
        let result = tape(tape(i + 1)?)? * tape(tape(i + 2)?)?
        tape.update(tape(i + 3)?, result)?
      | 99 => stop = true
      else
        env.out.print("Uh oh")
      end

      i = i + 4
    until stop end

    tape
