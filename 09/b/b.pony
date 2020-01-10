use "files"
use "promises"

primitive Running
primitive Waiting
primitive Stopped
primitive Error

type IntState is (Running | Waiting | Stopped | Error)

actor IntcodeInterpreter
  let _input : Array[ISize] iso
  let _tape : Array[ISize]
  let _env : Env
  var _pc : USize = 0
  var _running : IntState = Running
  var _relative_base : ISize = 0

  new create(env: Env) =>
    _input = []
    _env = env

    _tape = try
      let path = FilePath(_env.root as AmbientAuth, "input.text")?
      input_to_tape(path)
    else
      _env.out.print("Something went wrong")
      [99]
    end

    _tape.concat(Array[ISize].init(0, 10000).values())

  be receive_input(input': ISize) =>
    _input.push(input')

    match _running
    | Waiting => _running = Running; run_tape()
    end

  be run_tape() =>
    _running = Running

    repeat
      execute()
    until
      match _running
      | Running => false
      | Waiting => true
      | Stopped => true
      | Error => true
      end
    end

  fun ref execute() =>
    var step : USize = 4

    try
      let full_code = _tape(_pc)?
      let op_code = full_code % 100

      match op_code
      | 1 => // add
        let result = get_value(full_code, 1) + get_value(full_code, 2)
        let addr = get_addr(full_code, 3)
        set_value(addr, result)
      | 2 => // mul
        let result = get_value(full_code, 1) * get_value(full_code, 2)
        let addr = get_addr(full_code, 3)
        set_value(addr, result)
      | 3 => // read input
        if _input.size() == 0 then
          _running = Waiting
          step = 0
        else
          step = 2
          let addr = get_addr(full_code, 1)
          let value = _input.shift()?
          set_value(addr, value)
        end
      | 4 => // output value
        let result = get_value(full_code, 1)
        _env.out.print(result.string())
        step = 2
      | 5 => // not eq zero
        let cond = get_value(full_code, 1)
        let addr = get_value(full_code, 2).usize()

        if cond != 0 then
          _pc = addr
          step = 0
        else
          step = 3
        end
      | 6 => // equal zero
        let cond = get_value(full_code, 1)
        let addr = get_value(full_code, 2).usize()

        if cond == 0 then
          _pc = addr
          step = 0
        else
          step = 3
        end
      | 7 => // less-than
        let lhs = get_value(full_code, 1)
        let rhs = get_value(full_code, 2)
        let addr = get_addr(full_code, 3)

        if lhs < rhs then
          set_value(addr, 1)
        else
          set_value(addr, 0)
        end
      | 8 => // equal-to
        let lhs = get_value(full_code, 1)
        let rhs = get_value(full_code, 2)
        let addr = get_addr(full_code, 3)

        if lhs == rhs then
          set_value(addr, 1)
        else
          set_value(addr, 0)
        end
      | 9 =>
        let adjustment = get_value(full_code, 1)
        _relative_base = _relative_base + adjustment
        step = 2
      | 99 => // halt
        _running = Stopped
      else
        _env.out.print("Uh oh " + full_code.string())
        _running = Error
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
      | 2 => result = _tape((_tape(_pc + pos)? + _relative_base).usize())?
      end
    else
      _env.out.print("Couldn't get value")
      _running = Error
    end

    result

  fun ref get_addr(op_code : ISize, pos: USize) : USize =>
    var mode : U8 = 0
    var result : USize = 0

    match pos
    | 1 => mode = ((op_code / 100) % 10).u8()
    | 2 => mode = ((op_code / 1000) % 10).u8()
    | 3 => mode = ((op_code / 10000) % 10).u8()
    end

    try
      match mode
      | 0 => result = _tape(_pc + pos)?.usize()
      | 1 => _env.out.print("1 MODE??"); result =  (_pc + pos).usize()
      | 2 => result = (_tape(_pc + pos)? + _relative_base).usize()
      end
    else
      _env.out.print("Couldn't get addr")
      _running = Error
    end

    result

  fun ref set_value(pos: USize, value: ISize) =>
    try
      _tape.update(pos, value)?
    else
      _env.out.print("Failed to update tape")
      _running = Error
    end

  fun tag input_to_ints(input: Array[String]) : Array[ISize] =>
    let a = Array[ISize]

    for value in input.values() do
      try
        a.push(value.isize()?)
      end
    end

    a

  fun tag input_to_tape(path: FilePath val) : Array[ISize] =>
    let file = File.open(path)
    let input_string = file.read_string(100000)
    input_string.strip()
    let input : Array[String] = input_string.split_by(",")
    input_to_ints(input)

actor Main
  let _env: Env

  new create(env: Env) =>
    _env = env

    let ici = IntcodeInterpreter(env)

    ici.run_tape()
    ici.receive_input(2)
