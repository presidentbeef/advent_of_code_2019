use "files"
use "promises"

actor IntcodeInterpreter
  let _tape : Array[USize] iso
  let _env : Env
  var _pc : USize = 0
  var _running : Bool = false

  new create(tape': Array[USize] iso, env: Env) =>
    _tape = consume tape'
    _env = env

  be run_tape() =>
    _running = true

    repeat
      execute()
    until not _running end

  fun ref execute() =>
    let i : USize = _pc
    var step : USize = 4

    try
      match _tape(i)?
      | 1 =>
        let result = _tape(_tape(i + 1)?)? + _tape(_tape(i + 2)?)?
        _tape.update(_tape(i + 3)?, result)?
      | 2 =>
        let result = _tape(_tape(i + 1)?)? * _tape(_tape(i + 2)?)?
        _tape.update(_tape(i + 3)?, result)?
      | 3 =>
        _running = false
        step = 2
        let addr = _tape(i + 1)?
        let si = recover iso SetInput(this, addr) end
        _env.input(consume si, 1)
      | 4 =>
        let result = _tape(_tape(i + 1)?)?
        _env.out.print(result.string())
        step = 2
      | 99 =>
        _running = false
        _env.input.dispose()
      else
        _env.out.print("Uh oh")
        _running = false
      end
    end

    _pc = _pc + step

  be set_input(addr: USize, value: USize) =>
    try
      _tape.update(addr, value)?
    else
      _env.out.print("Uh ohs")
    end

    run_tape()

class SetInput is InputNotify
  let _i : IntcodeInterpreter
  var _addr : USize

  new create(i': IntcodeInterpreter, addr': USize) =>
    _i = i'
    _addr = addr'

  fun apply(data: Array[U8] val) =>
    try
      _i.set_input(_addr, String.from_array(data).usize()?)
    else
      _i.set_input(_addr, -1)
    end


actor Main
  new create(env: Env) =>
    try
      let path = FilePath(env.root as AmbientAuth, "input.text")?
      let tape = recover iso input_to_tape(path) end
      let machine = IntcodeInterpreter(consume tape, env)
      machine.run_tape()
    else
      env.out.print("Something went wrong")
    end

  fun input_to_ints(input: Array[String]) : Array[USize] iso^ =>
    let a : Array[USize] iso = recover iso Array[USize] end

    for value in input.values() do
      try
        a.push(value.usize()?)
      end
    end

    consume a

  fun input_to_tape(path: FilePath val) : Array[USize] iso^ =>
    let file = File.open(path)
    let input_string = file.read_string(10000)
    input_string.strip()
    let input : Array[String] = input_string.split_by(",")
    input_to_ints(consume input)
