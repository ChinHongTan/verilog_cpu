from typing import Literal

opcode_map: dict[int, str] = {
    0: "NOP",
    1:  "ADD",
    2:  "SUB",
    3:  "MUL",
    4:  "DIV",
    5:  "ADDI",
    6:  "SUBI",
    7:  "MOV",
    8:  "LOAD",
    9:  "LOADI", 
    10: "LOADR", 
    11: "STORE", 
    12: "STORER",
    13: "JMP",
    14: "JNZ",
    15: "JAL",	  
    16: "JMPR",  
    17: "BEQ",
    18: "BNE",
    19: "BLT",
    20: "BGE",
    21: "HALT"
}

type DataType = Literal["REG", "IMM", "BRAM", "LABEL"]

INSTRUCTION_FORMATS: dict[str, list[tuple[DataType, int]]] = {
    "NOP":      [],                                         # 0 args
    "ADD":      [("REG", 3), ("REG", 3), ("REG", 3)],       # [3 bit reg, 3 bit reg, 3 bit reg]
    "SUB":      [("REG", 3), ("REG", 3), ("REG", 3)],       # [3 bit reg, 3 bit reg, 3 bit reg]
    "MUL":      [("REG", 3), ("REG", 3), ("REG", 3)],       # [3 bit reg, 3 bit reg, 3 bit reg]
    "DIV":      [("REG", 3), ("REG", 3), ("REG", 3)],       # [3 bit reg, 3 bit reg, 3 bit reg]
    "ADDI":     [("REG", 3), ("REG", 3), ("IMM", 16)],      # [3 bit reg, 3 bit reg, 16 bit literal]
    "SUBI":     [("REG", 3), ("REG", 3), ("IMM", 16)],      # [3 bit reg, 3 bit reg, 16 bit literal]
    "MOV":      [("REG", 3), ("REG", 3)],                   # [3 bit reg, 3 bit reg]
    "LOAD":     [("REG", 3), ("BRAM", 16)],                 # [3 bit reg, 16 bit BRAM]
    "LOADI":    [("REG", 3), ("IMM", 16)],                  # [3 bit reg, 16 bit literal]
    "LOADR":    [("REG", 3), ("REG", 3)],                   # [3 bit reg, 3 bit reg]
    "STORE":    [("REG", 3), ("BRAM", 16)],                 # [3 bit reg, 16 bit BRAM]
    "STORER":   [("REG", 3), ("REG", 3)],                   # [3 bit reg, 3 bit reg]
    "JMP":      [("REG", 3), ("LABEL", 16)],                # [3 bit padding, 16 bit label]
    "JNZ":      [("REG", 3), ("LABEL", 16)],                # [3 bit reg, 16 bit label]
    "JAL":      [("REG", 3), ("LABEL", 16)],                # [3 bit reg, 16 bit literal]
    "JMPR":     [("REG", 3)],                               # [3 bit reg]
    "BEQ":      [("REG", 3), ("REG", 3), ("LABEL", 16)],    # [3 bit reg, 3 bit reg, 16 bit label]
    "BNE":      [("REG", 3), ("REG", 3), ("LABEL", 16)],    # [3 bit reg, 3 bit reg, 16 bit label]
    "BLT":      [("REG", 3), ("REG", 3), ("LABEL", 16)],    # [3 bit reg, 3 bit reg, 16 bit label]
    "BGE":      [("REG", 3), ("REG", 3), ("LABEL", 16)],    # [3 bit reg, 3 bit reg, 16 bit label]
    "HALT":     [],                                         # 0 args
}

def decode(word: str) -> tuple[None | str, list[int]]:
    opcode_val = int(word[0:5], 2)
    if opcode_val not in opcode_map:
        return None, []
    opcode = opcode_map[opcode_val]
    
    format = INSTRUCTION_FORMATS[opcode]
    last_index = 5
    operands: list[int] = []
    for data in format:
        width = data[1]
        val = int(word[last_index:last_index + width], base=2)
        last_index += width
        operands.append(val)
    return opcode, operands

def disasm(opcode: str | None, operands: list[int]):
    if opcode is None:
        return "??? undecodable"
    parts = []
    for (kind, _w), val in zip(INSTRUCTION_FORMATS[opcode], operands):

        match kind:
            case "REG":
                parts.append(f"R{val}")
            case "BRAM":
                parts.append("DISPLAY" if val >= 65500 else f"[{val}]")
            case "LABEL":
                parts.append(f"{val}")
            case "IMM":
                parts.append(f"{val}")

    return f"{opcode:<7}{' '.join(parts)}"

def target_of(opcode: str, operands: list[int]):
    if opcode in ("BEQ", "BNE", "BLT", "BGE"):
        return operands[2]
    if opcode in ("JMP", "JNZ", "JAL"):
        return operands[1]
    return None

def check(program):
    problems = []
    for pc, (opcode, operands) in enumerate(program):
        if opcode is None:
            problems.append((pc, "Error", "Undecodeable instruction"))
            continue
        target = target_of(opcode, operands)
        if target is None:
            continue # not a jump
        elif target >= len(program):
            problems.append((pc, "Error", f"Target {target} is past the end of program"))
        elif target == pc + 1:
            problems.append((pc, "Error", f"Jump to {target}, which is the next instruction (pc + 1). Both path leads to the same place, so the branch can never run."))

    seen = set()
    stack = [0]
    while stack:
        pc = stack.pop()
        if pc in seen or pc >= len(program):
            continue # already seen this path / program out of bound
        seen.add(pc)
        opcode, operands = program[pc]
        if opcode == "HALT":
            continue
        elif opcode == "JMPR":
            problems.append((pc, "Info", f"Indirect jump target unresolveable. Skipping."))
            continue
        elif opcode == "JMP":
            stack.append(operands[1])
            continue # unconditional jump, only check the jump dest
        target = target_of(opcode, operands)
        if target is not None:
            stack.append(target) # check the branch, do not exit out of loop
        stack.append(pc + 1)

    for pc in range(len(program)):
        if pc not in seen:
            problems.append((pc, "Warn", "unreachable: nothing jumps or falls through to here"))
    
    return problems

reg = [0] * 8
Bram = [0] * 256  # 256 words of 32 bits each

def load():
    decoded_instructions: list[tuple[None | str, list[int]]] = []
    with open("ex1.mem", "r", encoding="utf-8") as f:
        words: list[str] = []
        for line in f:
            words.append(line)
        for w in words:
            decoded_instructions.append(decode(w))
    return decoded_instructions

step = 0
program = load()
seen_states: dict[tuple[int, tuple[int, ...]], int] = {}
outputs:list[int] = []
print("===== Disassembly =====")
for i, (o, a) in enumerate(program):
    print(f"{i:<4}{disasm(o, a)}")

print()
problems = check(program)
print("===== Program Check =====")
if problems:
    for pc, level, message in problems:
        print(f"[{level}] pc {pc}: {message}")
else:
    print("Clean")

print()
pc = 0
print("===== Run =====")
print("STEP   PC  OPCODE ARGUMENTS                 EFFECTS")
while True:
    if pc >= len(program):
        print(f"\n[Stopped] PC ran off the end of the program (pc={pc}).")
        break

    state = (pc, tuple(reg))
    if state in seen_states:
        print(f"\n[Stopped] Infinite loop: Step {step} reached the exact same state as step {seen_states[state]}.")
        print(f"          pc={pc} " + " ".join(f"R{i}={reg[i]}" for i in range(8)))
        break
    seen_states[state] = step
    opcode, args = program[pc]
    pc += 1
    note = ""
    before = reg.copy()

    match opcode:
        case "NOP":
            pass

        case "ADD":
            result = reg[args[1]] + reg[args[2]]
            if result > 65535:
                note = f"  <-- overflow, {result} wraps to {result & 65535}"
            reg[args[0]] = result & 65535
            
        case "SUB":
            result = reg[args[1]] - reg[args[2]]
            if result < 0:
                note = f"  <-- underflow, {result} wraps to {result & 65535}"
            reg[args[0]] = result & 65535
            
        case "MUL":
            result = reg[args[1]] * reg[args[2]]
            if result > 65535:
                note = f"  <-- overflow, {result} wraps to {result & 65535}"
            reg[args[0]] = result & 65535
            
        case "DIV":
            if reg[args[2]]:
                note = f"  <-- Division by zero!"
                break
            reg[args[0]] = (reg[args[1]] // reg[args[2]]) & 65535

        case "ADDI":
            result = reg[args[1]] + args[2]
            if result > 65535:
                note = f"  <-- overflow, {result} wraps to {result & 65535}"
            reg[args[0]] = result & 65535

        case "SUBI":
            result = reg[args[1]] - args[2]
            if result < 0:
                note = f"  <-- underflow, {result} wraps to {result & 65535}"
            reg[args[0]] = result & 65535
            
        case "MOV":
            reg[args[0]] = reg[args[1]]
            
        case "LOAD": # BRAM
            reg[args[0]] = Bram[args[1]]
            
        case "LOADI":
            reg[args[0]] = args[1]
            
        case "LOADR": # BRAM
            reg[args[0]] = Bram[args[1]]
            
        case "STORE": # BRAM
            if args[1] >= 65500:
                outputs.append(reg[args[0]])
                note += f"OUTPUT: {reg[args[0]]}"
            else:
                Bram[args[1]] = reg[args[0]]

        case "STORER":
            Bram[args[1]] = reg[args[0]]
            
        case "JMP":
            pc = args[1]
            
        case "JNZ":
            note = f"  [R{args[0]}={reg[args[0]]} -> {'taken' if reg[args[0]] != 0 else 'fall through'}]"
            if reg[args[0]] != 0:
                pc = args[1]
            
        case "JAL":
            reg[args[0]] = pc # pc already incremented in fetch
            pc = args[1]
            
        case "JMPR":
            pc = reg[args[0]]
            
        case "BEQ":
            note = f"  [R{args[0]}={reg[args[0]]} -> {'taken' if reg[args[0]] == reg[args[1]] else 'fall through'}]"
            if reg[args[0]] == reg[args[1]]:
                pc = args[2]
            
        case "BNE":
            note = f"  [R{args[0]}={reg[args[0]]} -> {'taken' if reg[args[0]] != reg[args[1]] else 'fall through'}]"
            if reg[args[0]] != reg[args[1]]:
                pc = args[2]           
            
        case "BLT":
            note = f"  [R{args[0]}={reg[args[0]]} -> {'taken' if reg[args[0]] <  reg[args[1]] else 'fall through'}]"
            if reg[args[0]] <  reg[args[1]]:
                pc = args[2]
            
        case "BGE":
            note = f"  [R{args[0]}={reg[args[0]]} -> {'taken' if reg[args[0]] >= reg[args[1]] else 'fall through'}]"
            if reg[args[0]] >= reg[args[1]]:
                pc = args[2]
            
        case "HALT":
            break
    changed = []
    for i in range(8):
        if reg[i] != before[i]:
            changed.append(f"R{i}:{before[i]}->{reg[i]}")
    
    # debug
    print(f"{step:>4}  {pc:>3}  {disasm(opcode, args):<24}  {" ".join(changed)}  {note}")
    step += 1

print(f"Outputs: {outputs}")