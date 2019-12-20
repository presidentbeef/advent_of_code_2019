use "files"
use "promises"

actor IntcodeInterpreter
  let _tape : Array[ISize] iso
  let _env : Env
  var _pc : USize = 0
  var _running : Bool = false

  new create(tape': Array[ISize] iso, env: Env) =>
    _tape = consume tape'
    _env = env

  be run_tape() =>
    _running = true

    repeat
      execute()
    until not _running end

  fun ref execute() =>
    var step : USize = 4

    try
      let full_code = _tape(_pc)?
      let op_code = full_code % 100

      match op_code
      | 1 =>
        let result = get_value(full_code, 1) + get_value(full_code, 2)
        set_value(_tape(_pc + 3)?.usize(), result)
      | 2 =>
        let result = get_value(full_code, 1) * get_value(full_code, 2)
        set_value(_tape(_pc + 3)?.usize(), result)
      | 3 =>
        _running = false
        step = 2
        let addr = _tape(_pc + 1)?.usize()
        let si = recover iso SetInput(this, addr) end
        _env.input(consume si, 1)
      | 4 =>
        let result = get_value(full_code, 1)
        _env.out.print(result.string())
        step = 2
      | 5 =>
        let cond = get_value(full_code, 1)
        let addr = get_value(full_code, 2)

        if cond != 0 then
          _pc = addr.usize()
          step = 0
        else
          step = 3
        end
      | 6 =>
        let cond = get_value(full_code, 1)
        let addr = get_value(full_code, 2)

        if cond == 0 then
          _pc = addr.usize()
          step = 0
        else
          step = 3
        end
      | 7 =>
        let lhs = get_value(full_code, 1)
        let rhs = get_value(full_code, 2)
        let addr = _tape(_pc + 3)?.usize()

        if lhs < rhs then
          set_value(addr, 1)
        else
          set_value(addr, 0)
        end
      | 8 =>
        let lhs = get_value(full_code, 1)
        let rhs = get_value(full_code, 2)
        let addr = _tape(_pc + 3)?.usize()

        if lhs == rhs then
          _env.out.print(lhs.string() + " == " + rhs.string())
          set_value(addr, 1)
        else
          _env.out.print(lhs.string() + " != " + rhs.string())
          set_value(addr, 0)
        end

      | 99 =>
        _running = false
        _env.input.dispose()
      else
        _env.out.print("Uh oh")
        _running = false
      end
    end

    _pc = _pc + step

  // Get value from tape, figuring out mode and offset
  // pos is which operand to use
  fun ref get_value(op_code : ISize, pos: USize) : ISize =>
    var mode : U8 = 0
    var result : ISize = 0

    match pos
    | 1 => mode = ((op_code / 100) % 10).u8()
    | 2 => mode = ((op_code / 1000) % 10).u8()
    | 3 => mode = ((op_code / 10000) % 10).u8()
    end

    try
      match mode
      | 0 => result = _tape(_tape(_pc + pos)?.usize())?
      | 1 => result = _tape(_pc + pos)?
      end
    else
      _env.out.print("Couldn't get value ")
      _running = false
    end

    result

  fun ref set_value(pos: USize, value: ISize) =>
    try
      _tape.update(pos, value)?
    else
      _env.out.print("Failed to update tape")
      _running = false
    end

  be set_input(addr: USize, value: ISize) =>
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
      _i.set_input(_addr, String.from_array(data).isize()?)
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

  fun input_to_ints(input: Array[String]) : Array[ISize] iso^ =>
    let a : Array[ISize] iso = recover iso Array[ISize] end

    for value in input.values() do
      try
        a.push(value.isize()?)
      end
    end

    consume a

  fun input_to_tape(path: FilePath val) : Array[ISize] iso^ =>
    let file = File.open(path)
    let input_string = file.read_string(10000)
    input_string.strip()
    let input : Array[String] = input_string.split_by(",")
    input_to_ints(consume input)
