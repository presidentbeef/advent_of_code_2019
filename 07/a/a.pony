use "files"
use "promises"

actor IntcodeInterpreter
  let _tape : Array[ISize] iso
  let _env : Env
  var _pc : USize = 0
  var _running : Bool = false
  let _input : Array[ISize] iso
  var _output : ISize

  new create(tape': Array[ISize] iso, input': Array[ISize] iso, env: Env) =>
    _tape = consume tape'
    _env = env
    _output = -1
    _input = consume input'

  be run_tape(p: Promise[ISize]) =>
    _running = true

    repeat
      execute()
    until not _running end

    p(_output)

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
        step = 2
        let addr = _tape(_pc + 1)?.usize()
        let value = _input.pop()?
        set_value(addr, value)
      | 4 => // output value
        let result = get_value(full_code, 1)
        _output = result
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
        _running = false
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
      _env.out.print("Couldn't get value")
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

class Runner is Fulfill[ISize, None]
  let _env: Env
  let _phase: ISize
  let p : Promise[ISize]

  new iso create(env: Env, phase: ISize) =>
    _env = env
    _phase = phase
    p = Promise[ISize]

  fun apply(signal: ISize) =>
    try
      let path = FilePath(_env.root as AmbientAuth, "input.text")?
      let tape = recover iso input_to_tape(path) end
      let machine = IntcodeInterpreter(consume tape, [signal; _phase], _env)
      machine.run_tape(p)
    else
      _env.out.print("Something went wrong")
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
    let phases: Array[USize] = [0; 1; 2; 3; 4]

    var i: U8 = 0
    generate(5, phases)

  fun run(phases: Array[USize]) =>
    try
      let r1 = Runner(_env, phases(0)?.isize())
      let r2 = Runner(_env, phases(1)?.isize())
      let r3 = Runner(_env, phases(2)?.isize())
      let r4 = Runner(_env, phases(3)?.isize())
      let r5 = Runner(_env, phases(4)?.isize())

      r5.p.next[None](_max~update())
      r4.p.next[None](consume r5)
      r3.p.next[None](consume r4)
      r2.p.next[None](consume r3)
      r1.p.next[None](consume r2)
      r1(0)
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
