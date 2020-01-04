use "files"
use "promises"

primitive Running
primitive Waiting
primitive Stopped
primitive Error

type IntState is (Running | Waiting | Stopped | Error)

actor IntcodeInterpreter
  let _tape : Array[ISize]
  let _env : Env
  var _pc : USize = 0
  var _running : IntState = Waiting
  let _input : Array[ISize] iso
  var _next : IntcodeInterpreter
  let _max : MaxSignal

  new create(phase: ISize, max': MaxSignal, env: Env) =>
    _input = [phase]
    _max = max'
    _env = env
    _next = this

    _tape = try
      let path = FilePath(_env.root as AmbientAuth, "input.text")?
      input_to_tape(path)
    else
      _env.out.print("Something went wrong")
      [99]
    end

  be receive_input(input': ISize) =>
    _input.push(input')

    // This is goofy but... it's actually Amplifier A
    // (and ONLY Amplifier A) that updates
    // the max value, because it receives the FINAL output from
    // Amplifier E as input but doesn't use it because all the amps
    // are done.
    match _running
    | Waiting => _running = Running; run_tape()
    | Stopped => _max.update(input')
    end

  be set_next(i: IntcodeInterpreter) =>
    _next = i

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
        set_value(_tape(_pc + 3)?.usize(), result)
      | 2 => // mul
        let result = get_value(full_code, 1) * get_value(full_code, 2)
        set_value(_tape(_pc + 3)?.usize(), result)
      | 3 => // read input
        if _input.size() == 0 then
          _running = Waiting
          step = 0
        else
          step = 2
          let addr = _tape(_pc + 1)?.usize()
          let value = _input.shift()?
          set_value(addr, value)
        end
      | 4 => // output value
        let result = get_value(full_code, 1)
        _next.receive_input(result)
        step = 2
      | 5 => // not eq zero
        let cond = get_value(full_code, 1)
        let addr = get_value(full_code, 2)

        if cond != 0 then
          _pc = addr.usize()
          step = 0
        else
          step = 3
        end
      | 6 => // equal zero
        let cond = get_value(full_code, 1)
        let addr = get_value(full_code, 2)

        if cond == 0 then
          _pc = addr.usize()
          step = 0
        else
          step = 3
        end
      | 7 => // less-than
        let lhs = get_value(full_code, 1)
        let rhs = get_value(full_code, 2)
        let addr = _tape(_pc + 3)?.usize()

        if lhs < rhs then
          set_value(addr, 1)
        else
          set_value(addr, 0)
        end
      | 8 => // equal-to
        let lhs = get_value(full_code, 1)
        let rhs = get_value(full_code, 2)
        let addr = _tape(_pc + 3)?.usize()

        if lhs == rhs then
          set_value(addr, 1)
        else
          set_value(addr, 0)
        end

      | 99 => // halt
        _running = Stopped
      else
        _env.out.print("Uh oh")
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
      end
    else
      _env.out.print("Couldn't get value")
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
    let input_string = file.read_string(10000)
    input_string.strip()
    let input : Array[String] = input_string.split_by(",")
    input_to_ints(input)

actor MaxSignal
  var max: ISize = 0
  let _env: Env

  new create(env: Env) =>
    _env = env

  be update(signal: ISize) =>
    if signal > max then
    _env.out.print(signal.string())
      max = signal
    end

actor Main
  let _env: Env
  let _max: MaxSignal

  new create(env: Env) =>
    _env = env
    _max = MaxSignal(env)
    let phases: Array[USize] = [5; 6; 7; 8; 9]
    generate(5, phases)

  fun run(phases: Array[USize]) =>
    try
      let i1 = IntcodeInterpreter(phases(0)?.isize(), _max, _env)
      let i2 = IntcodeInterpreter(phases(1)?.isize(), _max, _env)
      let i3 = IntcodeInterpreter(phases(2)?.isize(), _max, _env)
      let i4 = IntcodeInterpreter(phases(3)?.isize(), _max, _env)
      let i5 = IntcodeInterpreter(phases(4)?.isize(), _max, _env)

      i1.set_next(i2)
      i2.set_next(i3)
      i3.set_next(i4)
      i4.set_next(i5)
      i5.set_next(i1)

      i1.run_tape()
      i1.receive_input(0)
    end

  // From https://en.wikipedia.org/wiki/Heap%27s_algorithm
  fun generate(k: USize, phases: Array[USize]) =>
    if k == 1 then
      run(phases)
    else
      generate(k - 1, phases)

      var i : USize = 0

      while i < (k - 1) do
        if (k % 2) == 0 then
          try
            phases.swap_elements(i, k - 1)?
          end
        else
          try
            phases.swap_elements(0, k - 1)?
          end
        end

        generate(k - 1, phases)

        i = i + 1
      end
    end

  fun output(a: Array[USize]) =>
      for j in a.values() do
        _env.out.write(j.string())
      end
      _env.out.print("")
